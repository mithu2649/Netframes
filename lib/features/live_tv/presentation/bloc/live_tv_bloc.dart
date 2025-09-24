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
        final initialChannel = channels.first;
        final filteredChannels = _filterChannels(channels, 'Zee', '');

        emit(LiveTvLoaded(
          allChannels: channels,
          filteredChannels: filteredChannels,
          categories: categories,
          selectedCategory: 'Zee',
          searchQuery: '',
          currentChannel: initialChannel,
          currentChannelUrl: initialChannel.isZee ? '' : initialChannel.url,
          headers: const {},
          favoriteChannelIds: favoriteChannelIds,
          isAutoStartupSequence: true,
          isStreamLoading: initialChannel.isZee,
        ));

        if (initialChannel.isZee) {
          final streamUrl = await _iptvRepository.getZeeStreamUrl(initialChannel.id);
          final headers = {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
          };
          emit((state as LiveTvLoaded).copyWith(
            currentChannelUrl: streamUrl,
            headers: headers,
            isStreamLoading: false,
          ));
        }
      } catch (e) {
        emit(LiveTvError(e.toString()));
      }
    });

    on<LiveTvTabEntered>((event, emit) async {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        final initialChannel = currentState.allChannels.first;

        emit(currentState.copyWith(
          currentChannel: initialChannel,
          currentChannelUrl: initialChannel.isZee ? '' : initialChannel.url,
          headers: {},
          isAutoStartupSequence: true,
          isStreamLoading: initialChannel.isZee,
        ));

        if (initialChannel.isZee) {
          final streamUrl = await _iptvRepository.getZeeStreamUrl(initialChannel.id);
          final headers = {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
          };
          emit((state as LiveTvLoaded).copyWith(
            currentChannelUrl: streamUrl,
            headers: headers,
            isStreamLoading: false,
          ));
        }
      }
    });

    on<ChannelSelected>((event, emit) async {
      if (state is LiveTvLoaded) {
        final currentState = state as LiveTvLoaded;
        final channel = currentState.allChannels
            .firstWhere((element) => element.url == event.channelUrl);

        if (channel.isZee) {
          emit(currentState.copyWith(isStreamLoading: true, currentChannel: channel));
          final streamUrl = await _iptvRepository.getZeeStreamUrl(channel.id);
          final headers = {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
          };
          emit(currentState.copyWith(
            currentChannel: channel,
            currentChannelUrl: streamUrl,
            headers: headers,
            isAutoStartupSequence: false,
            isStreamLoading: false,
          ));
        } else {
          emit(currentState.copyWith(
            currentChannel: channel,
            currentChannelUrl: event.channelUrl,
            headers: {},
            isAutoStartupSequence: false,
          ));
        }
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
              currentChannel: nextChannel,
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

    if (category == 'Zee') {
      filtered = filtered.where((c) => c.isZee).toList();
    } else if (category != 'All') {
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