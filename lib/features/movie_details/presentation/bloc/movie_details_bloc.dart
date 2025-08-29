import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/features/movie_details/presentation/bloc/movie_details_event.dart';
import 'package:netframes/features/movie_details/presentation/bloc/movie_details_state.dart';

class MovieDetailsBloc extends Bloc<MovieDetailsEvent, MovieDetailsState> {
  final MovieApiService movieApiService;

  MovieDetailsBloc({required this.movieApiService})
    : super(MovieDetailsLoading()) {
    on<FetchMovieDetails>((event, emit) async {
      try {
        final movieDetails = await movieApiService.getMovieDetails(
          event.movieId,
        );
        final recommendedMovies = await movieApiService.getRecommendedMovies(
          event.movieId,
        );
        emit(
          MovieDetailsLoaded(
            movieDetails: movieDetails,
            recommendedMovies: recommendedMovies,
          ),
        );
      } catch (e) {
        emit(MovieDetailsError(e.toString()));
      }
    });
  }
}
