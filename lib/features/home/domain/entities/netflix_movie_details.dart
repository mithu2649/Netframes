import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';

enum NetflixContentType { movie, tvShow }

class NetflixEpisode extends Equatable {
  final String id;
  final String title;
  final String season;
  final String episode;
  final String? thumbnail;
  final String? description;

  const NetflixEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episode,
    this.thumbnail,
    this.description,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    season,
    episode,
    thumbnail,
    description,
  ];
}

class NetflixSeason extends Equatable {
  final String season;
  final List<NetflixEpisode> episodes;

  const NetflixSeason({required this.season, required this.episodes});

  @override
  List<Object?> get props => [season, episodes];
}

class NetflixMovieDetails extends Equatable {
  final String title;
  final String plot;
  final String year;
  final String runtime;
  final List<String> cast;
  final List<String> genres;
  final NetflixContentType type;
  final List<NetflixSeason> seasons;
  final String? trailer;
  final List<Movie> recommendations;
  final String? backdropPath;

  const NetflixMovieDetails({
    this.title = '',
    this.plot = '',
    this.year = '',
    this.runtime = '',
    this.cast = const [],
    this.genres = const [],
    this.type = NetflixContentType.movie,
    this.seasons = const [],
    this.trailer,
    this.recommendations = const [],
    this.backdropPath,
  });

  @override
  List<Object?> get props => [
    title,
    plot,
    year,
    runtime,
    cast,
    genres,
    type,
    seasons,
    trailer,
    recommendations,
    backdropPath,
  ];
}
