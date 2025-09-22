import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _themeModeKey = 'themeMode';
  static const _accentColorKey = 'accentColor';

  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex =
          prefs.getInt(_themeModeKey) ?? ThemeMode.dark.index;
      return ThemeMode.values[themeModeIndex];
    } catch (e) {
      return ThemeMode.dark; // Fallback to default
    }
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, themeMode.index);
    } catch (e) {
      return  Future.value(); // Ignore errors
    }
  }

  Future<Color> getAccentColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accentColorValue =
          prefs.getInt(_accentColorKey) ?? Colors.deepPurple.value;
      return Color(accentColorValue);
    } catch (e) {
      return Colors.deepPurple; // Fallback to default
    }
  }

  Future<void> saveAccentColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, color.value);
    } catch (e) {
      print('ThemeService: Error in saveAccentColor: $e');
    }
  }
}
