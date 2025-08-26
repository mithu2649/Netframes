import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/home/presentation/bloc/home_event.dart';
import 'package:netframes/features/home/presentation/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final MovieApiService movieApiService;
  final NetflixMirrorProvider netflixMirrorProvider;

  HomeBloc({required this.movieApiService, required this.netflixMirrorProvider})
      : super(HomeLoading()) {
    on<FetchHomeData>((event, emit) async {
      try {
        if (event.provider == 'Netflix') {
          final movies = await netflixMirrorProvider.getHomePage();
          emit(HomeLoaded(movies: movies, selectedProvider: 'Netflix'));
        } else {
          final popularMovies = await movieApiService.getPopularMovies();
          final topRatedMovies = await movieApiService.getTopRatedMovies();
          final nowPlayingMovies = await movieApiService.getNowPlayingMovies();
          final upcomingMovies = await movieApiService.getUpcomingMovies();
          emit(HomeLoaded(
            movies: {
              'Popular': popularMovies,
              'Top Rated': topRatedMovies,
              'Now Playing': nowPlayingMovies,
              'Upcoming': upcomingMovies,
            },
            selectedProvider: 'TMDB',
          ));
        }
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });

    on<SelectProvider>((event, emit) {
      add(FetchHomeData(event.provider));
    });
  }
}
