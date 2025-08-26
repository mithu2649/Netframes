import 'package:equatable/equatable.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';

abstract class HomeState extends Equatable {
  final String selectedProvider;

  const HomeState({this.selectedProvider = 'Netflix'});

  @override
  List<Object> get props => [selectedProvider];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Map<String, List<Movie>> movies;

  const HomeLoaded({required this.movies, required super.selectedProvider});

  @override
  List<Object> get props => [movies, selectedProvider];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
