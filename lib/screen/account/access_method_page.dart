//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: unused_field

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/injector.dart';
import '../../database/cloud_database.dart';
import '../../database/entity/connection.dart';
import '../../util/constants.dart';
import '../bloc/persona/persona_bloc.dart';

class AccessMethodPage extends StatefulWidget {
  const AccessMethodPage({Key? key}) : super(key: key);

  @override
  State<AccessMethodPage> createState() => _AccessMethodPageState();
}

class _AccessMethodPageState extends State<AccessMethodPage> {
  var _redrawObject = Object();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(children: [
          Expanded(
              child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "add_account".tr(),
                style: theme.textTheme.headline1,
              ),
              addTitleSpace(),
              if (injector<ConfigurationService>().isDoneOnboarding()) ...[
                _createAccountOption(context),
                addDivider(),
              ],
              _linkAccount(context),
              addDivider(),
              _importAccount(context),
              injector<ConfigurationService>().isDoneOnboarding()
                  ? _linkDebugWidget(context)
                  : const SizedBox(),
            ]),
          ))
        ]),
      ),
    );
  }

  Widget _createAccountOption(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<PersonaBloc, PersonaState>(
      listener: (context, state) {
        switch (state.createAccountState) {
          case ActionState.done:
            UIHelper.hideInfoDialog(context);
            UIHelper.showGeneratedPersonaDialog(context, onContinue: () {
              UIHelper.hideInfoDialog(context);
              final createdPersona = state.persona;
              if (createdPersona != null) {
                Navigator.of(context).pushNamed(AppRouter.namePersonaPage,
                    arguments: createdPersona.uuid);
              }
            });
            break;

          default:
            break;
        }
      },
      builder: (context, state) {
        return TappableForwardRowWithContent(
          leftWidget: Text('new'.tr(), style: theme.textTheme.headline4),
          bottomWidget: Text("ne_make_a_new_account".tr(),
              //'Make a new account with addresses you can use to collect or receive NFTs on Ethereum, Feral File, and Tezos. ',
              style: theme.textTheme.bodyText1),
          onTap: () {
            if (state.createAccountState == ActionState.loading) return;
            UIHelper.showInfoDialog(context, "generating".tr(), "",
                isDismissible: true);
            context.read<PersonaBloc>().add(CreatePersonaEvent());
          },
        );
      },
    );
  }

  Widget _linkAccount(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRowWithContent(
        leftWidget: Text('link'.tr(), style: theme.textTheme.headline4),
        bottomWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "li_view_your_nfts".tr(),
              style: theme.textTheme.bodyText1,
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.linkAccountpage);
        });
  }

  Widget _importAccount(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRowWithContent(
      leftWidget: Text('import'.tr(), style: theme.textTheme.headline4),
      bottomWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("im_view_and_control".tr(),
              //'View and control your NFTs, sign authorizations, and connect to other platforms with Autonomy.',
              style: theme.textTheme.bodyText1),
          const SizedBox(height: 16),
          learnMoreAboutAutonomySecurityWidget(context),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.importAccountPage),
    );
  }

  Widget _linkDebugWidget(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Column(
              children: [
                addDivider(),
                TappableForwardRowWithContent(
                  leftWidget: Text('debug_address'.tr(),
                      style: theme.textTheme.headline4),
                  bottomWidget: Text("da_manually_input_an".tr(),
                      //'Manually input an address for debugging purposes.',
                      style: theme.textTheme.bodyText1),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRouter.linkManually, arguments: 'address'),
                ),
                _linkTokenIndexerIDWidget(context),
                addDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("show_token_debug_log".tr(),
                        style: theme.textTheme.headline4),
                    CupertinoSwitch(
                      value:
                          injector<ConfigurationService>().showTokenDebugInfo(),
                      onChanged: (isEnabled) async {
                        await injector<ConfigurationService>()
                            .setShowTokenDebugInfo(isEnabled);
                        setState(() {
                          _redrawObject = Object();
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    )
                  ],
                ),
                const SizedBox(height: 40),
              ],
            );
          }

          return const SizedBox();
        });
  }

  Widget _linkTokenIndexerIDWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addDivider(),
        TappableForwardRowWithContent(
          leftWidget: Text("debug_indexer_tokenId".tr(),
              style: theme.textTheme.headline4),
          bottomWidget: Text("dit_manually_input_an".tr(),
              //'Manually input an indexer tokenID for debugging purposes',
              style: theme.textTheme.bodyText1),
          onTap: () => Navigator.of(context)
              .pushNamed(AppRouter.linkManually, arguments: 'indexerTokenID'),
        ),
        TextButton(
            onPressed: () {
              injector<CloudDatabase>().connectionDao.deleteConnectionsByType(
                  ConnectionType.manuallyIndexerTokenID.rawValue);
            },
            child: Text("delete_all_debug_li".tr())),
      ],
    );
  }
}
