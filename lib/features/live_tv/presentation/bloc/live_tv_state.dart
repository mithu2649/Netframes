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
  final Channel currentChannel;
  final String currentChannelUrl;
  final Map<String, String> headers;
  final List<String> favoriteChannelIds;
  final bool isAutoStartupSequence;
  final bool isStreamLoading;

  const LiveTvLoaded({
    required this.allChannels,
    required this.filteredChannels,
    required this.categories,
    required this.selectedCategory,
    required this.searchQuery,
    required this.currentChannel,
    required this.currentChannelUrl,
    required this.headers,
    required this.favoriteChannelIds,
    this.isAutoStartupSequence = false,
    this.isStreamLoading = false,
  });

  @override
  List<Object> get props => [
        allChannels,
        filteredChannels,
        categories,
        selectedCategory,
        searchQuery,
        currentChannel,
        currentChannelUrl,
        headers,
        favoriteChannelIds,
        isAutoStartupSequence,
        isStreamLoading,
      ];

  LiveTvLoaded copyWith({
    List<Channel>? allChannels,
    List<Channel>? filteredChannels,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    Channel? currentChannel,
    String? currentChannelUrl,
    Map<String, String>? headers,
    List<String>? favoriteChannelIds,
    bool? isAutoStartupSequence,
    bool? isStreamLoading,
  }) {
    return LiveTvLoaded(
      allChannels: allChannels ?? this.allChannels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      currentChannel: currentChannel ?? this.currentChannel,
      currentChannelUrl: currentChannelUrl ?? this.currentChannelUrl,
      headers: headers ?? this.headers,
      favoriteChannelIds: favoriteChannelIds ?? this.favoriteChannelIds,
      isAutoStartupSequence:
          isAutoStartupSequence ?? this.isAutoStartupSequence,
      isStreamLoading: isStreamLoading ?? this.isStreamLoading,
    );
  }
}

class LiveTvError extends LiveTvState {
  final String message;

  const LiveTvError(this.message);

  @override
  List<Object> get props => [message];
}
