
import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';

abstract class NetflixMovieDetailsState extends Equatable {
  const NetflixMovieDetailsState();

  @override
  List<Object> get props => [];
}

class NetflixMovieDetailsLoading extends NetflixMovieDetailsState {}

class NetflixMovieDetailsLoaded extends NetflixMovieDetailsState {
  final NetflixMovieDetails movieDetails;

  const NetflixMovieDetailsLoaded(this.movieDetails);

  @override
  List<Object> get props => [movieDetails];
}

class NetflixMovieDetailsError extends NetflixMovieDetailsState {
  final String message;

  const NetflixMovieDetailsError(this.message);

  @override
  List<Object> get props => [message];
}
