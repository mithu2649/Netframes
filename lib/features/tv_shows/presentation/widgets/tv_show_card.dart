import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:netframes/core/widgets/shimmer_loading.dart';
import 'package:netframes/features/tv_shows/domain/entities/tv_show.dart';
import 'package:netframes/features/tv_shows/presentation/pages/tv_show_details_page.dart';

class TvShowCard extends StatelessWidget {
  final TvShow tvShow;

  const TvShowCard({super.key, required this.tvShow});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TvShowDetailsPage(tvShow: tvShow)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: CachedNetworkImage(
            imageUrl: 'https://image.tmdb.org/t/p/w500${tvShow.posterPath}',
            placeholder: (context, url) => ShimmerLoading(width: 100, height: 150),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}
