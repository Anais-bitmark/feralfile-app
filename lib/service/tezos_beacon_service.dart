//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

class TezosBeaconService implements BeaconHandler {
  final NavigationService _navigationService;
  final CloudDatabase _cloudDB;
  final List<BeaconRequest> _handlingRequests = [];

  late TezosBeaconChannel _beaconChannel;
  P2PPeer? _currentPeer;

  bool _addedConnectionFlag = false;
  bool _requestSignMessageForConnectionFlag = false;
  Timer? _timer;

  TezosBeaconService(this._navigationService, this._cloudDB) {
    _beaconChannel = TezosBeaconChannel(handler: this);
    unawaited(_beaconChannel.connect());
  }

  void _addedConnection() {
    _addedConnectionFlag = true;
    Future.delayed(const Duration(seconds: 10), () {
      _addedConnectionFlag = false;
    });
  }

  void _clearConnectFlag() {
    _addedConnectionFlag = false;
    _requestSignMessageForConnectionFlag = false;
  }

  void _requestSignMessageForConnection() {
    if (_addedConnectionFlag) {
      _requestSignMessageForConnectionFlag = true;
      _addedConnectionFlag = false;
    }
  }

  void _showYouAllSet() {
    if (_requestSignMessageForConnectionFlag) {
      _requestSignMessageForConnectionFlag = false;
      Future.delayed(const Duration(seconds: 3), () {
        showInfoNotification(const Key('switchBack'), 'you_all_set'.tr());
      });
    }
  }

  Future addPeer(String link, {Function()? onTimeout}) async {
    const maxRetries = 3;
    _timer?.cancel();
    _timer = Timer(CONNECT_FAILED_DURATION, () {
      onTimeout?.call();
      _beaconChannel.connect();
    });
    var retryCount = 0;
    do {
      try {
        final peer = await _beaconChannel.addPeer(link);
        _currentPeer = peer;
        return;
      } catch (_) {
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
      }
    } while (retryCount < maxRetries);
    if (retryCount >= maxRetries) {
      memoryValues.deepLink.value = null;
    }
  }

  Future removePeer(P2PPeer peer) async {
    await _beaconChannel.removePeer(peer);
  }

  Future permissionResponse(String? uuid, int? index, String id,
      String? publicKey, String? address) async {
    await _beaconChannel.permissionResponse(id, publicKey, address);

    if (_currentPeer != null && uuid != null && index != null) {
      final peer = _currentPeer!;
      final bcConnection =
          BeaconConnectConnection(personaUuid: uuid, index: index, peer: peer);

      final connection = Connection(
        key: peer.id,
        name: peer.name,
        data: json.encode(bcConnection),
        connectionType: ConnectionType.beaconP2PPeer.rawValue,
        accountNumber: address ?? '',
        createdAt: DateTime.now(),
      );
      unawaited(_cloudDB.connectionDao.insertConnection(connection));
      _addedConnection();
    }
  }

  Future signResponse(String id, String? signature) =>
      _beaconChannel.signResponse(id, signature);

  Future operationResponse(String id, String? txHash) =>
      _beaconChannel.operationResponse(id, txHash);

  @override
  void onRequest(BeaconRequest request) {
    log.info('TezosBeaconService: onRequest');
    _handlingRequests.add(request);
    if (_handlingRequests.length == 1) {
      unawaited(handleNextRequest());
    }
  }

  Future<void> handleNextRequest({bool isRemoved = false}) async {
    log.info('TezosBeaconService: handleRequest');
    if (isRemoved && _handlingRequests.isNotEmpty) {
      _handlingRequests.removeAt(0);
    }
    if (_handlingRequests.isEmpty) {
      return;
    }
    final request = _handlingRequests.first;
    if (request.type == 'permission') {
      _navigationService.hideInfoDialog();
      hideOverlay(NavigationService.contactingKey);
      _timer?.cancel();
      unawaited(_navigationService.navigateTo(AppRouter.tbConnectPage,
          arguments: request));
    } else if (request.type == 'signPayload') {
      _requestSignMessageForConnection();
      final result = await _navigationService
          .navigateTo(AppRouter.tbSignMessagePage, arguments: request);
      log.info('TezosBeaconService: handle permission Request result: $result');
      if (result) {
        _showYouAllSet();
      }
      _clearConnectFlag();
    } else if (request.type == 'operation') {
      unawaited(_navigationService.navigateTo(AppRouter.tbSendTransactionPage,
          arguments: request));
    }
  }

  @override
  void onAbort() {
    log.info('TezosBeaconService: onAbort');
    UIHelper.hideInfoDialog(_navigationService.navigatorKey.currentContext!);
  }

  @override
  void onRequestedPermission(Peer peer) {
    log.info('TezosBeaconService: ${peer.toJson()}');
    unawaited(UIHelper.showInfoDialog(
      _navigationService.navigatorKey.currentContext!,
      'link_requested'.tr(),
      'autonomy_has_sent'.tr(args: [peer.name]),
      isDismissible: true,
    ));
    //"Autonomy has sent a request to ${peer.name} to link to your account."
    //   " Please open the wallet and authorize the request. ");
  }

  Future<Connection?> getExistingAccount(String accountNumber) async {
    final existingConnections = await _cloudDB.connectionDao
        .getConnectionsByAccountNumber(accountNumber);

    if (existingConnections.isEmpty) {
      return null;
    }
    return existingConnections.first;
  }

  Future cleanup() async {
    final connections = await _cloudDB.connectionDao
        .getConnectionsByType(ConnectionType.beaconP2PPeer.rawValue);

    // retains connections under 7 days old and limit to 5 connections.
    while (connections.length > 5 &&
        connections.last.createdAt
            .isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
      connections.removeLast();
    }

    final ids = connections
        .map((e) => e.beaconConnectConnection?.peer.id)
        .whereNotNull()
        .toList();

    unawaited(_beaconChannel.cleanup(ids));
  }
}
