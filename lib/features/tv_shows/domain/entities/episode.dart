import 'package:equatable/equatable.dart';

class Episode extends Equatable {
  final int id;
  final String name;
  final String overview;
  final String? stillPath;
  final int episodeNumber;
  final double voteAverage;

  const Episode({
    required this.id,
    required this.name,
    required this.overview,
    this.stillPath,
    required this.episodeNumber,
    required this.voteAverage,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        overview,
        stillPath,
        episodeNumber,
        voteAverage,
      ];
}
