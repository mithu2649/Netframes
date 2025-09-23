import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _favoritesKey = 'favorite_channels';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> addFavorite(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (!favorites.contains(channelId)) {
      favorites.add(channelId);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  Future<void> removeFavorite(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (favorites.contains(channelId)) {
      favorites.remove(channelId);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }
}
