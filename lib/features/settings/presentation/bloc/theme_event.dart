import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class LoadTheme extends ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  const ThemeChanged(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class AccentColorChanged extends ThemeEvent {
  final Color accentColor;

  const AccentColorChanged(this.accentColor);

  @override
  List<Object> get props => [accentColor];
}
