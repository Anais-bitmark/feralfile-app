//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ether_gas.g.dart';

@JsonSerializable()
class EtherGas {
  int code;
  EtherGasData data;

  EtherGas({
    required this.code,
    required this.data,
  });

  factory EtherGas.fromJson(Map<String, dynamic> json) =>
      _$EtherGasFromJson(json);

  Map<String, dynamic> toJson() => _$EtherGasToJson(this);
}

@JsonSerializable()
class EtherGasData {
  int? rapid;
  int? fast;
  int? standard;
  int? slow;
  int? timestamp;
  double? priceUSD;

  EtherGasData(
      {this.rapid,
      this.fast,
      this.standard,
      this.slow,
      this.timestamp,
      this.priceUSD});

  factory EtherGasData.fromJson(Map<String, dynamic> json) =>
      _$EtherGasDataFromJson(json);

  Map<String, dynamic> toJson() => _$EtherGasDataToJson(this);
}

@JsonSerializable()
class EtherGasDataOracle {
  double safeLow;
  double standard;
  double fast;
  double fastest;
  double currentBaseFee;
  double recommendedBaseFee;

  EtherGasDataOracle({
    required this.safeLow,
    required this.standard,
    required this.fast,
    required this.fastest,
    required this.currentBaseFee,
    required this.recommendedBaseFee,
  });

  getFee(FeeOption feeOption) {
    switch (feeOption) {
      case FeeOption.LOW:
        return BigInt.from(safeLow * gWeiFactor);
      case FeeOption.MEDIUM:
        return BigInt.from(fast * gWeiFactor);
      case FeeOption.HIGH:
        return BigInt.from(fastest * gWeiFactor);
    }
  }

  factory EtherGasDataOracle.fromJson(Map<String, dynamic> json) =>
      _$EtherGasDataOracleFromJson(json);
}
