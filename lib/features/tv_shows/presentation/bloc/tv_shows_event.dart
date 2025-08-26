import 'package:equatable/equatable.dart';

abstract class TvShowsEvent extends Equatable {
  const TvShowsEvent();

  @override
  List<Object> get props => [];
}

class FetchTvShowsData extends TvShowsEvent {}
