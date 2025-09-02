import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:netframes/features/home/data/providers/streaming_provider.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';

class MPlayerProvider implements StreamingProvider {
  @override
  String get name => 'MPlayer';
  final String _mainUrl = "https://www.mxplayer.in";
  final String _webApi = "https://api.mxplayer.in/v1/web";
  final String _imageUrl = "https://qqcdnpictest.mxplay.com/";
  final String _endpointUrl = "https://d3sgzbosmwirao.cloudfront.net/";
  String? _userID;

  String get _endParam =>
      "&device-density=2&userid=$_userID&platform=com.mxplay.desktop&content-languages=hi,en&kids-mode-enabled=false";

  Future<void> _init() async {
    if (_userID != null) return;
    if (kDebugMode) {
      print('[MPlayerProvider] Initializing... Getting UserID');
    }
    final res = await http.get(Uri.parse(_mainUrl));
    final cookies = res.headers['set-cookie'];
    if (cookies != null) {
      final match = RegExp(r'UserID=([^;]+)').firstMatch(cookies);
      if (match != null) {
        _userID = match.group(1);
        if (kDebugMode) {
          print('[MPlayerProvider] UserID found: $_userID');
        }
      }
    }
    if (_userID == null) {
      throw Exception('[MPlayerProvider] Failed to get userID');
    }
  }

  @override
  Future<Map<String, List<Movie>>> getHomePage() async {
    await _init();
    final Map<String, List<Movie>> homePageData = {};

    try {
      final dramaResponse = await http.get(Uri.parse(
          "$_webApi/detail/browseItem?&pageNum=1&pageSize=20&isCustomized=true&genreFilterIds=48efa872f6f17facebf6149dfc536ee1&type=2$_endParam"));
      final dramaRoot = _MXPlayer.fromJson(json.decode(dramaResponse.body));
      homePageData['Drama Shows'] = dramaRoot.items.map((e) => e.toMovie(_imageUrl)).toList();

      final crimeResponse = await http.get(Uri.parse(
          "$_webApi/detail/browseItem?&pageNum=1&pageSize=20&isCustomized=true&genreFilterIds=b413dff55bdad743c577a8bea3b65044&type=2$_endParam"));
      final crimeRoot = _MXPlayer.fromJson(json.decode(crimeResponse.body));
      homePageData['Crime Shows'] = crimeRoot.items.map((e) => e.toMovie(_imageUrl)).toList();

      final thrillerResponse = await http.get(Uri.parse(
          "$_webApi/detail/browseItem?&pageNum=1&pageSize=20&isCustomized=true&genreFilterIds=2dd5daf25be5619543524f360c73c3d8&type=2$_endParam"));
      final thrillerRoot = _MXPlayer.fromJson(json.decode(thrillerResponse.body));
      homePageData['Thriller Shows'] = thrillerRoot.items.map((e) => e.toMovie(_imageUrl)).toList();

      final hindiMovieResponse = await http.get(Uri.parse(
          "$_webApi/detail/browseItem?&pageNum=1&pageSize=20&isCustomized=true&browseLangFilterIds=hi&type=1$_endParam"));
      final movieRoot = _MovieRoot.fromJson(json.decode(hindiMovieResponse.body));
      homePageData['Hindi Movies'] = movieRoot.items.map((e) => e.toMovie(_imageUrl)).toList();

      final teluguMovieResponse = await http.get(Uri.parse(
          "$_webApi/detail/browseItem?&pageNum=1&pageSize=20&isCustomized=true&browseLangFilterIds=te&type=1$_endParam"));
      final teluguMovieRoot = _MovieRoot.fromJson(json.decode(teluguMovieResponse.body));
      homePageData['Telugu Movies'] = teluguMovieRoot.items.map((e) => e.toMovie(_imageUrl)).toList();
    } catch (e, s) {
      if (kDebugMode) {
        print('[MPlayerProvider] Error in getHomePage: $e\n$s');
      }
      rethrow;
    }

    return homePageData;
  }

  @override
  Future<NetflixMovieDetails> getMovieDetails(Movie movie) async {
    if (kDebugMode) {
      print('[MPlayerProvider] getMovieDetails for: ${movie.title}');
      print('[MPlayerProvider] Movie ID (JSON): ${movie.id}');
    }

    _LoadUrl loadUrl;
    try {
      loadUrl = _LoadUrl.fromJson(json.decode(movie.id));
      if (kDebugMode) {
        print('[MPlayerProvider] Parsed LoadUrl successfully: ${loadUrl.title}');
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[MPlayerProvider] Error parsing LoadUrl: $e\n$s');
      }
      throw Exception('Failed to parse movie details');
    }

    final type = loadUrl.tvType.contains("tvshow")
        ? NetflixContentType.tvShow
        : NetflixContentType.movie;
    if (kDebugMode) {
      print('[MPlayerProvider] Content type: $type');
    }

    if (type == NetflixContentType.tvShow) {
      if (loadUrl.shareUrl == null) {
        throw Exception('shareUrl is null for TV Show');
      }
      if (kDebugMode) {
        print('[MPlayerProvider] Fetching seasons from: $_mainUrl${loadUrl.shareUrl}');
      }
      final response = await http.get(Uri.parse("$_mainUrl${loadUrl.shareUrl}"));
      if (kDebugMode) {
        print('[MPlayerProvider] Got seasons page, parsing...');
      }
      final seasonData = _getSeasonData(response.body);
      final episodes = <NetflixEpisode>[];

      for (var season in seasonData) {
        if (kDebugMode) {
          print('[MPlayerProvider] Fetching episodes for season ${season.season}...');
        }
        var page = 1;
        String? nextQuery;
        do {
          final url = nextQuery == null
              ? '$_webApi/detail/tab/tvshowepisodes?type=season&id=${season.seasonId}$_endParam'
              : '$_webApi/detail/tab/tvshowepisodes?type=season&$nextQuery&id=${season.seasonId}&sortOrder=0&device-density=2&userid=debug-user-id&platform=com.mxplay.desktop&content-languages=hi,en&kids-mode-enabled=false';
          if (kDebugMode) {
            print('[MPlayerProvider] Fetching episode page: $url');
          }
          final episodeResponse = await http.get(Uri.parse(url));
          final episodeData = _EpisodesParser.fromJson(json.decode(episodeResponse.body));

          episodes.addAll(episodeData.items.map((e) {
            final thumbnailUrl = e.imageInfo.isNotEmpty
                ? _imageUrl + e.imageInfo.first.url
                : null;
            return NetflixEpisode(
                id: json.encode(e.stream.toJson()), // Encode the whole stream object
                title: e.title ?? "",
                episode: e.sequence.toString(),
                season: season.season.toString(),
                thumbnail: thumbnailUrl);
          }));
          nextQuery = episodeData.next;
          page++;
        } while (nextQuery != null);
      }

      final seasons = <NetflixSeason>[];
      final episodesBySeason = <int, List<NetflixEpisode>>{};
      for (var episode in episodes) {
        final seasonNum = int.parse(episode.season);
        if (!episodesBySeason.containsKey(seasonNum)) {
          episodesBySeason[seasonNum] = [];
        }
        episodesBySeason[seasonNum]!.add(episode);
      }

      episodesBySeason.forEach((seasonNum, episodeList) {
        seasons.add(NetflixSeason(season: seasonNum.toString(), episodes: episodeList));
      });

      seasons.sort((a, b) => int.parse(a.season).compareTo(int.parse(b.season)));

      if (kDebugMode) {
        print('[MPlayerProvider] Finished processing TV show, returning details.');
      }
      return NetflixMovieDetails(
          title: loadUrl.title,
          plot: loadUrl.description,
          seasons: seasons,
          type: type);
    } else {
      if (kDebugMode) {
        print('[MPlayerProvider] Processing movie, returning details.');
      }
      return NetflixMovieDetails(
        title: loadUrl.title,
        plot: loadUrl.description,
        seasons: [
          NetflixSeason(season: "1", episodes: [
            NetflixEpisode(
                id: json.encode(loadUrl.stream?.toJson() ?? {}), // Encode the whole stream object
                title: loadUrl.title,
                episode: "1",
                season: "1")
          ])
        ],
        type: type,
      );
    }
  }

  List<_SeasonData> _getSeasonData(String html) {
    final document = parser.parse(html);
    final seasons = document.querySelectorAll("div.hs__items-container > div");
    return seasons.map((element) {
      final tab = element.attributes['data-tab'];
      final id = element.attributes['data-id'];
      if (tab != null && id != null) {
        return _SeasonData(season: int.parse(tab), seasonId: id);
      }
      return null;
    }).whereType<_SeasonData>().toList();
  }

  @override
  Future<Map<String, dynamic>> loadLink(Movie movie, {NetflixEpisode? episode}) async {
    if (kDebugMode) {
      print('[MPlayerProvider] loadLink for: ${movie.title}');
    }
    _Stream stream;
    if (episode != null && episode.id.isNotEmpty) {
      // It's a TV Show episode
      stream = _Stream.fromJson(json.decode(episode.id));
    } else {
      // It's a Movie
      final loadUrl = _LoadUrl.fromJson(json.decode(movie.id));
      stream = loadUrl.stream ?? _Stream();
    }

    final streamsWithQuality = stream.getAllStreamsWithQuality();
    if (streamsWithQuality.isEmpty) {
      throw Exception('No stream URL found');
    }

    final videoStreams = <VideoStream>[];
    streamsWithQuality.forEach((quality, url) {
      final fullUrl = url.startsWith("video") ? "$_endpointUrl$url" : url;
      videoStreams.add(VideoStream(url: fullUrl, quality: quality));
       if (kDebugMode) {
        print('[MPlayerProvider] Found stream: $quality -> $fullUrl');
      }
    });

    return {'streams': videoStreams};
  }

  @override
  Future<List<Movie>> search(String query) async {
    await _init();
    final response = await http.post(
      Uri.parse('$_webApi/search/resultv2?query=$query$_endParam'),
      body: json.encode({}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final searchResult = _SearchResult.fromJson(data);
      final List<Movie> movies = [];
      for (var section in searchResult.sections) {
        for (var item in section.items) {
          movies.add(item.toMovie(_imageUrl));
        }
      }
      return movies;
    } else {
      throw Exception('Failed to search');
    }
  }

  @override
  Future<void> clearCache() async {
    _userID = null;
  }
}

class _MXPlayer {
  final List<_Item> items;

  _MXPlayer({required this.items});

  factory _MXPlayer.fromJson(Map<String, dynamic> json) {
    return _MXPlayer(
      items: (json['items'] as List).map((e) => _Item.fromJson(e)).toList(),
    );
  }
}

class _Item {
  final String title;
  final String type;
  final String id;
  final List<_ImageInfo> imageInfo;
  final _Stream? stream;
  final String description;
  final String? shareUrl;

  _Item(
      {required this.title,
      required this.type,
      required this.id,
      required this.imageInfo,
      this.stream,
      required this.description,
      this.shareUrl});

  factory _Item.fromJson(Map<String, dynamic> json) {
    return _Item(
        title: json['title'],
        type: json['type'],
        id: json['id'],
        imageInfo: (json['imageInfo'] as List)
            .map((e) => _ImageInfo.fromJson(e))
            .toList(),
        stream: json['stream'] != null ? _Stream.fromJson(json['stream']) : null,
        description: json['description'],
        shareUrl: json['shareUrl']);
  }

  Movie toMovie(String imageUrl) {
    _ImageInfo? poster;
    if (imageInfo.isNotEmpty) {
      poster = imageInfo.firstWhere((e) => e.type == 'portrait_large', orElse: () => imageInfo.first);
    }
    
    String posterUrl = "";
    if (poster != null) {
      if (poster.url.startsWith("http")) {
        posterUrl = poster.url;
      } else {
        posterUrl = imageUrl + poster.url;
      }
    }

    if (kDebugMode) {
      print('[MPlayerProvider] Final Poster URL for $title: $posterUrl');
    }

    return Movie(
        id: json.encode(_LoadUrl(
                title: title,
                tvType: type,
                stream: stream,
                description: description,
                shareUrl: shareUrl)
            .toJson()),
        title: title,
        overview: description,
        posterPath: posterUrl,
        backdropPath: "",
        voteAverage: 0,
        provider: 'MPlayer');
  }
}

class _ImageInfo {
  final String type;
  final String url;

  _ImageInfo({required this.type, required this.url});

  factory _ImageInfo.fromJson(Map<String, dynamic> json) {
    return _ImageInfo(
      type: json['type'],
      url: json['url'],
    );
  }
}

class _MovieRoot {
  final List<_MovieItem> items;

  _MovieRoot({required this.items});

  factory _MovieRoot.fromJson(Map<String, dynamic> json) {
    return _MovieRoot(
      items: (json['items'] as List).map((e) => _MovieItem.fromJson(e)).toList(),
    );
  }
}

class _MovieItem {
  final String title;
  final String type;
  final String id;
  final List<_ImageInfo> imageInfo;
  final _Stream? stream;
  final String description;
  final String? shareUrl;

  _MovieItem(
      {required this.title,
      required this.type,
      required this.id,
      required this.imageInfo,
      this.stream,
      required this.description,
      this.shareUrl});

  factory _MovieItem.fromJson(Map<String, dynamic> json) {
    return _MovieItem(
        title: json['title'],
        type: json['type'],
        id: json['id'],
        imageInfo: (json['imageInfo'] as List)
            .map((e) => _ImageInfo.fromJson(e))
            .toList(),
        stream: json['stream'] != null ? _Stream.fromJson(json['stream']) : null,
        description: json['description'],
        shareUrl: json['shareUrl']);
  }

  Movie toMovie(String imageUrl) {
     _ImageInfo? poster;
    if (imageInfo.isNotEmpty) {
      poster = imageInfo.firstWhere((e) => e.type == 'portrait_large', orElse: () => imageInfo.first);
    }
    
    String posterUrl = "";
    if (poster != null) {
      if (poster.url.startsWith("http")) {
        posterUrl = poster.url;
      } else {
        posterUrl = imageUrl + poster.url;
      }
    }

    if (kDebugMode) {
      print('[MPlayerProvider] Final Poster URL for $title: $posterUrl');
    }

    return Movie(
        id: json.encode(_LoadUrl(
                title: title,
                tvType: type,
                stream: stream,
                description: description,
                shareUrl: shareUrl)
            .toJson()),
        title: title,
        overview: description,
        posterPath: posterUrl,
        backdropPath: "",
        voteAverage: 0,
        provider: 'MPlayer');
  }
}

class _SearchResult {
  final List<_Section> sections;

  _SearchResult({required this.sections});

  factory _SearchResult.fromJson(Map<String, dynamic> json) {
    return _SearchResult(
      sections: (json['sections'] as List)
          .map((e) => _Section.fromJson(e))
          .toList(),
    );
  }
}

class _Section {
  final List<_Item> items;

  _Section({required this.items});

  factory _Section.fromJson(Map<String, dynamic> json) {
    return _Section(
      items: (json['items'] as List).map((e) => _Item.fromJson(e)).toList(),
    );
  }
}

class _Stream {
  final _Hls? hls;
  final _Dash? dash;
  final _Mxplay? mxplay;
  final _ThirdParty? thirdParty;

  _Stream({this.hls, this.dash, this.mxplay, this.thirdParty});

  factory _Stream.fromJson(Map<String, dynamic> json) {
    return _Stream(
      hls: json['hls'] != null ? _Hls.fromJson(json['hls']) : null,
      dash: json['dash'] != null ? _Dash.fromJson(json['dash']) : null,
      mxplay: json['mxplay'] != null ? _Mxplay.fromJson(json['mxplay']) : null,
      thirdParty: json['thirdParty'] != null
          ? _ThirdParty.fromJson(json['thirdParty'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'hls': hls?.toJson(),
        'dash': dash?.toJson(),
        'mxplay': mxplay?.toJson(),
        'thirdParty': thirdParty?.toJson(),
      };

  Map<String, String> getAllStreamsWithQuality() {
    final streams = <String, String>{};
    if (hls?.high != null) streams['HLS High'] = hls!.high!;
    if (hls?.base != null) streams['HLS Base'] = hls!.base!;
    if (hls?.main != null) streams['HLS Main'] = hls!.main!;
    if (dash?.high != null) streams['DASH High'] = dash!.high!;
    if (dash?.base != null) streams['DASH Base'] = dash!.base!;
    if (dash?.main != null) streams['DASH Main'] = dash!.main!;
    if (mxplay?.hls?.high != null) streams['MXPlay HLS High'] = mxplay!.hls!.high!;
    if (mxplay?.hls?.base != null) streams['MXPlay HLS Base'] = mxplay!.hls!.base!;
    if (mxplay?.hls?.main != null) streams['MXPlay HLS Main'] = mxplay!.hls!.main!;
    if (mxplay?.dash?.high != null) streams['MXPlay DASH High'] = mxplay!.dash!.high!;
    if (mxplay?.dash?.base != null) streams['MXPlay DASH Base'] = mxplay!.dash!.base!;
    if (mxplay?.dash?.main != null) streams['MXPlay DASH Main'] = mxplay!.dash!.main!;
    if (thirdParty?.hlsUrl != null) streams['Third Party HLS'] = thirdParty!.hlsUrl!;
    if (thirdParty?.dashUrl != null) streams['Third Party DASH'] = thirdParty!.dashUrl!;
    return streams;
  }
}

class _Hls {
  final String? high;
  final String? base;
  final String? main;

  _Hls({this.high, this.base, this.main});

  factory _Hls.fromJson(Map<String, dynamic> json) {
    return _Hls(
      high: json['high'],
      base: json['base'],
      main: json['main'],
    );
  }

  Map<String, dynamic> toJson() => {
        'high': high,
        'base': base,
        'main': main,
      };
}

class _Dash {
  final String? high;
  final String? base;
  final String? main;

  _Dash({this.high, this.base, this.main});

  factory _Dash.fromJson(Map<String, dynamic> json) {
    return _Dash(
      high: json['high'],
      base: json['base'],
      main: json['main'],
    );
  }

  Map<String, dynamic> toJson() => {
        'high': high,
        'base': base,
        'main': main,
      };
}

class _Mxplay {
  final _Hls? hls;
  final _Dash? dash;

  _Mxplay({this.hls, this.dash});

  factory _Mxplay.fromJson(Map<String, dynamic> json) {
    return _Mxplay(
      hls: json['hls'] != null ? _Hls.fromJson(json['hls']) : null,
      dash: json['dash'] != null ? _Dash.fromJson(json['dash']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'hls': hls?.toJson(),
        'dash': dash?.toJson(),
      };
}

class _ThirdParty {
  final String? hlsUrl;
  final String? dashUrl;

  _ThirdParty({this.hlsUrl, this.dashUrl});

  factory _ThirdParty.fromJson(Map<String, dynamic> json) {
    return _ThirdParty(
      hlsUrl: json['hlsUrl'],
      dashUrl: json['dashUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'hlsUrl': hlsUrl,
        'dashUrl': dashUrl,
      };
}

class _LoadUrl {
  final String title;
  final String tvType;
  final _Stream? stream;
  final String description;
  final String? shareUrl;

  _LoadUrl(
      {required this.title,
      required this.tvType,
      this.stream,
      required this.description,
      this.shareUrl});

  factory _LoadUrl.fromJson(Map<String, dynamic> json) {
    return _LoadUrl(
      title: json['title'],
      tvType: json['tvType'],
      stream: json['stream'] != null ? _Stream.fromJson(json['stream']) : null,
      description: json['description'],
      shareUrl: json['shareUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'tvType': tvType,
        'stream': stream?.toJson(),
        'description': description,
        'shareUrl': shareUrl,
      };
}

class _EpisodesParser {
  final List<_EpisodesItem> items;
  final String? next;

  _EpisodesParser({required this.items, this.next});

  factory _EpisodesParser.fromJson(Map<String, dynamic> json) {
    return _EpisodesParser(
      items: (json['items'] as List)
          .map((e) => _EpisodesItem.fromJson(e))
          .toList(),
      next: json['next'],
    );
  }
}

class _EpisodesItem {
  final String? title;
  final _Stream stream;
  final int sequence;
  final List<_ImageInfo> imageInfo;


  _EpisodesItem({this.title, required this.stream, required this.sequence, required this.imageInfo});

  factory _EpisodesItem.fromJson(Map<String, dynamic> json) {
    return _EpisodesItem(
      title: json['title'],
      stream: _Stream.fromJson(json['stream']),
      sequence: json['sequence'],
      imageInfo: (json['imageInfo'] as List)
          .map((e) => _ImageInfo.fromJson(e))
          .toList(),
    );
  }
}

class _SeasonData {
  final int season;
  final String seasonId;

  _SeasonData({required this.season, required this.seasonId});
}
