import 'package:equatable/equatable.dart';
import 'package:netframes/features/movie_details/domain/entities/cast.dart';

class MovieDetails extends Equatable {
  final String id;
  final String title;
  final String overview;
  final String posterPath;
  final String? backdropPath;
  final double voteAverage;
  final List<Cast> cast;

  const MovieDetails({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.cast,
  });

  @override
  List<Object?> get props => [id, title, overview, posterPath, backdropPath, voteAverage, cast];
}
