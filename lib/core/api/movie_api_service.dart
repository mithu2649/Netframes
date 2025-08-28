import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:netframes/core/constants/api_constants.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/movie_details/domain/entities/cast.dart';
import 'package:netframes/features/movie_details/domain/entities/movie_details.dart';
import 'package:netframes/features/search/domain/entities/search_result.dart';
import 'package:netframes/features/tv_shows/domain/entities/episode.dart';
import 'package:netframes/features/tv_shows/domain/entities/season.dart';
import 'package:netframes/features/tv_shows/domain/entities/tv_show.dart';

class MovieApiService {
  Future<List<Movie>> getPopularMovies() async {
    return _getMovies('/movie/popular');
  }

  Future<List<Movie>> getTopRatedMovies() async {
    return _getMovies('/movie/top_rated');
  }

  Future<List<Movie>> getNowPlayingMovies() async {
    return _getMovies('/movie/now_playing');
  }

  Future<List<Movie>> getUpcomingMovies() async {
    return _getMovies('/movie/upcoming');
  }

  Future<List<TvShow>> getPopularTvShows() async {
    return _getTvShows('/tv/popular');
  }

  Future<List<TvShow>> getTopRatedTvShows() async {
    return _getTvShows('/tv/top_rated');
  }

  Future<List<Movie>> getRecommendedMovies(String movieId) async {
    return _getMovies('/movie/$movieId/recommendations');
  }

  Future<List<TvShow>> _getTvShows(String path) async {
    final url = '${ApiConstants.baseUrl}$path?api_key=${ApiConstants.apiKey}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((tvShow) => TvShow(
        id: tvShow['id'],
        name: tvShow['name'],
        overview: tvShow['overview'],
        posterPath: tvShow['poster_path'] ?? '',
        backdropPath: tvShow['backdrop_path'] ?? '',
        voteAverage: tvShow['vote_average'].toDouble(),
      )).toList();
    } else {
      throw Exception('Failed to load TV shows');
    }
  }

  Future<List<Movie>> _getMovies(String path) async {
    final url = '${ApiConstants.baseUrl}$path?api_key=${ApiConstants.apiKey}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((movie) => Movie(
        id: movie['id'].toString(),
        title: movie['title'],
        overview: movie['overview'],
        posterPath: movie['poster_path'] ?? '',
        backdropPath: movie['backdrop_path'] ?? '',
        voteAverage: movie['vote_average'].toDouble(),
      )).toList();
    } else {
      throw Exception('Failed to load movies');
    }
  }

  Future<MovieDetails> getMovieDetails(String movieId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}&append_to_response=credits'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final cast = (data['credits']['cast'] as List).map((cast) => Cast(
        name: cast['name'],
        profilePath: cast['profile_path'] ?? '',
      )).toList();
      return MovieDetails(
        id: data['id'].toString(),
        title: data['title'],
        overview: data['overview'],
        posterPath: data['poster_path'] ?? '',
        backdropPath: data['backdrop_path'] ?? '',
        voteAverage: data['vote_average'].toDouble(),
        cast: cast,
      );
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  Future<TvShow> getTvShowDetails(int tvShowId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/tv/$tvShowId?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Season> seasons = (data['seasons'] as List)
          .map((seasonJson) => Season(
                id: seasonJson['id'],
                name: seasonJson['name'],
                overview: seasonJson['overview'] ?? '',
                posterPath: seasonJson['poster_path'],
                seasonNumber: seasonJson['season_number'],
                episodeCount: seasonJson['episode_count'] ?? 0,
              ))
          .toList();

      return TvShow(
        id: data['id'],
        name: data['name'],
        overview: data['overview'],
        posterPath: data['poster_path'] ?? '',
        backdropPath: data['backdrop_path'] ?? '',
        voteAverage: data['vote_average'].toDouble(),
        seasons: seasons,
      );
    } else {
      throw Exception('Failed to load TV show details');
    }
  }

  Future<Season> getSeasonDetails(int tvShowId, int seasonNumber) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/tv/$tvShowId/season/$seasonNumber?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Episode> episodes = (data['episodes'] as List)
          .map((episodeJson) => Episode(
                id: episodeJson['id'],
                name: episodeJson['name'],
                overview: episodeJson['overview'] ?? '',
                stillPath: episodeJson['still_path'],
                episodeNumber: episodeJson['episode_number'],
                voteAverage: episodeJson['vote_average'].toDouble(),
              ))
          .toList();

      return Season(
        id: data['id'],
        name: data['name'],
        overview: data['overview'] ?? '',
        posterPath: data['poster_path'],
        seasonNumber: data['season_number'],
        episodeCount: data['episodes'].length,
        episodes: episodes,
      );
    } else {
      throw Exception('Failed to load season details');
    }
  }

  Future<List<SearchResult>> searchMulti(String query) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/search/multi?api_key=${ApiConstants.apiKey}&query=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((result) {
        if (result['media_type'] == 'movie') {
          return MovieSearchResult(Movie(
            id: result['id'].toString(),
            title: result['title'],
            overview: result['overview'],
            posterPath: result['poster_path'] ?? '',
            backdropPath: result['backdrop_path'] ?? '',
            voteAverage: result['vote_average'].toDouble(),
            provider: 'TMDB',
          ));
        } else if (result['media_type'] == 'tv') {
          return TvShowSearchResult(TvShow(
            id: result['id'],
            name: result['name'],
            overview: result['overview'],
            posterPath: result['poster_path'] ?? '',
            backdropPath: result['backdrop_path'] ?? '',
            voteAverage: result['vote_average'].toDouble(),
          ));
        }
        return null;
      }).where((element) => element != null).cast<SearchResult>().toList();
    } else {
      throw Exception('Failed to search');
    }
  }
}
