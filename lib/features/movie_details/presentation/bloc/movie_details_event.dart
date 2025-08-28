import 'package:equatable/equatable.dart';

abstract class MovieDetailsEvent extends Equatable {
  const MovieDetailsEvent();

  @override
  List<Object> get props => [];
}

class FetchMovieDetails extends MovieDetailsEvent {
  final String movieId;

  const FetchMovieDetails(this.movieId);

  @override
  List<Object> get props => [movieId];
}
