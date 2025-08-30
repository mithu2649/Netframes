// import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:netframes/core/widgets/shimmer_loading.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/movie_details/presentation/pages/streaming_movie_details_page.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final int? index;
  final String categoryTitle;

  const MovieCard({
    super.key,
    required this.movie,
    this.index,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        movie.provider == 'Netflix' ||
            movie.provider == 'JioHotstar' ||
            movie.provider == 'PrimeVideo' ||
            movie.provider == 'DramaDrip' ||
            movie.provider == 'MPlayer'
        ? movie.posterPath
        : 'https://image.tmdb.org/t/p/w500${movie.posterPath}';

    final httpHeaders =
        movie.provider == 'Netflix' ||
            movie.provider == 'JioHotstar' ||
            movie.provider == 'PrimeVideo' ||
            movie.provider == 'DramaDrip'
        ? {'Referer': 'https://dramadrip.com/'}
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreamingMovieDetailsPage(movie: movie),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Hero(
          tag:
              '${categoryTitle}_${movie.posterPath}_${movie.id}_${index ?? ''}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                httpHeaders: httpHeaders,
                fit: BoxFit.cover,
                placeholder: (context, url) => AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ShimmerLoading(width: 190, height: 285),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
