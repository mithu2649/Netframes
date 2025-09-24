
part of 'radio_cubit.dart';

enum PlaybackState {
  stopped,
  buffering,
  playing,
  error,
}

abstract class RadioState {}

class RadioInitial extends RadioState {}

class RadioLoading extends RadioState {}

class RadioLoaded extends RadioState {
  final List<RadioStation> stations;
  final String selectedCountry;
  final BetterPlayerController? playerController;
  final RadioStation? playingStation;
  final PlaybackState playbackState;
  final String? errorMessage;
  final List<RadioStation> allStations;

  RadioLoaded(this.stations, this.selectedCountry, this.playerController, this.playingStation, {this.playbackState = PlaybackState.stopped, this.errorMessage, required this.allStations});

  RadioLoaded copyWith({
    List<RadioStation>? stations,
    String? selectedCountry,
    BetterPlayerController? playerController,
    RadioStation? playingStation,
    PlaybackState? playbackState,
    String? errorMessage,
    List<RadioStation>? allStations,
  }) {
    return RadioLoaded(
      stations ?? this.stations,
      selectedCountry ?? this.selectedCountry,
      playerController ?? this.playerController,
      playingStation ?? this.playingStation,
      playbackState: playbackState ?? this.playbackState,
      errorMessage: errorMessage ?? this.errorMessage,
      allStations: allStations ?? this.allStations,
    );
  }
}

class RadioError extends RadioState {
  final String message;

  RadioError(this.message);
}
