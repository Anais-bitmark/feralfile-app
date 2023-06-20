//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

part 'accounts_state.dart';

class AccountsBloc extends AuBloc<AccountsEvent, AccountsState> {
  final ConfigurationService _configurationService;
  final CloudDatabase _cloudDB;
  final BackupService _backupService;
  final AuditService _auditService;
  final AccountService _accountService;

  AccountsBloc(this._configurationService, this._cloudDB, this._backupService,
      this._auditService, this._accountService)
      : super(AccountsState()) {
    on<ResetEventEvent>((event, emit) async {
      emit(state.setEvent(null));
    });

    on<GetAccountsEvent>((event, emit) async {
      final connectionsFuture =
          _cloudDB.connectionDao.getUpdatedLinkedAccounts();
      final addresses = await _cloudDB.addressDao.getAllAddresses();

      List<Account> accounts =
          await getAccountPersona(addresses, addDefault: true);

      final connections = await connectionsFuture;
      for (var connection in connections) {
        final cryptoType = CryptoType.fromAddress(connection.key).source;
        final name = connection.name.isNotEmpty ? connection.name : cryptoType;
        switch (connection.connectionType) {
          case 'feralFileWeb3':
          case "feralFileToken":
            final source = connection.ffConnection?.source ??
                connection.ffWeb3Connection?.source;
            if (source == null) continue;

            final accountNumber = connection.accountNumber;
            try {
              final account = accounts.firstWhere(
                  (element) => element.accountNumber == accountNumber);
              account.connections?.add(connection);
            } catch (error) {
              accounts.add(Account(
                  key: connection.key,
                  accountNumber: accountNumber,
                  connections: [connection],
                  blockchain: cryptoType,
                  name: name,
                  createdAt: connection.createdAt));
            }
            break;

          default:
            accounts.add(Account(
              key: connection.key,
              accountNumber: connection.accountNumber,
              connections: [connection],
              blockchain: cryptoType,
              name: name,
              createdAt: connection.createdAt,
            ));
            break;
        }
      }

      if (accounts.isEmpty) {
        await _backupService
            .deleteAllProfiles(await _accountService.getDefaultAccount());
        await _cloudDB.personaDao.removeAll();
        await _cloudDB.connectionDao.removeAll();
        await _auditService.auditPersonaAction('cleanUp', null);
      }

      accounts.sort(_compareAccount);

      emit(AccountsState(accounts: accounts));
    });

    on<GetAccountsIRLEvent>((event, emit) async {
      final addresses = await _cloudDB.addressDao.getAllAddresses();

      List<Account> accounts =
          await getAccountPersona(addresses, addDefault: true);

      accounts.sort(_compareAccount);
      emit(AccountsState(accounts: accounts));
    });

    on<GetCategorizedAccountsEvent>((event, emit) async {
      late List<WalletAddress> addresses;
      final type =
          WalletType.getWallet(eth: event.getEth, tezos: event.getTezos);
      switch (type) {
        case WalletType.Autonomy:
          addresses = await _cloudDB.addressDao.getAllAddresses();
          break;
        case WalletType.Ethereum:
          addresses = await _cloudDB.addressDao
              .getAddressesByType(CryptoType.ETH.source);
          break;
        case WalletType.Tezos:
          addresses = await _cloudDB.addressDao
              .getAddressesByType(CryptoType.XTZ.source);
          break;
        default:
          addresses = [];
      }

      List<Account> accounts = await getAccountPersona(addresses,
          addDefault: type == WalletType.Autonomy);
      accounts.sort(_compareAccount);
      emit(state.copyWith(accounts: accounts));
    });

    on<LinkLedgerWalletEvent>((event, emit) async {
      var connection =
          await _cloudDB.connectionDao.findById(event.ledgerBLEUUID);
      if (connection != null &&
          connection.accountNumber.contains(event.address)) {
        emit(state.setEvent(AlreadyLinkedError(connection)));
        return;
      }

      var data = LedgerConnection(
          ledgerName: event.ledgerName,
          ledgerUUID: event.ledgerBLEUUID,
          etheremAddress: [],
          tezosAddress: []);

      if (connection != null) {
        data = LedgerConnection.fromJson(json.decode(connection.data));
      }

      switch (event.blockchain) {
        case "Ethereum":
          data.etheremAddress.add(event.address.getETHEip55Address());
          break;
        case "Tezos":
          data.tezosAddress.add(event.address);
          break;
        default:
          throw "Unhandled blockchain ${event.blockchain}";
      }

      final newConnection = Connection(
        key: event.ledgerBLEUUID,
        name: connection?.name ?? event.ledgerName,
        data: json.encode(data),
        connectionType: ConnectionType.ledger.rawValue,
        accountNumber:
            ((connection?.accountNumbers ?? []) + [event.address]).join("||"),
        createdAt: connection?.createdAt ?? DateTime.now(),
      );

      _cloudDB.connectionDao.insertConnection(newConnection);
      emit(state.setEvent(LinkAccountSuccess(newConnection)));

      final metricClient = injector.get<MetricClientService>();

      metricClient.addEvent(
        MixpanelEvent.linkLedger,
        data: {"blockchain": event.blockchain},
        hashedData: {"address": event.address},
      );
      add(GetAccountsEvent());
    });

    on<NameLinkedAccountEvent>((event, emit) {
      final connection = event.connection;
      connection.name = event.name;

      _cloudDB.connectionDao.updateConnection(connection);
      add(GetAccountsEvent());
    });

    on<FetchAllAddressesEvent>((event, emit) async {
      List<String> addresses = [];
      if (_configurationService.isDemoArtworksMode()) {
        addresses = [await getDemoAccount()];
      } else {
        final personas = await _cloudDB.personaDao.getPersonas();

        for (var persona in personas) {
          addresses.addAll(await persona.getAddresses());
        }

        final linkedAccounts = await _cloudDB.connectionDao.getConnections();
        addresses.addAll(linkedAccounts.expand((e) => e.accountNumbers));
        addresses.removeWhere((e) => e == '');
      }

      final newState = state.copyWith(
          addresses: addresses,
          event: FetchAllAddressesSuccessEvent(addresses));
      emit(newState);

      // reset the event after triggering
      await Future.delayed(const Duration(milliseconds: 500), () {
        emit(newState.setEvent(null));
      });
    });

    on<FindAccount>((event, emit) async {
      final persona = await _cloudDB.personaDao.findById(event.personaUUID);
      List<Account> accounts = [];
      if (persona != null) {
        accounts.add(Account(
            key: persona.uuid,
            persona: persona,
            name: persona.name,
            blockchain: event.type.source,
            accountNumber: event.address,
            createdAt: persona.createdAt));
      }
      emit(AccountsState(accounts: accounts));
    });

    on<FindLinkedAccount>((event, emit) async {
      final connection =
          await _cloudDB.connectionDao.findById(event.connectionKey);
      List<Account> accounts = [];
      if (connection != null) {
        accounts.add(Account(
            key: connection.key,
            name: connection.name,
            blockchain: event.type.source,
            accountNumber: event.address,
            connections: [connection],
            createdAt: connection.createdAt));
      }
      emit(AccountsState(accounts: accounts));
    });
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) return null;

    return existingConnections.first;
  }

  Future<List<Account>> getAccountPersona(List<WalletAddress> walletAddresses,
      {bool addDefault = false}) async {
    final personas = await _cloudDB.personaDao.getPersonas();
    final List<WalletAddress> addresses = [];
    addresses.addAll(walletAddresses);
    if (walletAddresses.isEmpty && addDefault) {
      final defaultPersona =
          personas.firstWhere((element) => element.isDefault());
      final defaultAddresses =
          await defaultPersona.insertAddress(WalletType.Autonomy);
      addresses.addAll(defaultAddresses);
    }
    List<Account> accounts = [];
    for (var e in addresses) {
      final persona =
          personas.firstWhereOrNull((element) => element.uuid == e.uuid);
      if (persona != null) {
        accounts.add(Account(
            key: e.address,
            persona: persona,
            name: e.name ?? e.cryptoType,
            blockchain: e.cryptoType,
            walletAddress: e,
            accountNumber: e.address,
            createdAt: e.createdAt));
      }
    }
    return accounts;
  }

  int _compareAccount(Account a, Account b) {
    final aDefault = a.persona?.defaultAccount ?? 0;
    final bDefault = b.persona?.defaultAccount ?? 0;
    if (aDefault != bDefault) {
      return bDefault.compareTo(aDefault);
    }
    return a.createdAt.compareTo(b.createdAt);
  }
}
