import 'package:equatable/equatable.dart';
import 'package:netframes/features/tv_shows/domain/entities/season.dart';

class TvShow extends Equatable {
  final int id;
  final String name;
  final String overview;
  final String posterPath;
  final String? backdropPath;
  final double voteAverage;
  final List<Season>? seasons;

  const TvShow({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.seasons,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    overview,
    posterPath,
    backdropPath,
    voteAverage,
    seasons,
  ];
}
