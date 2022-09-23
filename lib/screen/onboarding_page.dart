//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:developer';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/eula_privacy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log("DefineViewRoutingEvent");
    context.read<RouterBloc>().add(DefineViewRoutingEvent());
  }

  // @override
  @override
  Widget build(BuildContext context) {
    var penroseWidth = MediaQuery.of(context).size.width;
    // maxWidth for Penrose
    if (penroseWidth > 380 || penroseWidth < 0) {
      penroseWidth = 380;
    }
    final theme = Theme.of(context);
    const edgeInsets =
        EdgeInsets.only(top: 135.0, bottom: 32.0, left: 16.0, right: 16.0);

    return Scaffold(
        body: BlocConsumer<RouterBloc, RouterState>(
      listener: (context, state) async {
        switch (state.onboardingStep) {
          case OnboardingStep.dashboard:
            Navigator.of(context)
                .pushReplacementNamed(AppRouter.homePageNoTransition);

            try {
              await injector<SettingsDataService>().restoreSettingsData();
            } catch (_) {
              // just ignore this so that user can go through onboarding
            }
            await askForNotification();
            await injector<VersionService>().checkForUpdate();
            // hide code show surveys issues/1459
            // await Future.delayed(SHORT_SHOW_DIALOG_DURATION,
            //     () => showSurveysNotification(context));
            break;

          case OnboardingStep.restoreWithEmergencyContact:
            Navigator.of(context)
                .pushNamed(AppRouter.restoreWithEmergencyContactPage);
            break;

          default:
            break;
        }

        if (state.onboardingStep != OnboardingStep.dashboard) {
          await injector<VersionService>().checkForUpdate();
        }
        injector<WalletConnectService>().initSessions(forced: true);
      },
      builder: (context, state) {
        return Stack(children: [
          state.onboardingStep != OnboardingStep.undefined
              ? Container(
                  margin: edgeInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "autonomy".tr(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.largeTitle,
                      ),
                    ],
                  ),
                )
              : const SizedBox(),
          SafeArea(
            child: Center(
                child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: _logo())),
          ),
          Container(
            margin: edgeInsets,
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              state.onboardingStep != OnboardingStep.undefined
                  ? privacyView(context)
                  : const SizedBox(),
              const SizedBox(height: 32.0),
              _getStartupButton(state),
            ]),
          )
        ]);
      },
    ));
  }

  Widget _getStartupButton(RouterState state) {
    switch (state.onboardingStep) {
      case OnboardingStep.startScreen:
      case OnboardingStep.restoreWithEmergencyContact:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "start".tr().toUpperCase(),
                    onPress: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.beOwnGalleryPage);
                    },
                  ),
                ),
              ],
            ),
            // NOTE: Update this when support Social Recovery in Android
            if (Platform.isIOS) ...[
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRouter.restoreIntroductionPage),
                child: Text(
                  "restore".tr().toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: "IBMPlexMono"),
                ),
              ),
            ]
          ],
        );
      case OnboardingStep.restore:
        return Row(
          children: [
            Expanded(
              child: AuFilledButton(
                text: state.isRestoring ? "RESTORING..." : "restore".tr().toUpperCase(),
                key: const Key("restore_button"),
                isProcessing: state.isRestoring,
                onPress: !state.isRestoring
                    ? () {
                        context
                            .read<RouterBloc>()
                            .add(RestoreCloudDatabaseRoutingEvent());
                      }
                    : null,
              ),
            )
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _logo() {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          return Image.asset(snapshot.data == true
              ? "assets/images/penrose_onboarding_appcenter.png"
              : "assets/images/penrose_onboarding.png");
        });
  }
}
