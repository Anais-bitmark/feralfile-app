// Mocks generated by Mockito 5.4.2 from annotations
// in autonomy_flutter/test/services/activation_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:autonomy_flutter/gateway/activation_api.dart' as _i2;
import 'package:autonomy_flutter/model/ff_account.dart' as _i10;
import 'package:autonomy_flutter/model/otp.dart' as _i11;
import 'package:autonomy_flutter/screen/claim/activation/claim_activation_page.dart'
    as _i12;
import 'package:autonomy_flutter/screen/irl_screen/webview_irl_screen.dart'
    as _i14;
import 'package:autonomy_flutter/service/navigation_service.dart' as _i9;
import 'package:autonomy_flutter/util/error_handler.dart' as _i13;
import 'package:flutter/foundation.dart' as _i4;
import 'package:flutter/material.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;
import 'package:nft_collection/models/asset_token.dart' as _i7;
import 'package:nft_collection/models/pending_tx_params.dart' as _i8;
import 'package:nft_collection/services/tokens_service.dart' as _i6;

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

class _FakeActivationInfo_0 extends _i1.SmartFake
    implements _i2.ActivationInfo {
  _FakeActivationInfo_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeActivationClaimResponse_1 extends _i1.SmartFake
    implements _i2.ActivationClaimResponse {
  _FakeActivationClaimResponse_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeGlobalKey_2<T extends _i3.State<_i3.StatefulWidget>>
    extends _i1.SmartFake implements _i3.GlobalKey<T> {
  _FakeGlobalKey_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeBuildContext_3 extends _i1.SmartFake implements _i3.BuildContext {
  _FakeBuildContext_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNavigatorState_4 extends _i1.SmartFake
    implements _i3.NavigatorState {
  _FakeNavigatorState_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );

  @override
  String toString({_i4.DiagnosticLevel? minLevel = _i4.DiagnosticLevel.info}) =>
      super.toString();
}

/// A class which mocks [ActivationApi].
///
/// See the documentation for Mockito's code generation for more information.
class MockActivationApi extends _i1.Mock implements _i2.ActivationApi {
  MockActivationApi() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<_i2.ActivationInfo> getActivation(String? activationId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getActivation,
          [activationId],
        ),
        returnValue: _i5.Future<_i2.ActivationInfo>.value(_FakeActivationInfo_0(
          this,
          Invocation.method(
            #getActivation,
            [activationId],
          ),
        )),
      ) as _i5.Future<_i2.ActivationInfo>);
  @override
  _i5.Future<_i2.ActivationClaimResponse> claim(
          _i2.ActivationClaimRequest? body) =>
      (super.noSuchMethod(
        Invocation.method(
          #claim,
          [body],
        ),
        returnValue: _i5.Future<_i2.ActivationClaimResponse>.value(
            _FakeActivationClaimResponse_1(
          this,
          Invocation.method(
            #claim,
            [body],
          ),
        )),
      ) as _i5.Future<_i2.ActivationClaimResponse>);
}

/// A class which mocks [TokensService].
///
/// See the documentation for Mockito's code generation for more information.
class MockTokensService extends _i1.Mock implements _i6.TokensService {
  MockTokensService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get isRefreshAllTokensListen => (super.noSuchMethod(
        Invocation.getter(#isRefreshAllTokensListen),
        returnValue: false,
      ) as bool);
  @override
  _i5.Future<dynamic> fetchTokensForAddresses(List<String>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchTokensForAddresses,
          [addresses],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<List<_i7.AssetToken>> fetchManualTokens(
          List<String>? indexerIds) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchManualTokens,
          [indexerIds],
        ),
        returnValue: _i5.Future<List<_i7.AssetToken>>.value(<_i7.AssetToken>[]),
      ) as _i5.Future<List<_i7.AssetToken>>);
  @override
  _i5.Future<dynamic> setCustomTokens(List<_i7.AssetToken>? assetTokens) =>
      (super.noSuchMethod(
        Invocation.method(
          #setCustomTokens,
          [assetTokens],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<_i5.Stream<List<_i7.AssetToken>>> refreshTokensInIsolate(
          Map<int, List<String>>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #refreshTokensInIsolate,
          [addresses],
        ),
        returnValue: _i5.Future<_i5.Stream<List<_i7.AssetToken>>>.value(
            _i5.Stream<List<_i7.AssetToken>>.empty()),
      ) as _i5.Future<_i5.Stream<List<_i7.AssetToken>>>);
  @override
  _i5.Future<dynamic> reindexAddresses(List<String>? addresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #reindexAddresses,
          [addresses],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<dynamic> purgeCachedGallery() => (super.noSuchMethod(
        Invocation.method(
          #purgeCachedGallery,
          [],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<dynamic> postPendingToken(_i8.PendingTxParams? params) =>
      (super.noSuchMethod(
        Invocation.method(
          #postPendingToken,
          [params],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
}

/// A class which mocks [NavigationService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNavigationService extends _i1.Mock implements _i9.NavigationService {
  MockNavigationService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.GlobalKey<_i3.NavigatorState> get navigatorKey => (super.noSuchMethod(
        Invocation.getter(#navigatorKey),
        returnValue: _FakeGlobalKey_2<_i3.NavigatorState>(
          this,
          Invocation.getter(#navigatorKey),
        ),
      ) as _i3.GlobalKey<_i3.NavigatorState>);
  @override
  _i3.BuildContext get context => (super.noSuchMethod(
        Invocation.getter(#context),
        returnValue: _FakeBuildContext_3(
          this,
          Invocation.getter(#context),
        ),
      ) as _i3.BuildContext);
  @override
  bool get mounted => (super.noSuchMethod(
        Invocation.getter(#mounted),
        returnValue: false,
      ) as bool);
  @override
  _i5.Future<dynamic>? navigateTo(
    String? routeName, {
    Object? arguments,
  }) =>
      (super.noSuchMethod(Invocation.method(
        #navigateTo,
        [routeName],
        {#arguments: arguments},
      )) as _i5.Future<dynamic>?);
  @override
  _i5.Future<dynamic>? popAndPushNamed(
    String? routeName, {
    Object? arguments,
  }) =>
      (super.noSuchMethod(Invocation.method(
        #popAndPushNamed,
        [routeName],
        {#arguments: arguments},
      )) as _i5.Future<dynamic>?);
  @override
  _i5.Future<void> selectPromptsThenStamp(
    _i3.BuildContext? context,
    _i7.AssetToken? asset,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #selectPromptsThenStamp,
          [
            context,
            asset,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<dynamic>? navigateUntil(
    String? routeName,
    _i3.RoutePredicate? predicate, {
    Object? arguments,
  }) =>
      (super.noSuchMethod(Invocation.method(
        #navigateUntil,
        [
          routeName,
          predicate,
        ],
        {#arguments: arguments},
      )) as _i5.Future<dynamic>?);
  @override
  _i3.NavigatorState navigatorState() => (super.noSuchMethod(
        Invocation.method(
          #navigatorState,
          [],
        ),
        returnValue: _FakeNavigatorState_4(
          this,
          Invocation.method(
            #navigatorState,
            [],
          ),
        ),
      ) as _i3.NavigatorState);
  @override
  _i5.Future<dynamic> showAirdropNotStarted(String? artworkId) =>
      (super.noSuchMethod(
        Invocation.method(
          #showAirdropNotStarted,
          [artworkId],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<dynamic> showAirdropExpired(String? artworkId) =>
      (super.noSuchMethod(
        Invocation.method(
          #showAirdropExpired,
          [artworkId],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<dynamic> showNoRemainingToken({required _i10.FFSeries? series}) =>
      (super.noSuchMethod(
        Invocation.method(
          #showNoRemainingToken,
          [],
          {#series: series},
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<dynamic> showOtpExpired(String? artworkId) => (super.noSuchMethod(
        Invocation.method(
          #showOtpExpired,
          [artworkId],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<dynamic> openClaimTokenPage(
    _i10.FFSeries? series, {
    _i11.Otp? otp,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #openClaimTokenPage,
          [series],
          {#otp: otp},
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<void> openActivationPage(
          {required _i12.ClaimActivationPagePayload? payload}) =>
      (super.noSuchMethod(
        Invocation.method(
          #openActivationPage,
          [],
          {#payload: payload},
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  void showErrorDialog(
    _i13.ErrorEvent? event, {
    dynamic Function()? defaultAction,
    dynamic Function()? cancelAction,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #showErrorDialog,
          [event],
          {
            #defaultAction: defaultAction,
            #cancelAction: cancelAction,
          },
        ),
        returnValueForMissingStub: null,
      );
  @override
  void hideInfoDialog() => super.noSuchMethod(
        Invocation.method(
          #hideInfoDialog,
          [],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void goBack({Object? result}) => super.noSuchMethod(
        Invocation.method(
          #goBack,
          [],
          {#result: result},
        ),
        returnValueForMissingStub: null,
      );
  @override
  void popUntilHome() => super.noSuchMethod(
        Invocation.method(
          #popUntilHome,
          [],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void popUntilHomeOrSettings() => super.noSuchMethod(
        Invocation.method(
          #popUntilHomeOrSettings,
          [],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void restorablePushHomePage() => super.noSuchMethod(
        Invocation.method(
          #restorablePushHomePage,
          [],
        ),
        returnValueForMissingStub: null,
      );
  @override
  void setIsWCConnectInShow(bool? appeared) => super.noSuchMethod(
        Invocation.method(
          #setIsWCConnectInShow,
          [appeared],
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i5.Future<void> showContactingDialog() => (super.noSuchMethod(
        Invocation.method(
          #showContactingDialog,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> waitTooLongDialog() => (super.noSuchMethod(
        Invocation.method(
          #waitTooLongDialog,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showDeclinedGeolocalization() => (super.noSuchMethod(
        Invocation.method(
          #showDeclinedGeolocalization,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> openPostcardReceivedPage({
    required _i7.AssetToken? asset,
    required String? shareCode,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #openPostcardReceivedPage,
          [],
          {
            #asset: asset,
            #shareCode: shareCode,
          },
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<dynamic> goToIRLWebview(_i14.IRLWebScreenPayload? payload) =>
      (super.noSuchMethod(
        Invocation.method(
          #goToIRLWebview,
          [payload],
        ),
        returnValue: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);
  @override
  _i5.Future<void> showAlreadyDeliveredPostcard() => (super.noSuchMethod(
        Invocation.method(
          #showAlreadyDeliveredPostcard,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showAirdropJustOnce() => (super.noSuchMethod(
        Invocation.method(
          #showAirdropJustOnce,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showAirdropAlreadyClaimed() => (super.noSuchMethod(
        Invocation.method(
          #showAirdropAlreadyClaimed,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showActivationError(
    Object? e,
    String? id,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #showActivationError,
          [
            e,
            id,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showAirdropClaimFailed() => (super.noSuchMethod(
        Invocation.method(
          #showAirdropClaimFailed,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showPostcardShareLinkExpired() => (super.noSuchMethod(
        Invocation.method(
          #showPostcardShareLinkExpired,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showPostcardShareLinkInvalid() => (super.noSuchMethod(
        Invocation.method(
          #showPostcardShareLinkInvalid,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showLocationExplain() => (super.noSuchMethod(
        Invocation.method(
          #showLocationExplain,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showPostcardRunOut() => (super.noSuchMethod(
        Invocation.method(
          #showPostcardRunOut,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showPostcardQRCodeExpired() => (super.noSuchMethod(
        Invocation.method(
          #showPostcardQRCodeExpired,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showPostcardClaimLimited() => (super.noSuchMethod(
        Invocation.method(
          #showPostcardClaimLimited,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> showPostcardNotInMiami() => (super.noSuchMethod(
        Invocation.method(
          #showPostcardNotInMiami,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
  @override
  _i5.Future<void> openAutonomyDocument(
    String? href,
    String? title,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #openAutonomyDocument,
          [
            href,
            title,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}
