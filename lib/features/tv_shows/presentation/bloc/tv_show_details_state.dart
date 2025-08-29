import 'package:equatable/equatable.dart';
import 'package:netframes/features/tv_shows/domain/entities/episode.dart';
import 'package:netframes/features/tv_shows/domain/entities/tv_show.dart';

abstract class TvShowDetailsState extends Equatable {
  const TvShowDetailsState();

  @override
  List<Object?> get props => [];
}

class TvShowDetailsInitial extends TvShowDetailsState {}

class TvShowDetailsLoading extends TvShowDetailsState {}

class TvShowDetailsLoaded extends TvShowDetailsState {
  final TvShow tvShowDetails;
  final int? selectedSeasonNumber;
  final List<Episode>? episodes;

  const TvShowDetailsLoaded(
    this.tvShowDetails, {
    this.selectedSeasonNumber,
    this.episodes,
  });

  @override
  List<Object?> get props => [tvShowDetails, selectedSeasonNumber, episodes];
}

class TvShowDetailsLoadingSeason extends TvShowDetailsLoaded {
  const TvShowDetailsLoadingSeason(
    super.tvShowDetails,
    int selectedSeasonNumber,
  ) : super(selectedSeasonNumber: selectedSeasonNumber);

  @override
  List<Object?> get props => [tvShowDetails, selectedSeasonNumber];
}

class TvShowDetailsError extends TvShowDetailsState {
  final String message;

  const TvShowDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
