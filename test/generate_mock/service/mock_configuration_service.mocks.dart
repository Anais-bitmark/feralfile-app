// Mocks generated by Mockito 5.4.2 from annotations
// in autonomy_flutter/test/generate_mock/service/mock_configuration_service.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i6;

import 'package:autonomy_flutter/database/entity/announcement_local.dart'
    as _i14;
import 'package:autonomy_flutter/model/jwt.dart' as _i7;
import 'package:autonomy_flutter/model/network.dart' as _i8;
import 'package:autonomy_flutter/model/play_list_model.dart' as _i10;
import 'package:autonomy_flutter/model/sent_artwork.dart' as _i9;
import 'package:autonomy_flutter/model/shared_postcard.dart' as _i11;
import 'package:autonomy_flutter/screen/chat/chat_thread_page.dart' as _i3;
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart'
    as _i13;
import 'package:autonomy_flutter/screen/interactive_postcard/stamp_preview.dart'
    as _i12;
import 'package:autonomy_flutter/service/configuration_service.dart' as _i5;
import 'package:autonomy_flutter/util/announcement_ext.dart' as _i4;
import 'package:flutter/material.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

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

class _FakeValueNotifier_0<T> extends _i1.SmartFake
    implements _i2.ValueNotifier<T> {
  _FakeValueNotifier_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePostcardChatConfig_1 extends _i1.SmartFake
    implements _i3.PostcardChatConfig {
  _FakePostcardChatConfig_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeShowAnouncementNotificationInfo_2 extends _i1.SmartFake
    implements _i4.ShowAnouncementNotificationInfo {
  _FakeShowAnouncementNotificationInfo_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [ConfigurationService].
///
/// See the documentation for Mockito's code generation for more information.
class MockConfigurationService extends _i1.Mock
    implements _i5.ConfigurationService {
  MockConfigurationService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.ValueNotifier<bool> get showNotifTip => (super.noSuchMethod(
        Invocation.getter(#showNotifTip),
        returnValue: _FakeValueNotifier_0<bool>(
          this,
          Invocation.getter(#showNotifTip),
        ),
      ) as _i2.ValueNotifier<bool>);
  @override
  _i2.ValueNotifier<bool> get showProTip => (super.noSuchMethod(
        Invocation.getter(#showProTip),
        returnValue: _FakeValueNotifier_0<bool>(
          this,
          Invocation.getter(#showProTip),
        ),
      ) as _i2.ValueNotifier<bool>);
  @override
  _i2.ValueNotifier<bool> get showTvAppTip => (super.noSuchMethod(
        Invocation.getter(#showTvAppTip),
        returnValue: _FakeValueNotifier_0<bool>(
          this,
          Invocation.getter(#showTvAppTip),
        ),
      ) as _i2.ValueNotifier<bool>);
  @override
  _i2.ValueNotifier<bool> get showCreatePlaylistTip => (super.noSuchMethod(
        Invocation.getter(#showCreatePlaylistTip),
        returnValue: _FakeValueNotifier_0<bool>(
          this,
          Invocation.getter(#showCreatePlaylistTip),
        ),
      ) as _i2.ValueNotifier<bool>);
  @override
  _i2.ValueNotifier<bool> get showLinkOrImportTip => (super.noSuchMethod(
        Invocation.getter(#showLinkOrImportTip),
        returnValue: _FakeValueNotifier_0<bool>(
          this,
          Invocation.getter(#showLinkOrImportTip),
        ),
      ) as _i2.ValueNotifier<bool>);
  @override
  _i2.ValueNotifier<bool> get showBackupSettingTip => (super.noSuchMethod(
        Invocation.getter(#showBackupSettingTip),
        returnValue: _FakeValueNotifier_0<bool>(
          this,
          Invocation.getter(#showBackupSettingTip),
        ),
      ) as _i2.ValueNotifier<bool>);
  @override
  _i6.Future<void> setHasMerchandiseSupport(
    String? indexId, {
    bool? value = true,
    bool? isOverride = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setHasMerchandiseSupport,
          [indexId],
          {
            #value: value,
            #isOverride: isOverride,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool hasMerchandiseSupport(String? indexId) => (super.noSuchMethod(
        Invocation.method(
          #hasMerchandiseSupport,
          [indexId],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setPostcardChatConfig(_i3.PostcardChatConfig? config) =>
      (super.noSuchMethod(
        Invocation.method(
          #setPostcardChatConfig,
          [config],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i3.PostcardChatConfig getPostcardChatConfig({
    required String? address,
    required String? id,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPostcardChatConfig,
          [],
          {
            #address: address,
            #id: id,
          },
        ),
        returnValue: _FakePostcardChatConfig_1(
          this,
          Invocation.method(
            #getPostcardChatConfig,
            [],
            {
              #address: address,
              #id: id,
            },
          ),
        ),
      ) as _i3.PostcardChatConfig);
  @override
  _i6.Future<void> setDidMigrateAddress(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setDidMigrateAddress,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool getDidMigrateAddress() => (super.noSuchMethod(
        Invocation.method(
          #getDidMigrateAddress,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setAnnouncementLastPullTime(int? lastPullTime) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAnnouncementLastPullTime,
          [lastPullTime],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setOldUser() => (super.noSuchMethod(
        Invocation.method(
          #setOldUser,
          [],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool getIsOldUser() => (super.noSuchMethod(
        Invocation.method(
          #getIsOldUser,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setIAPReceipt(String? value) => (super.noSuchMethod(
        Invocation.method(
          #setIAPReceipt,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setIAPJWT(_i7.JWT? value) => (super.noSuchMethod(
        Invocation.method(
          #setIAPJWT,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setPremium(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setPremium,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isPremium() => (super.noSuchMethod(
        Invocation.method(
          #isPremium,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setDevicePasscodeEnabled(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setDevicePasscodeEnabled,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isDevicePasscodeEnabled() => (super.noSuchMethod(
        Invocation.method(
          #isDevicePasscodeEnabled,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setNotificationEnabled(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setNotificationEnabled,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setAnalyticEnabled(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setAnalyticEnabled,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isAnalyticsEnabled() => (super.noSuchMethod(
        Invocation.method(
          #isAnalyticsEnabled,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setDoneOnboarding(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setDoneOnboarding,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isDoneOnboarding() => (super.noSuchMethod(
        Invocation.method(
          #isDoneOnboarding,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setPendingSettings(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setPendingSettings,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool hasPendingSettings() => (super.noSuchMethod(
        Invocation.method(
          #hasPendingSettings,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  bool shouldShowSubscriptionHint() => (super.noSuchMethod(
        Invocation.method(
          #shouldShowSubscriptionHint,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<dynamic> setShouldShowSubscriptionHint(bool? value) =>
      (super.noSuchMethod(
        Invocation.method(
          #setShouldShowSubscriptionHint,
          [value],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setLastTimeAskForSubscription(DateTime? date) =>
      (super.noSuchMethod(
        Invocation.method(
          #setLastTimeAskForSubscription,
          [date],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<void> setDoneOnboardingOnce(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setDoneOnboardingOnce,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isDoneOnboardingOnce() => (super.noSuchMethod(
        Invocation.method(
          #isDoneOnboardingOnce,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> readRemoveSupport(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #readRemoveSupport,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isReadRemoveSupport() => (super.noSuchMethod(
        Invocation.method(
          #isReadRemoveSupport,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setHideLinkedAccountInGallery(
    List<String>? address,
    bool? isEnabled, {
    bool? override = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setHideLinkedAccountInGallery,
          [
            address,
            isEnabled,
          ],
          {#override: override},
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<String> getLinkedAccountsHiddenInGallery() => (super.noSuchMethod(
        Invocation.method(
          #getLinkedAccountsHiddenInGallery,
          [],
        ),
        returnValue: <String>[],
      ) as List<String>);
  @override
  bool isLinkedAccountHiddenInGallery(String? value) => (super.noSuchMethod(
        Invocation.method(
          #isLinkedAccountHiddenInGallery,
          [value],
        ),
        returnValue: false,
      ) as bool);
  @override
  List<String> getTempStorageHiddenTokenIDs({_i8.Network? network}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTempStorageHiddenTokenIDs,
          [],
          {#network: network},
        ),
        returnValue: <String>[],
      ) as List<String>);
  @override
  _i6.Future<dynamic> updateTempStorageHiddenTokenIDs(
    List<String>? tokenIDs,
    bool? isAdd, {
    _i8.Network? network,
    bool? override = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateTempStorageHiddenTokenIDs,
          [
            tokenIDs,
            isAdd,
          ],
          {
            #network: network,
            #override: override,
          },
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  List<_i9.SentArtwork> getRecentlySentToken() => (super.noSuchMethod(
        Invocation.method(
          #getRecentlySentToken,
          [],
        ),
        returnValue: <_i9.SentArtwork>[],
      ) as List<_i9.SentArtwork>);
  @override
  _i6.Future<dynamic> updateRecentlySentToken(
    List<_i9.SentArtwork>? sentArtwork, {
    bool? override = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateRecentlySentToken,
          [sentArtwork],
          {#override: override},
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<void> setReadReleaseNotesInVersion(String? version) =>
      (super.noSuchMethod(
        Invocation.method(
          #setReadReleaseNotesInVersion,
          [version],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setPreviousBuildNumber(String? value) => (super.noSuchMethod(
        Invocation.method(
          #setPreviousBuildNumber,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<_i10.PlayListModel> getPlayList() => (super.noSuchMethod(
        Invocation.method(
          #getPlayList,
          [],
        ),
        returnValue: <_i10.PlayListModel>[],
      ) as List<_i10.PlayListModel>);
  @override
  _i6.Future<void> setPlayList(
    List<_i10.PlayListModel>? value, {
    bool? override = false,
    _i5.ConflictAction? onConflict = _i5.ConflictAction.abort,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setPlayList,
          [value],
          {
            #override: override,
            #onConflict: onConflict,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> removePlayList(String? id) => (super.noSuchMethod(
        Invocation.method(
          #removePlayList,
          [id],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<String> getAccountHMACSecret() => (super.noSuchMethod(
        Invocation.method(
          #getAccountHMACSecret,
          [],
        ),
        returnValue: _i6.Future<String>.value(''),
      ) as _i6.Future<String>);
  @override
  _i6.Future<void> setLastRemindReviewDate(String? value) =>
      (super.noSuchMethod(
        Invocation.method(
          #setLastRemindReviewDate,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setCountOpenApp(int? value) => (super.noSuchMethod(
        Invocation.method(
          #setCountOpenApp,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isDemoArtworksMode() => (super.noSuchMethod(
        Invocation.method(
          #isDemoArtworksMode,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<bool> toggleDemoArtworksMode() => (super.noSuchMethod(
        Invocation.method(
          #toggleDemoArtworksMode,
          [],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);
  @override
  bool showTokenDebugInfo() => (super.noSuchMethod(
        Invocation.method(
          #showTokenDebugInfo,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<dynamic> setShowTokenDebugInfo(bool? show) => (super.noSuchMethod(
        Invocation.method(
          #setShowTokenDebugInfo,
          [show],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setDoneOnboardingTime(DateTime? time) =>
      (super.noSuchMethod(
        Invocation.method(
          #setDoneOnboardingTime,
          [time],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setSubscriptionTime(DateTime? time) =>
      (super.noSuchMethod(
        Invocation.method(
          #setSubscriptionTime,
          [time],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setAlreadyShowProTip(bool? show) => (super.noSuchMethod(
        Invocation.method(
          #setAlreadyShowProTip,
          [show],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setAlreadyShowTvAppTip(bool? show) => (super.noSuchMethod(
        Invocation.method(
          #setAlreadyShowTvAppTip,
          [show],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setAlreadyShowCreatePlaylistTip(bool? show) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAlreadyShowCreatePlaylistTip,
          [show],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setAlreadyShowLinkOrImportTip(bool? show) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAlreadyShowLinkOrImportTip,
          [show],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  bool getAlreadyShowProTip() => (super.noSuchMethod(
        Invocation.method(
          #getAlreadyShowProTip,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  bool getAlreadyShowTvAppTip() => (super.noSuchMethod(
        Invocation.method(
          #getAlreadyShowTvAppTip,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  bool getAlreadyShowCreatePlaylistTip() => (super.noSuchMethod(
        Invocation.method(
          #getAlreadyShowCreatePlaylistTip,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  bool getAlreadyShowLinkOrImportTip() => (super.noSuchMethod(
        Invocation.method(
          #getAlreadyShowLinkOrImportTip,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<dynamic> setShowBackupSettingTip(DateTime? time) =>
      (super.noSuchMethod(
        Invocation.method(
          #setShowBackupSettingTip,
          [time],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<dynamic> setSentTezosArtworkMetric(int? hashedAddresses) =>
      (super.noSuchMethod(
        Invocation.method(
          #setSentTezosArtworkMetric,
          [hashedAddresses],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);
  @override
  _i6.Future<void> reload() => (super.noSuchMethod(
        Invocation.method(
          #reload,
          [],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> removeAll() => (super.noSuchMethod(
        Invocation.method(
          #removeAll,
          [],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<_i11.SharedPostcard> getSharedPostcard() => (super.noSuchMethod(
        Invocation.method(
          #getSharedPostcard,
          [],
        ),
        returnValue: <_i11.SharedPostcard>[],
      ) as List<_i11.SharedPostcard>);
  @override
  _i6.Future<void> updateSharedPostcard(
    List<_i11.SharedPostcard>? sharedPostcards, {
    bool? override = false,
    bool? isRemoved = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateSharedPostcard,
          [sharedPostcards],
          {
            #override: override,
            #isRemoved: isRemoved,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> removeSharedPostcardWhere(
          bool Function(_i11.SharedPostcard)? test) =>
      (super.noSuchMethod(
        Invocation.method(
          #removeSharedPostcardWhere,
          [test],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<String> getListPostcardMint() => (super.noSuchMethod(
        Invocation.method(
          #getListPostcardMint,
          [],
        ),
        returnValue: <String>[],
      ) as List<String>);
  @override
  _i6.Future<void> setListPostcardMint(
    List<String>? tokenID, {
    bool? override = false,
    bool? isRemoved = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setListPostcardMint,
          [tokenID],
          {
            #override: override,
            #isRemoved: isRemoved,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<_i12.StampingPostcard> getStampingPostcard() => (super.noSuchMethod(
        Invocation.method(
          #getStampingPostcard,
          [],
        ),
        returnValue: <_i12.StampingPostcard>[],
      ) as List<_i12.StampingPostcard>);
  @override
  _i6.Future<void> updateStampingPostcard(
    List<_i12.StampingPostcard>? values, {
    bool? override = false,
    bool? isRemove = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateStampingPostcard,
          [values],
          {
            #override: override,
            #isRemove: isRemove,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setProcessingStampPostcard(
    List<_i12.ProcessingStampPostcard>? values, {
    bool? override = false,
    bool? isRemove = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setProcessingStampPostcard,
          [values],
          {
            #override: override,
            #isRemove: isRemove,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<_i12.ProcessingStampPostcard> getProcessingStampPostcard() =>
      (super.noSuchMethod(
        Invocation.method(
          #getProcessingStampPostcard,
          [],
        ),
        returnValue: <_i12.ProcessingStampPostcard>[],
      ) as List<_i12.ProcessingStampPostcard>);
  @override
  _i6.Future<void> setAutoShowPostcard(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setAutoShowPostcard,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool isAutoShowPostcard() => (super.noSuchMethod(
        Invocation.method(
          #isAutoShowPostcard,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  List<_i13.PostcardIdentity> getListPostcardAlreadyShowYouDidIt() =>
      (super.noSuchMethod(
        Invocation.method(
          #getListPostcardAlreadyShowYouDidIt,
          [],
        ),
        returnValue: <_i13.PostcardIdentity>[],
      ) as List<_i13.PostcardIdentity>);
  @override
  _i6.Future<void> setListPostcardAlreadyShowYouDidIt(
    List<_i13.PostcardIdentity>? value, {
    bool? override = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setListPostcardAlreadyShowYouDidIt,
          [value],
          {#override: override},
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setAlreadyShowPostcardUpdates(
    List<_i13.PostcardIdentity>? value, {
    bool? override = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAlreadyShowPostcardUpdates,
          [value],
          {#override: override},
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<_i13.PostcardIdentity> getAlreadyShowPostcardUpdates() =>
      (super.noSuchMethod(
        Invocation.method(
          #getAlreadyShowPostcardUpdates,
          [],
        ),
        returnValue: <_i13.PostcardIdentity>[],
      ) as List<_i13.PostcardIdentity>);
  @override
  String getVersionInfo() => (super.noSuchMethod(
        Invocation.method(
          #getVersionInfo,
          [],
        ),
        returnValue: '',
      ) as String);
  @override
  _i6.Future<void> setVersionInfo(String? version) => (super.noSuchMethod(
        Invocation.method(
          #setVersionInfo,
          [version],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> updateShowAnnouncementNotificationInfo(
          _i14.AnnouncementLocal? announcement) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateShowAnnouncementNotificationInfo,
          [announcement],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i4.ShowAnouncementNotificationInfo getShowAnnouncementNotificationInfo() =>
      (super.noSuchMethod(
        Invocation.method(
          #getShowAnnouncementNotificationInfo,
          [],
        ),
        returnValue: _FakeShowAnouncementNotificationInfo_2(
          this,
          Invocation.method(
            #getShowAnnouncementNotificationInfo,
            [],
          ),
        ),
      ) as _i4.ShowAnouncementNotificationInfo);
  @override
  bool getAlreadyClaimedAirdrop(String? seriesId) => (super.noSuchMethod(
        Invocation.method(
          #getAlreadyClaimedAirdrop,
          [seriesId],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setAlreadyClaimedAirdrop(
    String? seriesId,
    bool? value,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAlreadyClaimedAirdrop,
          [
            seriesId,
            value,
          ],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  _i6.Future<void> setDidSyncArtists(bool? value) => (super.noSuchMethod(
        Invocation.method(
          #setDidSyncArtists,
          [value],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool getDidSyncArtists() => (super.noSuchMethod(
        Invocation.method(
          #getDidSyncArtists,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  List<String> getHiddenOrSentTokenIDs() => (super.noSuchMethod(
        Invocation.method(
          #getHiddenOrSentTokenIDs,
          [],
        ),
        returnValue: <String>[],
      ) as List<String>);
  @override
  _i6.Future<void> setShowPostcardBanner(bool? bool) => (super.noSuchMethod(
        Invocation.method(
          #setShowPostcardBanner,
          [bool],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  bool getShowPostcardBanner() => (super.noSuchMethod(
        Invocation.method(
          #getShowPostcardBanner,
          [],
        ),
        returnValue: false,
      ) as bool);
  @override
  _i6.Future<void> setMerchandiseOrderIds(
    List<String>? ids, {
    bool? override = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setMerchandiseOrderIds,
          [ids],
          {#override: override},
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
  @override
  List<String> getMerchandiseOrderIds() => (super.noSuchMethod(
        Invocation.method(
          #getMerchandiseOrderIds,
          [],
        ),
        returnValue: <String>[],
      ) as List<String>);
}
