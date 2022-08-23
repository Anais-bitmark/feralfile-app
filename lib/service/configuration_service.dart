//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_connect/wallet_connect.dart';

abstract class ConfigurationService {
  Future<void> setIAPReceipt(String? value);
  String? getIAPReceipt();
  Future<void> setIAPJWT(JWT? value);
  JWT? getIAPJWT();
  Future<void> setWCSessions(List<WCSessionStore> value);
  List<WCSessionStore> getWCSessions();
  Future<void> setDevicePasscodeEnabled(bool value);
  bool isDevicePasscodeEnabled();
  Future<void> setNotificationEnabled(bool value);
  bool? isNotificationEnabled();
  Future<void> setAnalyticEnabled(bool value);
  bool isAnalyticsEnabled();
  Future<void> setDoneOnboarding(bool value);
  bool isDoneOnboarding();
  Future<void> setDoneOnboardingOnce(bool value);
  bool isDoneOnboardingOnce();
  Future<void> setFullscreenIntroEnable(bool value);
  bool isFullscreenIntroEnabled();
  Future<void> setHidePersonaInGallery(
      List<String> personaUUIDs, bool isEnabled,
      {bool override = false});
  List<String> getPersonaUUIDsHiddenInGallery();
  bool isPersonaHiddenInGallery(String value);
  Future<void> setHideLinkedAccountInGallery(
      List<String> address, bool isEnabled,
      {bool override = false});
  List<String> getLinkedAccountsHiddenInGallery();
  bool isLinkedAccountHiddenInGallery(String value);
  List<String> getTempStorageHiddenTokenIDs({Network? network});
  Future updateTempStorageHiddenTokenIDs(List<String> tokenIDs, bool isAdd,
      {Network? network, bool override = false});
  Future<void> setWCDappSession(String? value);
  String? getWCDappSession();
  Future<void> setWCDappAccounts(List<String>? value);
  List<String>? getWCDappAccounts();
  DateTime? getLatestRefreshTokens();
  Future<bool> setLatestRefreshTokens(DateTime? value);
  Future<void> setReadReleaseNotesInVersion(String version);
  String? getReadReleaseNotesVersion();
  String? getPreviousBuildNumber();
  Future<void> setPreviousBuildNumber(String value);
  List<String> getFinishedSurveys();
  Future<void> setFinishedSurvey(List<String> surveyNames);
  Future<void> setImmediateInfoViewEnabled(bool value);
  bool isImmediateInfoViewEnabled();
  Future<String> getAccountHMACSecret();
  bool isFinishedFeedOnBoarding();
  Future<void> setFinishedFeedOnBoarding(bool value);
  String? lastRemindReviewDate();
  Future<void> setLastRemindReviewDate(String? value);
  int? countOpenApp();
  Future<void> setCountOpenApp(int? value);

  // ----- App Setting -----
  bool isDemoArtworksMode();
  Future<bool> toggleDemoArtworksMode();
  bool showTokenDebugInfo();
  Future setShowTokenDebugInfo(bool show);

  // Do at once

  /// to determine a hash value of the current addresses where
  /// the app checked for Tezos artworks
  int? sentTezosArtworkMetricValue();
  Future setSentTezosArtworkMetric(int hashedAddresses);

  // Reload
  Future<void> reload();
  Future<void> removeAll();
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String KEY_IAP_RECEIPT = "key_iap_receipt";
  static const String KEY_IAP_JWT = "key_iap_jwt";
  static const String KEY_WC_SESSIONS = "key_wc_sessions";
  static const String KEY_DEVICE_PASSCODE = "device_passcode";
  static const String KEY_NOTIFICATION = "notifications";
  static const String KEY_ANALYTICS = "analytics";
  static const String KEY_FULLSCREEN_INTRO = "fullscreen_intro";
  static const String KEY_DONE_ONBOARING = "done_onboarding";
  static const String KEY_DONE_ONBOARING_ONCE = "done_onboarding_once";
  static const String KEY_HIDDEN_PERSONAS_IN_GALLERY =
      'hidden_personas_in_gallery';
  static const String KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY =
      'hidden_linked_accounts_in_gallery';
  static const String KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS =
      'temp_storage_hidden_token_ids_mainnet';
  static const String KEY_READ_RELEASE_NOTES_VERSION =
      'read_release_notes_version';
  static const String KEY_FINISHED_SURVEYS = "finished_surveys";
  static const String KEY_IMMEDIATE_INFOVIEW = 'immediate_infoview';
  static const String ACCOUNT_HMAC_SECRET = "account_hmac_secret";
  static const String KEY_FINISHED_FEED_ONBOARDING = "finished_feed_onboarding";

  // keys for WalletConnect dapp side
  static const String KEY_WC_DAPP_SESSION = "wc_dapp_store";
  static const String KEY_WC_DAPP_ACCOUNTS = "wc_dapp_accounts";

  // ----- App Setting -----
  static const String KEY_APP_SETTING_DEMO_ARTWORKS =
      "show_demo_artworks_preference";
  static const String KEY_LASTEST_REFRESH_TOKENS =
      "latest_refresh_tokens_mainnet_1";
  static const String KEY_PREVIOUS_BUILD_NUMBER = "previous_build_number";
  static const String KEY_SHOW_TOKEN_DEBUG_INFO = "show_token_debug_info";
  static const String LAST_REMIND_REVIEW = "last_remind_review";
  static const String COUNT_OPEN_APP = "count_open_app";

  // Do at once
  static const String KEY_SENT_TEZOS_ARTWORK_METRIC =
      "sent_tezos_artwork_metric";

  final SharedPreferences _preferences;

  ConfigurationServiceImpl(this._preferences);

  @override
  Future<void> setIAPReceipt(String? value) async {
    if (value != null) {
      await _preferences.setString(KEY_IAP_RECEIPT, value);
    } else {
      await _preferences.remove(KEY_IAP_RECEIPT);
    }
  }

  @override
  String? getIAPReceipt() {
    return _preferences.getString(KEY_IAP_RECEIPT);
  }

  @override
  Future<void> setIAPJWT(JWT? value) async {
    if (value == null) {
      await _preferences.remove(KEY_IAP_JWT);
      return;
    }
    final json = jsonEncode(value);
    await _preferences.setString(KEY_IAP_JWT, json);
  }

  @override
  JWT? getIAPJWT() {
    final data = _preferences.getString(KEY_IAP_JWT);
    if (data == null) {
      return null;
    } else {
      final json = jsonDecode(data);
      return JWT.fromJson(json);
    }
  }

  @override
  Future<void> setWCSessions(List<WCSessionStore> value) async {
    log.info("setWCSessions: $value");
    final json = jsonEncode(value);
    await _preferences.setString(KEY_WC_SESSIONS, json);
  }

  @override
  List<WCSessionStore> getWCSessions() {
    final json = _preferences.getString(KEY_WC_SESSIONS);
    final sessions = json != null ? jsonDecode(json) : List.empty();
    return List.from(sessions)
        .map((e) => WCSessionStore.fromJson(e))
        .toList(growable: false);
  }

  @override
  Future<void> setImmediateInfoViewEnabled(bool value) async {
    log.info("setImmediateInfoViewEnabled: $value");
    await _preferences.setBool(KEY_IMMEDIATE_INFOVIEW, value);
  }

  @override
  bool isImmediateInfoViewEnabled() {
    return _preferences.getBool(KEY_IMMEDIATE_INFOVIEW) ?? false;
  }

  @override
  bool isDevicePasscodeEnabled() {
    return _preferences.getBool(KEY_DEVICE_PASSCODE) ?? false;
  }

  @override
  Future<void> setDevicePasscodeEnabled(bool value) async {
    log.info("setDevicePasscodeEnabled: $value");
    await _preferences.setBool(KEY_DEVICE_PASSCODE, value);
  }

  @override
  bool isAnalyticsEnabled() {
    return _preferences.getBool(KEY_ANALYTICS) ?? true;
  }

  @override
  bool? isNotificationEnabled() {
    return _preferences.getBool(KEY_NOTIFICATION);
  }

  @override
  bool isDoneOnboarding() {
    return _preferences.getBool(KEY_DONE_ONBOARING) ?? false;
  }

  @override
  bool isDoneOnboardingOnce() {
    return _preferences.getBool(KEY_DONE_ONBOARING_ONCE) ?? false;
  }

  @override
  Future<void> setAnalyticEnabled(bool value) async {
    log.info("setAnalyticEnabled: $value");
    await _preferences.setBool(KEY_ANALYTICS, value);
  }

  @override
  Future<void> setDoneOnboarding(bool value) async {
    log.info("setDoneOnboarding: $value");
    await _preferences.setBool(KEY_DONE_ONBOARING, value);
  }

  @override
  Future<void> setDoneOnboardingOnce(bool value) async {
    log.info("setDoneOnboardingOnce: $value");
    await _preferences.setBool(KEY_DONE_ONBOARING_ONCE, value);
  }

  @override
  Future<void> setNotificationEnabled(bool value) async {
    log.info("setNotificationEnabled: $value");
    await _preferences.setBool(KEY_NOTIFICATION, value);
  }

  @override
  bool isFullscreenIntroEnabled() {
    return _preferences.getBool(KEY_FULLSCREEN_INTRO) ?? true;
  }

  @override
  Future<void> setFullscreenIntroEnable(bool value) async {
    log.info("setFullscreenIntroEnable: $value");
    await _preferences.setBool(KEY_FULLSCREEN_INTRO, value);
  }

  @override
  Future<void> setHidePersonaInGallery(
      List<String> personaUUIDs, bool isEnabled,
      {bool override = false}) async {
    if (override && isEnabled) {
      await _preferences.setStringList(
          KEY_HIDDEN_PERSONAS_IN_GALLERY, personaUUIDs);
    } else {
      var currentPersonaUUIDs =
          _preferences.getStringList(KEY_HIDDEN_PERSONAS_IN_GALLERY) ?? [];

      isEnabled
          ? currentPersonaUUIDs.addAll(personaUUIDs)
          : currentPersonaUUIDs.removeWhere((i) => personaUUIDs.contains(i));
      await _preferences.setStringList(
          KEY_HIDDEN_PERSONAS_IN_GALLERY, currentPersonaUUIDs);
    }
  }

  @override
  List<String> getPersonaUUIDsHiddenInGallery() {
    return _preferences.getStringList(KEY_HIDDEN_PERSONAS_IN_GALLERY) ?? [];
  }

  @override
  bool isPersonaHiddenInGallery(String value) {
    var personaUUIDs = getPersonaUUIDsHiddenInGallery();
    return personaUUIDs.contains(value);
  }

  @override
  Future<void> setHideLinkedAccountInGallery(
      List<String> addresses, bool isEnabled,
      {bool override = false}) async {
    if (override && isEnabled) {
      await _preferences.setStringList(
          KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY, addresses);
    } else {
      var linkedAccounts =
          _preferences.getStringList(KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY) ??
              [];

      isEnabled
          ? linkedAccounts.addAll(addresses)
          : linkedAccounts.removeWhere((i) => addresses.contains(i));
      await _preferences.setStringList(
          KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY, linkedAccounts);
    }
  }

  @override
  List<String> getLinkedAccountsHiddenInGallery() {
    return _preferences.getStringList(KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY) ??
        [];
  }

  @override
  bool isLinkedAccountHiddenInGallery(String value) {
    var hiddenLinkedAccounts = getLinkedAccountsHiddenInGallery();
    return hiddenLinkedAccounts.contains(value);
  }

  @override
  List<String> getTempStorageHiddenTokenIDs({Network? network}) {
    return _preferences.getStringList(KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS) ?? [];
  }

  @override
  Future updateTempStorageHiddenTokenIDs(List<String> tokenIDs, bool isAdd,
      {Network? network, bool override = false}) async {
    const key = KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS;

    if (override && isAdd) {
      await _preferences.setStringList(key, tokenIDs);
    } else {
      var tempHiddenTokenIDs = _preferences.getStringList(key) ?? [];

      isAdd
          ? tempHiddenTokenIDs.addAll(tokenIDs)
          : tempHiddenTokenIDs
              .removeWhere((element) => tokenIDs.contains(element));
      await _preferences.setStringList(
          key, tempHiddenTokenIDs.toSet().toList());
    }
  }

  @override
  Future<void> setWCDappSession(String? value) async {
    log.info("setWCDappSession: $value");
    if (value != null) {
      await _preferences.setString(KEY_WC_DAPP_SESSION, value);
    } else {
      await _preferences.remove(KEY_WC_DAPP_SESSION);
    }
  }

  @override
  String? getWCDappSession() {
    return _preferences.getString(KEY_WC_DAPP_SESSION);
  }

  @override
  Future<void> setWCDappAccounts(List<String>? value) async {
    log.info("setWCDappAccounts: $value");
    if (value != null) {
      await _preferences.setStringList(KEY_WC_DAPP_ACCOUNTS, value);
    } else {
      await _preferences.remove(KEY_WC_DAPP_ACCOUNTS);
    }
  }

  @override
  List<String>? getWCDappAccounts() {
    return _preferences.getStringList(KEY_WC_DAPP_ACCOUNTS);
  }

  @override
  Future<void> setReadReleaseNotesInVersion(String version) async {
    await _preferences.setString(KEY_READ_RELEASE_NOTES_VERSION, version);
  }

  @override
  String? getReadReleaseNotesVersion() {
    return _preferences.getString(KEY_READ_RELEASE_NOTES_VERSION);
  }

  @override
  bool isDemoArtworksMode() {
    return _preferences.getBool(KEY_APP_SETTING_DEMO_ARTWORKS) ?? false;
  }

  @override
  Future<bool> toggleDemoArtworksMode() async {
    final newValue = !isDemoArtworksMode();
    await _preferences.setBool(KEY_APP_SETTING_DEMO_ARTWORKS, newValue);
    return newValue;
  }

  @override
  Future<void> reload() {
    return _preferences.reload();
  }

  @override
  DateTime? getLatestRefreshTokens() {
    const key = KEY_LASTEST_REFRESH_TOKENS;
    final time = _preferences.getInt(key);

    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  @override
  Future<bool> setLatestRefreshTokens(DateTime? value) {
    const key = KEY_LASTEST_REFRESH_TOKENS;

    if (value == null) {
      return _preferences.remove(key);
    }

    return _preferences.setInt(key, value.millisecondsSinceEpoch);
  }

  @override
  Future<void> setPreviousBuildNumber(String value) async {
    await _preferences.setString(KEY_PREVIOUS_BUILD_NUMBER, value);
  }

  @override
  String? getPreviousBuildNumber() {
    return _preferences.getString(KEY_PREVIOUS_BUILD_NUMBER);
  }

  @override
  List<String> getFinishedSurveys() {
    return _preferences.getStringList(KEY_FINISHED_SURVEYS) ?? [];
  }

  @override
  Future<void> setFinishedSurvey(List<String> surveyNames) {
    var finishedSurveys = getFinishedSurveys();
    finishedSurveys.addAll(surveyNames);
    return _preferences.setStringList(
        KEY_FINISHED_SURVEYS, finishedSurveys.toSet().toList());
  }

  @override
  bool isFinishedFeedOnBoarding() {
    return _preferences.getBool(KEY_FINISHED_FEED_ONBOARDING) ?? false;
  }

  @override
  Future<void> setFinishedFeedOnBoarding(bool value) async {
    await _preferences.setBool(KEY_FINISHED_FEED_ONBOARDING, true);
  }

  @override
  Future<String> getAccountHMACSecret() async {
    final value = _preferences.getString(ACCOUNT_HMAC_SECRET);
    if (value == null) {
      final setValue = const Uuid().v4();
      await _preferences.setString(ACCOUNT_HMAC_SECRET, setValue);
      return setValue;
    }

    return value;
  }

  @override
  bool showTokenDebugInfo() {
    return _preferences.getBool(KEY_SHOW_TOKEN_DEBUG_INFO) ?? false;
  }

  @override
  Future setShowTokenDebugInfo(bool show) async {
    await _preferences.setBool(KEY_SHOW_TOKEN_DEBUG_INFO, show);
  }

  @override
  Future<void> removeAll() {
    return _preferences.clear();
  }

  @override
  int? sentTezosArtworkMetricValue() {
    return _preferences.getInt(KEY_SENT_TEZOS_ARTWORK_METRIC);
  }

  @override
  Future setSentTezosArtworkMetric(int hashedAddresses) {
    return _preferences.setInt(KEY_SENT_TEZOS_ARTWORK_METRIC, hashedAddresses);
  }

  @override
  String? lastRemindReviewDate() {
    return _preferences.getString(LAST_REMIND_REVIEW);
  }

  @override
  Future<void> setLastRemindReviewDate(String? value) async {
    if (value == null) {
      await _preferences.remove(LAST_REMIND_REVIEW);
      return;
    }
    await _preferences.setString(LAST_REMIND_REVIEW, value);
  }

  @override
  int? countOpenApp() {
    return _preferences.getInt(COUNT_OPEN_APP);
  }

  @override
  Future<void> setCountOpenApp(int? value) async {
    if (value == null) {
      await _preferences.remove(COUNT_OPEN_APP);
      return;
    }
    await _preferences.setInt(COUNT_OPEN_APP, value);
  }
}
