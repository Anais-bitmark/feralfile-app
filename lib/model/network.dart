//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

enum Network { TESTNET, MAINNET }

extension RawValue on Network {
  String get rawValue => toString().split('.').last;
}
