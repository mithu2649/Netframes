import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_event.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_state.dart';

class TvShowsBloc extends Bloc<TvShowsEvent, TvShowsState> {
  final MovieApiService movieApiService;

  TvShowsBloc({required this.movieApiService}) : super(TvShowsLoading()) {
    on<FetchTvShowsData>((event, emit) async {
      try {
        final popularTvShows = await movieApiService.getPopularTvShows();
        final topRatedTvShows = await movieApiService.getTopRatedTvShows();
        emit(
          TvShowsLoaded(
            popularTvShows: popularTvShows,
            topRatedTvShows: topRatedTvShows,
          ),
        );
      } catch (e) {
        emit(TvShowsError(e.toString()));
      }
    });
  }
}
