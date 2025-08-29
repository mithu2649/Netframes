import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/home/data/providers/dramadrip_provider.dart';
import 'package:netframes/features/home/data/providers/jio_hotstar_provider.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/home/data/providers/prime_video_provider.dart';
import 'package:netframes/features/movie_details/presentation/bloc/streaming_movie_details/streaming_movie_details_event.dart';
import 'package:netframes/features/movie_details/presentation/bloc/streaming_movie_details/streaming_movie_details_state.dart';

class StreamingMovieDetailsBloc
    extends Bloc<StreamingMovieDetailsEvent, StreamingMovieDetailsState> {
  final NetflixMirrorProvider netflixMirrorProvider;
  final JioHotstarProvider jioHotstarProvider;
  final PrimeVideoProvider primeVideoProvider;
  final DramaDripProvider dramaDripProvider;

  StreamingMovieDetailsBloc({
    required this.netflixMirrorProvider,
    required this.jioHotstarProvider,
    required this.primeVideoProvider,
    required this.dramaDripProvider,
  }) : super(StreamingMovieDetailsLoading()) {
    on<FetchStreamingMovieDetails>((event, emit) async {
      if (kDebugMode) {
        print('--- FetchStreamingMovieDetails event received in Bloc ---');
      }
      print(
        'Fetching streaming movie details for: ${event.movie.title} (ID: ${event.movie.id})',
      );
      try {
        if (event.provider == 'Netflix') {
          final movieDetails = await netflixMirrorProvider.getMovieDetails(
            event.movie,
          );
          print('Successfully fetched Netflix movie details.');
          emit(StreamingMovieDetailsLoaded(movieDetails));
        } else if (event.provider == 'JioHotstar') {
          final movieDetails = await jioHotstarProvider.getMovieDetails(
            event.movie,
          );
          print('Successfully fetched JioHotstar movie details.');
          emit(StreamingMovieDetailsLoaded(movieDetails));
        } else if (event.provider == 'PrimeVideo') {
          final movieDetails = await primeVideoProvider.getMovieDetails(
            event.movie,
          );
          print('Successfully fetched PrimeVideo movie details.');
          emit(StreamingMovieDetailsLoaded(movieDetails));
        } else if (event.provider == 'DramaDrip') {
          final movieDetails = await dramaDripProvider.getMovieDetails(
            event.movie,
          );
          print('Successfully fetched DramaDrip movie details.');
          emit(StreamingMovieDetailsLoaded(movieDetails));
        }
      } catch (e) {
        print('Error fetching streaming movie details: $e');
        emit(StreamingMovieDetailsError(e.toString()));
      }
    });
  }
}
