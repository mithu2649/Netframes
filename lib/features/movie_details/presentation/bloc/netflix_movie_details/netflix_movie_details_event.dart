
import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';

abstract class NetflixMovieDetailsEvent extends Equatable {
  const NetflixMovieDetailsEvent();

  @override
  List<Object> get props => [];
}

class FetchNetflixMovieDetails extends NetflixMovieDetailsEvent {
  final Movie movie;

  const FetchNetflixMovieDetails(this.movie);

  @override
  List<Object> get props => [movie];
}
