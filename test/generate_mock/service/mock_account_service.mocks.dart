// Mocks generated by Mockito 5.4.2 from annotations
// in autonomy_flutter/test/generate_mock/service/mock_account_service.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i7;

import 'package:autonomy_flutter/database/entity/connection.dart' as _i5;
import 'package:autonomy_flutter/database/entity/persona.dart' as _i3;
import 'package:autonomy_flutter/database/entity/wallet_address.dart' as _i12;
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart'
    as _i11;
import 'package:autonomy_flutter/service/account_service.dart' as _i6;
import 'package:autonomy_flutter/util/constants.dart' as _i9;
import 'package:autonomy_flutter/util/wallet_storage_ext.dart' as _i4;
import 'package:autonomy_flutter/util/wallet_utils.dart' as _i8;
import 'package:libauk_dart/libauk_dart.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:nft_collection/models/models.dart' as _i10;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeWalletStorage_0 extends _i1.SmartFake implements _i2.WalletStorage {
  _FakeWalletStorage_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePersona_1 extends _i1.SmartFake implements _i3.Persona {
  _FakePersona_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeWalletIndex_2 extends _i1.SmartFake implements _i4.WalletIndex {
  _FakeWalletIndex_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeConnection_3 extends _i1.SmartFake implements _i5.Connection {
  _FakeConnection_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [AccountService].
///
/// See the documentation for Mockito's code generation for more information.
class MockAccountService extends _i1.Mock implements _i6.AccountService {
  MockAccountService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i7.Future<_i2.WalletStorage> getDefaultAccount() => (super.noSuchMethod(
        Invocation.method(
          #getDefaultAccount,
          [],
        ),
        returnValue: _i7.Future<_i2.WalletStorage>.value(_FakeWalletStorage_0(
          this,
          Invocation.method(
            #getDefaultAccount,
            [],
          ),
        )),
      ) as _i7.Future<_i2.WalletStorage>);
  @override
  _i7.Future<_i3.Persona> getOrCreateDefaultPersona() => (super.noSuchMethod(
        Invocation.method(
          #getOrCreateDefaultPersona,
          [],
        ),
        returnValue: _i7.Future<_i3.Persona>.value(_FakePersona_1(
          this,
          Invocation.method(
            #getOrCreateDefaultPersona,
            [],
          ),
        )),
      ) as _i7.Future<_i3.Persona>);
  @override
  _i7.Future<_i2.WalletStorage?> getCurrentDefaultAccount() =>
      (super.noSuchMethod(
        Invocation.method(
          #getCurrentDefaultAccount,
          [],
        ),
        returnValue: _i7.Future<_i2.WalletStorage?>.value(),
      ) as _i7.Future<_i2.WalletStorage?>);
  @override
  _i7.Future<_i4.WalletIndex> getAccountByAddress({
    required String? chain,
    required String? address,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAccountByAddress,
          [],
          {
            #chain: chain,
            #address: address,
          },
        ),
        returnValue: _i7.Future<_i4.WalletIndex>.value(_FakeWalletIndex_2(
          this,
          Invocation.method(
            #getAccountByAddress,
            [],
            {
              #chain: chain,
              #address: address,
            },
          ),
        )),
      ) as _i7.Future<_i4.WalletIndex>);
  @override
  _i7.Future<dynamic> androidBackupKeys() => (super.noSuchMethod(
        Invocation.method(
          #androidBackupKeys,
          [],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<List<_i5.Connection>> removeDoubleViewOnly(
          List<String>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #removeDoubleViewOnly,
          [addresses],
        ),
        returnValue: _i7.Future<List<_i5.Connection>>.value(<_i5.Connection>[]),
      ) as _i7.Future<List<_i5.Connection>>);
  @override
  _i7.Future<bool?> isAndroidEndToEndEncryptionAvailable() =>
      (super.noSuchMethod(
        Invocation.method(
          #isAndroidEndToEndEncryptionAvailable,
          [],
        ),
        returnValue: _i7.Future<bool?>.value(),
      ) as _i7.Future<bool?>);
  @override
  _i7.Future<dynamic> androidRestoreKeys() => (super.noSuchMethod(
        Invocation.method(
          #androidRestoreKeys,
          [],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<_i3.Persona> createPersona({
    String? name = r'',
    bool? isDefault = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #createPersona,
          [],
          {
            #name: name,
            #isDefault: isDefault,
          },
        ),
        returnValue: _i7.Future<_i3.Persona>.value(_FakePersona_1(
          this,
          Invocation.method(
            #createPersona,
            [],
            {
              #name: name,
              #isDefault: isDefault,
            },
          ),
        )),
      ) as _i7.Future<_i3.Persona>);
  @override
  _i7.Future<_i3.Persona> importPersona(
    String? words, {
    _i8.WalletType? walletType = _i8.WalletType.Autonomy,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #importPersona,
          [words],
          {#walletType: walletType},
        ),
        returnValue: _i7.Future<_i3.Persona>.value(_FakePersona_1(
          this,
          Invocation.method(
            #importPersona,
            [words],
            {#walletType: walletType},
          ),
        )),
      ) as _i7.Future<_i3.Persona>);
  @override
  _i7.Future<_i5.Connection> nameLinkedAccount(
    _i5.Connection? connection,
    String? name,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #nameLinkedAccount,
          [
            connection,
            name,
          ],
        ),
        returnValue: _i7.Future<_i5.Connection>.value(_FakeConnection_3(
          this,
          Invocation.method(
            #nameLinkedAccount,
            [
              connection,
              name,
            ],
          ),
        )),
      ) as _i7.Future<_i5.Connection>);
  @override
  _i7.Future<_i5.Connection> linkManuallyAddress(
    String? address,
    _i9.CryptoType? cryptoType,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #linkManuallyAddress,
          [
            address,
            cryptoType,
          ],
        ),
        returnValue: _i7.Future<_i5.Connection>.value(_FakeConnection_3(
          this,
          Invocation.method(
            #linkManuallyAddress,
            [
              address,
              cryptoType,
            ],
          ),
        )),
      ) as _i7.Future<_i5.Connection>);
  @override
  _i7.Future<dynamic> deletePersona(_i3.Persona? persona) =>
      (super.noSuchMethod(
        Invocation.method(
          #deletePersona,
          [persona],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<dynamic> deleteLinkedAccount(_i5.Connection? connection) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteLinkedAccount,
          [connection],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<dynamic> linkIndexerTokenID(String? indexerTokenID) =>
      (super.noSuchMethod(
        Invocation.method(
          #linkIndexerTokenID,
          [indexerTokenID],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<dynamic> setHideLinkedAccountInGallery(
    String? address,
    bool? isEnabled,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setHideLinkedAccountInGallery,
          [
            address,
            isEnabled,
          ],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<dynamic> setHideAddressInGallery(
    List<String>? addresses,
    bool? isEnabled,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setHideAddressInGallery,
          [
            addresses,
            isEnabled,
          ],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  bool isLinkedAccountHiddenInGallery(String? address) => (super.noSuchMethod(
        Invocation.method(
          #isLinkedAccountHiddenInGallery,
          [address],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i7.Future<List<String>> getAllAddresses({bool? logHiddenAddress = false}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAllAddresses,
          [],
          {#logHiddenAddress: logHiddenAddress},
        ),
        returnValue: _i7.Future<List<String>>.value(<String>[]),
      ) as _i7.Future<List<String>>);
  @override
  _i7.Future<List<_i10.AddressIndex>> getAllAddressIndexes() =>
      (super.noSuchMethod(
        Invocation.method(
          #getAllAddressIndexes,
          [],
        ),
        returnValue:
            _i7.Future<List<_i10.AddressIndex>>.value(<_i10.AddressIndex>[]),
      ) as _i7.Future<List<_i10.AddressIndex>>);
  @override
  _i7.Future<List<String>> getAddress(
    String? blockchain, {
    bool? withViewOnly = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAddress,
          [blockchain],
          {#withViewOnly: withViewOnly},
        ),
        returnValue: _i7.Future<List<String>>.value(<String>[]),
      ) as _i7.Future<List<String>>);
  @override
  _i7.Future<List<_i10.AddressIndex>> getHiddenAddressIndexes() =>
      (super.noSuchMethod(
        Invocation.method(
          #getHiddenAddressIndexes,
          [],
        ),
        returnValue:
            _i7.Future<List<_i10.AddressIndex>>.value(<_i10.AddressIndex>[]),
      ) as _i7.Future<List<_i10.AddressIndex>>);
  @override
  _i7.Future<List<String>> getShowedAddresses() => (super.noSuchMethod(
        Invocation.method(
          #getShowedAddresses,
          [],
        ),
        returnValue: _i7.Future<List<String>>.value(<String>[]),
      ) as _i7.Future<List<String>>);
  @override
  _i7.Future<bool> addAddressPersona(
    _i3.Persona? newPersona,
    List<_i11.AddressInfo>? addresses,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #addAddressPersona,
          [
            newPersona,
            addresses,
          ],
        ),
        returnValue: _i7.Future<bool>.value(false),
      ) as _i7.Future<bool>);
  @override
  _i7.Future<void> deleteAddressPersona(
    _i3.Persona? persona,
    _i12.WalletAddress? walletAddress,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteAddressPersona,
          [
            persona,
            walletAddress,
          ],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);
  @override
  _i7.Future<_i12.WalletAddress?> getAddressPersona(String? address) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAddressPersona,
          [address],
        ),
        returnValue: _i7.Future<_i12.WalletAddress?>.value(),
      ) as _i7.Future<_i12.WalletAddress?>);
  @override
  _i7.Future<void> updateAddressPersona(_i12.WalletAddress? walletAddress) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateAddressPersona,
          [walletAddress],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);
  @override
  _i7.Future<void> restoreIfNeeded({bool? isCreateNew = true}) =>
      (super.noSuchMethod(
        Invocation.method(
          #restoreIfNeeded,
          [],
          {#isCreateNew: isCreateNew},
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);
}
