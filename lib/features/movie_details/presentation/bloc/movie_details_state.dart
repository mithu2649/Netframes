import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/movie_details/domain/entities/movie_details.dart';

abstract class MovieDetailsState extends Equatable {
  const MovieDetailsState();

  @override
  List<Object> get props => [];
}

class MovieDetailsLoading extends MovieDetailsState {}

class MovieDetailsLoaded extends MovieDetailsState {
  final MovieDetails movieDetails;
  final List<Movie> recommendedMovies;

  const MovieDetailsLoaded({required this.movieDetails, required this.recommendedMovies});

  @override
  List<Object> get props => [movieDetails, recommendedMovies];
}

class MovieDetailsError extends MovieDetailsState {
  final String message;

  const MovieDetailsError(this.message);

  @override
  List<Object> get props => [message];
}