import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/prompt.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/prompt_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:video_player/video_player.dart';

class PostcardExplain extends StatefulWidget {
  static const String tag = 'postcard_explain_screen';
  final PostcardExplainPayload payload;

  const PostcardExplain({required this.payload, super.key});

  @override
  State<PostcardExplain> createState() => _PostcardExplainState();
}

class _PostcardExplainState extends State<PostcardExplain> {
  final _navigationService = injector<NavigationService>();
  final VideoPlayerController _controller =
      VideoPlayerController.asset('assets/videos/postcard_explain.mp4');
  final VideoPlayerController _colouringController =
      VideoPlayerController.asset('assets/videos/colouring_video.mp4');
  late int _currentIndex;
  late SwiperController _swiperController;

  @override
  void initState() {
    unawaited(_initPlayer());
    _swiperController = SwiperController();
    super.initState();
    unawaited(injector<ConfigurationService>().setAutoShowPostcard(false));
    _currentIndex = 0;
  }

  Future<void> _initPlayer() async {
    await _controller.initialize().then((_) {
      _controller.setLooping(true);
      setState(() {});
      _controller.play();
    });
    await _colouringController.initialize().then((_) {
      _colouringController.setLooping(true);
    });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    unawaited(_colouringController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.payload.asset;
    final metadata = asset.asset?.artworkMetadata;
    final hasPrompt = metadata != null
        ? widget.payload.asset.postcardMetadata.prompt != null
        : false;
    final isShare = metadata != null
        ? widget.payload.asset.postcardMetadata.locationInformation.isNotEmpty
        : false;
    final pages = widget.payload.pages ??
        [
          _page1(_controller),
          if (hasPrompt || !isShare) _promptExplain(context),
          _page3(1, _colouringController),
          _page2(2, totalDistance: 0),
          _page2(3, totalDistance: 7926),
          _page2(4, totalDistance: 91103),
          _page4(5),
          if (asset.getArtists.isNotEmpty) _postcardPreview(context, asset),
        ];
    final swiperSize = pages.length;
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageHorizontalEdgeInsets;
    final isLastPage = _currentIndex == pages.length - 1;
    return Scaffold(
      backgroundColor: AppColor.chatPrimaryColor,
      appBar: getLightEmptyAppBar(AppColor.chatPrimaryColor),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MoMA',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.moMASans700Black24
                            .copyWith(height: 1),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'postcard_project'.tr(),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.moMASans400Black24
                            .copyWith(height: 1),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_currentIndex == 0 || isLastPage) ...[
                    IconButton(
                      tooltip: 'CLOSE',
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      icon: SvgPicture.asset(
                        'assets/images/close.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                            AppColor.primaryBlack, BlendMode.srcIn),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ] else ...[
                    _skipButton(context, () async {
                      await _swiperController.move(swiperSize - 1);
                    })
                  ],
                ],
              ),
            ),
            const SizedBox(height: 80),
            Expanded(
              child: Stack(
                children: [
                  Swiper(
                    onIndexChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        if (index == 0) {
                          unawaited(_controller.play());
                        }
                        if (index == 1) {
                          unawaited(_colouringController.play());
                        }
                      });
                    },
                    itemBuilder: (context, index) => Padding(
                      padding: padding,
                      child: pages[index],
                    ),
                    itemCount: swiperSize,
                    pagination: const SwiperPagination(
                        builder: DotSwiperPaginationBuilder(
                            color: AppColor.auLightGrey,
                            activeColor: MomaPallet.lightYellow)),
                    control: const SwiperControl(
                        color: Colors.transparent,
                        disableColor: Colors.transparent,
                        size: 0),
                    loop: false,
                    controller: _swiperController,
                  ),
                  Visibility(
                    visible: isLastPage,
                    child: Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: padding,
                        child: widget.payload.startButton,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skipButton(BuildContext context, Function()? onSkip) =>
      GestureDetector(
        onTap: onSkip,
        child: SvgPicture.asset('assets/images/skip.svg'),
      );

  Widget _page1(VideoPlayerController controller) {
    final theme = Theme.of(context);
    final termsConditionsStyle = theme.textTheme.moMASans400Grey12
        .copyWith(color: AppColor.auQuickSilver);
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
              height: 265,
              child: controller.value.isInitialized
                  ? VideoPlayer(controller)
                  : Container()),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'moma_project_invite'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
              const SizedBox(height: 8),
              Text(
                'with_15_blank_stamps'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
              const SizedBox(height: 40),
              Text.rich(
                TextSpan(
                  style: termsConditionsStyle,
                  children: <TextSpan>[
                    TextSpan(
                      text: 'by_continuing'.tr(),
                    ),
                    TextSpan(
                        text: 'terms_and_conditions'.tr(),
                        style: termsConditionsStyle.copyWith(
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            unawaited(_navigationService.openAutonomyDocument(
                                MOMA_TERMS_CONDITIONS_URL,
                                'terms_and_conditions'.tr()));
                          }),
                    const TextSpan(
                      text: '.',
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _promptExplain(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 265,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PromptView(
                prompt: Prompt(id: '', description: 'prompt_example'.tr()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
        Text(
          'prompt_explain_desc'.tr(),
          style: theme.textTheme.moMASans400Black18,
        ),
      ],
    );
  }

  Widget _page2(int index, {double? totalDistance}) {
    final imagePath = 'assets/images/postcard_explain_$index.png';
    final theme = Theme.of(context);
    final distanceFormatter = DistanceFormatter();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalDistance != null)
            Text(
                'total_distance'.tr(namedArgs: {
                  'distance': distanceFormatter.showDistance(
                      distance: totalDistance, distanceUnit: DistanceUnit.mile)
                }),
                style: theme.textTheme.moMASans400Black18
                    .copyWith(color: const Color.fromRGBO(131, 79, 196, 1)))
          else
            const SizedBox(height: 24),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'moma_explain_$index'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _page3(int index, VideoPlayerController controller) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
                height: 265,
                child: controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller))
                    : Container()),
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'moma_explain_$index'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _rowItem(BuildContext context, String title, double totalDistance,
      String imagePath) {
    final theme = Theme.of(context);
    final distanceFormatter = DistanceFormatter();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          imagePath,
          height: 65,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.moMASans400Black18),
            Text(
                distanceFormatter.showDistance(
                    distance: totalDistance, distanceUnit: DistanceUnit.mile),
                style: theme.textTheme.moMASans400Black18
                    .copyWith(color: const Color.fromRGBO(131, 79, 196, 1))),
          ],
        )
      ],
    );
  }

  Widget _page4(int index) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 265,
            child: Column(
              children: [
                _rowItem(context, '1st'.tr(), 91103,
                    'assets/images/postcard_leaderboard_1.svg'),
                const SizedBox(height: 35),
                _rowItem(context, '2nd'.tr(), 88791,
                    'assets/images/postcard_leaderboard_2.svg'),
                const SizedBox(height: 35),
                _rowItem(context, '3rd'.tr(), 64003,
                    'assets/images/postcard_leaderboard_3.svg'),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index.',
                style: theme.textTheme.moMASans400Black18,
              ),
              Text(
                'moma_explain_$index'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _postcardPreview(BuildContext context, AssetToken asset) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 30,
                  height: (MediaQuery.of(context).size.width - 30) /
                      postcardAspectRatio,
                  child: PostcardViewWidget(
                    assetToken: asset,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'this_is_your_group_postcard'.tr(),
                style: theme.textTheme.moMASans400Black18,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class PostcardExplainPayload {
  final AssetToken asset;
  final Widget startButton;
  final bool isPayToMint;
  final List<Widget>? pages;

  PostcardExplainPayload(this.asset, this.startButton,
      {this.isPayToMint = false, this.pages});
}
