import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'design_stamp.dart';

class PostcardExplain extends StatefulWidget {
  static const String tag = 'postcard_explain_screen';

  const PostcardExplain({Key? key}) : super(key: key);

  @override
  State<PostcardExplain> createState() => _PostcardExplainState();
}

class _PostcardExplainState extends State<PostcardExplain> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColor.primaryBlack,
      appBar: getBackAppBar(
        context,
        title: "how_it_works".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
        isWhite: false,
      ),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  addTitleSpace(),
                  Text(
                    "postcard_explain".tr(),
                    style: theme.textTheme.ppMori400White14,
                  ),
                ],
              )),
            ),
            PrimaryButton(
              text: "continue".tr(),
              onTap: () async {
                final location = await getGeoLocationWithPermission();
                if (!mounted || location == null) return;
                Navigator.of(context).pushNamed(AppRouter.designStamp,
                    arguments: DesignStampPayload(location));
              },
            ),
          ],
        ),
      ),
    );
  }
}
