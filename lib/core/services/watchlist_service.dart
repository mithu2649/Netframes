import 'package:shared_preferences/shared_preferences.dart';

class WatchlistService {
  static const _watchlistKey = 'watchlist';

  Future<List<String>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_watchlistKey) ?? [];
  }

  Future<void> addToWatchlist(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final watchlist = await getWatchlist();
    if (!watchlist.contains(id)) {
      watchlist.add(id);
      await prefs.setStringList(_watchlistKey, watchlist);
    }
  }

  Future<void> removeFromWatchlist(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final watchlist = await getWatchlist();
    if (watchlist.contains(id)) {
      watchlist.remove(id);
      await prefs.setStringList(_watchlistKey, watchlist);
    }
  }

  Future<bool> isInWatchlist(String id) async {
    final watchlist = await getWatchlist();
    return watchlist.contains(id);
  }
}
