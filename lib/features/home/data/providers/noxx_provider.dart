
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:netframes/features/home/data/providers/streaming_provider.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';
import 'package:js_unpack/js_unpack.dart';

class NoxxProvider implements StreamingProvider {
  @override
  String get name => 'NOXX';
  final String _baseUrl = "https://noxx.to";
  String _cookie = "";

  Future<void> _bypassDdosGuard() async {
    if (kDebugMode) {
      print('Bypassing DDoS Guard...');
    }

    try {
      final response = await http.get(Uri.parse("https://check.ddos-guard.net/check.js"));
      if (response.statusCode == 200) {
        final match = RegExp("'(.*?)'",).firstMatch(response.body);
        final ddosBypassPath = match?.group(1);
        if (kDebugMode) {
          print('DDoS Bypass Path: $ddosBypassPath');
        }

        if (ddosBypassPath != null) {
          final url = '$_baseUrl$ddosBypassPath';
          if (kDebugMode) {
            print('DDoS Bypass URL: $url');
          }
          final response = await http.get(Uri.parse(url));
          if (kDebugMode) {
            print('DDoS Bypass Response Status: ${response.statusCode}');
            print('DDoS Bypass Response Headers: ${response.headers}');
          }
          if (response.statusCode == 200) {
            final rawCookie = response.headers['set-cookie'] ?? '';
            final cookieValue = rawCookie.split(';').first;
            _cookie = cookieValue;
            if (kDebugMode) {
              print('DDoS Cookie: $_cookie');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _bypassDdosGuard: $e');
      }
    }
  }

  @override
  Future<void> clearCache() async {
    _cookie = "";
  }

  @override
  Future<Map<String, List<Movie>>> getHomePage() async {
    await _bypassDdosGuard();
    final categories = ["Sci-Fi", "Adventure", "Action", "Comedy", "Fantasy", "Drama"];
    final Map<String, List<Movie>> homePageData = {};

    for (var category in categories) {
      try {
        final url = Uri.parse('$_baseUrl/fetch.php');
        final headers = {'Referer': _baseUrl, 'Cookie': _cookie};
        final body = {
          'no': '0',
          'gpar': category,
          'qpar': '',
          'spar': 'series_added_date desc',
        };

        if (kDebugMode) {
          print('GetHomePage Request URL: $url');
          print('GetHomePage Request Headers: $headers');
        }

        final response = await http.post(
          url,
          headers: headers,
          body: body,
        );

        if (kDebugMode) {
          print('GetHomePage Response Status: ${response.statusCode}');
          print('GetHomePage Response Body: ${response.body}');
        }

        if (response.statusCode == 200) {
          final document = parser.parse(response.body);
          final movieElements = document.querySelectorAll('a.block');
          final movies = <Movie>[];
          for (var movieElement in movieElements) {
            final title = movieElement.querySelector('div > div > span')?.text.trim();
            final href = movieElement.attributes['href'];
            final posterUrl = movieElement.querySelector('img')?.attributes['data-src'];

            if (title != null && href != null) {
              movies.add(
                Movie(
                  id: '$_baseUrl$href',
                  title: title,
                  overview: '',
                  posterPath: posterUrl ?? '',
                  backdropPath: '',
                  voteAverage: 0.0,
                  provider: name,
                ),
              );
            }
          }
          homePageData[category] = movies;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching category $category: $e');
        }
      }
    }
    return homePageData;
  }

  @override
  Future<List<Movie>> search(String query) async {
    await _bypassDdosGuard();
    final response = await http.post(
      Uri.parse('$_baseUrl/livesearch.php'),
      headers: {'Referer': _baseUrl, 'Cookie': _cookie},
      body: {'searchVal': query},
    );

    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      final movieElements = document.querySelectorAll('a[href^="/tv"]');
      final movies = <Movie>[];
      for (var movieElement in movieElements) {
        final title = movieElement.querySelector('div > h2')?.text.trim();
        final href = movieElement.attributes['href'];
        final posterUrl = movieElement.querySelector('img')?.attributes['src'];

        if (title != null && href != null) {
          movies.add(
            Movie(
              id: '$_baseUrl$href',
              title: title,
              overview: '',
              posterPath: posterUrl ?? '',
              backdropPath: '',
              voteAverage: 0.0,
              provider: name,
            ),
          );
        }
      }
      return movies;
    } else {
      throw Exception('Failed to search');
    }
  }

  @override
  Future<NetflixMovieDetails> getMovieDetails(Movie movie) async {
    if (kDebugMode) {
      print('Getting movie details for: ${movie.id}');
    }
    await _bypassDdosGuard();
    try {
      final response = await http.get(Uri.parse(movie.id), headers: {'Referer': _baseUrl, 'Cookie': _cookie});
      if (kDebugMode) {
        print('getMovieDetails Response Status: ${response.statusCode}');
        print('getMovieDetails Response Body: ${response.body}');
      }
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final title = document.querySelector('h1.px-5')?.text.trim() ?? '';
        final poster = document.querySelector('img.relative')?.attributes['src'] ?? '';
        final plot = document.querySelector('p.leading-tight')?.text.trim() ?? '';
        final tags = document.querySelectorAll('div.relative a[class*="py-0.5"]').map((e) => e.text).toList();
        final actors = document.querySelectorAll('div.font-semibold span.text-blue-300').map((e) => e.text).toList();
        final ratingElement = document.querySelector('span.text-xl');
        final rating = ratingElement != null ? (double.parse(ratingElement.text) * 10).toInt() : null;
        final recommendations = document.querySelectorAll('a.block').map((e) {
          final title = e.querySelector('div > div > span')?.text.trim() ?? '';
          final href = e.attributes['href'] ?? '';
          final posterUrl = e.querySelector('img')?.attributes['data-src'] ?? '';
          return Movie(
            id: '$_baseUrl$href',
            title: title,
            overview: '',
            posterPath: posterUrl,
            backdropPath: '',
            voteAverage: 0.0,
            provider: name,
          );
        }).toList();

        final seasons = <NetflixSeason>[];
        final seasonElements = document.querySelectorAll('section.container > div.border-b');
        for (var seasonElement in seasonElements) {
          final seasonNumText = seasonElement.querySelector('button > span')?.text ?? '';
          final seasonNumMatch = RegExp(r'\d+').firstMatch(seasonNumText);
          final seasonNum = seasonNumMatch?.group(0) ?? '1';

          final episodes = <NetflixEpisode>[];
          final episodeElements = seasonElement.querySelectorAll('div.season-list > a');
          for (var episodeElement in episodeElements) {
            final episodeHref = episodeElement.attributes['href'];
            var episodeTitle = episodeElement.text.trim();
            episodeTitle = episodeTitle.replaceAll(RegExp(r'^Now playing:?\s*'), '').trim();
            episodeTitle = episodeTitle.replaceAll(RegExp(r'^Episode\s*\d+:?\s*'), '').trim();
            final episodeNumText = episodeElement.querySelector('span.flex')?.text ?? '';
            final episodeNumMatch = RegExp(r'\d+').firstMatch(episodeNumText);
            final episodeNum = episodeNumMatch?.group(0) ?? '1';

            if (episodeHref != null) {
              episodes.add(NetflixEpisode(
                id: '$_baseUrl$episodeHref',
                title: episodeTitle,
                season: seasonNum,
                episode: episodeNum,
              ));
            }
          }
          seasons.add(NetflixSeason(season: seasonNum, episodes: episodes));
        }

        return NetflixMovieDetails(
          title: title,
          plot: plot,
          year: '', // Not available
          runtime: '', // Not available
          cast: actors,
          genres: tags,
          type: NetflixContentType.tvShow,
          seasons: seasons,
          posterPath: poster,
          rating: rating,
          recommendations: recommendations,
        );
      } else {
        throw Exception('Failed to load movie details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getMovieDetails: $e');
      }
      throw Exception('Failed to load movie details: $e');
    }
  }

@override
Future<Map<String, dynamic>> loadLink(Movie movie, {NetflixEpisode? episode}) async {
  await _bypassDdosGuard();
  if (episode == null) {
    throw Exception('Episode must be provided for Noxx provider');
  }

  final response1 = await http.get(
    Uri.parse(episode.id),
    headers: {'Referer': _baseUrl, 'Cookie': _cookie},
  );
  if (response1.statusCode != 200) {
    throw Exception('Failed to load episode page');
  }

  final doc1 = parser.parse(response1.body);
  final iframeSrc1 = doc1.querySelector('div.h-vw-65 iframe.w-full')?.attributes['src'];
  if (iframeSrc1 == null) throw Exception('Could not find iframe 1');

  final response2 = await http.get(
    Uri.parse(iframeSrc1),
    headers: {'Referer': _baseUrl, 'Cookie': _cookie},
  );
  if (response2.statusCode != 200) throw Exception('Failed to load iframe 1');

  final doc2 = parser.parse(response2.body);
  final iframeSrc2 = doc2.querySelector('iframe')?.attributes['src'];
  if (iframeSrc2 == null) throw Exception('Could not find iframe 2');

  final embedUrl = iframeSrc2.replaceFirst('/download/', '/e/');

  // derive scheme+host for dynamic headers
  final embedUri = Uri.parse(embedUrl);
  final embedOrigin = '${embedUri.scheme}://${embedUri.host}';

  final response3 = await http.get(
    embedUri,
    headers: {
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': embedOrigin,      // dynamic
      'Origin': embedOrigin,       // dynamic
      'Cookie': _cookie,
    },
  );
  if (response3.statusCode != 200) throw Exception('Failed to load embed url');

  // find m3u8 link
  RegExp m3u8Pattern = RegExp(r'file:\s*"([^"]*m3u8[^"]*)"');
  String? m3u8Url = m3u8Pattern.firstMatch(response3.body)?.group(1);

  if (m3u8Url == null) {
    final doc3 = parser.parse(response3.body);
    for (var script in doc3.querySelectorAll('script')) {
      if (script.text.contains('sources')) {
        String content = script.text;
        try {
          if (JsUnpack.detect(content)) {
            final unpacked = JsUnpack(content).unpack();
            m3u8Url = m3u8Pattern.firstMatch(unpacked)?.group(1);
          } else {
            m3u8Url = m3u8Pattern.firstMatch(content)?.group(1);
          }
        } catch (_) {}
        break;
      }
    }
  }

  if (m3u8Url != null) {
    final videoStreams = [
      VideoStream(
        url: m3u8Url,
        quality: 'Unknown',
        headers: {
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.5',
          'Origin': embedOrigin,        // dynamic
          'Connection': 'keep-alive',
          'Referer': embedOrigin,       // dynamic
          'Sec-Fetch-Dest': 'empty',
          'Sec-Fetch-Mode': 'cors',
          'Sec-Fetch-Site': 'cross-site',
        },
        cookies: {},
      ),
    ];
    return {'streams': videoStreams, 'subtitles': []};
  } else {
    throw Exception('Could not find m3u8 url');
  }
}
}