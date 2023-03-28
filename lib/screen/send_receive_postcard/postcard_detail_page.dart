//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';

class PostcardDetailPage extends StatefulWidget {
  final AssetToken asset;

  const PostcardDetailPage({
    Key? key,
    required this.asset,
  }) : super(key: key);

  @override
  State<PostcardDetailPage> createState() => _PostcardDetailPageState();
}

class _PostcardDetailPageState extends State<PostcardDetailPage> {
  late Locale locale;
  late DistanceFormatter distanceFormatter;
  late List<TravelInfo> travelInfo;

  @override
  void initState() {
    super.initState();
    travelInfo = [];
  }

  @override
  Widget build(BuildContext context) {
    _getTravelInfo(widget.asset);
    locale = Localizations.localeOf(context);
    distanceFormatter = DistanceFormatter(locale: locale);
    final theme = Theme.of(context);
    final asset = widget.asset;
    final artistName = asset.artistName?.toIdentityOrMask({});
    var subTitle = "";
    if (artistName != null && artistName.isNotEmpty) {
      subTitle = "by".tr(args: [artistName]);
    }

    return Scaffold(
        appBar: AppBar(
          leadingWidth: 0,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.title ?? '',
                style: theme.textTheme.ppMori400White16,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subTitle,
                style: theme.textTheme.ppMori400White14,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Semantics(
              label: 'close_icon',
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(
                  maxWidth: 44,
                  maxHeight: 44,
                ),
                icon: Icon(
                  AuIcon.close,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
            )
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                // Show artwork here.
                CachedNetworkImage(
                  imageUrl: asset.getPreviewUrl() ?? "",
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "total_distance_traveled".tr(),
                      style: theme.textTheme.ppMori700White14,
                    ),
                    Text(
                      distanceFormatter.format(
                          distance: travelInfo.totalDistance),
                      style: theme.textTheme.ppMori700White14,
                    ),
                  ],
                ),

                addDivider(color: AppColor.greyMedium),

                ...travelInfo
                    .mapIndexed((index, el) => [
                          _tripItem(context, el),
                          addDivider(color: AppColor.greyMedium)
                        ])
                    .flattened
                    .toList(),
              ],
            ),
          ),
        ));
  }

  Future<void> _getTravelInfo(AssetToken assetToken) async {
    final travelInfo = await assetToken.listTravelInfo;
    setState(() {
      this.travelInfo = travelInfo;
    });
  }

  Widget _tripItem(BuildContext context, TravelInfo travelInfo) {
    final theme = Theme.of(context);
    NumberFormat formatter = NumberFormat("00");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.format(travelInfo.index),
          style: theme.textTheme.ppMori400Grey12,
        ),
        Text(
          travelInfo.sentLocation ?? "Unknown",
          style: theme.textTheme.ppMori400White14,
        ),
        Row(
          children: [
            SvgPicture.asset("assets/images/arrow_3.svg"),
            const SizedBox(width: 6),
            Text(
              travelInfo.receivedLocation ?? "Unknown",
              style: theme.textTheme.ppMori400White14,
            ),
            const Spacer(),
            Text(
              distanceFormatter.format(distance: travelInfo.getDistance()),
              style: theme.textTheme.ppMori400White14,
            )
          ],
        ),
      ],
    );
  }
}
