//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/migration/migration_util.dart';
import 'package:autonomy_flutter/util/social_recovery_channel.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:libauk_dart/libauk_dart.dart';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:http/http.dart' as http;

enum SocialRecoveryStep {
  SetupShardService,
  SetupEmergencyContact,
  Done,
  RestartWhenHasChanges,
  RestartWhenLostPlatform,
}

abstract class SocialRecoveryService {
  ValueNotifier<SocialRecoveryStep?> get socialRecoveryStep;
  Future refreshSetupStep();
  Future sendDeckToShardService(String domain, String code);
  Future<String> getEmergencyContactDeck();
  Future doneSetupEmergencyContact();

  Future<ShardDeck> requestDeckFromShardService(String domain, String code);
  Future<bool> hasPlatformShards();
  Future restoreAccountWithPlatformKey(ShardDeck shardDeck);
  Future restoreAccount(ShardDeck shardDeck1, ShardDeck shardDeck2);
  Future clearRestoreProcess();

  Future<List<ContactDeck>> getContactDecks();
  Future storeContactDeck(ContactDeck contactDeck);
  Future deleteHelpingContactDecks();

  Future<String> storeDataInTempSecretFile(String data);
  Future cleanTempSecretFile();
}

class SocialRecoveryServiceImpl extends SocialRecoveryService {
  ValueNotifier<SocialRecoveryStep?> socialRecoveryStep = ValueNotifier(null);

  late SocialRecoveryChannel _socialRecoveryChannel;
  CloudDatabase _cloudDB;
  AccountService _accountService;
  AuditService _auditService;
  ConfigurationService _configurationService;
  BackupService _backupService;

  SocialRecoveryServiceImpl(
    this._cloudDB,
    this._accountService,
    this._auditService,
    this._configurationService,
    this._backupService,
  ) {
    _socialRecoveryChannel = SocialRecoveryChannel();
    refreshSetupStep();
  }

  Future refreshSetupStep() async {
    // NOTE: Update this when support Social Recovery in Android
    if (!Platform.isIOS) return;

    final account = await _accountService.getCurrentDefaultAccount();
    if (account == null) return;

    if (await account.getShard(ShardType.Platform) == null) {
      // Has not setupSSKR or LostPlatform
      final lastAudit = (await _cloudDB.auditDao
              .getAuditsByCategoryActions([], ['SetupSSKR', 'Done']))
          .firstOrNull;
      socialRecoveryStep.value = lastAudit != null
          ? SocialRecoveryStep.RestartWhenLostPlatform
          : SocialRecoveryStep.SetupShardService;
    } else {
      // has setupSSKR

      if (await account.getShard(ShardType.ShardService) != null) {
        // setupSSKR but hasn't done to send ShardDeck to ShardService
        socialRecoveryStep.value = SocialRecoveryStep.SetupShardService;
      } else {
        // done send ShardDeck to shard service

        // Check history to see if user deleted/added accounts after setupSSKR
        final lastAudit = (await _cloudDB.auditDao
                .getAuditsByCategoryActions([], ['setupSSKR']))
            .firstOrNull;

        if (lastAudit != null) {
          final accountUUIDs =
              (await _cloudDB.personaDao.getPersonas()).map((e) => e.uuid);
          final setupAccountUUIDs =
              List<String>.from(json.decode(lastAudit.metadata)['setupUUIDs']);
          final differences =
              accountUUIDs.toSet().difference(setupAccountUUIDs.toSet());
          if (differences.isNotEmpty) {
            socialRecoveryStep.value = SocialRecoveryStep.RestartWhenHasChanges;
            return;
          }
        }

        if (await account.getShard(ShardType.EmergencyContact) != null) {
          // has not setup EmergencyContact
          socialRecoveryStep.value = SocialRecoveryStep.SetupEmergencyContact;
        } else {
          // has setup EmergencyContact
          socialRecoveryStep.value = SocialRecoveryStep.Done;
        }
      }
    }
  }

  Future sendDeckToShardService(String domain, String code) async {
    // Create ShardService's ShardDeck
    // Send ShardDeck to ShardService with OTP Code
    final shardDeck =
        await _getShardDeckFromAccounts(ShardType.ShardService, runSSKR: true);
    final body = {"code": code, "secret": jsonEncode(shardDeck.toJson())};

    final response = await http.put(
      Uri.parse(domain + "/apis/v1/shard"),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      response.body.contains('invalid OTP token')
          ? throw ExpiredCodeLink()
          : throw Exception(response.body);
    } else {
      // Done
      final accounts = await _cloudDB.personaDao.getPersonas();
      await _removeShards(accounts, ShardType.ShardService);
      final setupUUIDs = [shardDeck.defaultAccount.uuid] +
          shardDeck.otherAccounts.map((e) => e.uuid).toList();
      await _auditService.auditSocialRecoveryAction(
          'setupSSKR', json.encode({'setupUUIDs': setupUUIDs}));
      socialRecoveryStep.value = SocialRecoveryStep.SetupEmergencyContact;
    }
  }

  Future<String> getEmergencyContactDeck() async {
    final shardDeck =
        await _getShardDeckFromAccounts(ShardType.EmergencyContact);
    return storeDataInTempSecretFile(jsonEncode(shardDeck));
  }

  Future doneSetupEmergencyContact() async {
    final accounts = await _cloudDB.personaDao.getPersonas();

    await _removeShards(accounts, ShardType.EmergencyContact);
    socialRecoveryStep.value = SocialRecoveryStep.Done;
    await _auditService.auditSocialRecoveryAction('Done', '');
  }

  Future<String> storeDataInTempSecretFile(String data) async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String filePath =
        '${appDocumentsDirectory.path}/social-recovery/secret.json';

    File file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(utf8.encode(data));

    return filePath;
  }

  Future cleanTempSecretFile() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String filePath =
        '${appDocumentsDirectory.path}/social-recovery/secret.json';
    File file = File(filePath);
    if (await file.exists()) {
      file.delete();
    }
  }

  Future<ShardDeck> requestDeckFromShardService(
      String domain, String code) async {
    // Get ShardDeck to ShardService with OTP Code
    final response = await http.get(
      Uri.parse(domain + "/apis/v1/shard?code=$code"),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );

    if (response.statusCode != 200) {
      response.body.contains('invalid OTP token')
          ? throw ExpiredCodeLink()
          : throw Exception(response.body);
    } else {
      final body = jsonDecode(response.body);
      return ShardDeck.fromJson(jsonDecode(body['secret']));
    }
  }

  Future<bool> hasPlatformShards() {
    return LibAukDart.general().hasPlatformShards();
  }

  Future restoreAccountWithPlatformKey(ShardDeck shardDeck) async {
    // Restore Default Account
    final defaultAccountUUID = shardDeck.defaultAccount.uuid;
    List<String> otherAccountUUIDs = [];

    for (final otherAccount in shardDeck.otherAccounts) {
      otherAccountUUIDs.add(otherAccount.uuid);
    }

    final platformDeck = await _getShardDeck(
      defaultAccountUUID,
      otherAccountUUIDs,
      ShardType.Platform,
      throwExceptionForOthers: false,
    );
    restoreAccount(platformDeck, shardDeck);
  }

  Future restoreAccount(ShardDeck shardDeck1, ShardDeck shardDeck2) async {
    // Restore Default Account
    final defaultAccountUUID = shardDeck1.defaultAccount.uuid;
    final defaultShares = [
      shardDeck1.defaultAccount.shard,
      shardDeck2.defaultAccount.shard
    ];

    final defaultAccountWallet = LibAukDart.getWallet(defaultAccountUUID);
    await defaultAccountWallet.restoreByBytewordShards(defaultShares,
        name: "Default");

    // -- Restore other accounts
    Map<String, List<dynamic>> accountsInfo = {};

    try {
      final backupVersion =
          await _backupService.fetchBackupVersion(defaultAccountWallet);

      if (backupVersion.isNotEmpty) {
        await _backupService.restoreCloudDatabase(
            defaultAccountWallet, backupVersion);

        // Get name and creationDate
        for (final persona in await _cloudDB.personaDao.getPersonas()) {
          accountsInfo[persona.uuid] = [persona.name, persona.createdAt];
        }
      }
    } catch (exception) {
      // Avoid interrupting restore keys, so skip if error when getting publicData
      Sentry.captureException(exception);
    }

    // Get shares from shardServiceDeck
    Map<String, String> accountsShards = {};
    for (final info in shardDeck1.otherAccounts) {
      accountsShards[info.uuid] = info.shard;
    }

    for (final info in shardDeck2.otherAccounts) {
      final shard = accountsShards[info.uuid];
      if (shard == null) continue; // ignore if doesn't have 2 shards

      final shards = [shard, info.shard];
      final accountInfo = accountsInfo[info.uuid];

      await LibAukDart.getWallet(info.uuid).restoreByBytewordShards(
        shards,
        name: accountInfo?[0],
        creationDate: accountInfo?[1],
      );
    }

    // Update defaultAccount's name in Keychain (after getting name from publicData)
    final defaultName = accountsInfo[defaultAccountUUID]?[0];
    if (defaultName != null && defaultName!.isNotEmpty)
      defaultAccountWallet.updateName(defaultName);

    injector<MigrationUtil>().migrationFromKeychain();

    // Done
    await _configurationService.setCachedDeckFromShardService(null);
    await _cloudDB.personaDao.setUniqueDefaultAccount(defaultAccountUUID);
    await _configurationService.setDoneOnboarding(true);
    await injector<AWSService>().initServices();
  }

  Future clearRestoreProcess() async {
    await _configurationService.setCachedDeckFromShardService(null);
  }

  Future<List<ContactDeck>> getContactDecks() async {
    return await _socialRecoveryChannel.getContactDecks();
  }

  Future storeContactDeck(ContactDeck contactDeck) async {
    return _socialRecoveryChannel.storeContactDeck(contactDeck);
  }

  Future deleteHelpingContactDecks() async {
    await _socialRecoveryChannel.deleteHelpingContactDecks();
  }

  Future<ShardDeck> _getShardDeckFromAccounts(
    ShardType shardType, {
    bool runSSKR = false,
  }) async {
    final defaultAccount = await _accountService.getCurrentDefaultAccount();
    if (defaultAccount == null) throw IncorrectFlow();

    if (runSSKR) await defaultAccount.setupSSKR();

    final accounts = await _cloudDB.personaDao.getPersonas();
    List<String> otherAccountUUIDs = [];
    for (final account in accounts) {
      final wallet = LibAukDart.getWallet(account.uuid);

      if (account.uuid == defaultAccount.uuid ||
          ((await wallet.getETHAddress()).isEmpty)) continue;
      otherAccountUUIDs.add(account.uuid);
      if (runSSKR) await wallet.setupSSKR();
    }

    return _getShardDeck(defaultAccount.uuid, otherAccountUUIDs, shardType);
  }

  Future<ShardDeck> _getShardDeck(
    String defaultUUID,
    List<String> otherUUIDs,
    ShardType shardType, {
    bool throwExceptionForOthers = true,
  }) async {
    String? defaultShard =
        await LibAukDart.getWallet(defaultUUID).getShard(shardType);
    if (defaultShard == null) throw SocialRecoveryMissingShard();

    ShardInfo defaultAccount =
        ShardInfo(uuid: defaultUUID, shard: defaultShard);
    List<ShardInfo> otherAccounts = [];

    for (final otherUUID in otherUUIDs) {
      String? shard = await LibAukDart.getWallet(otherUUID).getShard(shardType);

      if (shard != null) {
        otherAccounts.add(ShardInfo(uuid: otherUUID, shard: shard));
      } else {
        if (throwExceptionForOthers) throw SocialRecoveryMissingShard();
      }
    }

    return ShardDeck(
      defaultAccount: defaultAccount,
      otherAccounts: otherAccounts,
    );
  }

  Future _removeShards(List<Persona> accounts, ShardType shardType) async {
    for (final account in accounts) {
      await LibAukDart.getWallet(account.uuid).removeShard(shardType);
    }
  }
}
