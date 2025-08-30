import 'dart:convert';
import 'package:better_player/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:netframes/features/home/data/providers/streaming_provider.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:html/parser.dart' as parser;

class NetflixMirrorProvider implements StreamingProvider {
  final String _baseUrl = "https://net2025.cc";
  String _cookie = "";
  static const String _cookieKey = 'netflix_cookie';
  static const String _cookieTimestampKey = 'netflix_cookie_timestamp';

  final Map<String, String> _headers = {'X-Requested-With': 'XMLHttpRequest'};

  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
    await prefs.remove(_cookieTimestampKey);
    _cookie = '';
  }

  Future<String> bypass() async {
    if (_cookie.isNotEmpty) return _cookie;

    final prefs = await SharedPreferences.getInstance();
    final savedCookie = prefs.getString(_cookieKey);
    final savedTimestamp = prefs.getInt(_cookieTimestampKey);

    if (savedCookie != null &&
        savedTimestamp != null &&
        DateTime.now().millisecondsSinceEpoch - savedTimestamp < 54000000) {
      _cookie = savedCookie;
      if (kDebugMode) {
        print('Using cached cookie: $_cookie');
      }
      return _cookie;
    }

    if (kDebugMode) {
      print('Bypassing to get new cookie...');
    }
    String newCookieValue = '';
    int retries = 0;
    while (retries < 5) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/tv/p.php'),
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$_baseUrl/home',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['r'] == 'n') {
            final rawCookie = response.headers['set-cookie'] ?? '';
            if (kDebugMode) {
              print('Raw cookie from bypass: $rawCookie');
            }
            final cookieValue =
                RegExp(r't_hash_t=([^;]+)').firstMatch(rawCookie)?.group(1) ??
                '';
            newCookieValue = cookieValue;
            break;
          }
        }
      } catch (e) {
        // In case of timeout or other error, just retry
      }
      retries++;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (newCookieValue.isEmpty) {
      throw Exception('Failed to get bypass cookie after 5 retries.');
    }

    _cookie = newCookieValue;
    await prefs.setString(_cookieKey, _cookie);
    await prefs.setInt(
      _cookieTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (kDebugMode) {
      print('New cookie obtained and cached: $_cookie');
    }
    return _cookie;
  }

  Map<String, String> get _apiHeaders {
    return {
      ..._headers,
      'Cookie': 't_hash_t=$_cookie; ott=nf; hd=on',
      'Referer': '$_baseUrl/home',
    };
  }

  @override
  Future<Map<String, List<Movie>>> getHomePage() async {
    await bypass();
    final response = await http.get(
      Uri.parse('$_baseUrl/home'),
      headers: _apiHeaders,
    );

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final Map<String, List<Movie>> homePageData = {};

      final rows = document.querySelectorAll('.lolomoRow');
      for (var row in rows) {
        final title =
            row.querySelector('h2 > span > div')?.text.trim() ?? 'Unknown';
        final movies = <Movie>[];
        final movieElements = row.querySelectorAll('img.lazy');
        for (var movieElement in movieElements) {
          final id = movieElement.attributes['data-src']
              ?.split('/')
              .last
              .split('.')
              .first;
          if (id != null) {
            movies.add(
              Movie(
                id: id,
                title: '',
                overview: '',
                posterPath: 'https://imgcdn.media/poster/v/$id.jpg',
                backdropPath: '',
                voteAverage: 0.0,
                provider: 'Netflix',
              ),
            );
          }
        }
        homePageData[title] = movies;
      }
      return homePageData;
    } else {
      throw Exception('Failed to load home page');
    }
  }

  Future<List<_Episode>> _getEpisodes(String seriesId, String seasonId) async {
    final episodes = <_Episode>[];
    var page = 1;
    while (true) {
      final url =
          '$_baseUrl/episodes.php?s=$seasonId&series=$seriesId&t=${DateTime.now().millisecondsSinceEpoch}&page=$page';
      final response = await http.get(Uri.parse(url), headers: _apiHeaders);
      if (response.statusCode != 200) {
        break;
      }
      final data = _EpisodesData.fromJson(json.decode(response.body));
      if (data.episodes != null) {
        episodes.addAll(data.episodes!);
      }
      if (data.nextPageShow == 0) {
        break;
      }
      page++;
    }
    return episodes;
  }

  @override
  Future<NetflixMovieDetails> getMovieDetails(Movie movie) async {
    await bypass();
    final url =
        '$_baseUrl/post.php?id=${movie.id}&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url), headers: _apiHeaders);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'n') {
        throw Exception('Failed to load movie details: ${data["error"]}');
      }
      final postData = _PostData.fromJson(data);
      final seasons = <NetflixSeason>[];

      if (postData.episodes.isEmpty || postData.episodes.first == null) {
        // It's a movie
        seasons.add(
          NetflixSeason(
            season: '1',
            episodes: [
              NetflixEpisode(
                id: movie.id.toString(),
                title: postData.title,
                season: '1',
                episode: '1',
              ),
            ],
          ),
        );
      } else {
        // It's a TV Show
        final allEpisodes = <_Episode>[];
        allEpisodes.addAll(postData.episodes.whereType<_Episode>());

        if (postData.nextPageShow == 1 && postData.nextPageSeason != null) {
          final seasonEpisodes = await _getEpisodes(
            movie.id,
            postData.nextPageSeason!,
          );
          allEpisodes.addAll(seasonEpisodes);
        }

        if (postData.season != null) {
          final seasonData = postData.season!
              .map((e) => _Season.fromJson(e))
              .toList();
          for (var season in seasonData.sublist(0, seasonData.length - 1)) {
            final seasonEpisodes = await _getEpisodes(movie.id, season.id);
            allEpisodes.addAll(seasonEpisodes);
          }
        }

        final episodesBySeason = <String, List<NetflixEpisode>>{};
        for (var episode in allEpisodes) {
          final seasonNum = episode.s.replaceAll('S', '');
          if (!episodesBySeason.containsKey(seasonNum)) {
            episodesBySeason[seasonNum] = [];
          }
          episodesBySeason[seasonNum]!.add(
            NetflixEpisode(
              id: episode.id,
              title: episode.t,
              season: seasonNum,
              episode: episode.ep.replaceAll('E', ''),
              thumbnail: 'https://imgcdn.media/epimg/150/${episode.id}.jpg',
            ),
          );
        }

        episodesBySeason.forEach((seasonNum, episodes) {
          seasons.add(NetflixSeason(season: seasonNum, episodes: episodes));
        });

        seasons.sort(
          (a, b) => int.parse(a.season).compareTo(int.parse(b.season)),
        );
      }

      return NetflixMovieDetails(
        title: postData.title,
        plot: postData.desc ?? '',
        year: postData.year,
        runtime: postData.runtime ?? '',
        cast: postData.cast?.split(',').map((e) => e.trim()).toList() ?? [],
        genres: postData.genre?.split(',').map((e) => e.trim()).toList() ?? [],
        type: postData.episodes.isEmpty || postData.episodes.first == null
            ? NetflixContentType.movie
            : NetflixContentType.tvShow,
        seasons: seasons,
      );
    } else {
      throw Exception(
        'Failed to load movie details: Status code ${response.statusCode}',
      );
    }
  }

  String _fixUrl(String url) {
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    if (url.startsWith('/')) {
      return 'https://net50.cc${url.replaceFirst("/tv", "")}';
    }
    return url;
  }

  @override
  Future<Map<String, dynamic>> loadLink(
    Movie movie, {
    NetflixEpisode? episode,
  }) async {
    if (kDebugMode) {
      print('loadLink called');
      print('Cookie value: $_cookie');
    }
    await bypass();
    const playerBaseUrl = 'https://net50.cc';
    final h = _cookie;
    final url =
        '$playerBaseUrl/tv/playlist.php?id=${movie.id}&t=${movie.title}&tm=${DateTime.now().millisecondsSinceEpoch}&h=$h';
    final headers = {
      ..._apiHeaders,
      'Referer': '$playerBaseUrl/tv/play.php?id=${movie.id}&in=$h',
    };
    if (kDebugMode) {
      print('Loading link from: $url');
      print('Headers: $headers');
    }
    final response = await http.get(Uri.parse(url), headers: headers);

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      final responseBody = response.body;
      const chunkSize = 1024;
      for (var i = 0; i < responseBody.length; i += chunkSize) {
        final chunk = responseBody.substring(
          i,
          i + chunkSize > responseBody.length
              ? responseBody.length
              : i + chunkSize,
        );
        print('Response body chunk: $chunk');
      }
    }

    if (response.statusCode == 200) {
      final playlist = _PlayList.fromJson(json.decode(response.body));
      final videoStreams = <VideoStream>[];
      final subtitles = <BetterPlayerSubtitlesSource>[];
      final videoHeaders = {
        'Cookie': _apiHeaders['Cookie']!,
        'Referer': episode != null
            ? '$playerBaseUrl/play.php?id=${movie.id}&s=${episode.season}&e=${episode.episode}&in=$h'
            : '$playerBaseUrl/play.php?id=${movie.id}&in=$h',
      };

      if (kDebugMode) {
        print('Video Headers: $videoHeaders');
      }

      for (var item in playlist.items) {
        for (var source in item.sources) {
          final streamUrl = _fixUrl(source.file);
          if (kDebugMode) {
            print('Stream URL: $streamUrl');
          }
          videoStreams.add(
            VideoStream(
              url: streamUrl,
              quality: source.label ?? 'Unknown',
              headers: videoHeaders,
              cookies: {},
            ),
          );

          // Attempt to fetch the M3U8 content directly for debugging
          try {
            final m3u8Response = await http.get(
              Uri.parse(streamUrl),
              headers: videoHeaders,
            );
            if (kDebugMode) {
              print('M3U8 URL: $streamUrl');
              print('M3U8 Response Status: ${m3u8Response.statusCode}');
              print('M3U8 Response Body Length: ${m3u8Response.body.length}');
              print('M3U8 Response Body: ${m3u8Response.body.trim()}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching M3U8 content: $e');
            }
          }
        }
      }

      final subtitleUrl =
          'http://subs.nfmirrorcdn.top/files/${movie.id}/${movie.id}-en.[CC].srt';
      try {
        final subtitleResponse = await http.head(Uri.parse(subtitleUrl));
        if (subtitleResponse.statusCode == 200) {
          subtitles.add(
            BetterPlayerSubtitlesSource(
              type: BetterPlayerSubtitlesSourceType.network,
              urls: [subtitleUrl],
              name: "English",
              headers: videoHeaders,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('No subtitles found: $e');
        }
      }
      return {'streams': videoStreams, 'subtitles': subtitles};
    } else {
      throw Exception(
        'Failed to load link: Status code ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<Movie>> search(String query) async {
    await bypass();
    final url =
        '$_baseUrl/search.php?s=$query&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url), headers: _apiHeaders);

    if (response.statusCode == 200) {
      final data = _SearchData.fromJson(json.decode(response.body));
      return data.searchResult.map((result) {
        return Movie(
          id: result.id,
          title: result.title,
          overview: '',
          posterPath: 'https://imgcdn.media/poster/v/${result.id}.jpg',
          backdropPath: '',
          voteAverage: 0.0,
          provider: 'Netflix',
        );
      }).toList();
    } else {
      throw Exception('Failed to search');
    }
  }
}

class _EpisodesData {
  final List<_Episode>? episodes;
  final int nextPageShow;

  _EpisodesData({this.episodes, required this.nextPageShow});

  factory _EpisodesData.fromJson(Map<String, dynamic> json) {
    return _EpisodesData(
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => _Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextPageShow: json['nextPageShow'] as int,
    );
  }
}

class _Season {
  final String id;

  _Season({required this.id});

  factory _Season.fromJson(Map<String, dynamic> json) {
    return _Season(id: json['id']);
  }
}

class _SearchData {
  final List<_SearchResult> searchResult;
  _SearchData({required this.searchResult});
  factory _SearchData.fromJson(Map<String, dynamic> json) {
    return _SearchData(
      searchResult: (json['searchResult'] as List)
          .map((e) => _SearchResult.fromJson(e))
          .toList(),
    );
  }
}

class _SearchResult {
  final String id;
  final String title;
  _SearchResult({required this.id, required this.title});
  factory _SearchResult.fromJson(Map<String, dynamic> json) {
    return _SearchResult(id: json['id'], title: json['t']);
  }
}

class _PlayList {
  final List<_PlayListItem> items;
  _PlayList({required this.items});
  factory _PlayList.fromJson(List<dynamic> json) {
    return _PlayList(
      items: json.map((e) => _PlayListItem.fromJson(e)).toList(),
    );
  }
}

class _PlayListItem {
  final List<_Source> sources;
  final List<_Track>? tracks;

  _PlayListItem({required this.sources, this.tracks});

  factory _PlayListItem.fromJson(Map<String, dynamic> json) {
    return _PlayListItem(
      sources: (json['sources'] as List)
          .map((e) => _Source.fromJson(e))
          .toList(),
      tracks: (json['tracks'] as List?)
          ?.map((e) => _Track.fromJson(e))
          .toList(),
    );
  }
}

class _Track {
  final String file;
  final String? kind;

  _Track({required this.file, this.kind});

  factory _Track.fromJson(Map<String, dynamic> json) {
    return _Track(file: json['file'], kind: json['kind'] as String?);
  }
}

class _Source {
  final String file;
  final String? label;
  final String? type;
  _Source({required this.file, this.label, this.type});
  factory _Source.fromJson(Map<String, dynamic> json) {
    return _Source(
      file: json['file'],
      label: json['label'] as String?,
      type: json['type'] as String?,
    );
  }
}

class _Episode {
  final String complate;
  final String ep;
  final String id;
  final String s;
  final String t;
  final String time;
  _Episode({
    required this.complate,
    required this.ep,
    required this.id,
    required this.s,
    required this.t,
    required this.time,
  });
  factory _Episode.fromJson(Map<String, dynamic> json) {
    return _Episode(
      complate: json['complate'],
      ep: json['ep'],
      id: json['id'],
      s: json['s'],
      t: json['t'],
      time: json['time'],
    );
  }
}

class _PostData {
  final String? desc;
  final String? director;
  final String? ua;
  final List<_Episode?> episodes;
  final String? genre;
  final int? nextPage;
  final String? nextPageSeason;
  final int? nextPageShow;
  final List<dynamic>? season;
  final String title;
  final String year;
  final String? cast;
  final String? match;
  final String? runtime;
  final List<dynamic>? suggest;

  _PostData({
    this.desc,
    this.director,
    this.ua,
    required this.episodes,
    this.genre,
    this.nextPage,
    this.nextPageSeason,
    this.nextPageShow,
    this.season,
    required this.title,
    required this.year,
    this.cast,
    this.match,
    this.runtime,
    this.suggest,
  });

  factory _PostData.fromJson(Map<String, dynamic> json) {
    return _PostData(
      desc: json['desc'] as String?,
      director: json['director'] as String?,
      ua: json['ua'] as String?,
      episodes: (json['episodes'] as List)
          .map((e) => e == null ? null : _Episode.fromJson(e))
          .toList(),
      genre: json['genre'] as String?,
      nextPage: json['nextPage'] as int?,
      nextPageSeason: json['nextPageSeason'] as String?,
      nextPageShow: json['nextPageShow'] as int?,
      season: json['season'] as List?,
      title: json['title'],
      year: json['year'],
      cast: json['cast'] as String?,
      match: json['match'] as String?,
      runtime: json['runtime']?.toString(),
      suggest: json['suggest'] as List?,
    );
  }
}
