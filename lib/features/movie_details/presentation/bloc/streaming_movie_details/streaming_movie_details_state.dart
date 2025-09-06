import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';

abstract class StreamingMovieDetailsState extends Equatable {
  const StreamingMovieDetailsState();

  @override
  List<Object> get props => [];
}

class StreamingMovieDetailsLoading extends StreamingMovieDetailsState {}

class StreamingMovieDetailsLoaded extends StreamingMovieDetailsState {
  final NetflixMovieDetails movieDetails;

  const StreamingMovieDetailsLoaded(this.movieDetails);

  @override
  List<Object> get props => [movieDetails];
}

class StreamingMovieDetailsError extends StreamingMovieDetailsState {
  final String message;

  const StreamingMovieDetailsError(this.message);

  @override
  List<Object> get props => [message];
}

class StreamingLinksLoading extends StreamingMovieDetailsState {
  final String id;
  final NetflixMovieDetails movieDetails;

  const StreamingLinksLoading(this.id, this.movieDetails);

  @override
  List<Object> get props => [id, movieDetails];
}

class StreamingLinksLoaded extends StreamingMovieDetailsState {
  final List<VideoStream> streams;
  final NetflixMovieDetails movieDetails;

  const StreamingLinksLoaded(this.streams, this.movieDetails);

  @override
  List<Object> get props => [streams, movieDetails];
}

class StreamingLinksError extends StreamingMovieDetailsState {
  final String message;

  const StreamingLinksError(this.message);

  @override
  List<Object> get props => [message];
}
