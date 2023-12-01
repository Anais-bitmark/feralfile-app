//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

class CurrencyExchange {
  final String currency;
  final CurrencyExchangeRate rates;

  CurrencyExchange({required this.currency, required this.rates});

  factory CurrencyExchange.fromJson(Map<String, dynamic> json) =>
      CurrencyExchange(
        currency: json['currency'],
        rates: CurrencyExchangeRate.fromJson(json['rates']),
      );

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'rates': rates.toJson(),
      };
}

class CurrencyExchangeRate {
  final String eth;
  final String xtz;

  const CurrencyExchangeRate({required this.eth, required this.xtz});

  factory CurrencyExchangeRate.fromJson(Map<String, dynamic> json) =>
      CurrencyExchangeRate(
        eth: json['ETH'],
        xtz: json['XTZ'],
      );

  Map<String, dynamic> toJson() => {
        'ETH': eth,
        'XTZ': xtz,
      };

  String ethToUsd(BigInt amount) =>
      (amount.toDouble() / pow(10, 18) / double.parse(eth)).toStringAsFixed(2);

  String xtzToUsd(int amount) =>
      (amount / pow(10, 6) / double.parse(xtz)).toStringAsFixed(2);
}
