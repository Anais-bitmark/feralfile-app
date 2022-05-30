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
import 'package:wallet_connect/wallet_connect.dart';

abstract class ConfigurationService {
  Future<void> setIAPReceipt(String? value);
  String? getIAPReceipt();
  Future<void> setIAPJWT(JWT? value);
  JWT? getIAPJWT();
  Future<void> setWCSessions(List<WCSessionStore> value);
  List<WCSessionStore> getWCSessions();
  Future<void> setNetwork(Network value);
  Network getNetwork();
  Future<void> setImmediatePlaybackEnabled(bool value);
  bool isImmediatePlaybackEnabled();
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
  bool matchFeralFileSourceInNetwork(String source);
  Future<void> setWCDappSession(String? value);
  String? getWCDappSession();
  Future<void> setWCDappAccounts(List<String>? value);
  List<String>? getWCDappAccounts();
  DateTime? getLatestRefreshTokens();
  Future<bool> setLatestRefreshTokens(DateTime? value);
  Future<void> setReadReleaseNotesInVersion(String version);
  String getReadReleaseNotesVersion();
  String? getPreviousBuildNumber();
  Future<void> setPreviousBuildNumber(String value);
  List<String> getFinishedSurveys();
  Future<void> setFinishedSurvey(List<String> surveyNames);
  int? getUXGuideStep();
  Future<void> setUXGuideStep(int uxGuideStep);

  // ----- App Setting -----
  bool isDemoArtworksMode();
  Future<bool> toggleDemoArtworksMode();

  // Reload
  Future<void> reload();
  Future<void> removeAll();
}

class ConfigurationServiceImpl implements ConfigurationService {
  static const String KEY_IAP_RECEIPT = "key_iap_receipt";
  static const String KEY_IAP_JWT = "key_iap_jwt";
  static const String KEY_WC_SESSIONS = "key_wc_sessions";
  static const String KEY_NETWORK = "key_network";
  static const String KEY_IMMEDIATE_PLAYBACK = 'immediate_playback';
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
  static const String KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS_MAINNET =
      'temp_storage_hidden_token_ids_mainnet';
  static const String KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS_TESTNET =
      'temp_storage_hidden_token_ids_testnet';
  static const String KEY_READ_RELEASE_NOTES_VERSION =
      'read_release_notes_version';
  static const String KEY_FINISHED_SURVEYS = "finished_surveys";

  // keys for WalletConnect dapp side
  static const String KEY_WC_DAPP_SESSION = "wc_dapp_store";
  static const String KEY_WC_DAPP_ACCOUNTS = "wc_dapp_accounts";

  // ----- App Setting -----
  static const String KEY_APP_SETTING_DEMO_ARTWORKS =
      "show_demo_artworks_preference";
  static const String KEY_LASTEST_REFRESH_TOKENS_MAINNET =
      "latest_refresh_tokens_mainnet";
  static const String KEY_LASTEST_REFRESH_TOKENS_TESTNET =
      "latest_refresh_tokens_testnet";
  static const String KEY_PREVIOUS_BUILD_NUMBER = "previous_build_number";
  static const String KEY_GUIDED_STEP = "guided_step";

  SharedPreferences _preferences;

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
  Future<void> setNetwork(Network value) async {
    log.info("setNetwork: $value");
    await _preferences.setString(KEY_NETWORK, value.toString());
  }

  @override
  Network getNetwork() {
    final value =
        _preferences.getString(KEY_NETWORK) ?? Network.MAINNET.toString();
    try {
      return Network.values
          .firstWhere((element) => element.toString() == value);
    } catch (e) {
      return Network.MAINNET;
    }
  }

  Future<void> setImmediatePlaybackEnabled(bool value) async {
    log.info("setImmediatePlaybackEnabled: $value");
    await _preferences.setBool(KEY_IMMEDIATE_PLAYBACK, value);
  }

  bool isImmediatePlaybackEnabled() {
    return _preferences.getBool(KEY_IMMEDIATE_PLAYBACK) ?? true;
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

  List<String> getPersonaUUIDsHiddenInGallery() {
    return _preferences.getStringList(KEY_HIDDEN_PERSONAS_IN_GALLERY) ?? [];
  }

  bool isPersonaHiddenInGallery(String value) {
    var personaUUIDs = getPersonaUUIDsHiddenInGallery();
    return personaUUIDs.contains(value);
  }

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

  List<String> getLinkedAccountsHiddenInGallery() {
    return _preferences.getStringList(KEY_HIDDEN_LINKED_ACCOUNTS_IN_GALLERY) ??
        [];
  }

  bool isLinkedAccountHiddenInGallery(String value) {
    var hiddenLinkedAccounts = getLinkedAccountsHiddenInGallery();
    return hiddenLinkedAccounts.contains(value);
  }

  List<String> getTempStorageHiddenTokenIDs({Network? network}) {
    final key = (network ?? getNetwork()) == Network.MAINNET
        ? KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS_MAINNET
        : KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS_TESTNET;
    return _preferences.getStringList(key) ?? [];
  }

  Future updateTempStorageHiddenTokenIDs(List<String> tokenIDs, bool isAdd,
      {Network? network, bool override = false}) async {
    final key = (network ?? getNetwork()) == Network.MAINNET
        ? KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS_MAINNET
        : KEY_TEMP_STORAGE_HIDDEN_TOKEN_IDS_TESTNET;

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
  bool matchFeralFileSourceInNetwork(String source) {
    final network = getNetwork();
    if (network == Network.MAINNET) {
      return source == "https://feralfile.com";
    } else {
      return source != "https://feralfile.com";
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

  Future<void> setReadReleaseNotesInVersion(String version) async {
    await _preferences.setString(KEY_READ_RELEASE_NOTES_VERSION, version);
  }

  String getReadReleaseNotesVersion() {
    return _preferences.getString(KEY_READ_RELEASE_NOTES_VERSION) ?? '0.0.0';
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
    final key = getNetwork() == Network.MAINNET
        ? KEY_LASTEST_REFRESH_TOKENS_MAINNET
        : KEY_LASTEST_REFRESH_TOKENS_TESTNET;
    final time = _preferences.getInt(key);

    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  Future<bool> setLatestRefreshTokens(DateTime? value) {
    final key = getNetwork() == Network.MAINNET
        ? KEY_LASTEST_REFRESH_TOKENS_MAINNET
        : KEY_LASTEST_REFRESH_TOKENS_TESTNET;

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

  int? getUXGuideStep() {
    return _preferences.getInt(KEY_GUIDED_STEP);
  }

  Future<void> setUXGuideStep(int uxGuideStep) async {
    await _preferences.setInt(KEY_GUIDED_STEP, uxGuideStep);
  }

  @override
  Future<void> removeAll() {
    return _preferences.clear();
  }
}
