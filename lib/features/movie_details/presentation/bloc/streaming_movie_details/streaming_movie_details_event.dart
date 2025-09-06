import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';

abstract class StreamingMovieDetailsEvent extends Equatable {
  const StreamingMovieDetailsEvent();

  @override
  List<Object> get props => [];
}

class FetchStreamingMovieDetails extends StreamingMovieDetailsEvent {
  final Movie movie;
  final String provider;

  const FetchStreamingMovieDetails(this.movie, this.provider);

  @override
  List<Object> get props => [movie, provider];
}

class LoadStreamingLinks extends StreamingMovieDetailsEvent {
  final Movie movie;
  final NetflixEpisode? episode;

  const LoadStreamingLinks(this.movie, {this.episode});

  @override
  List<Object> get props => [movie];
}
