import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/core/services/watchlist_service.dart';
import 'package:netframes/features/library/presentation/bloc/library_event.dart';
import 'package:netframes/features/library/presentation/bloc/library_state.dart';
import 'package:netframes/features/search/domain/entities/search_result.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final WatchlistService watchlistService;
  final MovieApiService movieApiService;

  LibraryBloc({required this.watchlistService, required this.movieApiService}) : super(LibraryLoading()) {
    on<FetchWatchlist>((event, emit) async {
      emit(LibraryLoading());
      try {
        final watchlistIds = await watchlistService.getWatchlist();
        final List<SearchResult> watchlist = [];
        for (final id in watchlistIds) {
          try {
            final movieDetails = await movieApiService.getMovieDetails(id);
            watchlist.add(MovieSearchResult(Movie(
              id: movieDetails.id,
              title: movieDetails.title,
              overview: movieDetails.overview,
              posterPath: movieDetails.posterPath,
              backdropPath: movieDetails.backdropPath ?? '',
              voteAverage: movieDetails.voteAverage,
            )));
          } catch (e) {
            try {
              final tvShowDetails = await movieApiService.getTvShowDetails(int.parse(id));
              watchlist.add(TvShowSearchResult(tvShowDetails));
            } catch (e) {
              print('Error fetching details for ID $id: $e');
            }
          }
        }
        emit(LibraryLoaded(watchlist));
      } catch (e) {
        emit(LibraryError(e.toString()));
      }
    });
  }
}
