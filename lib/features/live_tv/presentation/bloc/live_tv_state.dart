import 'package:equatable/equatable.dart';
import 'package:netframes/features/live_tv/data/models/channel_model.dart';

abstract class LiveTvState extends Equatable {
  const LiveTvState();

  @override
  List<Object> get props => [];
}

class LiveTvInitial extends LiveTvState {}

class LiveTvLoading extends LiveTvState {}

class LiveTvLoaded extends LiveTvState {
  final List<Channel> allChannels;
  final List<Channel> filteredChannels;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final String currentChannelUrl;
  final List<String> favoriteChannelIds;
  final bool isAutoStartupSequence;

  const LiveTvLoaded({
    required this.allChannels,
    required this.filteredChannels,
    required this.categories,
    required this.selectedCategory,
    required this.searchQuery,
    required this.currentChannelUrl,
    required this.favoriteChannelIds,
    this.isAutoStartupSequence = false,
  });

  @override
  List<Object> get props => [
        allChannels,
        filteredChannels,
        categories,
        selectedCategory,
        searchQuery,
        currentChannelUrl,
        favoriteChannelIds,
        isAutoStartupSequence,
      ];

  LiveTvLoaded copyWith({
    List<Channel>? allChannels,
    List<Channel>? filteredChannels,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    String? currentChannelUrl,
    List<String>? favoriteChannelIds,
    bool? isAutoStartupSequence,
  }) {
    return LiveTvLoaded(
      allChannels: allChannels ?? this.allChannels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      currentChannelUrl: currentChannelUrl ?? this.currentChannelUrl,
      favoriteChannelIds: favoriteChannelIds ?? this.favoriteChannelIds,
      isAutoStartupSequence: isAutoStartupSequence ?? this.isAutoStartupSequence,
    );
  }
}

class LiveTvError extends LiveTvState {
  final String message;

  const LiveTvError(this.message);

  @override
  List<Object> get props => [message];
}
