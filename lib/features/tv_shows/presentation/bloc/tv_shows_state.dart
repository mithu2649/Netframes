import 'package:equatable/equatable.dart';
import 'package:netframes/features/tv_shows/domain/entities/tv_show.dart';

abstract class TvShowsState extends Equatable {
  const TvShowsState();

  @override
  List<Object> get props => [];
}

class TvShowsLoading extends TvShowsState {}

class TvShowsLoaded extends TvShowsState {
  final List<TvShow> popularTvShows;
  final List<TvShow> topRatedTvShows;

  const TvShowsLoaded({
    required this.popularTvShows,
    required this.topRatedTvShows,
  });

  @override
  List<Object> get props => [popularTvShows, topRatedTvShows];
}

class TvShowsError extends TvShowsState {
  final String message;

  const TvShowsError(this.message);

  @override
  List<Object> get props => [message];
}
