import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/tv_shows/domain/entities/tv_show.dart';

abstract class SearchResult extends Equatable {
  const SearchResult();
}

class MovieSearchResult extends SearchResult {
  final Movie movie;

  const MovieSearchResult(this.movie);

  @override
  List<Object?> get props => [movie];
}

class TvShowSearchResult extends SearchResult {
  final TvShow tvShow;

  const TvShowSearchResult(this.tvShow);

  @override
  List<Object?> get props => [tvShow];
}
