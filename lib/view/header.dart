//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HeaderView extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final Widget? action;
  final EdgeInsets? padding;

  const HeaderView({
    required this.title,
    this.titleStyle,
    this.padding,
    super.key,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.ppMori700White24.copyWith(fontSize: 36);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: padding ?? const EdgeInsets.fromLTRB(12, 33, 0, 42),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle ?? defaultStyle,
                  ),
                ),
                action ?? const SizedBox()
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AutonomyLogo extends StatelessWidget {
  final bool isWhite;

  const AutonomyLogo({super.key, this.isWhite = false});

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
      // ignore: discarded_futures
      future: logoState(),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const SizedBox(height: 50);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              isWhite
                  ? 'assets/images/autonomy_icon_white.svg'
                  : snapshot.data!
                      ? 'assets/images/logo_dev.svg'
                      : 'assets/images/penrose_moma.svg',
              width: 50,
              height: 50,
            ),
          ],
        );
      });
}
