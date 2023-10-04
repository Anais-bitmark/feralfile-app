import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/iterable_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/play_control.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/canvas_device_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';

enum CollectionType { manual, medium, artist }

class ViewPlaylistScreenPayload {
  final PlayListModel? playListModel;
  final CollectionType collectionType;
  final Widget? titleIcon;

  const ViewPlaylistScreenPayload(
      {this.playListModel,
      this.titleIcon,
      this.collectionType = CollectionType.manual});
}

class ViewPlaylistScreen extends StatefulWidget {
  final ViewPlaylistScreenPayload payload;

  const ViewPlaylistScreen({Key? key, required this.payload}) : super(key: key);

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen> {
  final bloc = injector.get<ViewPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>(param1: false);
  final _playlistService = injector<PlaylistService>();
  List<ArtworkIdentity> accountIdentities = [];
  List<CompactedAssetToken> tokensPlaylist = [];
  bool isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();
  final _focusNode = FocusNode();
  late CanvasDeviceBloc _canvasDeviceBloc;
  late SortOrder _sortOrder;
  late bool editable;

  List<SortOrder> _getAvailableOrders() {
    if (widget.payload.collectionType == CollectionType.artist) {
      return [
        SortOrder.title,
        SortOrder.newest,
      ];
    }
    if (widget.payload.collectionType == CollectionType.medium) {
      return [
        SortOrder.title,
        SortOrder.artist,
        SortOrder.newest,
      ];
    }
    return [
      SortOrder.manual,
      SortOrder.title,
      SortOrder.artist,
    ];
  }

  @override
  void initState() {
    _sortOrder = _getAvailableOrders().first;
    editable = widget.payload.collectionType == CollectionType.manual;
    super.initState();

    nftBloc.add(RefreshNftCollectionByIDs(
      ids: isDemo ? [] : widget.payload.playListModel?.tokenIDs,
      debugTokenIds: isDemo ? widget.payload.playListModel?.tokenIDs : [],
    ));

    _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
    _fetchDevice();
    bloc.add(GetPlayList(playListModel: widget.payload.playListModel));
  }

  Future<void> deletePlayList() async {
    final listPlaylist = await _playlistService.getPlayList();
    listPlaylist.removeWhere(
        (element) => element.id == widget.payload.playListModel?.id);
    _playlistService.setPlayList(listPlaylist, override: true);
    injector.get<SettingsDataService>().backup();
    injector<NavigationService>().popUntilHomeOrSettings();
  }

  List<CompactedAssetToken> setupPlayList({
    required List<CompactedAssetToken> tokens,
    List<String>? selectedTokens,
  }) {
    tokens = tokens.filterAssetToken();

    final temp = selectedTokens
            ?.map((e) =>
                tokens.where((element) => element.id == e).firstOrDefault())
            .toList() ??
        [];

    temp.removeWhere((element) => element == null);

    tokensPlaylist = List.from(temp)
      ..sort((a, b) {
        final x = _sortOrder.compare(a, b);
        return x;
      });

    accountIdentities = tokensPlaylist
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => ArtworkIdentity(element.id, element.owner))
        .toList();
    return tokensPlaylist;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelectOrder(SortOrder order) {
    setState(() {
      _sortOrder = order;
    });
  }

  Future<void> _onOrderTap(BuildContext context, List<SortOrder> orders) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.isMobile
              ? double.infinity
              : Constants.maxWidthModalTablet),
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            color: theme.auSuperTeal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 17, 15, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3, left: 37),
                          child: Text(
                            "sort_by".tr(),
                            style: theme.textTheme.ppMori400Black14,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(maxHeight: 18, maxWidth: 18),
                          icon: const Icon(
                            AuIcon.close,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                addOnlyDivider(color: AppColor.white),
                const SizedBox(height: 20),
                ListView.separated(
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _onSelectOrder(order);
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              AuRadio<SortOrder>(
                                onTap: (order) {
                                  Navigator.pop(context);
                                  _onSelectOrder(order);
                                },
                                value: order,
                                groupValue: _sortOrder,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  order.text,
                                  style: theme.textTheme.ppMori400Black14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: orders.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 15);
                  },
                ),
                const SizedBox(height: 65),
              ],
            ),
          );
        });
      },
    );
  }

  void _onMoreTap(BuildContext context, PlayListModel? playList) {
    final theme = Theme.of(context);
    UIHelper.showDrawerAction(
      context,
      options: [
        OptionItem(
          title: 'edit_collection'.tr(),
          icon: SvgPicture.asset(
            'assets/images/rename_icon.svg',
            width: 24,
          ),
          onTap: () {
            Navigator.pop(context);
            if (isDemo) return;
            Navigator.pushNamed(
              context,
              AppRouter.editPlayListPage,
              arguments: playList,
            );
          },
        ),
        OptionItem(
          title: 'delete_collection'.tr(),
          icon: SvgPicture.asset(
            'assets/images/delete_icon.svg',
            width: 24,
          ),
          onTap: () {
            Navigator.pop(context);
            UIHelper.showMessageActionNew(
              context,
              tr('delete_playlist'),
              '',
              descriptionWidget: Text(
                "delete_playlist_desc".tr(),
                style: theme.textTheme.ppMori400White14,
              ),
              actionButton: "remove_collection".tr(),
              onAction: deletePlayList,
            );
          },
        ),
        OptionItem(),
      ],
    );
  }

  void _onShufferTap(PlayListModel? playList) {
    final playControlModel = playList?.playControlModel ?? PlayControlModel();
    playControlModel.isShuffle = !playControlModel.isShuffle;
    bloc.add(UpdatePlayControl(playControlModel: playControlModel));
  }

  void _onTimerTap(PlayListModel? playList) {
    final playControlModel = playList?.playControlModel ?? PlayControlModel();
    bloc.add(
        UpdatePlayControl(playControlModel: playControlModel.onChangeTime()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ViewPlaylistBloc, ViewPlaylistState>(
      bloc: bloc,
      listener: (context, state) {},
      builder: (context, state) {
        final playList = state.playListModel;
        if (playList == null) return const SizedBox();
        return Scaffold(
          appBar: AppBar(
            systemOverlayStyle: systemUiOverlayLightStyle(AppColor.white),
            elevation: 0,
            shadowColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(
                children: [
                  SizedBox(
                    width: 15,
                  ),
                  Icon(
                    AuIcon.chevron,
                    size: 18,
                  ),
                ],
              ),
            ),
            titleSpacing: 0,
            backgroundColor: theme.colorScheme.background,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.payload.titleIcon != null)
                    SizedBox(
                        width: 22,
                        height: 22,
                        child: widget.payload.titleIcon!),
                  const SizedBox(width: 10),
                  Text(
                    playList.getName(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.ppMori400Black16,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  _onOrderTap(context, _getAvailableOrders());
                },
                child: SvgPicture.asset(
                  "assets/images/sort.svg",
                  colorFilter:
                      ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
                  width: 22,
                  height: 22,
                ),
              ),
              if (editable) ...[
                const SizedBox(width: 15),
                GestureDetector(
                    onTap: () => _onMoreTap(context, playList),
                    child: SvgPicture.asset(
                      'assets/images/more_circle.svg',
                      colorFilter:
                          ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
                      width: 24,
                    )),
              ],
              const SizedBox(width: 15),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.25),
              child:
                  addOnlyDivider(color: AppColor.auQuickSilver, border: 0.25),
            ),
          ),
          body: BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
            bloc: nftBloc,
            builder: (context, nftState) {
              return NftCollectionGrid(
                state: nftState.state,
                tokens: setupPlayList(
                  tokens: nftState.tokens.items,
                  selectedTokens: playList.tokenIDs,
                ),
                customGalleryViewBuilder: (context, tokens) => _assetsWidget(
                  context,
                  tokens,
                  accountIdentities: accountIdentities,
                  playControlModel:
                      playList.playControlModel ?? PlayControlModel(),
                  onShuffleTap: () => _onShufferTap(playList),
                  onTimerTap: () => _onTimerTap(playList),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void moveToAddNftToCollection(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRouter.addToCollectionPage,
      arguments: widget.payload.playListModel,
    ).then((value) {
      if (value != null && value is PlayListModel) {
        bloc.add(SavePlaylist(name: value.name));
        nftBloc.add(RefreshNftCollectionByIDs(
          ids: isDemo ? [] : value.tokenIDs,
          debugTokenIds: isDemo ? value.tokenIDs : [],
        ));
      }
    });
  }

  Widget _assetsWidget(
    BuildContext context,
    List<CompactedAssetToken> tokens, {
    required List<ArtworkIdentity> accountIdentities,
    Function()? onShuffleTap,
    Function()? onTimerTap,
    required PlayControlModel playControlModel,
  }) {
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    final estimatedCellWidth = MediaQuery.of(context).size.width / cellPerRow -
        cellSpacing * (cellPerRow - 1);
    final cachedImageSize = (estimatedCellWidth * 3).ceil();
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cellPerRow,
                    crossAxisSpacing: cellSpacing,
                    mainAxisSpacing: cellSpacing,
                  ),
                  itemBuilder: (context, index) {
                    final asset = tokens[index];
                    return GestureDetector(
                      child: asset.pending == true && !asset.hasMetadata
                          ? PendingTokenWidget(
                              thumbnail: asset.galleryThumbnailURL,
                              tokenId: asset.tokenId,
                            )
                          : tokenGalleryThumbnailWidget(
                              context,
                              asset,
                              cachedImageSize,
                              usingThumbnailID: index > 50,
                              useHero: false,
                            ),
                      onTap: () {
                        if (asset.pending == true && !asset.hasMetadata) return;

                        final index = tokens
                            .where((e) => e.pending != true || e.hasMetadata)
                            .toList()
                            .indexOf(asset);
                        final payload = asset.isPostcard
                            ? PostcardDetailPagePayload(
                                accountIdentities,
                                index,
                                playControl: playControlModel,
                              )
                            : ArtworkDetailPayload(
                                accountIdentities,
                                index,
                                playControl: playControlModel,
                              );
                        final pageName = asset.isPostcard
                            ? AppRouter.claimedPostcardDetailsPage
                            : AppRouter.artworkDetailsPage;

                        Navigator.of(context)
                            .pushNamed(pageName, arguments: payload);
                      },
                    );
                  },
                  itemCount: tokens.length),
            ),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (editable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Center(
                    child: AddButton(
                      icon: SvgPicture.asset(
                        "assets/images/Add.svg",
                        width: 21,
                        height: 21,
                      ),
                      onTap: () {
                        moveToAddNftToCollection(context);
                      },
                    ),
                  ),
                ),
              // AddButton(
              //   onTap: () => Navigator.pushNamed(
              //     context,
              //     AppRouter.createPlayListPage,
              //     arguments: widget.payload.playListModel,
              //   ).then((value) {
              //     if (value != null && value is PlayListModel) {
              //       bloc.add(SavePlaylist(name: value.name));
              //       nftBloc.add(RefreshNftCollectionByIDs(
              //         ids: isDemo ? [] : value.tokenIDs,
              //         debugTokenIds: isDemo ? value.tokenIDs : [],
              //       ));
              //     }
              //   }),
              //   icon: null,
              // ),
              const SizedBox(height: 22),
              BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
                  bloc: _canvasDeviceBloc,
                  builder: (context, state) {
                    return PlaylistControl(
                      playControl: playControlModel,
                      showPlay: accountIdentities.isNotEmpty,
                      onShuffleTap: onShuffleTap,
                      onTimerTap: onTimerTap,
                      isCasting: state.isCasting,
                      onPlayTap: () {
                        final payload = ArtworkDetailPayload(
                          accountIdentities,
                          0,
                          playControl: playControlModel,
                        );
                        Navigator.of(context).pushNamed(
                          AppRouter.artworkPreviewPage,
                          arguments: payload,
                        );
                      },
                      onCastTap: () async {
                        final playlist = widget.payload.playListModel;
                        if (playlist?.tokenIDs == null ||
                            playlist!.tokenIDs!.isEmpty) {
                          log.info("Cast collection failed: playlist empty");
                          return;
                        }
                        playlist.playControlModel = playControlModel;
                        await _openCanvasDeviceDialog(context, playlist);
                        _fetchDevice();
                      },
                    );
                  })
            ],
          ),
        )
      ],
    );
  }

  Future<void> _fetchDevice() async {
    _canvasDeviceBloc.add(CanvasDeviceGetDevicesEvent(
        widget.payload.playListModel?.id ?? "",
        syncAll: false));
  }

  Future<void> _openCanvasDeviceDialog(
      BuildContext context, PlayListModel playlist) async {
    await UIHelper.showFlexibleDialog(
      context,
      BlocProvider.value(
        value: _canvasDeviceBloc,
        child: CanvasDeviceView(
          sceneId: widget.payload.playListModel?.id ?? "",
          isCollection: true,
          playlist: playlist,
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      isDismissible: true,
    );
  }
}

enum SortOrder {
  title,
  artist,
  newest,
  manual;

  String get text {
    switch (this) {
      case SortOrder.title:
        return tr('sort_by_title');
      case SortOrder.artist:
        return tr('sort_by_artist');
      case SortOrder.newest:
        return tr('sort_by_newest');
      case SortOrder.manual:
        return tr('sort_by_manual');
    }
  }

  int compare(CompactedAssetToken a, CompactedAssetToken b) {
    switch (this) {
      case SortOrder.title:
        return a.title?.compareTo(b.title ?? "") ?? 1;
      case SortOrder.artist:
        return a.artistID?.compareTo(b.artistID ?? "") ?? 1;
      case SortOrder.newest:
        return b.lastActivityTime.compareTo(a.lastActivityTime);
      case SortOrder.manual:
        return 1;
    }
  }
}

class AddButton extends StatelessWidget {
  final Widget icon;
  final void Function() onTap;

  const AddButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: icon,
    );
  }
}
