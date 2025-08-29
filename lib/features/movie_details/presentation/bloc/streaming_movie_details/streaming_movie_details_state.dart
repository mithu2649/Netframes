import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';

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
