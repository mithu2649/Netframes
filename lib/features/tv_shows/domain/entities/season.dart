import 'package:equatable/equatable.dart';
import 'package:netframes/features/tv_shows/domain/entities/episode.dart';

class Season extends Equatable {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final int seasonNumber;
  final int episodeCount;
  final List<Episode>? episodes;

  const Season({
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    required this.seasonNumber,
    required this.episodeCount,
    this.episodes,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        overview,
        posterPath,
        seasonNumber,
        episodeCount,
        episodes,
      ];
}
