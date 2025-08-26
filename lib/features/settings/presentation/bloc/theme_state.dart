import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final Color accentColor;

  const ThemeState(this.themeMode, this.accentColor);

  @override
  List<Object> get props => [themeMode, accentColor];
}

class ThemeInitial extends ThemeState {
  const ThemeInitial(super.themeMode, super.accentColor);
}

class ThemeLoaded extends ThemeState {
  const ThemeLoaded(super.themeMode, super.accentColor);
}