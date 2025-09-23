import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/live_tv/data/models/channel_model.dart';
import 'package:netframes/features/live_tv/data/repositories/iptv_repository.dart';
import 'package:netframes/features/live_tv/data/services/favorites_service.dart';
import 'package:netframes/features/live_tv/presentation/bloc/live_tv_event.dart';
import 'package:netframes/features/live_tv/presentation/bloc/live_tv_state.dart';

class LiveTvBloc extends Bloc<LiveTvEvent, LiveTvState> {
  final IptvRepository _iptvRepository;
  final FavoritesService _favoritesService;

  LiveTvBloc(this._iptvRepository, this._favoritesService)
      : super(LiveTvInitial()) {
    on<FetchChannels>((event, emit) async {
      emit(LiveTvLoading());
      try {
        final result = await _iptvRepository.fetchChannels();
        final channels = result['channels'] as List<Channel>;
        final categories = result['categories'] as List<String>;

        if (channels.isEmpty) {
          emit(const LiveTvError('No channels could be loaded.'));
          return;
        }

        final favoriteChannelIds = await _favoritesService.getFavorites();
        final initialChannelUrl = channels.first.url;

        emit(LiveTvLoaded(
          allChannels: channels,
          filteredChannels: channels,
          categories: categories,
          selectedCategory: 'All',
          searchQuery: '',
          currentChannelUrl: initialChannelUrl,
          favoriteChannelIds: favoriteChannelIds,
          isAutoStartupSequence: true,
        ));
      } catch (e) {
        emit(LiveTvError(e.toString()));
      }
    });

    on<LiveTvTabEntered>((event, emit) {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        // Restart the auto-sequence.
        emit(currentState.copyWith(
          currentChannelUrl: currentState.allChannels.first.url,
          isAutoStartupSequence: true,
        ));
      }
    });

    on<ChannelSelected>((event, emit) {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        emit(currentState.copyWith(
          currentChannelUrl: event.channelUrl,
          isAutoStartupSequence: false,
        ));
      }
    });

    on<PlaybackSuccessful>((event, emit) {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        if (currentState.isAutoStartupSequence) {
          emit(currentState.copyWith(isAutoStartupSequence: false));
        }
      }
    });

    on<PlayerErrorOccurred>((event, emit) {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        if (currentState.isAutoStartupSequence) {
          final allChannels = currentState.allChannels;
          final currentUrl = currentState.currentChannelUrl;

          final currentIndex = allChannels.indexWhere((c) => c.url == currentUrl);

          if (currentIndex != -1 && currentIndex < allChannels.length - 1) {
            final nextChannel = allChannels[currentIndex + 1];
            emit(currentState.copyWith(
              currentChannelUrl: nextChannel.url,
              isAutoStartupSequence: true,
            ));
          } else {
            emit(currentState.copyWith(isAutoStartupSequence: false));
          }
        }
      }
    });

    on<ToggleFavorite>((event, emit) async {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        final isFavorite = currentState.favoriteChannelIds.contains(event.channelId);

        if (isFavorite) {
          await _favoritesService.removeFavorite(event.channelId);
        } else {
          await _favoritesService.addFavorite(event.channelId);
        }

        final favoriteChannelIds = await _favoritesService.getFavorites();
        final channels = currentState.allChannels;
        channels.sort((a, b) {
          final aIsFavorite = favoriteChannelIds.contains(a.id);
          final bIsFavorite = favoriteChannelIds.contains(b.id);
          if (aIsFavorite && !bIsFavorite) {
            return -1;
          } else if (!aIsFavorite && bIsFavorite) {
            return 1;
          } else {
            return a.name.compareTo(b.name);
          }
        });

        final filteredChannels = _filterChannels(
          channels,
          currentState.selectedCategory,
          currentState.searchQuery,
        );

        emit(currentState.copyWith(
          allChannels: channels,
          filteredChannels: filteredChannels,
          favoriteChannelIds: favoriteChannelIds,
        ));
      }
    });

    on<CategorySelected>((event, emit) {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        final filteredChannels = _filterChannels(
          currentState.allChannels,
          event.category,
          currentState.searchQuery,
        );
        emit(currentState.copyWith(
          selectedCategory: event.category,
          filteredChannels: filteredChannels,
        ));
      }
    });

    on<SearchQueryChanged>((event, emit) {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        final filteredChannels = _filterChannels(
          currentState.allChannels,
          currentState.selectedCategory,
          event.query,
        );
        emit(currentState.copyWith(
          searchQuery: event.query,
          filteredChannels: filteredChannels,
        ));
      }
    });
  }

  List<Channel> _filterChannels(
    List<Channel> channels,
    String category,
    String query,
  ) {
    List<Channel> filtered = channels;

    if (category != 'All') {
      filtered = filtered.where((c) => c.group == category).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return filtered;
  }
}