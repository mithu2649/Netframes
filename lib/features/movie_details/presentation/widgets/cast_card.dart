import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:netframes/features/movie_details/domain/entities/cast.dart';

class CastCard extends StatelessWidget {
  final Cast cast;

  const CastCard({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: CachedNetworkImageProvider(
              'https://image.tmdb.org/t/p/w200${cast.profilePath}',
            ),
            onBackgroundImageError: (exception, stackTrace) => const Icon(Icons.person),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              cast.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}