import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_cached_manager.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import "package:collection/collection.dart";
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uni_links/uni_links.dart';
import 'package:autonomy_flutter/util/string_ext.dart';

class HomePage extends StatefulWidget {
  static const tag = "home";

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver {
  StreamSubscription? _deeplinkSubscription;
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  int _cachedImageSize = 0;
  String _gallerySortBy = GallerySortProperty.Platform;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
    _cloudBackup();
    WidgetsBinding.instance?.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController();
    context.read<HomeBloc>().add(RefreshTokensEvent());
    context.read<HomeBloc>().add(ReindexIndexerEvent());
    OneSignal.shared
        .setNotificationWillShowInForegroundHandler(_shouldShowNotifications);

    _gallerySortBy = injector<ConfigurationService>().getGallerySortBy() ??
        GallerySortProperty.Platform;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cloudBackup();
    } else if (state == AppLifecycleState.resumed) {
      injector<VersionService>().checkForUpdate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    routeObserver.unsubscribe(this);
    _deeplinkSubscription?.cancel();
    _fgbgSubscription?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() async {
    super.didPopNext();
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      context.read<HomeBloc>().add(RefreshTokensEvent());

      Future.delayed(const Duration(milliseconds: 1000), () {
        context.read<HomeBloc>().add(ReindexIndexerEvent());
      });
    }

    setState(() {
      _gallerySortBy = injector<ConfigurationService>().getGallerySortBy() ??
          GallerySortProperty.Platform;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeBloc>().state;
    final tokens = state.tokens;

    final shouldShowMainView = tokens != null && tokens.isNotEmpty;
    IdentityState? identityState;
    if (_gallerySortBy == GallerySortProperty.ArtistName) {
      identityState = context.watch<IdentityBloc>().state;
    }

    final Widget assetsWidget = shouldShowMainView
        ? _assetsWidget(tokens!, identityState?.identityMap)
        : _emptyGallery();

    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.tokens == null) return;
        final fetchingIdentityArtistNames = state.tokens!
            .map((e) => e.artistName ?? '')
            .where((e) => (e.startsWith("0x") || e.startsWith("tz")))
            .toSet();
        context
            .read<IdentityBloc>()
            .add(GetIdentityEvent(fetchingIdentityArtistNames));
      },
      child: PrimaryScrollController(
        controller: _controller,
        child: Scaffold(
          body: Stack(
            fit: StackFit.loose,
            children: [
              assetsWidget,
              PenroseTopBarView(true, _controller),
              if (state.fetchTokenState == ActionState.loading) ...[
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        0, MediaQuery.of(context).padding.top + 120, 20, 0),
                    child: CupertinoActivityIndicator(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyGallery() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        SizedBox(height: 160),
        Text(
          "Gallery",
          style: appTextTheme.headline1,
        ),
        SizedBox(height: 24.0),
        Text(
          "Your gallery is empty for now.",
          style: appTextTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _assetsWidget(
      List<AssetToken> tokens, Map<String, String>? identityMap) {
    final groupByProperty = groupBy(tokens, (AssetToken obj) {
      switch (_gallerySortBy) {
        case GallerySortProperty.Medium:
          return obj.medium?.capitalize();
        case GallerySortProperty.ArtistName:
          return obj.artistName;
        case GallerySortProperty.Chain:
          return obj.blockchain.capitalize();
        default:
          return polishSource(obj.source ?? "");
      }
    });
    var sortedKeys = groupByProperty.keys.toList()..sort();
    final tokenIDs = sortedKeys
        .map((e) => groupByProperty[e] ?? [])
        .expand((element) => element.map((e) => e.id))
        .toList();

    var sources = sortedKeys.map((sortingPropertyValue) {
      final assets = groupByProperty[sortingPropertyValue] ?? [];
      const int cellPerRow = 3;
      const double cellSpacing = 3.0;
      if (_cachedImageSize == 0) {
        final estimatedCellWidth =
            MediaQuery.of(context).size.width / cellPerRow -
                cellSpacing * (cellPerRow - 1);
        _cachedImageSize = (estimatedCellWidth * 3).ceil();
      }

      var _sortingPropertyValue = sortingPropertyValue;
      if (_sortingPropertyValue != null &&
          _gallerySortBy == GallerySortProperty.ArtistName) {
        final identity = identityMap?[_sortingPropertyValue];
        _sortingPropertyValue =
            _sortingPropertyValue.toIdentityOrMask(identityMap);
      }

      return <Widget>[
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(14, 0, 24, 14),
            child: Text(
              _sortingPropertyValue ?? '',
              style: appTextTheme.headline1,
            ),
          ),
        ),
        SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cellPerRow,
              crossAxisSpacing: cellSpacing,
              mainAxisSpacing: cellSpacing,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final asset = assets[index];
                final ext = p.extension(asset.galleryThumbnailURL!);
                return GestureDetector(
                  child: Hero(
                    tag: asset.id,
                    child: ext == ".svg"
                        ? SvgPicture.network(asset.galleryThumbnailURL!)
                        : CachedNetworkImage(
                            imageUrl: asset.galleryThumbnailURL!,
                            fit: BoxFit.cover,
                            memCacheHeight: _cachedImageSize,
                            memCacheWidth: _cachedImageSize,
                            cacheManager: injector<AUCacheManager>(),
                            placeholder: (context, index) => Container(
                                color: Color.fromRGBO(227, 227, 227, 1)),
                            placeholderFadeInDuration:
                                Duration(milliseconds: 300),
                            errorWidget: (context, url, error) => Container(
                                color: Color.fromRGBO(227, 227, 227, 1),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/image_error.svg',
                                    width: 75,
                                    height: 75,
                                  ),
                                )),
                          ),
                  ),
                  onTap: () {
                    final index = tokenIDs.indexOf(asset.id);
                    final payload = ArtworkDetailPayload(tokenIDs, index);
                    if (injector<ConfigurationService>()
                        .isImmediatePlaybackEnabled()) {
                      Navigator.of(context).pushNamed(
                          AppRouter.artworkPreviewPage,
                          arguments: payload);
                    } else {
                      Navigator.of(context).push(
                        AppRouter.onGenerateRoute(RouteSettings(
                            name: AppRouter.artworkDetailsPage,
                            arguments: payload)),
                      );
                    }
                  },
                );
              },
              childCount: assets.length,
            )),
        SliverToBoxAdapter(
            child: Container(
          height: 56.0,
        ))
      ];
    }).reduce((value, element) => value += element);

    sources.insert(
        0,
        SliverToBoxAdapter(
            child: Container(
          height: 168.0,
        )));

    return CustomScrollView(
      slivers: sources,
      controller: _controller,
    );
  }

  Future<void> _cloudBackup() async {
    final backup = injector<BackupService>();
    await backup.backupCloudDatabase();
  }

  Future<void> _initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      _handleDeeplink(initialLink);

      _deeplinkSubscription = linkStream.listen(_handleDeeplink);
    } on PlatformException {}
  }

  void _handleDeeplink(String? link) {
    if (link == null) return;

    final wcPrefixes = [
      "https://au.bitmark.com/apps/wc?uri=",
      "https://au.bitmark.com/apps/wc/wc?uri=", // maybe something wrong with WC register; fix by this for now
      "https://autonomy.io/apps/wc?uri=",
      "https://autonomy.io/apps/wc/wc?uri=",
    ];

    final tzPrefixes = [
      "https://au.bitmark.com/apps/tezos?uri=",
      "https://autonomy.io/apps/tezos?uri=",
    ];

    final wcDeeplinkPrefixes = [
      'wc:',
      'autonomy-wc:',
    ];

    final tbDeeplinkPrefixes = [
      "tezos://",
      "autonomy-tezos://",
    ];

    // Check Universal Link
    final callingWCPrefix =
        wcPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCPrefix != null) {
      final wcUri = link.substring(callingWCPrefix.length);
      final decodedWcUri = Uri.decodeFull(wcUri);
      context.read<HomeBloc>().add(HomeConnectWCEvent(decodedWcUri));
      return;
    }

    final callingTBPrefix =
        tzPrefixes.firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBPrefix != null) {
      final tzUri = link.substring(callingTBPrefix.length);
      context.read<HomeBloc>().add(HomeConnectTZEvent(tzUri));
      return;
    }

    final callingWCDeeplinkPrefix = wcDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingWCDeeplinkPrefix != null) {
      context.read<HomeBloc>().add(HomeConnectWCEvent(link));
      return;
    }

    final callingTBDeeplinkPrefix = tbDeeplinkPrefixes
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (callingTBDeeplinkPrefix != null) {
      context.read<HomeBloc>().add(HomeConnectTZEvent(link));
      return;
    }
  }

  void _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        if (injector<ConfigurationService>().isDevicePasscodeEnabled()) {
          injector<NavigationService>()
              .lockScreen()
              ?.then((_) => _deeplinkSubscription?.resume());
        } else {
          _deeplinkSubscription?.resume();
        }
        injector<ConfigurationService>().reload();
        Future.delayed(const Duration(milliseconds: 3500), () async {
          context.read<HomeBloc>().add(RefreshTokensEvent());
          context.read<HomeBloc>().add(ReindexIndexerEvent());
          await injector<AWSService>()
              .storeEventWithDeviceData("device_foreground");
        });
        break;
      case FGBGType.background:
        injector<AWSService>().storeEventWithDeviceData("device_background");
        injector<TokensService>().disposeIsolate();
        _deeplinkSubscription?.pause();
        break;
    }
  }

  void _shouldShowNotifications(OSNotificationReceivedEvent event) {
    log.info("Receive notification: ${event.notification}");
    showNotifications(event.notification);
    event.complete(null);
  }
}
