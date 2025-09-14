import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:netframes/features/home/data/providers/js_unpacker.dart';
import 'package:netframes/features/home/data/providers/streaming_provider.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';

class BollyzoneProvider implements StreamingProvider {
  @override
  String get name => 'Bollyzone';

  final String _mainUrl = "https://www.bollyzone.to";
  final String _proxy = "https://desicinemas.phisherdesicinema.workers.dev/";

  @override
  Future<Map<String, List<Movie>>> getHomePage() async {
    final url = '$_proxy?url=$_mainUrl/tv-channels/';
    final response = await http.get(Uri.parse(url), headers: {'Referer': '$_mainUrl/'});
    final doc = parser.parse(response.body);

    final Map<String, List<Movie>> homePageData = {};

    final headers = doc.querySelectorAll('h2.Title').where((it) => it.text.contains('Shows'));

    for (var header in headers) {
      final sectionName = header.querySelector('a')?.text.trim();
      if (sectionName == null) continue;

      var movieListDiv = header.nextElementSibling;
      while (movieListDiv != null &&
          !(movieListDiv.localName == 'div' && movieListDiv.classes.contains('MovieListTop'))) {
        movieListDiv = movieListDiv.nextElementSibling;
      }

      if (movieListDiv != null) {
        final movies = _toHomePageList(movieListDiv);
        homePageData[sectionName] = movies;
      }
    }

    return homePageData;
  }

  List<Movie> _toHomePageList(dom.Element element) {
    return element
        .querySelectorAll('div.TPostMv')
        .map((e) => _toHomePageResult(e))
        .where((e) => e != null)
        .cast<Movie>()
        .toList();
  }

  Movie? _toHomePageResult(dom.Element element) {
    final title = element.querySelector('h2.Title')?.text.trim();
    final href = element.querySelector('a')?.attributes['href'];
    if (title == null || href == null) return null;

    final img = element.querySelector('img');
    final posterUrl = _getImageAttr(img);

    return Movie(
      id: href,
      title: title,
      posterPath: posterUrl ?? '',
      provider: name,
      overview: '',
      backdropPath: '',
      voteAverage: 0.0,
    );
  }

  String? _getImageAttr(dom.Element? element) {
    if (element == null) return null;
    String? src;
    if (element.attributes.containsKey('data-src')) {
      src = element.attributes['data-src'];
    } else if (element.attributes.containsKey('src')) {
      src = element.attributes['src'];
    }
    if (src != null) {
      if (src.startsWith('http')) {
        return '$_proxy?url=$src';
      } else {
        return '$_proxy?url=$_mainUrl$src';
      }
    }
    return null;
  }

  @override
  Future<NetflixMovieDetails> getMovieDetails(Movie movie) async {
    final url = "$_proxy?url=${movie.id}";
    final response = await http.get(Uri.parse(url), headers: {'Referer': _mainUrl});
    final doc = parser.parse(response.body);

    if (movie.id.contains("/series/")) {
      final title = doc.querySelector('h1')?.text.trim() ?? '';
      final posterUrl = _getImageAttr(doc.querySelector('.Image img'));
      final plot = doc.querySelector('.Description p')?.text;
      final tags = doc.querySelectorAll('.Genre a').map((e) => e.text).toList();

      return NetflixMovieDetails(
        title: title,
        plot: plot ?? '',
        genres: tags,
        type: NetflixContentType.movie,
        seasons: [
          NetflixSeason(season: '1', episodes: [
            NetflixEpisode(id: movie.id, title: title, season: '1', episode: '1', thumbnail: posterUrl)
          ])
        ],
      );
    }

    String title = '';
    for (var metaTag in doc.querySelectorAll('meta')) {
      if (metaTag.attributes['property'] == 'og:title') {
        title = metaTag.attributes['content'] ?? '';
        break;
      }
    }
    final posterUrl = _getImageAttr(doc.querySelector("div.Image img"));
    String description = '';
    for (var metaTag in doc.querySelectorAll('meta')) {
      if (metaTag.attributes['property'] == 'og:description') {
        description = metaTag.attributes['content'] ?? '';
        break;
      }
    }
    final tags = doc.querySelectorAll(".Genre a").map((e) => e.text).toList();

    final lastPageNumber = doc
            .querySelectorAll("section > nav > div > a")
            .map((e) => int.tryParse(e.text) ?? 0)
            .fold(0, (max, e) => e > max ? e : max);
    
    final episodes = <NetflixEpisode>[];
    for (var page = 1; page <= lastPageNumber; page++) {
      final pageUrl = "$_proxy?url=${movie.id}/page/$page/";
      final pageResponse = await http.get(Uri.parse(pageUrl), headers: {'Referer': _mainUrl});
      final pageDoc = parser.parse(pageResponse.body);

      final episodeElements = pageDoc.querySelectorAll("ul.MovieList li");
      for (var element in episodeElements) {
        final epUrl = element.querySelector("a")?.attributes['href'];
        if (epUrl == null) continue;

        final titleText = element.querySelector("a h2")?.text.trim();
        final epName = titleText ?? "Episode";
        final epPoster = _getImageAttr(element.querySelector("img"));

        episodes.add(NetflixEpisode(
          id: epUrl,
          title: epName,
          thumbnail: epPoster,
          season: '1',
          episode: (episodes.length + 1).toString(),
        ));
      }
    }

    return NetflixMovieDetails(
      title: title,
      plot: description,
      genres: tags,
      type: NetflixContentType.tvShow,
      seasons: [NetflixSeason(season: '1', episodes: episodes)],
      backdropPath: posterUrl,
    );
  }

  @override
  Future<Map<String, dynamic>> loadLink(Movie movie, {NetflixEpisode? episode}) async {
    final url = "$_proxy?url=${episode?.id ?? movie.id}";
    final response = await http.get(Uri.parse(url), headers: {'Referer': _mainUrl});
    final doc = parser.parse(response.body);

    final List<VideoStream> streams = [];

    final links = doc.querySelectorAll(".MovieList .OptionBx");
    for (var link in links) {
      final name = link.querySelector("p.AAIco-dns")?.text;
      final href = link.querySelector("a")?.attributes['href'];
      if (name != null && href != null) {
        final headers = {
          "referer": _mainUrl,
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Accept-Language": "en-US,en;q=0.5",
          "Connection": "keep-alive",
          "Cache-Control": "no-cache"
        };
        final srcResponse = await http.get(Uri.parse(href), headers: headers);
        final srcDoc = parser.parse(srcResponse.body);
        final iframe = srcDoc.querySelector("iframe")?.attributes['src'];
        if (iframe != null) {
          final tvlogyUrl = "https://proxy.phisher2.workers.dev/?url=$iframe";
          final tvlogyResponse = await http.get(Uri.parse(tvlogyUrl), headers: {'Referer': 'https://flow.tvlogy.to'});
          final tvlogyBody = tvlogyResponse.body;

          if (tvlogyBody.contains('.m3u8')) {
            final RegExp regex = RegExp(r'"src":"(.*?)"');
            final match = regex.firstMatch(tvlogyBody);
            if (match != null) {
              final streamUrl = match.group(1);
              if (streamUrl != null) {
                final streamHeaders = {
                  'Referer': iframe,
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0'
                };
                streams.add(VideoStream(url: streamUrl, quality: name, headers: streamHeaders));
              }
            }
          } else {
            final juicyCodesPrefix = 'JuicyCodes.Run("';
            final juicyCodesSuffix = '");';
            final startIndex = tvlogyBody.indexOf(juicyCodesPrefix);
            if (startIndex != -1) {
              final endIndex = tvlogyBody.indexOf(juicyCodesSuffix, startIndex + juicyCodesPrefix.length);
              if (endIndex != -1) {
                var encoded = tvlogyBody.substring(startIndex + juicyCodesPrefix.length, endIndex);
                encoded = encoded.replaceAll('"', '').replaceAll('+', '').replaceAll(RegExp(r'\s'), '');
                
                if (encoded.length % 4 > 0) {
                  encoded += '=' * (4 - encoded.length % 4);
                }

                try {
                  final decodedScript = utf8.decode(base64.decode(encoded));
                  final unpackedScript = JsUnpacker(decodedScript).unpack();

                  if (unpackedScript != null) {
                    final fileRegex = RegExp(r'file":"(.*?)"');
                    final match = fileRegex.firstMatch(unpackedScript);
                    if (match != null) {
                      final streamUrl = match.group(1);
                      if (streamUrl != null) {
                        final streamHeaders = {
                          'Referer': iframe,
                          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0'
                        };
                        streams.add(VideoStream(url: streamUrl, quality: name, headers: streamHeaders));
                      }
                    }
                  }
                } catch (e) {
                  print("Error unpacking script: $e");
                }
              }
            }
          }
        }
      }
    }

    return {'streams': streams};
  }

  @override
  Future<List<Movie>> search(String query) async {
    final url = "$_proxy?url=$_mainUrl/?s=$query";
    final response = await http.get(Uri.parse(url), headers: {'Referer': _mainUrl});
    final doc = parser.parse(response.body);

    return doc
        .querySelectorAll(".MovieList li")
        .map((e) => _toHomePageResult(e))
        .where((e) => e != null)
        .cast<Movie>()
        .toList();
  }

  @override
  Future<void> clearCache() async {
    // No cache to clear
  }
}