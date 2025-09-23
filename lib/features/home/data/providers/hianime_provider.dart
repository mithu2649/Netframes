import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:netframes/features/home/data/providers/streaming_provider.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';
// import 'package:crypto/crypto.dart';
import 'package:netframes/features/home/data/providers/webview_resolver.dart';

class HiAnimeProvider implements StreamingProvider {

  String get name => 'Hi Anime';
  static const String _baseUrl = 'https://hianime.to';

  Future<Map<String, List<Movie>>> getHomePage() async {
    final List<Map<String, String>> categories = [
      {'Latest Episodes': '$_baseUrl/recently-updated?page='},
      {'Top Airing': '$_baseUrl/top-airing?page='},
      {'Recently Updated (SUB)': '$_baseUrl/filter?status=2&language=1&sort=recently_updated&page='},
      {'Recently Updated (DUB)': '$_baseUrl/filter?status=2&language=2&sort=recently_updated&page='},
      {'New On HiAnime': '$_baseUrl/recently-added?page='},
      {'Most Popular': '$_baseUrl/most-popular?page='},
      {'Most Favorite': '$_baseUrl/most-favorite?page='},
      {'Latest Completed': '$_baseUrl/completed?page='},
    ];

    Map<String, List<Movie>> allMovies = {};
    for (var category in categories) {
      final response = await http.get(Uri.parse(category.values.first + '1'));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final movies = _parseMovies(document, category.keys.first);
        allMovies[category.keys.first] = movies;
      }
    }
    return allMovies;
  }

  Future<List<Movie>> search(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/search?keyword=$query'));
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      return _parseMovies(document, 'Search Results');
    } else {
      return [];
    }
  }

  List<Movie> _parseMovies(dom.Document document, String category) {
    final movieElements = document.querySelectorAll('div.flw-item');
    return movieElements.map((element) {
      final title = element.querySelector('h3.film-name a')?.attributes['title'] ?? '';
      final posterUrl = element.querySelector('img')?.attributes['data-src'] ?? '';
      final url = element.querySelector('a')?.attributes['href'] ?? '';
      return Movie(
        id: '$_baseUrl$url',
        title: title,
        overview: '',
        posterPath: posterUrl,
        backdropPath: '',
        voteAverage: 0,
        provider: 'HiAnime',
      );
    }).toList();
  }

  Future<NetflixMovieDetails> getMovieDetails(Movie movie) async {
    final response = await http.get(Uri.parse(movie.id));
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final title = document.querySelector('.anisc-detail .film-name')?.text ?? '';
      final poster = document.querySelector('.anisc-poster img')?.attributes['src'] ?? '';
      String plot = '';
      try {
        final plotElement = document.querySelectorAll('.anisc-info .item-head').firstWhere((element) => element.text.trim() == 'Overview');
        plot = plotElement.nextElementSibling?.text.trim() ?? '';
      } catch (e) {
        // Overview not found, plot will be empty
      }
      final animeId = movie.id.split('-').last;

      final subEpisodes = await _fetchEpisodes(animeId, 'sub');
      final dubEpisodes = await _fetchEpisodes(animeId, 'dub');

      return NetflixMovieDetails(
        title: title,
        posterPath: poster,
        plot: plot,
        seasons: [NetflixSeason(season: 'Sub', episodes: subEpisodes), NetflixSeason(season: 'Dub', episodes: dubEpisodes)],
        type: NetflixContentType.tvShow,
      );
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  Future<List<NetflixEpisode>> _fetchEpisodes(String animeId, String type) async {
    final response = await http.get(Uri.parse('$_baseUrl/ajax/v2/episode/list/$animeId'));
    if (response.statusCode == 200) {
      final document = parser.parse(jsonDecode(response.body)['html']);
      final episodeElements = document.querySelectorAll('.ss-list > a[href].ssl-item.ep-item');
      return episodeElements.map((element) {
        final title = element.attributes['title'] ?? '';
        final url = element.attributes['href']?.replaceFirst('/', '') ?? '';
        final episodeNumber = element.querySelector('.ssli-order')?.text ?? '';
        return NetflixEpisode(
          title: title,
          id: '$type|$url',
          episode: episodeNumber,
          season: type == 'sub' ? 'Sub' : 'Dub',
        );
      }).toList();
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> loadLink(Movie movie, {NetflixEpisode? episode}) async {
    final data = episode!.id;
    final parts = data.split('|');
    final dubType = parts[0];
    final hrefPart = parts[1];
    final epId = hrefPart.split('=').last;

    final response = await http.get(Uri.parse('$_baseUrl/ajax/v2/episode/servers?episodeId=$epId'));
    if (response.statusCode == 200) {
      final doc = parser.parse(jsonDecode(response.body)['html']);
      final servers = doc.querySelectorAll('.server-item[data-type=$dubType][data-id]');
      for (var server in servers) {
        final id = server.attributes['data-id'];
        if (id != null && id.isNotEmpty) {
          final sourceUrlResponse = await http.get(Uri.parse('$_baseUrl/ajax/v2/episode/sources?id=$id'));
          if (sourceUrlResponse.statusCode == 200) {
            final sourceUrl = jsonDecode(sourceUrlResponse.body)['link'];
            return await _megacloudExtractor(sourceUrl);
          }
        }
      }
    }
    throw Exception('Failed to load video links');
  }

  Future<Map<String, dynamic>> _megacloudExtractor(String url) async {
    try {
      return await _megacloudExtractorPrimary(url);
    } catch (e) {
      print('[_megacloudExtractor] Primary extractor failed: $e');
      return await _megacloudExtractorFallback(url);
    }
  }

  Future<Map<String, dynamic>> _megacloudExtractorPrimary(String url) async {
    final headers = {
      'Accept': '*/*',
      'X-Requested-With': 'XMLHttpRequest',
      'Referer': url,
    };

    final videoId = url.split('/').last.split('?').first;

    final nonceResponse = await http.get(Uri.parse(url), headers: headers);
    final nonce = RegExp(r'\b[a-zA-Z0-9]{48}\b').firstMatch(nonceResponse.body)?.group(0) ?? 
        RegExp(r'\b([a-zA-Z0-9]{16})\b.*?\b([a-zA-Z0-9]{16})\b.*?\b([a-zA-Z0-9]{16})\b')
            .firstMatch(nonceResponse.body)
            ?.let((it) => it.group(1)! + it.group(2)! + it.group(3)!);

    final sourceUrl = 'https://megacloud.blog/embed-2/v3/e-1/getSources?id=$videoId&_k=$nonce';

    final response = await http.get(Uri.parse(sourceUrl), headers: headers);

    final data = jsonDecode(response.body);
    final sources = data['sources'];
    final tracks = data['tracks'];

    final mainHeaders = {
      'user-agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0',
      'accept': '*/*',
      'accept-language': 'en-US,en;q=0.5',
      'origin': 'https://megacloud.blog',
      'referer': 'https://megacloud.blog/',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'cross-site',
      'te': 'trailers',
    };

    if (sources is String) {
      final keyResponse = await http.get(Uri.parse('https://raw.githubusercontent.com/yogesh-hacker/MegacloudKeys/refs/heads/main/keys.json'));
      final key = jsonDecode(keyResponse.body)['megacloud'];

      final decodeUrl = 'https://script.google.com/macros/s/AKfycbxHbYHbrGMXYD2-bC-C43D3njIbU-wGiYQuJL61H4vyy6YVXkybMNNEPJNPPuZrD1gRVA/exec';
      final fullUrl = '$decodeUrl?encrypted_data=${Uri.encodeComponent(sources)}&nonce=${Uri.encodeComponent(nonce!)}&secret=${Uri.encodeComponent(key)}';

      final decryptedResponse = await http.get(Uri.parse(fullUrl));
      final m3u8Url = RegExp(r'"file":"(.*?)"').firstMatch(decryptedResponse.body)?.group(1) ?? '';

      final subtitles = (tracks as List)
          .where((e) => e['kind'] == 'captions')
          .map((e) => SubtitleFile(e['label'], e['file']))
          .toList();
      print('[_megacloudExtractorPrimary] Subtitles: $subtitles');

      return {
        'streams': [VideoStream(url: m3u8Url, quality: 'Unknown', headers: mainHeaders)],
        'subtitles': subtitles,
      };
    } else {
      final streams = (sources as List)
          .map((e) => VideoStream(url: e['file'], quality: e['label'] ?? 'default', headers: mainHeaders))
          .toList();

      final subtitles = (tracks as List)
          .where((e) => e['kind'] == 'captions')
          .map((e) => SubtitleFile(e['label'], e['file']))
          .toList();
      print('[_megacloudExtractorPrimary] Subtitles: $subtitles');

      return {
        'streams': streams,
        'subtitles': subtitles,
      };
    }
  }

  Future<Map<String, dynamic>> _megacloudExtractorFallback(String url) async {
    final jsToClickPlay = """
      (() => {
          const btn = document.querySelector('.jw-icon-display.jw-button-color.jw-reset');
          if (btn) { btn.click(); return \"clicked\"; } 
          return \"button not found\";
      })();
    """;

    final resolver = WebViewResolver(
      interceptUrl: RegExp(r'\.m3u8'),
      script: jsToClickPlay,
      timeout: 15000,
    );

    final m3u8Url = await resolver.resolve(url);

    return {
      'streams': [VideoStream(url: m3u8Url, quality: 'Unknown')],
      'subtitles': [],
    };
  }

  // String _decrypt(String encrypted, String key) {
  //   final keyBytes = utf8.encode(key);
  //   final encryptedBytes = base64.decode(encrypted);
  //   final hmac = Hmac(sha256, keyBytes);
  //   final digest = hmac.convert(encryptedBytes.sublist(16));
  //   final decrypted = <int>[];
  //   for (var i = 0; i < encryptedBytes.length - 16; i++) {
  //     decrypted.add(encryptedBytes[i] ^ digest.bytes[i % digest.bytes.length]);
  //   }
  //   return utf8.decode(decrypted);
  // }

  @override
  Future<void> clearCache() async {
    return;
  }
}

class MegacloudResponse {
  final List<Source> sources;
  final List<Track> tracks;
  final bool encrypted;
  final Intro intro;
  final Outro outro;
  final int server;

  MegacloudResponse({
    required this.sources,
    required this.tracks,
    required this.encrypted,
    required this.intro,
    required this.outro,
    required this.server,
  });

  factory MegacloudResponse.fromJson(Map<String, dynamic> json) {
    return MegacloudResponse(
      sources: (json['sources'] as List).map((e) => Source.fromJson(e)).toList(),
      tracks: (json['tracks'] as List).map((e) => Track.fromJson(e)).toList(),
      encrypted: json['encrypted'],
      intro: Intro.fromJson(json['intro']),
      outro: Outro.fromJson(json['outro']),
      server: json['server'],
    );
  }

  
}

class Source {
  final String file;
  final String type;

  Source({required this.file, required this.type});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      file: json['file'],
      type: json['type'],
    );
  }
}

class Track {
  final String file;
  final String label;
  final String kind;
  final bool? defaultTrack;

  Track({required this.file, required this.label, required this.kind, this.defaultTrack});

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      file: json['file'],
      label: json['label'],
      kind: json['kind'],
      defaultTrack: json['default'],
    );
  }
}

class Intro {
  final int start;
  final int end;

  Intro({required this.start, required this.end});

  factory Intro.fromJson(Map<String, dynamic> json) {
    return Intro(
      start: json['start'],
      end: json['end'],
    );
  }
}

class Outro {
  final int start;
  final int end;

  Outro({required this.start, required this.end});

  factory Outro.fromJson(Map<String, dynamic> json) {
    return Outro(
      start: json['start'],
      end: json['end'],
    );
  }
}

class Megakey {
  final String rabbit;
  final String mega;

  Megakey({required this.rabbit, required this.mega});

  factory Megakey.fromJson(Map<String, dynamic> json) {
    return Megakey(
      rabbit: json['rabbit'],
      mega: json['mega'],
    );
  }
}

class SubtitleFile {
  final String label;
  final String file;

  SubtitleFile(this.label, this.file);
}

extension Let<T> on T {
  R let<R>(R Function(T self) block) {
    return block(this);
  }
}