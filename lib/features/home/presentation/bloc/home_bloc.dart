import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/features/home/data/providers/dramadrip_provider.dart';
import 'package:netframes/features/home/data/providers/jio_hotstar_provider.dart';
import 'package:netframes/features/home/data/providers/m_player_provider.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/home/data/providers/prime_video_provider.dart';
import 'package:netframes/features/home/presentation/bloc/home_event.dart';
import 'package:netframes/features/home/presentation/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final MovieApiService movieApiService;
  final NetflixMirrorProvider netflixMirrorProvider;
  final JioHotstarProvider jioHotstarProvider;
  final PrimeVideoProvider primeVideoProvider;
  final DramaDripProvider dramaDripProvider;
  final MPlayerProvider mPlayerProvider;

  HomeBloc({
    required this.movieApiService,
    required this.netflixMirrorProvider,
    required this.jioHotstarProvider,
    required this.primeVideoProvider,
    required this.dramaDripProvider,
    required this.mPlayerProvider,
  }) : super(HomeLoading()) {
    on<FetchHomeData>((event, emit) async {
      try {
        if (event.provider == 'Netflix') {
          final movies = await netflixMirrorProvider.getHomePage();
          emit(HomeLoaded(movies: movies, selectedProvider: 'Netflix'));
        } else if (event.provider == 'JioHotstar') {
          final movies = await jioHotstarProvider.getHomePage();
          emit(HomeLoaded(movies: movies, selectedProvider: 'JioHotstar'));
        } else if (event.provider == 'PrimeVideo') {
          final movies = await primeVideoProvider.getHomePage();
          emit(HomeLoaded(movies: movies, selectedProvider: 'PrimeVideo'));
        } else if (event.provider == 'DramaDrip') {
          final movies = await dramaDripProvider.getHomePage();
          emit(HomeLoaded(movies: movies, selectedProvider: 'DramaDrip'));
        } else if (event.provider == 'MPlayer') {
          final movies = await mPlayerProvider.getHomePage();
          emit(HomeLoaded(movies: movies, selectedProvider: 'MPlayer'));
        } else {
          final popularMovies = await movieApiService.getPopularMovies();
          final topRatedMovies = await movieApiService.getTopRatedMovies();
          final nowPlayingMovies = await movieApiService.getNowPlayingMovies();
          final upcomingMovies = await movieApiService.getUpcomingMovies();
          emit(
            HomeLoaded(
              movies: {
                'Popular': popularMovies,
                'Top Rated': topRatedMovies,
                'Now Playing': nowPlayingMovies,
                'Upcoming': upcomingMovies,
              },
              selectedProvider: 'TMDB',
            ),
          );
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
