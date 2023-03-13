//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_rendering/nft_rendering.dart';

class ArtworkPreviewWidget extends StatefulWidget {
  final ArtworkIdentity identity;
  final Function({int? time})? onLoaded;
  final Function({int? time})? onDispose;
  final bool isMute;
  final FocusNode? focusNode;

  const ArtworkPreviewWidget({
    Key? key,
    required this.identity,
    this.onLoaded,
    this.onDispose,
    this.isMute = false,
    this.focusNode,
  }) : super(key: key);

  @override
  State<ArtworkPreviewWidget> createState() => _ArtworkPreviewWidgetState();
}

class _ArtworkPreviewWidgetState extends State<ArtworkPreviewWidget>
    with WidgetsBindingObserver, RouteAware {
  final bloc = ArtworkPreviewDetailBloc(injector(), injector());

  INFTRenderingWidget? _renderingWidget;

  @override
  void initState() {
    bloc.add(ArtworkPreviewDetailGetAssetTokenEvent(widget.identity));
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
    return BlocBuilder<ArtworkPreviewDetailBloc, ArtworkPreviewDetailState>(
      bloc: bloc,
      builder: (context, state) {
        switch (state.runtimeType) {
          case ArtworkPreviewDetailLoadingState:
            return const CircularProgressIndicator();
          case ArtworkPreviewDetailLoadedState:
            final assetToken =
                (state as ArtworkPreviewDetailLoadedState).assetToken;
            if (assetToken != null) {
              return BlocProvider(
                create: (_) => RetryCubit(),
                child: BlocBuilder<RetryCubit, int>(
                  builder: (context, attempt) {
                    if (attempt > 0) {
                      _renderingWidget?.dispose();
                      _renderingWidget = null;
                    }
                    if (_renderingWidget == null ||
                        _renderingWidget!.previewURL !=
                            assetToken.getPreviewUrl()) {
                      _renderingWidget = buildRenderingWidget(
                        context,
                        assetToken,
                        attempt: attempt > 0 ? attempt : null,
                        onLoaded: widget.onLoaded,
                        onDispose: widget.onLoaded,
                        overriddenHtml: state.overriddenHtml,
                        isMute: widget.isMute,
                        focusNode: widget.focusNode,
                      );
                    }

                    switch (assetToken.getMimeType) {
                      case RenderingType.image:
                      case RenderingType.video:
                      case RenderingType.gif:
                      case RenderingType.pdf:
                      case RenderingType.svg:
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: _renderingWidget?.build(context),
                          ),
                        );
                      default:
                        return Center(
                          child: _renderingWidget?.build(context),
                        );
                    }
                  },
                ),
              );
            }
            return const SizedBox();
          default:
            return Container();
        }
      },
    );
  }
}
