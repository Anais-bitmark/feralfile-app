//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/postcard_bigmap.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/request_response.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';

abstract class PostcardService {
  Future<ReceivePostcardResponse> receivePostcard(
      {required String shareCode,
      required Position location,
      required String address});

  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request);

  Future<SharePostcardResponse> sharePostcard(AssetToken asset);

  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode);

  Future<AssetToken> getPostcard(String tokenId);

  Future<bool> stampPostcard(
      String tokenId,
      WalletStorage wallet,
      int index,
      File image,
      File metadata,
      Position? location,
      int counter,
      String contractAddress);

  Future<bool> isReceivedSuccess(
      {required contractAddress,
      required String address,
      required String tokenId,
      required int counter});

  Future<PostcardValue?> getPostcardValue({
    required contractAddress,
    required String tokenId,
  });

  List<StampingPostcard> getStampingPostcard();

  StampingPostcard? getStampingPostcardWithPath(
      StampingPostcard stampingPostcard);

  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false});
}

class PostcardServiceImpl extends PostcardService {
  final PostcardApi _postcardApi;
  final TezosService _tezosService;
  final IndexerService _indexerService;
  final _tzktApi = injector<TZKTApi>();
  final _configurationService = injector<ConfigurationService>();

  PostcardServiceImpl(
      this._postcardApi, this._tezosService, this._indexerService);

  @override
  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request) async {
    return _postcardApi.claim(request);
  }

  @override
  Future<ReceivePostcardResponse> receivePostcard({
    required String shareCode,
    required Position location,
    required String address,
  }) async {
    try {
      final body = {
        "shareCode": shareCode,
        "location": [location.latitude, location.longitude],
        "address": address,
      };
      final respone = await _postcardApi.receive(body);
      return respone;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SharePostcardResponse> sharePostcard(AssetToken asset) async {
    final owner = await asset.getOwnerWallet();
    final ownerWallet = owner?.first;
    final addressIndex = owner?.second;
    if (ownerWallet == null) {
      throw Exception("Owner wallet is null");
    }
    final counter = asset.postcardMetadata.counter;
    final contractAddress = asset.contractAddress ?? '';
    final tokenId = asset.tokenId ?? '';
    final data = [
      TezosPack.packAddress(contractAddress),
      TezosPack.packInteger(int.parse(tokenId)),
      TezosPack.packInteger(counter),
    ].toList();

    final message2sign = getMessage2Sign(data);
    final publicKey = await ownerWallet.getTezosPublicKey(index: addressIndex!);
    final signature = await _tezosService.signMessage(
        ownerWallet, addressIndex, Uint8List.fromList(message2sign));
    final body = {
      "address": asset.owner,
      "contractAddress": asset.contractAddress,
      "signature": signature,
      "publicKey": publicKey,
      "counter": counter,
    };
    try {
      final response = await _postcardApi.share(tokenId, body);

      final deeplink = response["deeplink"];
      return SharePostcardResponse(deeplink: deeplink);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AssetToken> getPostcard(String tokenId) async {
    final request = QueryListTokensRequest(
      ids: [tokenId],
    );
    final assets = await _indexerService.getNftTokens(request);
    return assets.first;
  }

  @override
  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode) async {
    try {
      final response = await _postcardApi.claimShareCode(shareCode);
      response["shareCode"] = shareCode;
      final sharedPostcardInfor = SharedPostcardInfor.fromJson(response);
      return sharedPostcardInfor;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> stampPostcard(
      String tokenId,
      WalletStorage wallet,
      int index,
      File image,
      File metadata,
      Position? location,
      int counter,
      String contractAddress) async {
    try {
      final data = [
        TezosPack.packAddress(contractAddress),
        TezosPack.packInteger(int.parse(tokenId)),
        TezosPack.packInteger(counter)
      ].toList();

      final message2sign = getMessage2Sign(data);

      final signature = await _tezosService.signMessage(
          wallet, index, Uint8List.fromList(message2sign));
      final address = await wallet.getTezosAddress(index: index);
      final publicKey = await wallet.getTezosPublicKey(index: index);
      final lat = location?.latitude;
      final lon = location?.longitude;
      final result = await _postcardApi.updatePostcard(
          tokenId: tokenId,
          data: image,
          metadata: metadata,
          signature: signature,
          address: address,
          publicKey: publicKey,
          lat: lat,
          lon: lon,
          counter: counter) as Map<String, dynamic>;

      final ok = result["metadataCID"] as String;
      return ok.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isReceivedSuccess(
      {required contractAddress,
      required String address,
      required String tokenId,
      required int counter}) async {
    final postcardData = await getPostcardValue(
        contractAddress: contractAddress, tokenId: tokenId);
    if (postcardData == null) return false;
    if (postcardData.counter == counter && postcardData.postman == address) {
      return true;
    }
    return false;
  }

  @override
  Future<PostcardValue?> getPostcardValue({
    required contractAddress,
    required String tokenId,
  }) async {
    final ptr = await _tzktApi.getBigMapsId(contract: contractAddress);
    if (ptr.isEmpty) return null;
    final bigMapId = ptr.first;
    final result = await _tzktApi.getBigMaps(bigMapId, key: tokenId);
    if (result.isEmpty) return null;
    return result.first;
  }

  @override
  List<StampingPostcard> getStampingPostcard() {
    return _configurationService.getStampingPostcard();
  }

  @override
  Future<void> updateStampingPostcard(List<StampingPostcard> values,
      {bool override = false, bool isRemove = false}) async {
    await _configurationService.updateStampingPostcard(values,
        override: override, isRemove: isRemove);
    if (isRemove) {
      Future.delayed(const Duration(seconds: 2), () async {
        for (var element in values) {
          final imageFile = File(element.imagePath);
          if (await imageFile.exists()) {
            imageFile.deleteSync();
          }
          final metadataFile = File(element.metadataPath);
          if (await metadataFile.exists()) {
            metadataFile.deleteSync();
          }
        }
      });
    }
  }

  List<int> getMessage2Sign(List<Uint8List> data) {
    final prefix = utf8.encode(POSTCARD_SIGN_PREFIX);
    final sep = utf8.encode("|");
    final lst = data.mapIndexed((index, e) {
      if (index == data.length - 1) {
        return e;
      }
      return e.toList()..addAll(sep);
    }).toList();

    final message2sign = prefix.toList()
      ..addAll(
        lst.reduce(
          (value, element) {
            return value + element;
          },
        ),
      );
    return message2sign;
  }

  @override
  StampingPostcard? getStampingPostcardWithPath(
      StampingPostcard stampingPostcard) {
    final stampingPostcards = getStampingPostcard();
    return stampingPostcards
        .firstWhereOrNull((element) => element == stampingPostcard);
  }
}
