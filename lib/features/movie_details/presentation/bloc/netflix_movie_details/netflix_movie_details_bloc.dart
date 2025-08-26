
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/movie_details/presentation/bloc/netflix_movie_details/netflix_movie_details_event.dart';
import 'package:netframes/features/movie_details/presentation/bloc/netflix_movie_details/netflix_movie_details_state.dart';

class NetflixMovieDetailsBloc
    extends Bloc<NetflixMovieDetailsEvent, NetflixMovieDetailsState> {
  final NetflixMirrorProvider netflixMirrorProvider;

  NetflixMovieDetailsBloc({required this.netflixMirrorProvider})
      : super(NetflixMovieDetailsLoading()) {
    on<FetchNetflixMovieDetails>((event, emit) async {
      if (kDebugMode) {
        print('--- FetchNetflixMovieDetails event received in Bloc ---');
      }
      print('Fetching Netflix movie details for: ${event.movie.title} (ID: ${event.movie.id})');
      try {
        final movieDetails = await netflixMirrorProvider.getMovieDetails(event.movie);
        print('Successfully fetched Netflix movie details.');
        emit(NetflixMovieDetailsLoaded(movieDetails));
      } catch (e) {
        print('Error fetching Netflix movie details: $e');
        emit(NetflixMovieDetailsError(e.toString()));
      }
    });
  }
}
