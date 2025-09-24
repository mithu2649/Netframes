
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:better_player/better_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/radio_station.dart';

part 'radio_state.dart';

class RadioCubit extends Cubit<RadioState> {
  BetterPlayerController? _betterPlayerController;
  List<RadioStation> _allStations = [];
  List<RadioStation> _favoriteStations = [];

  RadioCubit() : super(RadioInitial()) {
    _initPlayer();
    _loadStations();
  }

  void _initPlayer() {
    var betterPlayerConfiguration = BetterPlayerConfiguration(
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        showControls: false,
      ),
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController?.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        emit((state as RadioLoaded).copyWith(playbackState: PlaybackState.playing));
      } else if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        emit((state as RadioLoaded).copyWith(playbackState: PlaybackState.playing));
      } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
        emit((state as RadioLoaded).copyWith(playbackState: PlaybackState.stopped));
      } else if (event.betterPlayerEventType == BetterPlayerEventType.bufferingStart) {
        emit((state as RadioLoaded).copyWith(playbackState: PlaybackState.buffering));
      } else if (event.betterPlayerEventType == BetterPlayerEventType.bufferingEnd) {
        emit((state as RadioLoaded).copyWith(playbackState: PlaybackState.playing));
      } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        emit((state as RadioLoaded).copyWith(playbackState: PlaybackState.error, errorMessage: 'Playback failed'));
      }
    });
  }

  Future<void> _loadStations() async {
    emit(RadioLoading());
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final radioFiles = manifestMap.keys
          .where((String key) => key.contains('lib/radios/'))
          .toList();

      for (var file in radioFiles) {
        final String country = file
            .split('/')
            .last
            .replaceAll('-stations.json', '')
            .capitalize();
        final String response = await rootBundle.loadString(file);
        final List<dynamic> data = json.decode(response);
        _allStations.addAll(data
            .map((stationJson) => RadioStation.fromJson(stationJson, country))
            .toList());
      }
      await _loadFavorites();
      emit(RadioLoaded(_allStations, 'All', _betterPlayerController, null, allStations: _allStations));
    } catch (e) {
      emit(RadioError('Failed to load radio stations.'));
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteUrls = prefs.getStringList('favorite_radios') ?? [];
    _favoriteStations = _allStations
        .where((station) => favoriteUrls.contains(station.streamUrl))
        .toList();
    for (var station in _favoriteStations) {
      station.isFavorite = true;
    }
  }

  void playStation(RadioStation station) {
    try {
      BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        station.streamUrl,
        liveStream: true,
        // notificationConfiguration: BetterPlayerNotificationConfiguration(
        //   showNotification: true,
        //   title: station.name,
        //   author: station.country,
        // ),
      );
      _betterPlayerController?.setupDataSource(betterPlayerDataSource);
      emit((state as RadioLoaded).copyWith(
        playingStation: station,
        playbackState: PlaybackState.buffering,
        errorMessage: null,
      ));
    } catch (e) {
      emit((state as RadioLoaded).copyWith(
        playingStation: station,
        playbackState: PlaybackState.error,
        errorMessage: 'Failed to play: ${e.toString()}',
      ));
    }
  }

  void stopPlayback() {
    _betterPlayerController?.pause();
    emit((state as RadioLoaded).copyWith(
      playingStation: null,
      playbackState: PlaybackState.stopped,
      errorMessage: null,
    ));
  }

  void toggleFavorite(RadioStation station) async {
    station.isFavorite = !station.isFavorite;
    if (station.isFavorite) {
      _favoriteStations.add(station);
    } else {
      _favoriteStations.removeWhere((s) => s.streamUrl == station.streamUrl);
    }

    final prefs = await SharedPreferences.getInstance();
    final favoriteUrls = _favoriteStations.map((s) => s.streamUrl).toList();
    await prefs.setStringList('favorite_radios', favoriteUrls);

    emit((state as RadioLoaded).copyWith(
      stations: _getFilteredStations((state as RadioLoaded).selectedCountry),
    ));
  }

  void filterByCountry(String country) {
    emit((state as RadioLoaded).copyWith(
      stations: _getFilteredStations(country),
      selectedCountry: country,
    ));
  }

  void search(String query) {
    final filteredStations = _allStations
        .where((station) =>
            station.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    emit((state as RadioLoaded).copyWith(
      stations: filteredStations,
      selectedCountry: 'All',
    ));
  }

  List<RadioStation> _getFilteredStations(String country) {
    if (country == 'All') {
      return _allStations;
    } else if (country == 'Favorites') {
      return _favoriteStations;
    } else {
      return _allStations.where((s) => s.country == country).toList();
    }
  }

  void playNext() {
    final currentState = state;
    if (currentState is RadioLoaded && currentState.playingStation != null) {
      final currentList = _getFilteredStations(currentState.selectedCountry);
      final currentIndex = currentList.indexOf(currentState.playingStation!);
      if (currentIndex != -1 && currentIndex < currentList.length - 1) {
        playStation(currentList[currentIndex + 1]);
      } else if (currentIndex == currentList.length - 1) {
        // Loop back to the first station if at the end
        playStation(currentList.first);
      }
    }
  }

  void playPrevious() {
    final currentState = state;
    if (currentState is RadioLoaded && currentState.playingStation != null) {
      final currentList = _getFilteredStations(currentState.selectedCountry);
      final currentIndex = currentList.indexOf(currentState.playingStation!);
      if (currentIndex > 0) {
        playStation(currentList[currentIndex - 1]);
      } else if (currentIndex == 0) {
        // Loop back to the last station if at the beginning
        playStation(currentList.last);
      }
    }
  }

  @override
  Future<void> close() {
    _betterPlayerController?.dispose();
    return super.close();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
