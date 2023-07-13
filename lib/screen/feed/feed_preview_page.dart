//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tip_card.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_view/gif_view.dart';
import 'package:measured_size/measured_size.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Map<String, double> heightMap = {};

class FeedPreviewPage extends StatelessWidget {
  final ScrollController? controller;

  FeedPreviewPage({Key? key, this.controller}) : super(key: key);

  final nftCollectionBloc = injector<NftCollectionBloc>();

  @override
  Widget build(BuildContext context) {
    heightMap = {};
    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => FeedBloc(
              injector(),
              injector(),
              nftCollectionBloc.database.tokenDao,
            ),
          ),
          BlocProvider(
              create: (_) => IdentityBloc(injector<AppDatabase>(), injector())),
        ],
        child: FeedPreviewScreen(
          controller: controller,
        ),
      ),
    );
  }
}

class FeedPreviewScreen extends StatefulWidget {
  final ScrollController? controller;

  const FeedPreviewScreen({Key? key, this.controller}) : super(key: key);

  @override
  State<FeedPreviewScreen> createState() => _FeedPreviewScreenState();
}

class _FeedPreviewScreenState extends State<FeedPreviewScreen>
    with
        RouteAware,
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        AfterLayoutMixin<FeedPreviewScreen> {
  String? swipeDirection;

  late FeedBloc _bloc;
  final _metricClient = injector<MetricClientService>();

  @override
  void initState() {
    super.initState();
    _bloc = context.read<FeedBloc>();
    _bloc.add(GetFeedsEvent());
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _metricClient.timerEvent(MixpanelEvent.loadingDiscovery);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    Sentry.getSpan()?.finish(status: const SpanStatus.ok());
    super.dispose();
  }

  final nftCollectionBloc = injector<NftCollectionBloc>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: BlocConsumer<FeedBloc, FeedState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state.error != null) {
              return Padding(
                padding:
                    ResponsiveLayout.pageEdgeInsets.copyWith(top: 24, right: 5),
                child: Text(
                  "discover_unable_to_load".tr(),
                  style: theme.textTheme.ppMori400White14,
                ),
              );
            }
            if (state.feedTokenEventsMap?.isEmpty ?? true) {
              return _emptyOrLoadingDiscoveryWidget(state.appFeedData);
            }
            _metricClient.addEvent(MixpanelEvent.loadingDiscovery);
            return Column(children: [
              Expanded(
                child: CustomScrollView(
                  controller: widget.controller,
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 1000,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Tipcard(
                          titleText: "want_to_receive_real_time".tr(),
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(AppRouter.preferencesPage);
                          },
                          buttonText: "turn_on_notif".tr(),
                          content: Text(
                            "turn_on_notif_to_get".tr(),
                            style: theme.textTheme.ppMori400Black14,
                          ),
                          listener:
                              injector<ConfigurationService>().showNotifTip,
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _listItem(
                            state.feedTokenEventsMap!.entries.elementAt(index)),
                        childCount: state.feedTokenEventsMap?.length ?? 0,
                      ),
                    )
                  ],
                ),
              )
            ]);
          }),
    );
  }

  Widget _listItem(MapEntry<AssetToken, List<FeedEvent>> entry) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _moveToInfo(entry.key, entry.value);
      },
      child: Column(children: [
        Center(
          child: IgnorePointer(
            child: FeedArtwork(
              assetToken: entry.key,
            ),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        BlocProvider(
          create: (_) => IdentityBloc(injector<AppDatabase>(), injector()),
          child: Align(
              alignment: Alignment.topCenter,
              child:
                  ControlView(feedEvents: entry.value, feedToken: entry.key)),
        ),
        const SizedBox(
          height: 60,
        ),
      ]),
    );
  }

  Future _moveToInfo(AssetToken asset, List<FeedEvent> events) async {
    Navigator.of(context).pushNamed(
      AppRouter.feedArtworkDetailsPage,
      arguments: FeedDetailPayload(asset, events),
    );
  }

  Widget _emptyOrLoadingDiscoveryWidget(AppFeedData? appFeedData) {
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Padding(
        padding: ResponsiveLayout.pageEdgeInsets
            .copyWith(top: safeAreaTop + 2, right: 5),
        child: Stack(children: [
          // loading
          if (appFeedData == null) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GifView.asset(
                    "assets/images/loading_white.gif",
                    width: 52,
                    height: 52,
                    frameRate: 12,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    "loading...".tr(),
                    style: ResponsiveLayout.isMobile
                        ? theme.textTheme.ppMori400White12
                        : theme.textTheme.ppMori400White14,
                  ),
                ],
              ),
            )
          ] else if (appFeedData.events.isEmpty) ...[
            Column(children: [
              const SizedBox(height: 100),
              Container(
                padding: ResponsiveLayout.pageEdgeInsets
                    .copyWith(top: 0, left: 0, bottom: 0),
                child: Text(
                  "discovery_keep_you_up".tr(),
                  //'Discovery keeps you up to date on what your favorite artists are creating and collecting.
                  // For now they haven’t created or collected anything new yet. Once they do, you can view it here. ',
                  style: theme.primaryTextTheme.bodyLarge,
                  textAlign: TextAlign.justify,
                ),
              )
            ])
          ],
        ]));
  }
}

class FeedArtwork extends StatefulWidget {
  final AssetToken? assetToken;
  final Function? onInit;

  const FeedArtwork({Key? key, this.assetToken, this.onInit}) : super(key: key);

  @override
  State<FeedArtwork> createState() => _FeedArtworkState();
}

class _FeedArtworkState extends State<FeedArtwork>
    with RouteAware, WidgetsBindingObserver {
  INFTRenderingWidget? _renderingWidget;

  final _bloc = ArtworkPreviewDetailBloc(injector(), injector(), injector());

  @override
  void initState() {
    if (widget.assetToken == null) {
    } else {
      _bloc.add(ArtworkFeedPreviewDetailGetAssetTokenEvent(widget.assetToken!));
    }
    widget.onInit?.call();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _renderingWidget?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    _renderingWidget?.didPopNext();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    _renderingWidget?.clearPrevious();
    super.didPushNext();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateWebviewSize();
  }

  _updateWebviewSize() {
    if (_renderingWidget != null &&
        _renderingWidget is WebviewNFTRenderingWidget) {
      (_renderingWidget as WebviewNFTRenderingWidget).updateWebviewSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assetToken == null) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      return Container(
        color: AppColor.secondarySpanishGrey,
        width: screenWidth,
        height: screenHeight * 0.55,
      );
    }

    return BlocBuilder<ArtworkPreviewDetailBloc, ArtworkPreviewDetailState>(
      bloc: _bloc,
      builder: (context, state) {
        switch (state.runtimeType) {
          case ArtworkPreviewDetailLoadingState:
            final screenWidth = MediaQuery.of(context).size.width;
            return SizedBox(
              height: heightMap[widget.assetToken?.id] ?? screenWidth,
              width: screenWidth,
            );
          case ArtworkPreviewDetailLoadedState:
            final asset = (state as ArtworkPreviewDetailLoadedState).assetToken;
            if (asset != null) {
              return MeasuredSize(
                onChange: (Size size) {
                  final id = asset.id;
                  if (id.isEmpty) {
                    return;
                  }
                  heightMap[id] = size.height;
                },
                child: BlocProvider(
                  create: (_) => RetryCubit(),
                  child: BlocBuilder<RetryCubit, int>(
                    builder: (context, attempt) {
                      if (attempt > 0) {
                        _renderingWidget?.dispose();
                        _renderingWidget = null;
                      }
                      if (_renderingWidget == null ||
                          _renderingWidget!.previewURL !=
                              asset.getPreviewUrl()) {
                        _renderingWidget = buildRenderingWidget(
                          context,
                          asset,
                          attempt: attempt > 0 ? attempt : null,
                          overriddenHtml: state.overriddenHtml,
                          isMute: true,
                        );
                      }
                      final mimeType = asset.getMimeType;
                      switch (mimeType) {
                        case "image":
                        case "svg":
                        case 'gif':
                        case "audio":
                          return Container(
                            child: _renderingWidget?.build(context),
                          );
                        case "video":
                          return Container(
                            child: _renderingWidget?.build(context),
                          );
                        default:
                          return AspectRatio(
                            aspectRatio: 1,
                            child: _renderingWidget?.build(context),
                          );
                      }
                    },
                  ),
                ),
              );
            }
            return const SizedBox();
          default:
            return const SizedBox();
        }
      },
    );
  }
}

class FeedDetailPayload {
  AssetToken? feedToken;
  List<FeedEvent> feedEvents;

  FeedDetailPayload(
    this.feedToken,
    this.feedEvents,
  );

  FeedDetailPayload copyWith(
      AssetToken? feedToken, List<FeedEvent>? feedEvents) {
    return FeedDetailPayload(
      feedToken ?? this.feedToken,
      feedEvents ?? this.feedEvents,
    );
  }
}

class ControlView extends StatefulWidget {
  final List<FeedEvent> feedEvents;
  final AssetToken? feedToken;

  const ControlView({Key? key, required this.feedEvents, this.feedToken})
      : super(key: key);

  @override
  State<ControlView> createState() => _ControlViewState();
}

class _ControlViewState extends State<ControlView> {
  @override
  void initState() {
    fetchIdentities();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchIdentities() {
    final currentToken = widget.feedToken;
    final currentFeedEvents = widget.feedEvents;

    final neededIdentities = [
      currentToken?.artistName ?? '',
      ...currentFeedEvents.map((e) => e.recipient),
    ];
    neededIdentities.removeWhere((element) => element == '');

    if (neededIdentities.isNotEmpty) {
      context.read<IdentityBloc>().add(GetIdentityEvent(neededIdentities));
    }
  }

  Widget _controlViewWhenNoAsset(FeedEvent event) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.only(
        left: 15,
        right: 5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: theme.primaryTextTheme.headlineSmall,
                      children: <TextSpan>[
                        TextSpan(
                          text: 'nft_indexing'.tr(),
                          style: ResponsiveLayout.isMobile
                              ? theme.textTheme.ppMori400White12
                              : theme.textTheme.atlasWhiteItalic14,
                        ),
                      ],
                    )),
                const SizedBox(height: 4),
                Row(children: [
                  Flexible(child: BlocBuilder<IdentityBloc, IdentityState>(
                      builder: (context, identityState) {
                    final followingName = event.recipient
                            .toIdentityOrMask(identityState.identityMap) ??
                        event.recipient;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.galleryPage,
                          arguments: GalleryPagePayload(
                            address: event.recipient,
                            artistName: followingName,
                          ),
                        );
                      },
                      child: Text(
                        followingName,
                        style: ResponsiveLayout.isMobile
                            ? theme.textTheme.ppMori400White14
                            : theme.textTheme.atlasWhiteBold14,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })),
                ]),
              ],
            ),
          ),
          const SizedBox(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.feedToken;
    final events = widget.feedEvents;
    if (asset == null) {
      return _controlViewWhenNoAsset(events.first);
    }
    final neededIdentities = [
      asset.artistName ?? '',
      ...events.map((e) => e.recipient)
    ];
    neededIdentities.removeWhere((element) => element == '');
    if (neededIdentities.isNotEmpty) {
      context.read<IdentityBloc>().add(GetIdentityEvent(neededIdentities));
    }

    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.only(left: 15, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: BlocBuilder<IdentityBloc, IdentityState>(
                builder: (context, identityState) {
              final artistName =
                  asset.artistName?.toIdentityOrMask(identityState.identityMap);
              final followingNames = events
                  .map((event) =>
                      event.recipient
                          .toIdentityOrMask(identityState.identityMap) ??
                      event.recipient)
                  .toList();
              final followingTime =
                  getDateTimeRepresentation(events.first.timestamp.toLocal());

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.title != null && asset.title!.isEmpty
                              ? 'nft'
                              : '${asset.title} ',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.ppMori400White16,
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        if (artistName != null) ...[
                          RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                                text: 'by'.tr(args: [artistName]),
                                style: theme.textTheme.ppMori400White14),
                          ),
                        ],
                        const SizedBox(
                          height: 3,
                        ),
                        Wrap(
                          runSpacing: 4.0,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.ppMori400White14,
                                children: [
                                  TextSpan(
                                    text: "_by".tr(args: [
                                      events.first.actionRepresentation
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                            ...events
                                .mapIndexed((i, event) => [
                                      GestureDetector(
                                        child: Text(
                                          followingNames[i],
                                          style: theme
                                              .textTheme.ppMori400White14
                                              .copyWith(
                                                  color: AppColor.auSuperTeal),
                                        ),
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                            AppRouter.galleryPage,
                                            arguments: GalleryPagePayload(
                                              address: event.recipient,
                                              artistName: followingNames[i],
                                            ),
                                          );
                                        },
                                      ),
                                      if (i < events.length - 1)
                                        Text(", ",
                                            style: theme
                                                .textTheme.ppMori400White14)
                                    ])
                                .flattened,
                            Text(" • ", style: theme.textTheme.ppMori400Grey14),
                            Text(
                                events.length > 1
                                    ? "last_time_format"
                                        .tr(args: [followingTime])
                                    : followingTime,
                                style: theme.textTheme.ppMori400Grey14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
