import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:netframes/core/services/theme_service.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_event.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService _themeService;

  ThemeBloc({required ThemeService themeService}) : _themeService = themeService, super(const ThemeInitial(ThemeMode.dark, Colors.deepPurple)) {
    on<LoadTheme>((event, emit) async {
      try {
        final themeMode = await _themeService.getThemeMode();
        final accentColor = await _themeService.getAccentColor();
        emit(ThemeLoaded(themeMode, accentColor));
      } catch (e) {
        // Handle error, e.g., log it or emit an error state
        // Optionally, emit a default state or an error state
        emit(const ThemeInitial(ThemeMode.dark, Colors.deepPurple));
      }
    });
    on<ThemeChanged>((event, emit) {
      emit(ThemeLoaded(event.themeMode, state.accentColor));
      _themeService.saveThemeMode(event.themeMode);
    });
    on<AccentColorChanged>((event, emit) {
      emit(ThemeLoaded(state.themeMode, event.accentColor));
      _themeService.saveAccentColor(event.accentColor);
    });

    add(LoadTheme()); // Dispatch LoadTheme event in the constructor
  }
}