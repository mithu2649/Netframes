
import 'package:equatable/equatable.dart';

enum NetflixContentType { movie, tvShow }

class NetflixEpisode extends Equatable {
  final String id;
  final String title;
  final String season;
  final String episode;

  const NetflixEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episode,
  });

  @override
  List<Object?> get props => [id, title, season, episode];
}

class NetflixMovieDetails extends Equatable {
  final String title;
  final String plot;
  final String year;
  final String runtime;
  final List<String> cast;
  final List<String> genres;
  final NetflixContentType type;
  final List<NetflixEpisode> episodes;
  final String? h;
  final String? in_param;

  const NetflixMovieDetails({
    this.title = '',
    this.plot = '',
    this.year = '',
    this.runtime = '',
    this.cast = const [],
    this.genres = const [],
    this.type = NetflixContentType.movie,
    this.episodes = const [],
    this.h,
    this.in_param,
  });

  @override
  List<Object?> get props => [title, plot, year, runtime, cast, genres, type, episodes, h, in_param];
}
