import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/home/data/providers/dramadrip_provider.dart';
import 'package:netframes/features/home/data/providers/hianime_provider.dart';
import 'package:netframes/features/home/data/providers/jio_hotstar_provider.dart';
import 'package:netframes/features/home/data/providers/m_player_provider.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/home/data/providers/noxx_provider.dart';
import 'package:netframes/features/home/data/providers/prime_video_provider.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';
import 'package:netframes/features/movie_details/presentation/bloc/streaming_movie_details/streaming_movie_details_event.dart';
import 'package:netframes/features/movie_details/presentation/bloc/streaming_movie_details/streaming_movie_details_state.dart';

class StreamingMovieDetailsBloc
    extends Bloc<StreamingMovieDetailsEvent, StreamingMovieDetailsState> {
  final NetflixMirrorProvider netflixMirrorProvider;
  final JioHotstarProvider jioHotstarProvider;
  final PrimeVideoProvider primeVideoProvider;
  final DramaDripProvider dramaDripProvider;
  final MPlayerProvider mPlayerProvider;
  final NoxxProvider noxxProvider;
  final HiAnimeProvider hiAnimeProvider;

  StreamingMovieDetailsBloc({
    required this.netflixMirrorProvider,
    required this.jioHotstarProvider,
    required this.primeVideoProvider,
    required this.dramaDripProvider,
    required this.mPlayerProvider,
    required this.noxxProvider,
    required this.hiAnimeProvider,
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
        } else if (event.provider == 'MPlayer') {
          final movieDetails = await mPlayerProvider.getMovieDetails(
            event.movie,
          );
          print('Successfully fetched MPlayer movie details.');
          emit(StreamingMovieDetailsLoaded(movieDetails));
        } else if (event.provider == 'NOXX') {
          final movieDetails = await noxxProvider.getMovieDetails(
            event.movie,
          );
          print('Successfully fetched NOXX movie details.');
          emit(StreamingMovieDetailsLoaded(movieDetails));
        } else if (event.provider == 'HiAnime') {
          final movieDetails = await hiAnimeProvider.getMovieDetails(
            event.movie,
          );
          print('Successfully fetched HiAnime movie details.');
          emit(StreamingMovieDetailsLoaded(movieDetails));
        }
      } catch (e) {
        print('Error fetching streaming movie details: $e');
        emit(StreamingMovieDetailsError(e.toString()));
      }
    });

    on<LoadStreamingLinks>((event, emit) async {
      NetflixMovieDetails? details;
      if (state is StreamingMovieDetailsLoaded) {
        details = (state as StreamingMovieDetailsLoaded).movieDetails;
      } else if (state is StreamingLinksLoading) {
        details = (state as StreamingLinksLoading).movieDetails;
      } else if (state is StreamingLinksLoaded) {
        details = (state as StreamingLinksLoaded).movieDetails;
      }

      if (details != null) {
        emit(StreamingLinksLoading(
            event.episode?.id ?? event.movie.id, details));
        try {
          dynamic result;
          if (event.movie.provider == 'Netflix') {
            result = await netflixMirrorProvider.loadLink(
              event.movie,
              episode: event.episode,
            );
          } else if (event.movie.provider == 'JioHotstar') {
            result = await jioHotstarProvider.loadLink(
              event.movie,
              episode: event.episode,
            );
          } else if (event.movie.provider == 'PrimeVideo') {
            result = await primeVideoProvider.loadLink(
              event.movie,
              episode: event.episode,
            );
          } else if (event.movie.provider == 'DramaDrip') {
            result = await dramaDripProvider.loadLink(
              event.movie,
              episode: event.episode,
            );
          } else if (event.movie.provider == 'MPlayer') {
            result = await mPlayerProvider.loadLink(
              event.movie,
              episode: event.episode,
            );
          } else if (event.movie.provider == 'NOXX') {
            result = await noxxProvider.loadLink(
              event.movie,
              episode: event.episode,
            );
          } else if (event.movie.provider == 'HiAnime') {
            result = await hiAnimeProvider.loadLink(
              event.movie,
              episode: event.episode,
            );
          }
          if (result != null && result['streams'] != null) {
            final streams = result['streams'] as List<VideoStream>;
            emit(StreamingLinksLoaded(streams, details));
          } else {
            emit(const StreamingLinksError('No streams found'));
          }
        } catch (e) {
          emit(StreamingLinksError('Error loading streams: $e'));
        }
      }
    });
  }
}
