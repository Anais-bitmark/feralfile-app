//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_flutter/view/tip_card.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version_check/version_check.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with RouteAware, WidgetsBindingObserver, TickerProviderStateMixin {
  PackageInfo? _packageInfo;
  VersionCheck? _versionCheck;
  late ScrollController _controller;
  int _lastTap = 0;
  int _consecutiveTaps = 0;

  final GlobalKey<State> _preferenceKey = GlobalKey();
  bool _pendingSettingsCleared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPackageInfo();
    _checkVersion();
    injector<SettingsDataService>().backup();
    injector<VersionService>().checkForUpdate();
    _controller = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ));
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ));
    injector<SettingsDataService>().backup();
  }

  Widget _settingItem(
      {required String title,
      required Widget icon,
      required Function() onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0),
      child: TappableForwardRow(
        leftWidget: Row(
          children: [
            icon,
            const SizedBox(width: 32),
            Text(
              title,
              style: theme.textTheme.ppMori400Black16,
            )
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getCloseAppBar(
        context,
        title: "settings".tr(),
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: NotificationListener(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Tipcard(
                    titleText: "try_autonomy_pro_free".tr(),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.subscriptionPage);
                    },
                    buttonText: "start_free_trial".tr(),
                    content: Text("experience_premium_features".tr(),
                        style: theme.textTheme.ppMori400Black14),
                    listener: injector<ConfigurationService>().showProTip),
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  _settingItem(
                    title: "preferences".tr(),
                    icon: const Icon(AuIcon.preferences),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.preferencesPage);
                    },
                  ),
                  addOnlyDivider(),
                  _settingItem(
                    title: "hidden_artwork".tr(),
                    icon: const Icon(AuIcon.hidden_artwork),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.hiddenArtworksPage);
                    },
                  ),
                  addOnlyDivider(),
                  _settingItem(
                    title: "autonomy_pro".tr(),
                    icon: const Icon(AuIcon.subscription),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.subscriptionPage);
                    },
                  ),
                  addOnlyDivider(),
                  _settingItem(
                    title: "data_management".tr(),
                    icon: const Icon(AuIcon.data_management),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.dataManagementPage);
                    },
                  ),
                  addOnlyDivider(),
                  _settingItem(
                    title: "help_us_improve".tr(),
                    icon: const Icon(AuIcon.help_us),
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRouter.helpUsPage);
                    },
                  ),
                  addOnlyDivider(),
                ],
              ),
              const Spacer(),
              Container(
                padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
                alignment: Alignment.bottomCenter,
                child: _versionSection(),
              ),
            ],
          ),
          onNotification: (ScrollNotification notification) {
            var currentContext = _preferenceKey.currentContext;
            if (currentContext == null) return false;
            final renderObject = currentContext.findRenderObject();
            if (renderObject == null) return false;
            final viewport = RenderAbstractViewport.of(renderObject);
            final bottom = viewport.getOffsetToReveal(renderObject, 1.0).offset;
            final top = viewport.getOffsetToReveal(renderObject, 0.0).offset;
            final offset = notification.metrics.pixels;
            if (offset > 2 * (top + (bottom - top) / 3)) {
              _clearPendingSettings();
            }
            return false;
          },
        ),
      ),
    );
  }

  void _clearPendingSettings() {
    if (!_pendingSettingsCleared) {
      injector<ConfigurationService>().setPendingSettings(false);
      injector<ConfigurationService>().setShouldShowSubscriptionHint(false);
      _pendingSettingsCleared = true;
    }
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _checkVersion() async {
    final versionCheck = VersionCheck();
    await versionCheck.checkVersion(context);
    setState(() {
      _versionCheck = versionCheck;
    });
  }

  Widget _versionSection() {
    final theme = Theme.of(context);
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            child: Text(
              "eula".tr(),
              style: theme.textTheme.ppMori400Grey12
                  .copyWith(decoration: TextDecoration.underline),
            ),
            onTap: () => Navigator.of(context)
                .pushNamed(AppRouter.githubDocPage, arguments: {
              "prefix": "/bitmark-inc/autonomy.io/main/apps/docs/",
              "document": "eula.md",
              "title": "eula".tr(),
            }),
          ),
          Text(
            "_and".tr(),
            style: theme.textTheme.ppMori400Grey12,
          ),
          GestureDetector(
            child: Text(
              "privacy_policy".tr(),
              style: theme.textTheme.ppMori400Grey12
                  .copyWith(decoration: TextDecoration.underline),
            ),
            onTap: () => Navigator.of(context)
                .pushNamed(AppRouter.githubDocPage, arguments: {
              "prefix": "/bitmark-inc/autonomy.io/main/apps/docs/",
              "document": "privacy.md",
              "title": "privacy_policy".tr(),
            }),
          ),
        ],
      ),
      const SizedBox(height: 24),
      if (_packageInfo != null)
        GestureDetector(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColor.auGrey),
              ),
              child: Text(
                "version_".tr(
                  namedArgs: {
                    "version": _packageInfo!.version,
                    "buildNumber": _packageInfo!.buildNumber
                  },
                ),
                key: const Key("version"),
                style: theme.textTheme.ppMori400Grey14,
              ),
            ),
            onTap: () async {
              injector<VersionService>().showReleaseNotes();
            }),
      const SizedBox(height: 10),
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        final isLastestVersion = _versionCheck?.storeVersion
                ?.compareTo(_versionCheck?.packageVersion ?? "") ==
            0;
        return GestureDetector(
          onTap: () async {
            if (isLastestVersion) {
              int now = DateTime.now().millisecondsSinceEpoch;
              if (now - _lastTap < 1000) {
                _consecutiveTaps++;
                if (_consecutiveTaps == 3) {
                  final newValue = await injector<ConfigurationService>()
                      .toggleDemoArtworksMode();
                  if (!mounted) return;
                  await UIHelper.showInfoDialog(
                      context,
                      "demo_mode".tr(),
                      "demo_mode_en".tr(
                          args: [newValue ? "enable".tr() : "disable".tr()]),
                      autoDismissAfter: 1);
                }
              } else {
                _consecutiveTaps = 0;
              }
              _lastTap = now;
            } else {
              injector<VersionService>().openLastestVersion();
            }
          },
          child: isLastestVersion
              ? Text(
                  'up_to_date'.tr(),
                  style: theme.textTheme.ppMori400Grey12,
                )
              : Text(
                  'update_to_the_latest_version'.tr(),
                  style: theme.textTheme.linkStyle14.copyWith(
                      fontWeight: FontWeight.w400,
                      decorationColor: AppColor.disabledColor,
                      color: AppColor.disabledColor,
                      shadows: [const Shadow()]),
                ),
        );
      }),
    ]);
  }
}
