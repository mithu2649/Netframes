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
import 'package:netframes/features/movie_details/presentation/widgets/shimmer_streaming_movie_details.dart';

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
            noxxProvider: homeBloc.noxxProvider,
            hiAnimeProvider: homeBloc.hiAnimeProvider,
          )..add(
            FetchStreamingMovieDetails(
              widget.movie,
              widget.movie.provider ?? '',
            ),
          ),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.movie.title)),
        body: BlocConsumer<StreamingMovieDetailsBloc, StreamingMovieDetailsState>(
          listener: (context, state) {
            if (state is StreamingLinksLoaded) {
              _playVideo(context, state.streams);
            } else if (state is StreamingLinksError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is StreamingMovieDetailsLoading) {
              return const ShimmerStreamingMovieDetails();
            } else if (state is StreamingMovieDetailsLoaded ||
                state is StreamingLinksLoading ||
                state is StreamingLinksLoaded) {
              final details = state is StreamingMovieDetailsLoaded
                  ? state.movieDetails
                  : state is StreamingLinksLoading
                      ? state.movieDetails
                      : (state as StreamingLinksLoaded).movieDetails;
              final backdropPath = details.backdropPath ?? widget.movie.backdropPath;
              final posterPath = details.posterPath ?? widget.movie.posterPath;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (backdropPath.isNotEmpty)
                      Image.network(
                        backdropPath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 250,
                      )
                    else if (posterPath.isNotEmpty)
                      Image.network(
                        posterPath,
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
                          Row(
                            children: [
                              if (details.rating != null)
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text('Rating: ${details.rating! / 10}'),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              if (details.year.isNotEmpty)
                                Text('Year: ${details.year}'),
                              if (details.runtime.isNotEmpty)
                                Text(' • ${details.runtime}'),
                            ],
                          ),
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
                                  key: ValueKey(details), // Add this line
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
                                    var episodeTitle = episode.title;
                                    episodeTitle = episodeTitle.replaceAll(RegExp(r'Now Playing', caseSensitive: false, multiLine: true), '').trim();
                                    episodeTitle = episodeTitle.replaceAll(RegExp(r'\s+'), ' ').trim();
                                    episodeTitle = episodeTitle.replaceAll(RegExp(r'^\s*:\s*'), '').trim();
                                   
                                    return ListTile(
                                      leading: SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: (state is StreamingLinksLoading && state.id == episode.id)
                                              ? const Center(child: CircularProgressIndicator())
                                              : Image.network(
                                                  episode.thumbnail?.isNotEmpty == true
                                                      ? episode.thumbnail!
                                                      : (details.backdropPath?.isNotEmpty == true
                                                          ? details.backdropPath!
                                                          : (details.posterPath?.isNotEmpty == true
                                                              ? details.posterPath!
                                                              : (widget.movie.backdropPath.isNotEmpty == true
                                                                  ? widget.movie.backdropPath
                                                                  : widget.movie.posterPath))),
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return const Center(child: CircularProgressIndicator());
                                                  },
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.error),
                                                ),
                                        ),
                                      title: Text(episodeTitle),
                                      subtitle: Text(
                                        'Season ${episode.season}, Episode ${episode.episode}',
                                      ),
                                      onTap: () {
                                        final movie = Movie(
                                          id: episode.id,
                                          title: episode.title,
                                          overview: details.plot,
                                          posterPath: widget.movie.posterPath,
                                          backdropPath:
                                              widget.movie.backdropPath,
                                          voteAverage: 0.0,
                                          provider: widget.movie.provider,
                                        );
                                        context
                                            .read<StreamingMovieDetailsBloc>()
                                            .add(
                                              LoadStreamingLinks(
                                                movie,
                                                episode: episode,
                                              ),
                                            );
                                      },
                                    );
                                  },
                                ),
                              ],
                            )
                          else
                            ElevatedButton(
                              onPressed: () {
                                final movieWithTitle = Movie(
                                  id: widget.movie.id,
                                  title: details.title,
                                  overview: details.plot,
                                  posterPath: widget.movie.posterPath,
                                  backdropPath: widget.movie.backdropPath,
                                  voteAverage: 0.0,
                                  provider: widget.movie.provider,
                                );
                                context
                                    .read<StreamingMovieDetailsBloc>()
                                    .add(LoadStreamingLinks(movieWithTitle));
                              },
                              child: (state is StreamingLinksLoading &&
                                      state.id == widget.movie.id)
                                  ? const CircularProgressIndicator()
                                  : const Text('Play'),
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
    );
  }

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
        if (!context.mounted) return;
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
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video playback error: ${e.message}')),
        );
        Navigator.pop(context); // Pop the video player page
      } catch (e) {
        if (!context.mounted) return;
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No streams found')));
    }
  }
}