import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/domain/entities/netflix_movie_details.dart';

abstract class StreamingProvider {
  Future<Map<String, List<Movie>>> getHomePage();
  Future<NetflixMovieDetails> getMovieDetails(Movie movie);
  Future<Map<String, dynamic>> loadLink(Movie movie);
  Future<List<Movie>> search(String query);
  Future<void> clearCache();
}
