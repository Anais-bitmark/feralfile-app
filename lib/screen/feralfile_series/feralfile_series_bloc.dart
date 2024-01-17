import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';

class FeralFileSeriesBloc
    extends AuBloc<FeralFileSeriesEvent, FeralFileSeriesState> {
  final FeralFileService _feralFileService;

  FeralFileSeriesBloc(this._feralFileService) : super(FeralFileSeriesState()) {
    on<FeralFileSeriesGetSeriesEvent>((event, emit) async {
      final result = await Future.wait([
        _feralFileService.getExhibition(event.exhibitionId),
        _feralFileService.getSeriesArtworks(event.seriesId),
      ]);
      final exhibition = result[0] as Exhibition;
      final artworks = result[1] as List<Artwork>;
      final exhibitionDetail = ExhibitionDetail(
        exhibition: exhibition,
        artworks: artworks,
      );
      final tokenIds = artworks
          .map((e) => exhibitionDetail.getArtworkTokenId(e) ?? '')
          .toList();
      emit(state.copyWith(
        exhibitionDetail: exhibitionDetail,
        series: exhibition.series!
            .firstWhere((element) => element.id == event.seriesId),
        artworks: artworks,
        tokenIds: tokenIds,
      ));
    });
  }
}
