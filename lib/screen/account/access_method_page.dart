//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
// ignore_for_file: unused_field

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccessMethodPage extends StatefulWidget {
  static const tag = "access_method_page";

  const AccessMethodPage({Key? key}) : super(key: key);

  @override
  State<AccessMethodPage> createState() => _AccessMethodPageState();
}

class _AccessMethodPageState extends State<AccessMethodPage> {
  var _redrawObject = Object();
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "Test page",
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: _linkDebugWidget(context),
        ),
      ),
    );
  }

  Widget _addWalletItem(
      {required BuildContext context,
      required String title,
      String? content,
      required dynamic Function()? onTap,
      bool forward = true}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.ppMori400Black16,
                  ),
                  const Spacer(),
                  forward
                      ? SvgPicture.asset('assets/images/iconForward.svg')
                      : const SizedBox(),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text(
              content ?? "",
              style: theme.textTheme.ppMori400Black14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkDebugWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: padding,
          child: _addWalletItem(
              context: context,
              title: 'test_artwork'.tr(),
              onTap: () => Navigator.of(context).pushNamed(
                    AppRouter.testArtwork,
                  )),
        ),
        addDivider(height: 48),
        Padding(
          padding: padding,
          child: _linkTokenIndexerIDWidget(context),
        ),
        addDivider(height: 48),
        Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("show_token_debug_log".tr(),
                  style: theme.textTheme.headlineMedium),
              AuToggle(
                value: injector<ConfigurationService>().showTokenDebugInfo(),
                onToggle: (isEnabled) async {
                  await injector<ConfigurationService>()
                      .setShowTokenDebugInfo(isEnabled);
                  setState(() {
                    _redrawObject = Object();
                  });
                },
              )
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _linkTokenIndexerIDWidget(BuildContext context) {
    return Column(
      children: [
        _addWalletItem(
          context: context,
          title: "debug_indexer_tokenId".tr(),
          content: "dit_manually_input_an".tr(),
          onTap: () => Navigator.of(context)
              .pushNamed(AppRouter.linkManually, arguments: 'indexerTokenID'),
        ),
        TextButton(
            onPressed: () async {
              await injector<CloudDatabase>()
                  .connectionDao
                  .deleteConnectionsByType(
                      ConnectionType.manuallyIndexerTokenID.rawValue);
              injector<ClientTokenService>().refreshTokens();
            },
            child: Text("delete_all_debug_li".tr())),
      ],
    );
  }
}
