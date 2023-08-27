import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class ListPlaylistsScreen extends StatefulWidget {
  final ValueNotifier<List<PlayListModel>?> playlists;

  const ListPlaylistsScreen({Key? key, required this.playlists})
      : super(key: key);

  @override
  State<ListPlaylistsScreen> createState() => _ListPlaylistsScreenState();
}

class _ListPlaylistsScreenState extends State<ListPlaylistsScreen>
    with RouteAware, WidgetsBindingObserver {
  final isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  _onUpdatePlaylists() async {
    if (isDemo || widget.playlists.value == null) return;
    await injector
        .get<PlaylistService>()
        .setPlayList(widget.playlists.value!, override: true);
    injector.get<SettingsDataService>().backup();
  }

  @override
  Widget build(BuildContext context) {
    const cellPerRow = 2;
    const cellSpacing = 16.0;
    return ValueListenableBuilder<List<PlayListModel>?>(
      valueListenable: widget.playlists,
      builder: (context, value, child) {
        return value == null
            ? const SizedBox.shrink()
            : ReorderableGridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = value.removeAt(oldIndex);
                    value.insert(newIndex, item);
                    _onUpdatePlaylists();
                  });
                },
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cellPerRow,
                  crossAxisSpacing: cellSpacing,
                  mainAxisSpacing: cellSpacing,
                ),
                itemBuilder: (context, index) {
                  return PlaylistItem(
                      key: ValueKey(value[index]),
                      playlist: value[index],
                      onSelected: () => Navigator.pushNamed(
                            context,
                            AppRouter.viewPlayListPage,
                            arguments: ViewPlaylistScreenPayload(
                                playListModel: value[index]),
                          ));
                },
                onDragStart: (index) {
                  Vibrate.feedback(FeedbackType.light);
                },
                itemCount: value.length,
              );
      },
    );
  }
}

class PlaylistItem extends StatefulWidget {
  final Function()? onSelected;
  final PlayListModel playlist;
  final bool onHold;

  const PlaylistItem({
    Key? key,
    this.onSelected,
    required this.playlist,
    this.onHold = false,
  }) : super(key: key);

  @override
  State<PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<PlaylistItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormater = NumberFormat("#,###");
    final thumbnailURL = widget.playlist.thumbnailURL;
    final name = widget.playlist.name;
    const width = 140.0;
    const height = 165.0;
    return GestureDetector(
      onTap: widget.onSelected,
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Container(
          width: height,
          height: width,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: widget.onHold ? theme.auSuperTeal : Colors.transparent,
              width: widget.onHold ? 2 : 0,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    (name?.isNotEmpty ?? false) ? name! : 'Untitled',
                    style: theme.textTheme.ppMori400Black14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    numberFormater
                        .format(widget.playlist.tokenIDs?.length ?? 0),
                    style: theme.textTheme.ppMori400Grey14,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Center(
                  child: thumbnailURL == null || thumbnailURL.isEmpty
                      ? Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: theme.disableColor,
                        )
                      : CachedNetworkImage(
                          imageUrl: thumbnailURL,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: theme.disableColor,
                            );
                          },
                          fadeInDuration: Duration.zero,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
