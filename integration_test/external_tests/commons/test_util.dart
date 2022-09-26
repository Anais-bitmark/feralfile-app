//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';
import 'dart:math';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';

import 'dart:convert';

AppiumBy settingButtonLocator = const AppiumBy.accessibilityId("Settings");
AppiumBy accountAliasLocator =
    const AppiumBy.xpath("//android.widget.EditText[@text='Enter alias']");
AppiumBy saveAliasButtonLocator = const AppiumBy.accessibilityId("SAVE ALIAS");
AppiumBy continueButtonLocator = const AppiumBy.accessibilityId("CONTINUE");
AppiumBy continueWithouItbuttonLocation = const AppiumBy.xpath(
    "//android.widget.Button[@content-desc='CONTINUE WITHOUT IT']");
AppiumBy accountSeedsLocator = const AppiumBy.xpath(
    "//android.widget.EditText[contains(@text,'Enter recovery phrase')]");

AppiumBy confirmButtonLocator = const AppiumBy.accessibilityId("CONFIRM");
AppiumBy closeArtworkButtonLocator =
    const AppiumBy.accessibilityId("CloseArtwork");

AppiumBy dotIconLocator = const AppiumBy.accessibilityId("AppbarAction");
AppiumBy sendArtworkButtonLocator =
    const AppiumBy.xpath("//android.view.View[@content-desc='Send artwork']");
AppiumBy reviewButtonLocator = const AppiumBy.accessibilityId("REVIEW");
AppiumBy quantityTxtLocator =
    const AppiumBy.xpath("//android.widget.EditText[@text='1']");
AppiumBy toTxtLocator = const AppiumBy.xpath(
    "//android.widget.EditText[@text='Paste or scan address']");
AppiumBy isFeeCalculatingLocator = const AppiumBy.xpath(
    "//android.view.View[contains(@content-desc,'Gas fee: calculating')]");
AppiumBy isFeeCalculatedLocator = const AppiumBy.xpath(
    "//android.view.View[contains(@content-desc,'Gas fee: 0.')]");
AppiumBy sendButtonLocator = const AppiumBy.accessibilityId("SEND");

AppiumBy newAccountLocator =  const AppiumBy.xpath(
    "//android.widget.ImageView[contains(@content-desc,'Make a new account with addresses')]");

AppiumBy enterAliasLocator = const AppiumBy.xpath('//android.widget.EditText[contains(@text,"Enter alias")]');

Future<void> selectSubSettingMenu(AppiumWebDriver driver, String menu) async {
  String sub_menu = await menu;
  while (menu.indexOf('->') > 0) {
    int index = await menu.indexOf('->');
    sub_menu = await menu.substring(0, index);
    menu = await menu.substring(menu.indexOf('->') + 2, menu.length);

    if (sub_menu == "Settings") {
      var settingButton = await driver.findElement(settingButtonLocator);
      await settingButton.click();
    } else {
      var subButton =
          await driver.findElement(AppiumBy.accessibilityId(sub_menu));
      await subButton.click();
    }
  }
  var lastButton = await driver.findElement(AppiumBy.accessibilityId(menu));
  await lastButton.click();
}

Future<String> genTestDataRandom(String baseString) async {
  var rng = Random();
  baseString = baseString + rng.nextInt(10000).toString();
  return baseString;
}

Future<void> enterAccountAlias(AppiumWebDriver driver, String alias) async {
  var accountAliasTxt = await driver.findElement(accountAliasLocator);
  await accountAliasTxt.click();
  await accountAliasTxt.sendKeys(alias);

  var saveAliasButton = await driver.findElement(saveAliasButtonLocator);
  await saveAliasButton.click();
}

Future<void> enterSeeds(AppiumWebDriver driver, String seeds) async {
  var accountSeedsTxt = await driver.findElement(accountSeedsLocator);
  await accountSeedsTxt.click();
  await accountSeedsTxt.sendKeys(seeds);

  var confirmButton = await driver.findElement(confirmButtonLocator);
  await confirmButton.click();
}

Future<bool> findArtwork(AppiumWebDriver driver, String artworkName) async {
  int i = 2;
  int hasArtwork = await driver
      .findElements(AppiumBy.xpath(
          "//android.widget.ScrollView/android.widget.ImageView[$i]"))
      .length;

  while (hasArtwork == 1) {
    sleep(const Duration(seconds: 2));
    var artworkIcon = await driver.findElement(AppiumBy.xpath(
        "//android.widget.ScrollView/android.widget.ImageView[$i]"));
    await artworkIcon.click();
    i++;
    int isCorrectArtwork = await driver
        .findElements(AppiumBy.xpath(
            "//android.widget.ImageView[contains(@content-desc,'$artworkName')]"))
        .length;

    if (isCorrectArtwork == 1) {
      return true;
    } else {
      var closeArtworkButton =
          await driver.findElement(closeArtworkButtonLocator);
      await closeArtworkButton.click();
    }
  }
  return false;
}

Future<void> sendAwrtwork(AppiumWebDriver driver, String artworkName,
    String toAddress, int amount) async {
  bool isArtworkFound = await findArtwork(driver, artworkName);

  var artworkTitle = await driver.findElement(AppiumBy.xpath(
      "//android.widget.ImageView[contains(@content-desc,'$artworkName')]"));
  await artworkTitle.click();

  var dotIcon = await driver.findElement(dotIconLocator);
  await dotIcon.click();
  var sendArtworkButton = await driver.findElement(sendArtworkButtonLocator);
  await sendArtworkButton.click();

  var reviewButton = await driver.findElement(reviewButtonLocator);
  String statusReviewButton = await reviewButton.attributes["clickable"];

  expect(statusReviewButton, "false");

  var quantityTxt = await driver.findElement(quantityTxtLocator);
  await quantityTxt.click();
  await quantityTxt.clear();
  await Future.delayed(const Duration(seconds: 1));
  await quantityTxt.sendKeys(amount.toString());

  var toTxt = await driver.findElement(toTxtLocator);
  await toTxt.click();
  await toTxt.sendKeys(toAddress);

  await driver.device.pressKeycode(66);

  await Future.delayed(const Duration(seconds: 5));
  int isFeeCalculated =
      await driver.findElements(isFeeCalculatedLocator).length;

  expect(isFeeCalculated, 1);

  var reviewButton1 = await driver.findElement(reviewButtonLocator);
  statusReviewButton = await reviewButton1.attributes["clickable"];
  expect(statusReviewButton, "true");

  await reviewButton1.click();

  var sendButton = await driver.findElement(sendButtonLocator);
  await sendButton.click();
}

Future<void> wait4TezBlockchainConfirmation(AppiumWebDriver driver) async {
  await Future.delayed(const Duration(seconds: 40));
  await driver.device.getDisplayDensity();
  await Future.delayed(const Duration(seconds: 40));
  await driver.device.getDisplayDensity();
  await Future.delayed(const Duration(seconds: 30));
}

Future<void> scroll(driver, scrollUIAutomator) async {
  var finder = await AppiumBy.uiautomator(scrollUIAutomator);
  await driver.findElement(finder);
}

Future<void> scrollUntil(AppiumWebDriver driver, String decs) async {
  var subSelector = 'new UiSelector().descriptionContains("$decs")';
  var scrollViewSeletor =
      'new UiSelector().className("android.widget.ScrollView")';
  var scrollUIAutomator =
      await 'new UiScrollable($scrollViewSeletor).setSwipeDeadZonePercentage(0.4).scrollIntoView($subSelector)';
  await scroll(driver, scrollUIAutomator);
}

Future<void> timeDelay(int second) async {
  Duration dur = Duration(seconds: 1);
  for (int i = 0; i < second; i++){
    await Future.delayed(dur);
  }
}

Future<void> goBack(AppiumWebDriver driver, int step) async {
  for (int i = 0; i < step; i++) {
    await driver.back();
  }
}

Future<void> captureScreen(AppiumWebDriver driver) async {
  var screenshot = await driver.captureScreenshotAsBase64();

  final decodedBytes = base64Decode(screenshot.replaceAll(RegExp(r'\s+'), ''));

  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('MMddyyyy');
  final String formattedFolder = formatter.format(now);

  final filename = DateTime.now().microsecondsSinceEpoch;
  var file = await File("/tmp/AUResult/$formattedFolder/$filename.png")
      .create(recursive: true);
  file.writeAsBytesSync(decodedBytes);
}

Future<AppiumWebElement> getElementByContentDesc(AppiumWebDriver driver, String contain) async {
  AppiumBy locator = AppiumBy.xpath(
      '//*[contains(@content-desc,"$contain")]');
  var element = driver.findElements(locator).elementAt(0);
  return element;
}
/////
Future<DateTime> depositTezos(String address) async {
  var dotenv = DotEnv(includePlatformEnvironment: true)..load();
  final faucetUrl = '${dotenv["TEZOS_FAUCET_URL"]}' ?? '';
  final token = '${dotenv["TEZOS_FAUCET_AUTH_TOKEN"]}' ?? '';

  await http.post(
    Uri.parse(faucetUrl),
    body: json.encode({"address": address}),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Basic $token",
    },
  );
  return DateTime.now();
}

Future<double> round(double x, int n) async {
  String tmp = x.toStringAsFixed(n);
  return double.parse(tmp);
}

DateTime from24to12(DateTime time24){
  String timeStr = DateFormat('yyyy-MM-dd hh:mm a').format(time24);
  return DateTime.parse(timeStr.substring(0, timeStr.length - 3));
}

Future<void> continueStep(AppiumWebDriver driver) async {
  int isContinueWithoutButtonExist =
      await driver.findElements(continueWithouItbuttonLocation).length;
  if (isContinueWithoutButtonExist == 1) {
    var continueWithoutItButton =
        await driver.findElement(continueWithouItbuttonLocation);
    await continueWithoutItButton.click();
  } else {
    var continueButton = await driver.findElement(continueButtonLocator);
    await continueButton.click();
  }
}
