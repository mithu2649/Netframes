import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/presentation/bloc/home_bloc.dart';
import 'package:netframes/features/movie_details/presentation/bloc/streaming_movie_details/streaming_movie_details_bloc.dart';
import 'package:netframes/features/movie_details/presentation/bloc/streaming_movie_details/streaming_movie_details_event.dart';
import 'package:netframes/features/movie_details/presentation/bloc/streaming_movie_details/streaming_movie_details_state.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';
import 'package:netframes/features/movie_details/presentation/pages/video_player_page.dart';

import '../../../home/domain/entities/movie.dart';

class StreamingMovieDetailsPage extends StatefulWidget {
  final Movie movie;

  const StreamingMovieDetailsPage({super.key, required this.movie});

  @override
  State<StreamingMovieDetailsPage> createState() =>
      _StreamingMovieDetailsPageState();
}

class _StreamingMovieDetailsPageState extends State<StreamingMovieDetailsPage> {
  int _selectedSeasonIndex = 0;

  Future<void> _playVideo(
    BuildContext context,
    List<VideoStream> streams,
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
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No streams found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();

    return BlocProvider(
      create: (context) =>
          StreamingMovieDetailsBloc(
            netflixMirrorProvider: homeBloc.netflixMirrorProvider,
            jioHotstarProvider: homeBloc.jioHotstarProvider,
            primeVideoProvider: homeBloc.primeVideoProvider,
            dramaDripProvider: homeBloc.dramaDripProvider,
            mPlayerProvider: homeBloc.mPlayerProvider,
          )..add(
            FetchStreamingMovieDetails(
              widget.movie,
              widget.movie.provider ?? '',
            ),
          ),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.movie.title)),
        body: BlocListener<StreamingMovieDetailsBloc, StreamingMovieDetailsState>(
          listener: (context, state) {
            if (state is StreamingMovieDetailsLoaded) {
              if (state.movieDetails.seasons.isNotEmpty) {
                setState(() {
                  _selectedSeasonIndex = state.movieDetails.seasons.length - 1;
                });
              }
            }
          },
          child: BlocBuilder<StreamingMovieDetailsBloc, StreamingMovieDetailsState>(
            builder: (context, state) {
              if (state is StreamingMovieDetailsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is StreamingMovieDetailsLoaded) {
                final details = state.movieDetails;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.movie.backdropPath != '' && widget.movie.backdropPath.isNotEmpty)
                        Image.network(
                          widget.movie.backdropPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 250,
                        )
                      else if (widget.movie.posterPath.isNotEmpty)
                        Image.network(
                          widget.movie.posterPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 250,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text('Year: ${details.year} • ${details.runtime}'),
                            const SizedBox(height: 8),
                            Text('Plot: ${details.plot}'),
                            const SizedBox(height: 8),
                            if (details.cast.isNotEmpty)
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Cast: ',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    TextSpan(
                                      text: details.cast.join(', '),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (details.type == NetflixContentType.tvShow)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seasons',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: List<Widget>.generate(
                                        details.seasons.length,
                                        (int index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                            ),
                                            child: ChoiceChip(
                                              padding: const EdgeInsets.all(9.0),
                                              label: Text(
                                                'Season ${details.seasons[index].season}',
                                              ),
                                              selected:
                                                  _selectedSeasonIndex == index,
                                              onSelected: (bool selected) {
                                                if (selected) {
                                                  setState(() {
                                                    _selectedSeasonIndex = index;
                                                  });
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Episodes',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: details.seasons.isEmpty
                                        ? 0
                                        : details
                                            .seasons[_selectedSeasonIndex]
                                            .episodes
                                            .length,
                                    itemBuilder: (context, index) {
                                      final episode = details
                                          .seasons[_selectedSeasonIndex]
                                          .episodes[index];
                                      return ListTile(
                                        leading: SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: episode.thumbnail != null
                                              ? Image.network(
                                                  episode.thumbnail!,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (
                                                    BuildContext context,
                                                    Widget child,
                                                    ImageChunkEvent?
                                                        loadingProgress,
                                                  ) {
                                                    if (loadingProgress == null) {
                                                      return child;
                                                    }
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  },
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) =>
                                                      const Icon(Icons.error),
                                                )
                                              : const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                        ),
                                        title: Text(episode.title),
                                        subtitle: Text(
                                          'Season ${episode.season}, Episode ${episode.episode}',
                                        ),
                                        onTap: () async {
                                          try {
                                            final episodeMovie = Movie(
                                              id: episode.id,
                                              title: episode.title,
                                              overview: details.plot,
                                              posterPath: widget.movie.posterPath,
                                              backdropPath:
                                                  widget.movie.backdropPath,
                                              voteAverage: 0.0,
                                              provider: widget.movie.provider,
                                            );
                                            dynamic result;
                                            if (widget.movie.provider ==
                                                'Netflix') {
                                              result = await context
                                                  .read<HomeBloc>()
                                                  .netflixMirrorProvider
                                                  .loadLink(
                                                    episodeMovie,
                                                    episode: episode,
                                                  );
                                            } else if (widget.movie.provider ==
                                                'JioHotstar') {
                                              result = await context
                                                  .read<HomeBloc>()
                                                  .jioHotstarProvider
                                                  .loadLink(
                                                    episodeMovie,
                                                    episode: episode,
                                                  );
                                            } else if (widget.movie.provider ==
                                                'PrimeVideo') {
                                              result = await context
                                                  .read<HomeBloc>()
                                                  .primeVideoProvider
                                                  .loadLink(
                                                    episodeMovie,
                                                    episode: episode,
                                                  );
                                            } else if (widget.movie.provider ==
                                                'DramaDrip') {
                                              result = await context
                                                  .read<HomeBloc>()
                                                  .dramaDripProvider
                                                  .loadLink(
                                                    episodeMovie,
                                                    episode: episode,
                                                  );
                                            } else if (widget.movie.provider ==
                                                'MPlayer') {
                                              result = await context
                                                  .read<HomeBloc>()
                                                  .mPlayerProvider
                                                  .loadLink(
                                                    episodeMovie,
                                                    episode: episode,
                                                  );
                                            }
                                            if (result != null &&
                                                result['streams'] != null) {
                                              final streams =
                                                  result['streams']
                                                      as List<VideoStream>;
                                              _playVideo(context, streams);
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('No streams found'),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error loading streams: $e',
                                                ),
                                              ),
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
                                      id: widget.movie.id,
                                      title: details.title,
                                      overview: details.plot,
                                      posterPath: widget.movie.posterPath,
                                      backdropPath: widget.movie.backdropPath,
                                      voteAverage: 0.0,
                                      provider: widget.movie.provider,
                                    );
                                    dynamic result;
                                    if (widget.movie.provider == 'Netflix') {
                                      result = await context
                                          .read<HomeBloc>()
                                          .netflixMirrorProvider
                                          .loadLink(movieWithTitle);
                                    } else if (widget.movie.provider ==
                                        'JioHotstar') {
                                      result = await context
                                          .read<HomeBloc>()
                                          .jioHotstarProvider
                                          .loadLink(movieWithTitle);
                                    } else if (widget.movie.provider ==
                                        'PrimeVideo') {
                                      result = await context
                                          .read<HomeBloc>()
                                          .primeVideoProvider
                                          .loadLink(movieWithTitle);
                                    } else if (widget.movie.provider ==
                                        'DramaDrip') {
                                      final episode =
                                          details.seasons.first.episodes.first;
                                      result = await context
                                          .read<HomeBloc>()
                                          .dramaDripProvider
                                          .loadLink(
                                            movieWithTitle,
                                            episode: episode,
                                          );
                                    } else if (widget.movie.provider == 'MPlayer') {
                                      result = await context
                                          .read<HomeBloc>()
                                          .mPlayerProvider
                                          .loadLink(movieWithTitle);
                                    }
                                    if (result != null &&
                                        result['streams'] != null) {
                                      final streams =
                                          result['streams'] as List<VideoStream>;
                                      _playVideo(context, streams);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('No streams found'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error loading streams: $e'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Play'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is StreamingMovieDetailsError) {
                return Center(child: Text(state.message));
              }
              return Container();
            },
          ),
        ),
      ),
    );
  }
}