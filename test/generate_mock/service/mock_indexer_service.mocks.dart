// Mocks generated by Mockito 5.4.2 from annotations
// in autonomy_flutter/test/generate_mock/service/mock_indexer_service.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:mockito/mockito.dart' as _i1;
import 'package:nft_collection/graphql/model/get_list_tokens.dart' as _i6;
import 'package:nft_collection/graphql/model/identity.dart' as _i7;
import 'package:nft_collection/models/asset_token.dart' as _i5;
import 'package:nft_collection/models/identity.dart' as _i2;
import 'package:nft_collection/services/indexer_service.dart' as _i3;

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

class _FakeBlockchainIdentity_0 extends _i1.SmartFake
    implements _i2.BlockchainIdentity {
  _FakeBlockchainIdentity_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [IndexerService].
///
/// See the documentation for Mockito's code generation for more information.
class MockIndexerService extends _i1.Mock implements _i3.IndexerService {
  MockIndexerService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<List<_i5.AssetToken>> getNftTokens(
          _i6.QueryListTokensRequest? request) =>
      (super.noSuchMethod(
        Invocation.method(
          #getNftTokens,
          [request],
        ),
        returnValue: _i4.Future<List<_i5.AssetToken>>.value(<_i5.AssetToken>[]),
      ) as _i4.Future<List<_i5.AssetToken>>);
  @override
  _i4.Future<_i2.BlockchainIdentity> getIdentity(
          _i7.QueryIdentityRequest? request) =>
      (super.noSuchMethod(
        Invocation.method(
          #getIdentity,
          [request],
        ),
        returnValue:
            _i4.Future<_i2.BlockchainIdentity>.value(_FakeBlockchainIdentity_0(
          this,
          Invocation.method(
            #getIdentity,
            [request],
          ),
        )),
      ) as _i4.Future<_i2.BlockchainIdentity>);
}
