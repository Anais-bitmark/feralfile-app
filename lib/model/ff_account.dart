//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ff_account.g.dart';

@JsonSerializable()
class FFAccount {
  @JsonKey(name: 'ID', defaultValue: '')
  String id;
  String alias;
  String location;
  WyreWallet? wyreWallet;
  Map<String, String>? vaultAddresses;

  FFAccount(
      {required this.id,
      required this.alias,
      required this.location,
      required this.wyreWallet,
      required this.vaultAddresses});

  factory FFAccount.fromJson(Map<String, dynamic> json) =>
      _$FFAccountFromJson(json);

  Map<String, dynamic> toJson() => _$FFAccountToJson(this);

  @override
  String toString() => toJson().toString();

  String? get ethereumAddress => vaultAddresses?['ethereum'];

  String? get tezosAddress => vaultAddresses?['tezos'];
}

@JsonSerializable()
class WyreWallet {
  Map<String, double> availableBalances;

  WyreWallet({
    required this.availableBalances,
  });

  factory WyreWallet.fromJson(Map<String, dynamic> json) =>
      _$WyreWalletFromJson(json);

  Map<String, dynamic> toJson() => _$WyreWalletToJson(this);
}

@JsonSerializable()
class FFContract {
  final String name;
  final String blockchainType;
  final String address;

  FFContract(
    this.name,
    this.blockchainType,
    this.address,
  );

  factory FFContract.fromJson(Map<String, dynamic> json) =>
      _$FFContractFromJson(json);

  Map<String, dynamic> toJson() => _$FFContractToJson(this);
}

@JsonSerializable()
class AirdropInfo {
  final String contractAddress;
  final String blockchain;
  final int remainAmount;
  final String? seriesId; // TODO: rename?
  final String? seriesTitle;
  final String? artist;
  final String? gifter;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? twitterCaption;

  AirdropInfo(
    this.contractAddress,
    this.blockchain,
    this.remainAmount,
    this.seriesId,
    this.seriesTitle,
    this.artist,
    this.gifter,
    this.startedAt,
    this.endedAt,
    this.twitterCaption,
  );

  factory AirdropInfo.fromJson(Map<String, dynamic> json) =>
      _$AirdropInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AirdropInfoToJson(this);

  bool get isAirdropStarted => startedAt?.isBefore(DateTime.now()) == true;
}

@JsonSerializable()
class TokenClaimResponse {
  final TokenClaimResult result;

  TokenClaimResponse(this.result);

  factory TokenClaimResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenClaimResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenClaimResponseToJson(this);

  @override
  String toString() => 'TokenClaimResponse{result: $result}';
}

@JsonSerializable()
class TokenClaimResult {
  final String id;
  final String claimerID;
  final String exhibitionID;
  final String seriesID;
  final String artworkID;
  final String txID;
  final Map<String, dynamic>? metadata;

  TokenClaimResult(
    this.id,
    this.claimerID,
    this.exhibitionID,
    this.artworkID,
    this.txID,
    this.seriesID,
    this.metadata,
  );

  factory TokenClaimResult.fromJson(Map<String, dynamic> json) =>
      _$TokenClaimResultFromJson(json);

  Map<String, dynamic> toJson() => _$TokenClaimResultToJson(this);

  @override
  String toString() => 'TokenClaimResult{id: $id, '
      'claimerID: $claimerID, '
      'exhibitionID: $exhibitionID, '
      'artworkID: $artworkID, '
      'txID: $txID}';
}

@JsonSerializable()
class FeralfileError {
  final int code;
  final String message;

  FeralfileError(
    this.code,
    this.message,
  );

  factory FeralfileError.fromJson(Map<String, dynamic> json) =>
      _$FeralfileErrorFromJson(json);

  Map<String, dynamic> toJson() => _$FeralfileErrorToJson(this);

  @override
  String toString() => 'FeralfileError{code: $code, message: $message}';
}

@JsonSerializable()
class ResaleResponse {
  final FeralFileResaleInfo result;

  ResaleResponse(this.result);

  factory ResaleResponse.fromJson(Map<String, dynamic> json) =>
      _$ResaleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ResaleResponseToJson(this);
}

@JsonSerializable()
class FeralFileResaleInfo {
  final String exhibitionID;
  final String saleType;
  final double platform;
  final double artist;
  final double seller;
  final double curator;
  final double partner;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeralFileResaleInfo(
      this.exhibitionID,
      this.saleType,
      this.platform,
      this.artist,
      this.seller,
      this.curator,
      this.partner,
      this.createdAt,
      this.updatedAt);

  factory FeralFileResaleInfo.fromJson(Map<String, dynamic> json) =>
      _$FeralFileResaleInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FeralFileResaleInfoToJson(this);
}

@JsonSerializable()
class ArtworkResponse {
  final Artwork result;

  ArtworkResponse(this.result);

  factory ArtworkResponse.fromJson(Map<String, dynamic> json) =>
      _$ArtworkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkResponseToJson(this);
}

@JsonSerializable()
class Artwork {
  final String id;
  final String seriesID;
  final int index;
  final String name;
  final String category;
  final String ownerAccountID;
  final bool? virgin;
  final bool? burned;
  final String blockchainStatus;
  final bool isExternal;
  final DateTime mintedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isArchived;
  final FFSeries? series;

  Artwork(
      this.id,
      this.seriesID,
      this.index,
      this.name,
      this.category,
      this.ownerAccountID,
      this.virgin,
      this.burned,
      this.blockchainStatus,
      this.isExternal,
      this.mintedAt,
      this.createdAt,
      this.updatedAt,
      this.isArchived,
      this.series);

  factory Artwork.fromJson(Map<String, dynamic> json) =>
      _$ArtworkFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkToJson(this);
}
