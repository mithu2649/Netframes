import 'dart:convert';
import 'package:better_player/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:netframes/features/home/data/providers/streaming_provider.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';

class DomainsParser {
  final String? dramadrip;

  DomainsParser({this.dramadrip});

  factory DomainsParser.fromJson(Map<String, dynamic> json) {
    return DomainsParser(dramadrip: json['dramadrip']);
  }
}

class ResponseData {
  final Meta? meta;

  ResponseData({this.meta});

  factory ResponseData.fromJson(Map<String, dynamic> json) {
    return ResponseData(
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

class Meta {
  final String? description;
  final List<String>? cast;
  final String? background;
  final List<Video>? videos;

  Meta({this.description, this.cast, this.background, this.videos});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      description: json['description'],
      cast: json['cast']?.cast<String>(),
      background: json['background'],
      videos: (json['videos'] as List<dynamic>?)
          ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Video {
  final int? season;
  final int? episode;
  final String? name;
  final String? thumbnail;
  final String? overview;

  Video({this.season, this.episode, this.name, this.thumbnail, this.overview});

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      season: json['season'],
      episode: json['episode'],
      name: json['name'],
      thumbnail: json['thumbnail'],
      overview: json['overview'],
    );
  }
}

class DramaDripProvider implements StreamingProvider {
  @override
  String get name => 'DramaDrip';
  String _baseUrl = "https://dramadrip.com";
  final String _cinemetaUrl = "https://v3-cinemeta.strem.io/meta";
  static const String _domainsUrl =
      "https://raw.githubusercontent.com/phisher98/TVVVV/refs/heads/main/domains.json";
  static DomainsParser? _cachedDomains;

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
  };

  Future<void> _updateDomain() async {
    if (_cachedDomains == null) {
      try {
        final response = await http.get(Uri.parse(_domainsUrl));
        if (response.statusCode == 200) {
          _cachedDomains = DomainsParser.fromJson(jsonDecode(response.body));
          if (_cachedDomains?.dramadrip != null) {
            _baseUrl = _cachedDomains!.dramadrip!;
          }
        }
      } catch (e) {
        // ignore
      }
    } else {
      if (_cachedDomains?.dramadrip != null) {
        _baseUrl = _cachedDomains!.dramadrip!;
      }
    }
  }

  @override
  Future<void> clearCache() async {
    return;
  }

  Movie? _toMovie(Element element) {
    try {
      final titleElement = element.querySelector("h2.entry-title > a");
      final title = titleElement?.text.replaceFirst("Download", "").trim();
      final href = titleElement?.attributes['href'];
      final imgElement = element.querySelector("img");
      final srcset = imgElement?.attributes["srcset"];

      String? posterUrl;
      if (srcset != null && srcset.isNotEmpty) {
        posterUrl = srcset
            .split(",\n")
            .map((e) => e.trim().split(" ").first)
            .last;
      } else {
        posterUrl = imgElement?.attributes["src"];
      }

      if (title != null &&
          title.isNotEmpty &&
          href != null &&
          href.isNotEmpty) {
        return Movie(
          id: href,
          title: title,
          posterPath: posterUrl ?? '',
          provider: 'DramaDrip',
          overview: '',
          backdropPath: '',
          voteAverage: 0.0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, List<Movie>>> getHomePage() async {
    await _updateDomain();
    final Map<String, String> categories = {
      "Ongoing Dramas": "drama/ongoing",
      "Latest Releases": "latest",
      "Chinese Dramas": "drama/chinese-drama",
      "Korean Dramas": "drama/korean-drama",
      "Movies": "movies",
    };
    final Map<String, List<Movie>> homePageData = {};

    for (var category in categories.entries) {
      final url = '$_baseUrl/${category.value}';
      try {
        final response = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final document = parser.parse(response.body);
          final movieElements = document.querySelectorAll("article");
          final movies = movieElements
              .map(_toMovie)
              .whereType<Movie>()
              .toList();
          homePageData[category.key] = movies;
        }
      } catch (e) {
        // Ignore
      }
    }
    return homePageData;
  }

  @override
  Future<List<Movie>> search(String query) async {
    await _updateDomain();
    final url = '$_baseUrl/?s=${Uri.encodeComponent(query)}';
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final movieElements = document.querySelectorAll("article");
        return movieElements.map(_toMovie).whereType<Movie>().toList();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  @override
  Future<NetflixMovieDetails> getMovieDetails(Movie movie) async {
    await _updateDomain();
    final url = movie.id;
    final response = await http.get(Uri.parse(url), headers: _headers);
    final document = parser.parse(response.body);

    String? imdbId;
    String? tmdbId;
    String? tmdbType;

    document
        .querySelectorAll("div.su-spoiler-content ul.wp-block-list > li")
        .forEach((li) {
          final text = li.text;
          if (imdbId == null && text.contains("imdb.com/title/tt")) {
            imdbId = RegExp(r'tt\d+').firstMatch(text)?.group(0);
          }

          if (tmdbId == null &&
              tmdbType == null &&
              text.contains("themoviedb.org")) {
            final match = RegExp(r'/(movie|tv)/(\d+)').firstMatch(text);
            if (match != null) {
              tmdbType = match.group(1);
              tmdbId = match.group(2);
            }
          }
        });

    final tvType = (tmdbType?.toLowerCase().contains("movie") == true)
        ? NetflixContentType.movie
        : NetflixContentType.tvShow;

    final image =
        document
            .querySelector("meta[property='og:image']")
            ?.attributes['content'] ??
        '';
    final title =
        document
            .querySelector("div.wp-block-column > h2.wp-block-heading")
            ?.text
            .split("(")
            .first
            .trim() ??
        movie.title;
    final tags = document
        .querySelectorAll("div.mt-2 span.badge")
        .map((e) => e.text)
        .toList();
    final year =
        document
                .querySelector("div.wp-block-column > h2.wp-block-heading")
                ?.text
                .contains("(") ==
            true
        ? document
              .querySelector("div.wp-block-column > h2.wp-block-heading")!
              .text
              .split("(")[1]
              .replaceAll(")", "")
              .trim()
        : '';
    final descriptions =
        document.querySelector("div.content-section p.mt-4")?.text.trim() ?? '';
    final typeset = tvType == NetflixContentType.tvShow ? "series" : "movie";

    ResponseData? responseData;
    if (imdbId != null && imdbId!.isNotEmpty) {
      final jsonResponse = await http.get(
        Uri.parse("$_cinemetaUrl/$typeset/$imdbId.json"),
      );
      if (jsonResponse.statusCode == 200 &&
          jsonResponse.body.isNotEmpty &&
          jsonResponse.body.startsWith("{")) {
        responseData = ResponseData.fromJson(jsonDecode(jsonResponse.body));
      }
    }

    final description = responseData?.meta?.description ?? descriptions;
    final cast = responseData?.meta?.cast ?? [];
    final background = responseData?.meta?.background ?? image;

    final trailer = document
        .querySelector("div.wp-block-embed__wrapper > iframe")
        ?.attributes['src'];

    final recommendations = document
        .querySelectorAll("div.entry-related-inner-content article")
        .map((it) {
          final recName = it.querySelector("h3")?.text.substring(8);
          final recHref = it.querySelector("h3 a")?.attributes['href'];
          final recPosterUrl = it.querySelector("img")?.attributes['src'];
          if (recName != null && recHref != null) {
            return Movie(
              id: recHref,
              title: recName,
              posterPath: recPosterUrl ?? '',
              provider: 'DramaDrip',
              overview: '',
              backdropPath: '',
              voteAverage: 0.0,
            );
          }
          return null;
        })
        .whereType<Movie>()
        .toList();

    if (tvType == NetflixContentType.tvShow) {
      final Map<int, Map<int, List<String>>> episodesBySeason = {};
      final seasonBlocks = document.querySelectorAll("div.su-accordion h2");

      for (var seasonHeader in seasonBlocks) {
        final seasonText = seasonHeader.text;
        if (seasonText.toLowerCase().contains("zip")) continue;

        final seasonMatch = RegExp(
          r'S?e?a?s?o?n?\s*([0-9]+)',
          caseSensitive: false,
        ).firstMatch(seasonText);
        final seasonNum = int.tryParse(seasonMatch?.group(1) ?? '');

        if (seasonNum != null) {
          var linksBlock = seasonHeader.nextElementSibling;
          if (linksBlock == null ||
              linksBlock.querySelectorAll("div.wp-block-button").isEmpty) {
            linksBlock = seasonHeader.parent?.querySelector(
              "div.wp-block-button",
            );
          }

          final qualityLinks =
              linksBlock
                  ?.querySelectorAll("a")
                  .map((e) => e.attributes['href'])
                  .whereType<String>()
                  .where((href) => href != "#")
                  .toList() ??
              [];

          for (var qualityLink in qualityLinks) {
            try {
              final qualityResponse = await http.get(
                Uri.parse(qualityLink),
                headers: _headers,
              );
              final episodeDoc = parser.parse(qualityResponse.body);
              final episodeButtons = episodeDoc
                  .querySelectorAll("a")
                  .where(
                    (el) => RegExp(
                      r'(Episode|Ep|E)?\s*0*([0-9]+)',
                      caseSensitive: false,
                    ).hasMatch(el.text),
                  );

              for (var btn in episodeButtons) {
                final epHref = btn.attributes['href'];
                final epText = btn.text;
                final epMatch = RegExp(
                  r'(?:Episode|Ep|E)?\s*0*([0-9]+)',
                  caseSensitive: false,
                ).firstMatch(epText);
                final epNum = int.tryParse(epMatch?.group(1) ?? '');

                if (epNum != null &&
                    epHref != null &&
                    epHref.isNotEmpty &&
                    epHref != "#") {
                  episodesBySeason.putIfAbsent(seasonNum, () => {});
                  episodesBySeason[seasonNum]!.putIfAbsent(epNum, () => []);
                  if (!episodesBySeason[seasonNum]![epNum]!.contains(epHref)) {
                    episodesBySeason[seasonNum]![epNum]!.add(epHref);
                  }
                }
              }
            } catch (e) {
              // ignore
            }
          }
        }
      }

      final seasons = <NetflixSeason>[];
      episodesBySeason.forEach((seasonNum, episodesMap) {
        final episodes = <NetflixEpisode>[];
        episodesMap.forEach((epNum, links) {
          final info = responseData?.meta?.videos?.firstWhere(
            (v) => v.season == seasonNum && v.episode == epNum,
            orElse: () => Video(),
          );
          episodes.add(
            NetflixEpisode(
              id: jsonEncode(links.toSet().toList()),
              title: info?.name ?? 'Episode $epNum',
              season: seasonNum.toString(),
              episode: epNum.toString(),
              thumbnail: info?.thumbnail,
              description: info?.overview,
            ),
          );
        });
        episodes.sort(
          (a, b) => int.parse(a.episode).compareTo(int.parse(b.episode)),
        );
        seasons.add(
          NetflixSeason(season: seasonNum.toString(), episodes: episodes),
        );
      });
      seasons.sort(
        (a, b) => int.parse(a.season).compareTo(int.parse(b.season)),
      );

      return NetflixMovieDetails(
        title: title,
        plot: description,
        year: year,
        cast: cast,
        genres: tags,
        runtime: '',
        type: tvType,
        seasons: seasons,
        trailer: trailer,
        recommendations: recommendations,
        backdropPath: background,
      );
    } else {
      List<String> movieLinks = [];
      final initialLinks = document.querySelectorAll("div.wp-block-button > a");
      for (var linkElement in initialLinks) {
        final link = linkElement.attributes['href'];
        if (link != null && link != "#") {
          try {
            final pageRes = await http.get(Uri.parse(link), headers: _headers);
            final pageDoc = parser.parse(pageRes.body);
            final finalLinks = pageDoc
                .querySelectorAll("div.wp-block-button.movie_btn a")
                .map((e) => e.attributes['href'])
                .whereType<String>()
                .where((href) => href != "#");
            movieLinks.addAll(finalLinks);
          } catch (e) {
            // ignore
          }
        }
      }

      final seasons = <NetflixSeason>[];
      if (movieLinks.isNotEmpty) {
        seasons.add(
          NetflixSeason(
            season: "1",
            episodes: [
              NetflixEpisode(
                id: jsonEncode(movieLinks),
                title: title,
                season: "1",
                episode: "1",
              ),
            ],
          ),
        );
      }

      return NetflixMovieDetails(
        title: title,
        plot: description,
        year: year,
        cast: cast,
        genres: tags,
        runtime: '',
        type: tvType,
        seasons: seasons,
        trailer: trailer,
        recommendations: recommendations,
        backdropPath: background,
      );
    }
  }

  String _base64Decode(String input) {
    String clean = input.trim().replaceAll("\n", "").replaceAll("\r", "");
    String padded = clean.padRight((clean.length + 3) ~/ 4 * 4, '=');
    return utf8.decode(base64.decode(padded));
  }

  Future<String?> _cinematickitBypass(String url) async {
    try {
      final cleanedUrl = url.replaceAll("&#038;", "&");
      final encodedLink = cleanedUrl.split("safelink=").last.split("-").first;
      if (encodedLink.isEmpty) return null;

      final decodedUrl = _base64Decode(encodedLink);
      final docRes = await http
          .get(Uri.parse(decodedUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));
      final doc = parser.parse(docRes.body);
      final goValue = doc
          .querySelector("form#landing input[name=go]")
          ?.attributes['value'];
      if (goValue == null || goValue.isEmpty) return null;

      final decodedGoUrl = _base64Decode(goValue).replaceAll("&#038;", "&");
      final responseDocRes = await http
          .get(Uri.parse(decodedGoUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));
      final responseDoc = parser.parse(responseDocRes.body);
      final script = responseDoc
          .querySelectorAll("script")
          .firstWhere((s) => s.innerHtml.contains("window.location.replace"))
          .innerHtml;
      final redirectPath = RegExp(
        r'window\.location\.replace\s*\(\s*["\\](.+?)["\\]\s*\)\s*;?',
      ).firstMatch(script)?.group(1);

      if (redirectPath == null) return null;
      if (redirectPath.startsWith("http")) return redirectPath;

      final uri = Uri.parse(decodedGoUrl);
      return '${uri.scheme}://${uri.host}$redirectPath';
    } catch (e) {
      return null;
    }
  }

  Future<List<VideoStream>> _driveseedExtractor(String url) async {
    final streams = <VideoStream>[];
    try {
      if (kDebugMode) {
        print("Driveseed extractor called for url: $url");
      }
      final response = await http.get(Uri.parse(url), headers: _headers);
      final document = parser.parse(response.body);

      final qualityText =
          document.querySelector("li.list-group-item")?.text ?? '';
      final quality =
          RegExp(r'(\d{3,4})[pP]').firstMatch(qualityText)?.group(1) ?? '720p';

      final links = document.querySelectorAll("div.text-center > a");
      if (kDebugMode) {
        print("Found ${links.length} links in driveseed page");
      }
      for (var link in links) {
        final href = link.attributes['href'];
        final text = link.text;
        if (kDebugMode) {
          print("Processing driveseed link: $href, text: $text");
        }
        if (href != null && href.isNotEmpty) {
          if (text.toLowerCase().contains("direct links")) {
            final directStreams = await _cfType1(href, quality);
            if (kDebugMode) {
              print("Found ${directStreams.length} direct links");
            }
            streams.addAll(directStreams);
          } else if (text.toLowerCase().contains("resume cloud")) {
            final streamUrl = await _resumeCloudLink(url, href);
            if (streamUrl != null) {
              if (kDebugMode) {
                print("Found resume cloud link: $streamUrl");
              }
              streams.add(
                VideoStream(
                  url: streamUrl,
                  quality: "Resume Cloud - $quality",
                  headers: _headers,
                ),
              );
            }
          } else if (text.toLowerCase().contains("instant download")) {
            final uri = Uri.parse(href);
            final host = uri.host;
            final token = href.split("url=").last;
            final apiResponse = await http.post(
              Uri.parse('https://$host/api'),
              body: {'keys': token},
              headers: {'x-token': host, ..._headers},
            );
            final streamUrl = jsonDecode(
              apiResponse.body,
            )['url'].toString().replaceAll("/", "/");
            if (kDebugMode) {
              print("Found instant download link: $streamUrl");
            }
            streams.add(
              VideoStream(url: streamUrl, quality: quality, headers: _headers),
            );
          } else if (text.toLowerCase().contains("resume worker bot")) {
            final botResponse = await http.get(
              Uri.parse(href),
              headers: _headers,
            );
            final docString = botResponse.body;
            final ssid = botResponse.headers['set-cookie'] ?? '';
            final token =
                RegExp(
                  r"formData\.append\('token',\s*'([a-f0-9]+)'\)",
                ).firstMatch(docString)?.group(1) ??
                '';
            final path =
                RegExp(
                  r"fetch\('\/download\?id=([a-zA-Z0-9\/+=]+)'")
                    .firstMatch(docString)?.group(1) ??
                '';
            final baseUrl = href.split("/download")[0];

            if (token.isNotEmpty && path.isNotEmpty) {
              final apiResponse = await http.post(
                Uri.parse('$baseUrl/download?id=$path'),
                body: {'token': token},
                headers: {
                  'Accept': '*/*',
                  'Origin': baseUrl,
                  'Sec-Fetch-Site': 'same-origin',
                  'Cookie': ssid,
                  ..._headers,
                },
              );
              final streamUrl = jsonDecode(
                apiResponse.body,
              )['url'].toString().replaceAll("/", "/");
              if (kDebugMode) {
                print("Found resume worker bot link: $streamUrl");
              }
              streams.add(
                VideoStream(
                  url: streamUrl,
                  quality: "Resume Worker Bot - $quality",
                  headers: {'Cookie': ssid, ..._headers},
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in driveseed extractor: $e");
      }
    }
    if (kDebugMode) {
      print("Driveseed extractor finished, found ${streams.length} streams");
    }
    return streams;
  }

  Future<List<VideoStream>> _cfType1(String url, String quality) async {
    final streams = <VideoStream>[];
    try {
      final response = await http.get(
        Uri.parse("$url?type=1"),
        headers: _headers,
      );
      final document = parser.parse(response.body);
      final links = document.querySelectorAll("a.btn-success");
      for (var link in links) {
        final href = link.attributes['href'];
        if (href != null && href.startsWith("http")) {
          streams.add(
            VideoStream(
              url: href,
              quality: "Direct Link - $quality",
              headers: _headers,
            ),
          );
        }
      }
    } catch (e) {
      // ignore
    }
    return streams;
  }

  Future<String?> _resumeCloudLink(String baseUrl, String path) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl + path),
        headers: _headers,
      );
      final document = parser.parse(response.body);
      return document.querySelector("a.btn-success")?.attributes['href'];
    } catch (e) {
      return null;
    }
  }

  Future<String?> _bypassHrefli(String url) async {
    try {
      var res = await http.get(Uri.parse(url), headers: _headers);
      var doc = parser.parse(res.body);
      var form = doc.querySelector("form#landing");
      var formUrl = form?.attributes['action'];
      var formData = <String, String>{};
      form?.querySelectorAll("input").forEach((input) {
        final name = input.attributes['name'];
        final value = input.attributes['value'];
        if (name != null && value != null) {
          formData[name] = value;
        }
      });

      if (formUrl == null) return null;

      res = await http.post(
        Uri.parse(formUrl),
        headers: _headers,
        body: formData,
      );
      doc = parser.parse(res.body);
      form = doc.querySelector("form#landing");
      formUrl = form?.attributes['action'];
      formData = <String, String>{};
      form?.querySelectorAll("input").forEach((input) {
        final name = input.attributes['name'];
        final value = input.attributes['value'];
        if (name != null && value != null) {
          formData[name] = value;
        }
      });

      if (formUrl == null) return null;

      res = await http.post(
        Uri.parse(formUrl),
        headers: _headers,
        body: formData,
      );
      doc = parser.parse(res.body);
      final skTokenScript = doc
          .querySelectorAll("script")
          .firstWhere((script) => script.innerHtml.contains("?go="));
      final skToken = skTokenScript.innerHtml.split("?go=")[1].split('"')[0];

      final host = Uri.parse(url).host;
      final driveUrlRes = await http.get(
        Uri.parse("https://$host?go=$skToken"),
        headers: {..._headers, 'Cookie': '$skToken=${formData["_wp_http2"]}'},
      );
      final driveUrl = parser
          .parse(driveUrlRes.body)
          .querySelector("meta[http-equiv=refresh]")
          ?.attributes['content']
          ?.split("url=")[1];

      if (driveUrl == null) return null;

      final pathRes = await http.get(Uri.parse(driveUrl));
      final path = pathRes.body.split('replace("')[1].split('"_blank")')[0];

      if (path == "/404") return null;

      final driveUri = Uri.parse(driveUrl);
      return '${driveUri.scheme}://${driveUri.host}$path';
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> loadLink(
    Movie movie,
    {
    NetflixEpisode? episode,
  } ) async {
    if (episode == null) return {};

    final List<String> links = List<String>.from(jsonDecode(episode.id));
    final streams = <VideoStream>[];

    for (var link in links) {
      try {
        if (kDebugMode) {
          print("Processing link: $link");
        }
        String? finalLink;
        if (link.contains("safelink=")) {
          finalLink = await _cinematickitBypass(link);
        } else if (link.contains("unblockedgames")) {
          finalLink = await _bypassHrefli(link);
        } else {
          finalLink = link;
        }

        if (kDebugMode) {
          print("Final link: $finalLink");
        }

        if (finalLink != null) {
          if (finalLink.startsWith("https://driveseed.org")) {
            final driveseedStreams = await _driveseedExtractor(finalLink);
            streams.addAll(driveseedStreams);
          } else {
            // Assume it's a direct link
            streams.add(
              VideoStream(url: finalLink, quality: "720p", headers: _headers),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to load link $link: $e");
        }
      }
    }

    if (streams.isNotEmpty) {
      return {'streams': streams, 'subtitles': <BetterPlayerSubtitlesSource>[]};
    }

    return {}; // Return empty if no links succeed
  }
}
