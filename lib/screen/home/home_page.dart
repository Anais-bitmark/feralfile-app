//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_screen.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/cloud_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/locale_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/carousel.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tip_card.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:open_settings/open_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

import '../../util/token_ext.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<HomePage>,
        AutomaticKeepAliveClientMixin {
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  late MetricClientService _metricClient;
  int _cachedImageSize = 0;

  final _collectionProKey = GlobalKey<CollectionProState>();

  Future<List<AddressIndex>> getAddressIndexes() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddressIndexes();
  }

  Future<List<String>> getAddresses() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddresses();
  }

  final _clientTokenService = injector<ClientTokenService>();
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();

  final nftBloc = injector<ClientTokenService>().nftBloc;

  @override
  void initState() {
    super.initState();
    _metricClient = injector.get<MetricClientService>();
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController()..addListener(_scrollListenerToLoadMore);
    _configurationService.setAutoShowPostcard(true);
    NftCollectionBloc.eventController.stream.listen((event) async {
      switch (event.runtimeType) {
        case ReloadEvent:
        case GetTokensByOwnerEvent:
        case UpdateTokensEvent:
          nftBloc.add(event);
          break;
        default:
      }
    });

    refreshFeeds();
    _clientTokenService.refreshTokens(syncAddresses: true).then((value) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
    });

    context.read<HomeBloc>().add(CheckReviewAppEvent());

    injector<IAPService>().setup();
    memoryValues.inGalleryView = true;
  }

  _scrollListenerToLoadMore() {
    if (_controller.position.pixels + 100 >=
        _controller.position.maxScrollExtent) {
      final nextKey = nftBloc.state.nextKey;
      if (nextKey == null || nextKey.isLoaded) return;
      nftBloc.add(GetTokensByOwnerEvent(pageKey: nextKey));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    injector<FeralFileService>().completeDelayedFFConnections();
    _handleForeground();
    injector<AutonomyService>().postLinkedAddresses();
    _checkForKeySync(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _fgbgSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() async {
    super.didPopNext();
    final connectivityResult = await (Connectivity().checkConnectivity());
    _clientTokenService.refreshTokens().then((value) => refreshFeeds());
    refreshNotification();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!mounted) return;
        nftBloc
            .add(RequestIndexEvent(await _clientTokenService.getAddresses()));
      });
    }
    memoryValues.inGalleryView = true;
  }

  @override
  void didPushNext() {
    memoryValues.inGalleryView = false;
    super.didPushNext();
  }

  void _onTokensUpdate(List<CompactedAssetToken> tokens) async {
    final artistIds = tokens
        .map((e) => e.artistID)
        .where((value) => value?.isNotEmpty == true)
        .map((e) => e as String)
        .toList();
    injector<FeedService>().refreshFollowings(artistIds);

    //check minted postcard and naviagtor to artwork detail
    final config = injector.get<ConfigurationService>();
    final listTokenMints = config.getListPostcardMint();
    if (tokens.any((element) =>
        listTokenMints.contains(element.id) && element.pending != true)) {
      final tokenMints = tokens
          .where(
            (element) =>
                listTokenMints.contains(element.id) && element.pending != true,
          )
          .map((e) => e.identity)
          .toList();
      if (config.isAutoShowPostcard()) {
        log.info("Auto show minted postcard");
        final payload = ArtworkDetailPayload(tokenMints, 0);
        Navigator.of(context).pushNamed(
          AppRouter.claimedPostcardDetailsPage,
          arguments: payload,
        );
      }

      config.setListPostcardMint(
        tokenMints.map((e) => e.id).toList(),
        isRemoved: true,
      );
    }

    // Check if there is any Tezos token in the list
    List<String> allAccountNumbers =
        await injector<AccountService>().getAllAddresses();
    final hashedAddresses = allAccountNumbers.fold(
        0, (int previousValue, element) => previousValue + element.hashCode);

    if (_configurationService.sentTezosArtworkMetricValue() !=
            hashedAddresses &&
        tokens.any((asset) =>
            asset.blockchain == Blockchain.TEZOS.name.toLowerCase())) {
      _metricClient.addEvent("collection_has_tezos");
      _configurationService.setSentTezosArtworkMetric(hashedAddresses);
    }
  }

  List<CompactedAssetToken> _updateTokens(List<CompactedAssetToken> tokens) {
    tokens = tokens.filterAssetToken();
    final nextKey = nftBloc.state.nextKey;
    if (nextKey != null &&
        !nextKey.isLoaded &&
        tokens.length < COLLECTION_INITIAL_MIN_SIZE) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: nextKey));
    }
    return tokens;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final contentWidget =
        BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
      bloc: nftBloc,
      listenWhen: (previousState, currentState) {
        final currentNumber = currentState.tokens.items
            .filterAssetToken(isShowHidden: true)
            .length;
        final previousNumber = previousState.tokens.items
            .filterAssetToken(isShowHidden: true)
            .length;
        final diffLength = currentNumber - previousNumber;
        if (diffLength != 0) {
          _metricClient.addEvent(MixpanelEvent.addNFT, data: {
            'number': diffLength,
          });
        }
        if (diffLength != 0) {
          _metricClient.addEvent(MixpanelEvent.numberNft, data: {
            'number': currentNumber,
          });
          _metricClient.setLabel(MixpanelProp.numberNft, currentNumber);
        }
        return true;
      },
      builder: (context, state) {
        final isPremium = _configurationService.isPremium();
        if (isPremium) {
          return CollectionPro(
            key: _collectionProKey,
            tokens: _updateTokens(state.tokens.items),
          );
        }
        return NftCollectionGrid(
          state: state.state,
          tokens: _updateTokens(state.tokens.items),
          loadingIndicatorBuilder: _loadingView,
          emptyGalleryViewBuilder: _emptyGallery,
          customGalleryViewBuilder: (context, tokens) =>
              _assetsWidget(context, tokens),
        );
      },
      listener: (context, state) async {
        log.info("[NftCollectionBloc] State update $state");
        _collectionProKey.currentState?.loadCollection();
        if (state.state == NftLoadingState.done) {
          _onTokensUpdate(state.tokens.items);
        }
      },
    );

    return BlocListener<UpgradesBloc, UpgradeState>(
      listener: (context, state) {
        ConfigurationService config = injector<ConfigurationService>();
        WCPeerMeta? peerMeta = config.getTVConnectPeerMeta();
        int? id = config.getTVConnectID();
        if (peerMeta != null || id != null) {
          if (state.status == IAPProductStatus.trial ||
              state.status == IAPProductStatus.completed) {
            injector<NavigationService>().navigateTo(AppRouter.tvConnectPage,
                arguments: WCConnectPageArgs(id!, peerMeta!));
            config.deleteTVConnectData();
          } else if (state.status != IAPProductStatus.loading &&
              state.status != IAPProductStatus.pending) {
            injector<WalletConnectService>().rejectRequest(peerMeta!, id!);
            config.deleteTVConnectData();
          }
        }
      },
      child: PrimaryScrollController(
        controller: _controller,
        child: Scaffold(
          appBar: getLightEmptyAppBar(),
          backgroundColor: theme.colorScheme.background,
          body: contentWidget,
        ),
      ),
    );
  }

  Widget _loadingView(BuildContext context) {
    final paddingTop = MediaQuery.of(context).viewPadding.top;

    return Center(
        child: Column(
      children: [
        HeaderView(
          paddingTop: paddingTop,
        ),
        loadingIndicator(),
      ],
    ));
  }

  Widget _emptyGallery(BuildContext context) {
    final theme = Theme.of(context);
    final paddingTop = MediaQuery.of(context).viewPadding.top;
    return ListView(
      padding: ResponsiveLayout.getPadding.copyWith(left: 0, right: 0),
      children: [
        HeaderView(paddingTop: paddingTop),
        _carouselTipcard(context),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            "collection_empty_now".tr(),
            //"Your collection is empty for now.",
            style: theme.textTheme.ppMori400Black14,
          ),
        ),
      ],
    );
  }

  Widget _assetsWidget(BuildContext context, List<CompactedAssetToken> tokens) {
    final accountIdentities = tokens
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => element.identity)
        .toList();

    const int cellPerRowPhone = 3;
    const int cellPerRowTablet = 6;
    const double cellSpacing = 3.0;
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;
    if (_cachedImageSize == 0) {
      final estimatedCellWidth =
          MediaQuery.of(context).size.width / cellPerRow -
              cellSpacing * (cellPerRow - 1);
      _cachedImageSize = (estimatedCellWidth * 3).ceil();
    }
    List<Widget> sources;
    final paddingTop = MediaQuery.of(context).viewPadding.top;
    sources = [
      SliverToBoxAdapter(
        child: HeaderView(paddingTop: paddingTop),
      ),
      SliverToBoxAdapter(
        child: _carouselTipcard(context),
      ),
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cellPerRow,
          crossAxisSpacing: cellSpacing,
          mainAxisSpacing: cellSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final asset = tokens[index];

            if (asset.pending == true && asset.isPostcard) {
              return MintTokenWidget(
                thumbnail: asset.galleryThumbnailURL,
                tokenId: asset.tokenId,
              );
            }

            return GestureDetector(
              child: asset.pending == true && !asset.hasMetadata
                  ? PendingTokenWidget(
                      thumbnail: asset.galleryThumbnailURL,
                      tokenId: asset.tokenId,
                    )
                  : tokenGalleryThumbnailWidget(
                      context,
                      asset,
                      _cachedImageSize,
                      usingThumbnailID: index > 50,
                    ),
              onTap: () {
                if (asset.pending == true && !asset.hasMetadata) return;

                final index = tokens
                    .where((e) => e.pending != true || e.hasMetadata)
                    .toList()
                    .indexOf(asset);
                final payload = ArtworkDetailPayload(accountIdentities, index);

                final pageName = asset.isPostcard
                    ? AppRouter.claimedPostcardDetailsPage
                    : AppRouter.artworkDetailsPage;
                Navigator.of(context)
                    .pushNamed(pageName, ////need change to pageName
                        arguments: payload);

                _metricClient.addEvent(MixpanelEvent.viewArtwork,
                    data: {"id": asset.id});
              },
            );
          },
          childCount: tokens.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: sources,
      controller: _controller,
    );
  }

  Widget _carouselTipcard(BuildContext context) {
    return MultiValueListenableBuilder(
      valueListenables: [
        _configurationService.showTvAppTip,
        _configurationService.showCreatePlaylistTip,
        _configurationService.showLinkOrImportTip,
        _configurationService.showBackupSettingTip,
        _configurationService.expiredPostcardSharedLinkTip,
      ],
      builder: (BuildContext context, List<dynamic> values, Widget? child) {
        return CarouselWithIndicator(
          items: _listTipcards(context, values),
        );
      },
    );
  }

  List<Tipcard> _listTipcards(BuildContext context, List<dynamic> values) {
    final theme = Theme.of(context);
    final isShowTvAppTip = values[0] as bool;
    final isShowCreatePlaylistTip = values[1] as bool;
    final isShowLinkOrImportTip = values[2] as bool;
    final isShowBackupSettingTip = values[3] as bool;
    final expiredPostcardShareLink = values[4] as List<SharedPostcard>;
    final compactedToken = nftBloc.state.tokens.items;
    return [
      if (isShowLinkOrImportTip)
        Tipcard(
            titleText: "do_you_have_NFTs_in_other_wallets".tr(),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.accessMethodPage);
            },
            buttonText: "add_wallet".tr(),
            content: Text("you_can_link_or_import".tr(),
                style: theme.textTheme.ppMori400Black14),
            listener: _configurationService.showLinkOrImportTip),
      if (isShowCreatePlaylistTip)
        Tipcard(
            titleText: "create_your_first_playlist".tr(),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.createPlayListPage);
            },
            buttonText: "create_new_playlist".tr(),
            content: Text("as_a_pro_sub_playlist".tr(),
                style: theme.textTheme.ppMori400Black14),
            listener: _configurationService.showCreatePlaylistTip),
      if (isShowTvAppTip)
        Tipcard(
            titleText: "enjoy_your_collection".tr(),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.scanQRPage,
                arguments: ScannerItem.GLOBAL,
              );
            },
            buttonText: "sync_up_with_autonomy_tv".tr(),
            content: RichText(
              text: TextSpan(
                text: "as_a_pro_sub_TV_app".tr(),
                style: theme.textTheme.ppMori400Black14,
                children: [
                  TextSpan(
                    text: "google_TV_app".tr(),
                    style: theme.textTheme.ppMori400Black14.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final metricClient = injector<MetricClientService>();
                        metricClient.addEvent(MixpanelEvent.tapLinkInTipCard,
                            data: {
                              "link": TV_APP_STORE_URL,
                              "title": "enjoy_your_collection".tr()
                            });
                        launchUrl(Uri.parse(TV_APP_STORE_URL),
                            mode: LaunchMode.externalApplication);
                      },
                  ),
                  TextSpan(
                    text: "currently_available_on".tr(),
                  )
                ],
              ),
            ),
            listener: _configurationService.showTvAppTip),
      if (isShowBackupSettingTip)
        Tipcard(
            titleText: "backup_failed".tr(),
            onPressed: Platform.isAndroid
                ? () {
                    OpenSettings.openAddAccountSetting();
                  }
                : () async {
                    openAppSettings();
                  },
            buttonText: Platform.isAndroid
                ? "open_device_setting".tr()
                : "open_icloud_setting".tr(),
            content: Text(
                Platform.isAndroid
                    ? "backup_tip_card_content_android".tr()
                    : "backup_tip_card_content_ios".tr(),
                style: theme.textTheme.ppMori400Black14),
            listener: _configurationService.showBackupSettingTip),
      if (!(_configurationService.isNotificationEnabled() ?? false))
        ...expiredPostcardShareLink.map((e) {
          final title = compactedToken
                  .firstWhereOrNull((element) => element.id == e.tokenID)
                  ?.title ??
              "";
          return Tipcard(
            titleText: "moma_postcard".tr(),
            onPressed: () async {
              final payload = ArtworkDetailPayload(
                  [ArtworkIdentity(e.tokenID, e.owner)], 0);
              Navigator.of(context).pushNamed(
                  AppRouter.claimedPostcardDetailsPage,
                  arguments: payload);
              _configurationService.updateSharedPostcard([e], isRemoved: true);
            },
            onClosed: () async {
              _configurationService.updateSharedPostcard([e], isRemoved: true);
            },
            buttonText: "go_to_postcard".tr(),
            content: Text(
                "postcard_not_deliveried".tr(namedArgs: {"title": title}),
                style: theme.textTheme.ppMori400Black14),
            listener: ValueNotifier<bool>(true),
          );
        }).toList(),
    ];
  }

  Future<void> _checkForKeySync(BuildContext context) async {
    final cloudDatabase = injector<CloudDatabase>();
    final defaultAccounts = await cloudDatabase.personaDao.getDefaultPersonas();

    if (defaultAccounts.length >= 2) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRouter.keySyncPage);
    }
  }

  void refreshFeeds() async {
    await injector<FeedService>().checkNewFeeds();
  }

  void scrollToTop() {
    _controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn);
  }

  Future refreshNotification() async {
    await injector<CustomerSupportService>().getIssuesAndAnnouncement();
  }

  void _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        _handleForeground();
        break;
      case FGBGType.background:
        _handleBackground();
        break;
    }
  }

  Future _checkTipCardShowTime() async {
    final metricClient = injector<MetricClientService>();
    log.info("_checkTipCardShowTime");
    final configurationService = injector<ConfigurationService>();

    final doneOnboardingTime = configurationService.getDoneOnboardingTime();
    final subscriptionTime = configurationService.getSubscriptionTime();

    final now = DateTime.now();
    if (subscriptionTime != null) {
      if (now.isAfter(subscriptionTime.add(const Duration(hours: 24))) &&
          !configurationService.getAlreadyShowTvAppTip()) {
        configurationService.showTvAppTip.value = true;
        await configurationService.setAlreadyShowTvAppTip(true);
        metricClient.addEvent(MixpanelEvent.showTipcard,
            data: {"title": "enjoy_your_collection".tr()});
      }
      if (now.isAfter(subscriptionTime.add(const Duration(hours: 24))) &&
          !configurationService.getAlreadyShowCreatePlaylistTip() &&
          injector<ConfigurationService>().getPlayList().isEmpty != false) {
        configurationService.showCreatePlaylistTip.value = true;
        configurationService.setAlreadyShowCreatePlaylistTip(true);
        metricClient.addEvent(MixpanelEvent.showTipcard,
            data: {"title": "create_your_first_playlist".tr()});
      }
    }

    final remindTime = configurationService.getShowBackupSettingTip();
    final shouldRemindNow = remindTime == null || now.isAfter(remindTime);
    if (shouldRemindNow) {
      configurationService
          .setShowBackupSettingTip(now.add(const Duration(days: 7)));
      bool showTip = false;
      if (Platform.isAndroid) {
        final isAndroidEndToEndEncryptionAvailable =
            await injector<AccountService>()
                .isAndroidEndToEndEncryptionAvailable();
        showTip = isAndroidEndToEndEncryptionAvailable != true;
      } else {
        final iCloudAvailable = injector<CloudService>().isAvailableNotifier;
        showTip = !iCloudAvailable.value;
      }
      if (showTip && configurationService.showBackupSettingTip.value == false) {
        configurationService.showBackupSettingTip.value = true;
        metricClient.addEvent(MixpanelEvent.showTipcard,
            data: {"title": "backup_failed".tr()});
      }
    }
    if (doneOnboardingTime != null) {
      if (now.isAfter(doneOnboardingTime.add(const Duration(hours: 24))) &&
          !configurationService.getAlreadyShowLinkOrImportTip()) {
        configurationService.showLinkOrImportTip.value = true;
        configurationService.setAlreadyShowLinkOrImportTip(true);
        metricClient.addEvent(MixpanelEvent.showTipcard,
            data: {"title": "do_you_have_NFTs_in_other_wallets".tr()});
      }
      final premium = await isPremium();
      if (now.isAfter(doneOnboardingTime.add(const Duration(hours: 72))) &&
          !premium &&
          !configurationService.getAlreadyShowProTip()) {
        configurationService.showProTip.value = true;
        configurationService.setAlreadyShowProTip(true);
        metricClient.addEvent(MixpanelEvent.showTipcard,
            data: {"title": "try_autonomy_pro_free".tr()});
      }
    }
    await _postcardService.checkNotification();
  }

  void _handleForeground() async {
    final locale = Localizations.localeOf(context);
    LocaleService.refresh(locale);
    memoryValues.inForegroundAt = DateTime.now();
    await injector<ConfigurationService>().reload();
    await _checkTipCardShowTime();
    try {
      await injector<SettingsDataService>().restoreSettingsData();
    } catch (exception) {
      if (exception is DioException && exception.response?.statusCode == 404) {
        // if there is no backup, upload one.
        await injector<SettingsDataService>().backup();
      } else {
        Sentry.captureException(exception);
      }
    }

    injector<WalletConnectService>().initSessions(forced: true);

    refreshFeeds();
    _clientTokenService.refreshTokens(checkPendingToken: true);
    refreshNotification();
    _metricClient.addEvent("device_foreground");
    _subscriptionNotify();
    injector<VersionService>().checkForUpdate();
    // Reload token in Isolate
    final jwtToken =
        (await injector<AuthService>().getAuthToken(forceRefresh: true))
            .jwtToken;

    final feedService = injector<FeedService>();
    feedService
        .refreshJWTToken(jwtToken)
        .then((value) => feedService.checkNewFeeds());

    injector<CustomerSupportService>().getIssuesAndAnnouncement();
    injector<CustomerSupportService>().processMessages();
  }

  Future _subscriptionNotify() async {
    final configService = injector<ConfigurationService>();
    final iapService = injector<IAPService>();

    if (configService.isNotificationEnabled() != true ||
        await iapService.isSubscribed() ||
        !configService.shouldShowSubscriptionHint() ||
        configService
                .getLastTimeAskForSubscription()
                ?.isAfter(DateTime.now().subtract(const Duration(days: 2))) ==
            true) {
      return;
    }

    log.info("[HomePage] Show subscription notification");
    await configService.setLastTimeAskForSubscription(DateTime.now());
    const key = Key("subscription");
    if (!mounted) return;
    showInfoNotification(key, "subscription_hint".tr(),
        duration: const Duration(seconds: 5), openHandler: () {
      UpgradesView.showSubscriptionDialog(context, null, null, () {
        hideOverlay(key);
        context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
      });
    }, addOnTextSpan: [
      TextSpan(
        text: 'trial_today'.tr(),
        style: Theme.of(context).textTheme.ppMori400Green14,
      )
    ]);
  }

  void _handleBackground() {
    _metricClient.addEvent(MixpanelEvent.deviceBackground);
    _metricClient.sendAndClearMetrics();
    FileLogger.shrinkLogFileIfNeeded();
  }

  @override
  bool get wantKeepAlive => true;
}
