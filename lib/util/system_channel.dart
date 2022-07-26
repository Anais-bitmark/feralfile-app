//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:flutter/services.dart';

class SystemChannel {
  static const MethodChannel _channel = const MethodChannel('system');

  Future<List<String>> getWalletUUIDsFromKeychain() async {
    final result =
        await _channel.invokeMethod('getWalletUUIDsFromKeychain', {});
    return List<String>.from(result);
  }

  Future migrateAccountsFromV0ToV1() async {
    final result = await _channel.invokeMethod('migrateAccountsFromV0ToV1', {});
    if (result['error'] == 0) {
      return;
    } else {
      throw SystemException(result['reason']);
    }
  }

  Future removeAllKeychainKeys(bool isSync) async {
    final result = await _channel.invokeMethod(
      'removeAllKeychainKeys',
      {"isSync": isSync},
    );
    if (result['error'] == 0) {
      return;
    } else {
      throw SystemException(result['reason']);
    }
  }
}
