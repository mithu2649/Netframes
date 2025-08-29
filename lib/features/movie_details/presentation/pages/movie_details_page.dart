import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/core/services/watchlist_service.dart';
import 'package:netframes/features/common/pages/watch_now_page.dart'; // Added import
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/presentation/widgets/movie_list.dart';
import 'package:netframes/features/movie_details/presentation/bloc/movie_details_bloc.dart';
import 'package:netframes/features/movie_details/presentation/bloc/movie_details_event.dart';
import 'package:netframes/features/movie_details/presentation/bloc/movie_details_state.dart';
import 'package:netframes/features/movie_details/presentation/widgets/cast_list.dart';

class MovieDetailsPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailsPage({super.key, required this.movie});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final WatchlistService _watchlistService = WatchlistService();
  bool _isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    _checkIfInWatchlist();
  }

  void _checkIfInWatchlist() async {
    final isInWatchlist = await _watchlistService.isInWatchlist(
      widget.movie.id.toString(),
    );
    setState(() {
      _isInWatchlist = isInWatchlist;
    });
  }

  void _toggleWatchlist() async {
    if (_isInWatchlist) {
      await _watchlistService.removeFromWatchlist(widget.movie.id.toString());
    } else {
      await _watchlistService.addToWatchlist(widget.movie.id.toString());
    }
    _checkIfInWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MovieDetailsBloc(movieApiService: MovieApiService())
            ..add(FetchMovieDetails(widget.movie.id)),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250.0, // Changed from 200.0
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.movie.title,
                  style: const TextStyle(fontSize: 16.0),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: '${widget.movie.posterPath}_${widget.movie.id}',
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w500${widget.movie.backdropPath}',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.7),
                            Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                  ),
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
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8.0),
                    Text(widget.movie.overview),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4.0),
                        Text(widget.movie.voteAverage.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Changed from spaceEvenly
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
                        const SizedBox(width: 16.0), // Added spacing
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WatchNowPage(
                                    url:
                                        'https://autoembed.pro/embed/movie/${widget.movie.id}',
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
                    Text(
                      'Cast',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
                      builder: (context, state) {
                        if (state is MovieDetailsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is MovieDetailsLoaded) {
                          return CastList(cast: state.movieDetails.cast);
                        } else if (state is MovieDetailsError) {
                          return Text(state.message);
                        }
                        return Container(); // Or a loading indicator/error message
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Recommended',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
                      builder: (context, state) {
                        if (state is MovieDetailsLoaded) {
                          return MovieList(
                            title: '',
                            movies: state.recommendedMovies,
                          );
                        }
                        return Container(); // Or a loading indicator/error message
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
