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
    Widget? titleIcon,
    Function()? action,
    bool isWhite = true}) {
  final theme = Theme.of(context);

  final primaryColor = isWhite ? AppColor.primaryBlack : AppColor.white;
  final secondaryColor = isWhite ? AppColor.white : AppColor.primaryBlack;
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: secondaryColor,
        statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
        statusBarBrightness: isWhite ? Brightness.light : Brightness.dark),
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
                color: primaryColor,
              ),
            ),
          )
        : const SizedBox(),
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (titleIcon != null) ...[titleIcon, const SizedBox(width: 10)],
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.ppMori400Black16.copyWith(color: primaryColor),
          textAlign: TextAlign.center,
        ),
      ],
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
                  color: primaryColor,
                ),
          ),
        )
    ],
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: addOnlyDivider(color: isWhite ? null : AppColor.auGreyBackground),
    ),
  );
}

AppBar getTitleEditAppBar(BuildContext context,
    {String backTitle = "BACK",
    required TextEditingController controller,
    required FocusNode focusNode,
    required Function(String value) onSubmit,
    bool hasBack = true,
    Widget? icon,
    Widget? titleIcon,
    bool hasAction = true,
    bool isWhite = true}) {
  final theme = Theme.of(context);

  final primaryColor = isWhite ? AppColor.auGrey : AppColor.white;
  final secondaryColor = isWhite ? AppColor.white : AppColor.primaryBlack;
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: secondaryColor,
        statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
        statusBarBrightness: isWhite ? Brightness.light : Brightness.dark),
    centerTitle: true,
    leadingWidth: 44,
    leading: hasBack
        ? Semantics(
            label: "BACK",
            child: IconButton(
              onPressed: () {},
              constraints: const BoxConstraints(maxWidth: 36.0),
              icon: SvgPicture.asset(
                'assets/images/icon_back.svg',
                color: primaryColor,
              ),
            ),
          )
        : const SizedBox(),
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (titleIcon != null) ...[titleIcon, const SizedBox(width: 10)],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200.0),
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            style: theme.textTheme.ppMori700Black16,
            onSubmitted: onSubmit,
            decoration: null,
          ),
        ),
      ],
    ),
    actions: [
      if (hasAction)
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: IconButton(
            tooltip: "AppbarAction",
            constraints: const BoxConstraints(maxWidth: 36.0),
            onPressed: () {},
            icon: icon ??
                Icon(
                  Icons.more_horiz,
                  color: primaryColor,
                ),
          ),
        )
    ],
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: addOnlyDivider(color: isWhite ? null : AppColor.auGreyBackground),
    ),
  );
}

AppBar getCloseAppBar(BuildContext context,
    {String title = "",
    required Function()? onClose,
    Widget? icon,
    bool withBottomDivider = true,
    bool isWhite = true}) {
  final theme = Theme.of(context);
  final primaryColor = isWhite ? AppColor.primaryBlack : AppColor.white;
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: theme.colorScheme.secondary,
      statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
      statusBarBrightness: isWhite ? Brightness.light : Brightness.dark,
    ),
    centerTitle: true,
    automaticallyImplyLeading: false,
    title: Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.ppMori400Black16.copyWith(color: primaryColor),
      textAlign: TextAlign.center,
    ),
    actions: [
      if (onClose != null)
        IconButton(
          tooltip: "CLOSE",
          onPressed: onClose,
          icon: icon ?? closeIcon(color: primaryColor),
        )
    ],
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: withBottomDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: addOnlyDivider(
                color: isWhite ? null : AppColor.auGreyBackground),
          )
        : null,
  );
}

// class MomaPallet to save colors
// Path: lib/util/style.dart
