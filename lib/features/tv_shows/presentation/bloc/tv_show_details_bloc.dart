import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_show_details_event.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_show_details_state.dart';

class TvShowDetailsBloc extends Bloc<TvShowDetailsEvent, TvShowDetailsState> {
  final MovieApiService movieApiService;

  TvShowDetailsBloc({required this.movieApiService})
    : super(TvShowDetailsInitial()) {
    on<FetchTvShowDetails>((event, emit) async {
      emit(TvShowDetailsLoading());
      try {
        final tvShowDetails = await movieApiService.getTvShowDetails(
          event.tvShowId,
        );
        // Automatically select the first season if available
        if (tvShowDetails.seasons != null &&
            tvShowDetails.seasons!.isNotEmpty) {
          final firstSeasonNumber = tvShowDetails.seasons!.first.seasonNumber;
          final seasonDetails = await movieApiService.getSeasonDetails(
            tvShowDetails.id,
            firstSeasonNumber,
          );
          emit(
            TvShowDetailsLoaded(
              tvShowDetails,
              selectedSeasonNumber: firstSeasonNumber,
              episodes: seasonDetails.episodes,
            ),
          );
        } else {
          emit(TvShowDetailsLoaded(tvShowDetails));
        }
      } catch (e) {
        emit(TvShowDetailsError(e.toString()));
      }
    });

    on<SelectSeason>((event, emit) async {
      if (state is TvShowDetailsLoaded) {
        final currentTvShowDetails =
            (state as TvShowDetailsLoaded).tvShowDetails;
        emit(
          TvShowDetailsLoadingSeason(currentTvShowDetails, event.seasonNumber),
        );
        try {
          final seasonDetails = await movieApiService.getSeasonDetails(
            currentTvShowDetails.id,
            event.seasonNumber,
          );
          emit(
            TvShowDetailsLoaded(
              currentTvShowDetails,
              selectedSeasonNumber: event.seasonNumber,
              episodes: seasonDetails.episodes,
            ),
          );
        } catch (e) {
          emit(TvShowDetailsError(e.toString()));
        }
      }
    });
  }
}
