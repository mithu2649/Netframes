import 'package:equatable/equatable.dart';

abstract class TvShowDetailsEvent extends Equatable {
  const TvShowDetailsEvent();

  @override
  List<Object> get props => [];
}

class FetchTvShowDetails extends TvShowDetailsEvent {
  final int tvShowId;

  const FetchTvShowDetails(this.tvShowId);

  @override
  List<Object> get props => [tvShowId];
}

class SelectSeason extends TvShowDetailsEvent {
  final int seasonNumber;

  const SelectSeason(this.seasonNumber);

  @override
  List<Object> get props => [seasonNumber];
}
