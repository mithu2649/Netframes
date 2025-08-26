import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/presentation/bloc/home_bloc.dart'; // Added import
import 'package:netframes/features/movie_details/presentation/bloc/netflix_movie_details/netflix_movie_details_bloc.dart';
import 'package:netframes/features/movie_details/presentation/bloc/netflix_movie_details/netflix_movie_details_event.dart';
import 'package:netframes/features/movie_details/presentation/bloc/netflix_movie_details/netflix_movie_details_state.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';
import 'package:netframes/features/movie_details/presentation/pages/video_player_page.dart';

import '../../../home/domain/entities/movie.dart';

class NetflixMovieDetailsPage extends StatelessWidget {
  final Movie movie;

  const NetflixMovieDetailsPage({super.key, required this.movie});

  Future<void> _playVideo(
    BuildContext context,
    List<VideoStream> streams,
    List<BetterPlayerSubtitlesSource> subtitles,
  ) async {
    if (streams.isNotEmpty) {
      final lowQualityStream = streams.firstWhere(
        (s) => s.quality.toLowerCase().contains('low'),
        orElse: () => streams.first,
      );
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              videoUrl: lowQualityStream.url,
              headers: lowQualityStream.headers,
              cookies: lowQualityStream.cookies,
              subtitles: subtitles,
              videoStreams: streams,
            ),
          ),
        );
      } on FormatException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video playback error: ${e.message}')),
        );
        Navigator.pop(context); // Pop the video player page
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
        Navigator.pop(context); // Pop the video player page
      }
      if (kDebugMode) {
        print('Playing video with URL: ${lowQualityStream.url}');
        print('VideoPlayerPage headers: ${lowQualityStream.headers}');
        print('VideoPlayerPage cookies: ${lowQualityStream.cookies}');
        print('VideoPlayerPage subtitles: $subtitles');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No streams found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final netflixMirrorProvider = context.read<HomeBloc>().netflixMirrorProvider;

    return BlocProvider(
      create: (context) => NetflixMovieDetailsBloc(
        netflixMirrorProvider: netflixMirrorProvider,
      )..add(FetchNetflixMovieDetails(movie)),
      child: Scaffold(
        appBar: AppBar(title: Text(movie.title)),
        body: BlocBuilder<NetflixMovieDetailsBloc, NetflixMovieDetailsState>(
          builder: (context, state) {
            if (state is NetflixMovieDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is NetflixMovieDetailsLoaded) {
              final details = state.movieDetails;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Year: ${details.year}'),
                      const SizedBox(height: 8),
                      Text('Runtime: ${details.runtime}'),
                      const SizedBox(height: 8),
                      Text('Plot: ${details.plot}'),
                      const SizedBox(height: 16),
                      if (details.type == NetflixContentType.tvShow)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Episodes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: details.episodes.length,
                              itemBuilder: (context, index) {
                                final episode = details.episodes[index];
                                return ListTile(
                                  title: Text(episode.title),
                                  subtitle: Text(
                                      'Season ${episode.season}, Episode ${episode.episode}'),
                                  onTap: () async {
                                    try {
                                      final episodeMovie = Movie(
                                        id: int.parse(episode.id),
                                        title: episode.title,
                                        overview: details.plot,
                                        posterPath: movie.posterPath,
                                        backdropPath: movie.backdropPath,
                                        voteAverage: 0.0,
                                        provider: 'Netflix',
                                      );
                                      final result = await context
                                          .read<HomeBloc>()
                                          .netflixMirrorProvider
                                          .loadLink(episodeMovie, episode: episode);
                                      final streams =
                                          result['streams'] as List<VideoStream>;
                                      final subtitles = result['subtitles']
                                          as List<BetterPlayerSubtitlesSource>;
                                      _playVideo(context, streams, subtitles);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Error loading streams: $e')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final movieWithTitle = Movie(
                                id: movie.id,
                                title: details.title,
                                overview: details.plot,
                                posterPath: movie.posterPath,
                                backdropPath: movie.backdropPath,
                                voteAverage: 0.0,
                                provider: 'Netflix',
                              );
                              final result = await context
                                  .read<HomeBloc>()
                                  .netflixMirrorProvider
                                  .loadLink(movieWithTitle);
                              final streams =
                                  result['streams'] as List<VideoStream>;
                              final subtitles = result['subtitles']
                                  as List<BetterPlayerSubtitlesSource>;
                              _playVideo(context, streams, subtitles);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error loading streams: $e')),
                              );
                            }
                          },
                          child: const Text('Play'),
                        ),
                    ],
                  ),
                ),
              );
            } else if (state is NetflixMovieDetailsError) {
              return Center(child: Text(state.message));
            }
            return Container();
          },
        ),
      ),
    );
  }
}
