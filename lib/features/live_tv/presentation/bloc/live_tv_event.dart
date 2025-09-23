import 'package:equatable/equatable.dart';

abstract class LiveTvEvent extends Equatable {
  const LiveTvEvent();

  @override
  List<Object> get props => [];
}

class FetchChannels extends LiveTvEvent {}

class LiveTvTabEntered extends LiveTvEvent {}

class ChannelSelected extends LiveTvEvent {
  final String channelUrl;

  const ChannelSelected(this.channelUrl);

  @override
  List<Object> get props => [channelUrl];
}

class ToggleFavorite extends LiveTvEvent {
  final String channelId;

  const ToggleFavorite(this.channelId);

  @override
  List<Object> get props => [channelId];
}

class CategorySelected extends LiveTvEvent {
  final String category;

  const CategorySelected(this.category);

  @override
  List<Object> get props => [category];
}

class SearchQueryChanged extends LiveTvEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class PlayerErrorOccurred extends LiveTvEvent {}

class PlaybackSuccessful extends LiveTvEvent {}
