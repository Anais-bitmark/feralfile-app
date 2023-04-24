//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

AppBar getBackAppBar(BuildContext context,
    {String backTitle = "BACK",
    String title = "",
    required Function()? onBack,
    Widget? icon,
    Function()? action}) {
  final theme = Theme.of(context);

  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: theme.colorScheme.secondary,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    centerTitle: true,
    leadingWidth: 44,
    leading: onBack != null
        ? Semantics(
            label: "BACK",
            child: IconButton(
              onPressed: onBack,
              constraints: const BoxConstraints(maxWidth: 36.0),
              icon: SvgPicture.asset(
                'assets/images/icon_back.svg',
                color: theme.colorScheme.primary,
              ),
            ),
          )
        : const SizedBox(),
    automaticallyImplyLeading: false,
    title: Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.ppMori400Black16,
      textAlign: TextAlign.center,
    ),
    actions: [
      if (action != null)
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: IconButton(
            tooltip: "AppbarAction",
            constraints: const BoxConstraints(maxWidth: 36.0),
            onPressed: action,
            icon: icon ??
                Icon(
                  Icons.more_horiz,
                  color: theme.colorScheme.primary,
                ),
          ),
        )
    ],
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: addOnlyDivider(),
    ),
  );
}

AppBar getCloseAppBar(BuildContext context,
    {String title = "",
    required Function()? onClose,
    Widget? icon,
    bool withBottomDivider = true}) {
  final theme = Theme.of(context);

  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: theme.colorScheme.secondary,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    centerTitle: true,
    automaticallyImplyLeading: false,
    title: Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.ppMori400Black16,
      textAlign: TextAlign.center,
    ),
    actions: [
      if (onClose != null)
        IconButton(
          tooltip: "CLOSE",
          onPressed: onClose,
          icon: icon ?? closeIcon(),
        )
    ],
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: withBottomDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: addOnlyDivider(),
          )
        : null,
  );
}
