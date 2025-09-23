import 'package:http/http.dart' as http;
import 'package:netframes/features/live_tv/data/models/channel_model.dart';
import 'package:netframes/features/live_tv/data/services/favorites_service.dart';

class IptvRepository {
  final String _url = 'https://iptv-org.github.io/iptv/countries/in.m3u';
  final FavoritesService _favoritesService;

  IptvRepository(this._favoritesService);

  Future<Map<String, dynamic>> fetchChannels() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode == 200) {
      final channels = _parseM3u(response.body);
      final favoriteIds = await _favoritesService.getFavorites();
      channels.sort((a, b) {
        final aIsFavorite = favoriteIds.contains(a.id);
        final bIsFavorite = favoriteIds.contains(b.id);
        if (aIsFavorite && !bIsFavorite) {
          return -1;
        } else if (!aIsFavorite && bIsFavorite) {
          return 1;
        } else {
          return a.name.compareTo(b.name);
        }
      });

      final categories = channels.map((c) => c.group).toSet().toList();
      categories.insert(0, 'All');

      return {'channels': channels, 'categories': categories};
    } else {
      throw Exception('Failed to load channels');
    }
  }

  List<Channel> _parseM3u(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXTINF')) {
        final info = lines[i];
        final url = lines[++i].trim();

        final tvgId = _getAttribute(info, 'tvg-id');
        final tvgLogo = _getAttribute(info, 'tvg-logo');
        final groupTitle = _getAttribute(info, 'group-title');
        final name = info.split(',').last.trim();

        if (url.isNotEmpty) {
          channels.add(Channel(
            id: tvgId,
            name: name,
            logo: tvgLogo,
            group: groupTitle,
            url: url,
          ));
        }
      }
    }

    return channels;
  }

  String _getAttribute(String line, String attribute) {
    try {
      final regex = RegExp('$attribute="(.*?)"');
      final match = regex.firstMatch(line);
      return match?.group(1) ?? '';
    } catch (e) {
      return '';
    }
  }
}
