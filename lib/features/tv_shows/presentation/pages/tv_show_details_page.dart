import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/core/services/watchlist_service.dart';
import 'package:netframes/core/widgets/shimmer_loading.dart'; // Added import
import 'package:netframes/features/common/pages/watch_now_page.dart'; // Added import
import 'package:netframes/features/tv_shows/domain/entities/tv_show.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_show_details_bloc.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_show_details_event.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_show_details_state.dart';

class TvShowDetailsPage extends StatefulWidget {
  final TvShow tvShow;

  const TvShowDetailsPage({super.key, required this.tvShow});

  @override
  State<TvShowDetailsPage> createState() => _TvShowDetailsPageState();
}

class _TvShowDetailsPageState extends State<TvShowDetailsPage> {
  final WatchlistService _watchlistService = WatchlistService();
  bool _isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    _checkIfInWatchlist();
  }

  void _checkIfInWatchlist() async {
    final isInWatchlist = await _watchlistService.isInWatchlist(widget.tvShow.id.toString());
    setState(() {
      _isInWatchlist = isInWatchlist;
    });
  }

  void _toggleWatchlist() async {
    if (_isInWatchlist) {
      await _watchlistService.removeFromWatchlist(widget.tvShow.id.toString());
    } else {
      await _watchlistService.addToWatchlist(widget.tvShow.id.toString());
    }
    _checkIfInWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TvShowDetailsBloc>(
      create: (context) => TvShowDetailsBloc(
        movieApiService: MovieApiService(),
      )..add(FetchTvShowDetails(widget.tvShow.id)),
      child: Scaffold(
        body: BlocBuilder<TvShowDetailsBloc, TvShowDetailsState>(
          builder: (context, state) {
            if (state is TvShowDetailsLoading || state is TvShowDetailsInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TvShowDetailsLoaded) {
              final tvShowDetails = state.tvShowDetails;
              final selectedSeasonNumber = state.selectedSeasonNumber;
              final episodes = state.episodes;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 250.0, // Changed from 200.0
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(tvShowDetails.name, style: const TextStyle(fontSize: 16.0)),
                      background: Hero(
                        tag: '${tvShowDetails.posterPath}_${tvShowDetails.id}',
                        child: CachedNetworkImage(
                          imageUrl: 'https://image.tmdb.org/t/p/w500${tvShowDetails.backdropPath ?? tvShowDetails.posterPath}', // Changed to backdropPath
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(_isInWatchlist ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: _toggleWatchlist,
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8.0),
                          Text(tvShowDetails.overview),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 4.0),
                              Text(tvShowDetails.voteAverage.toStringAsFixed(1)),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Implement download functionality
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download'),
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WatchNowPage(
                                          url: 'https://autoembed.pro/embed/tv/${tvShowDetails.id}/1/1',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Watch Now'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Text('Cast', style: Theme.of(context).textTheme.headlineSmall),
                          // For TV shows, we need to fetch cast separately if needed.
                          // For now, just a placeholder.
                          const Text('Cast information not available for TV shows yet.'),
                          const SizedBox(height: 16.0),
                          Text('Seasons', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8.0),
                          SizedBox(
                            height: 50, // Height for horizontal season chips
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: tvShowDetails.seasons?.length ?? 0,
                              itemBuilder: (context, index) {
                                final season = tvShowDetails.seasons![index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ChoiceChip(
                                    label: Text('Season ${season.seasonNumber}'),
                                    selected: season.seasonNumber == selectedSeasonNumber,
                                    onSelected: (selected) {
                                      if (selected) {
                                        context.read<TvShowDetailsBloc>().add(SelectSeason(season.seasonNumber));
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          if (episodes != null && episodes.isNotEmpty) ...[
                            Text('Episodes', style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8.0),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: episodes.length,
                              itemBuilder: (context, index) {
                                final episode = episodes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (episode.stillPath != null) ...[
                                          CachedNetworkImage(
                                            imageUrl: 'https://image.tmdb.org/t/p/w200${episode.stillPath}',
                                            width: 100,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => ShimmerLoading(width: 100, height: 60),
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                          ),
                                          const SizedBox(width: 8.0),
                                        ],
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('E${episode.episodeNumber}: ${episode.name}', style: Theme.of(context).textTheme.titleMedium),
                                              Text(episode.overview, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                                              // Add duration if available in API
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ] else if (selectedSeasonNumber != null) ...[
                            const Center(child: Text('No episodes found for this season.')),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (state is TvShowDetailsError) {
              return Center(child: Text(state.message));
            }
            return Container(); // Fallback for unhandled states
          },
        ),
      ),
    );
  }
}