import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:netframes/core/widgets/shimmer_loading.dart';
import 'package:netframes/features/movie_details/presentation/pages/movie_details_page.dart';
import 'package:netframes/features/search/domain/entities/search_result.dart';
import 'package:netframes/features/tv_shows/presentation/pages/tv_show_details_page.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const SearchResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result is MovieSearchResult) {
      final movie = (result as MovieSearchResult).movie;
      return Card(
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MovieDetailsPage(movie: movie)),
            );
          },
          leading: AspectRatio(
            aspectRatio: 2 / 3,
            child: CachedNetworkImage(
              imageUrl: 'https://image.tmdb.org/t/p/w300${movie.posterPath}',
              fit: BoxFit.cover,
              placeholder: (context, url) => const AspectRatio(
                aspectRatio: 2 / 3,
                child: ShimmerLoading(width: 100, height: 150),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.movie),
            ),
          ),
          title: Text(movie.title),
          subtitle: Text(movie.overview, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      );
    } else if (result is TvShowSearchResult) {
      final tvShow = (result as TvShowSearchResult).tvShow;
      return Card(
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TvShowDetailsPage(tvShow: tvShow)),
            );
          },
          leading: AspectRatio(
            aspectRatio: 2 / 3,
            child: CachedNetworkImage(
              imageUrl: 'https://image.tmdb.org/t/p/w300${tvShow.posterPath}',
              fit: BoxFit.cover,
              placeholder: (context, url) => const AspectRatio(
                aspectRatio: 2 / 3,
                child: ShimmerLoading(width: 100, height: 150),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.tv),
            ),
          ),
          title: Text(tvShow.name),
          subtitle: Text(tvShow.overview, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      );
    }
    return Container();
  }
}