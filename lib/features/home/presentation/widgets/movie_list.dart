import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/presentation/widgets/movie_card.dart';

class MovieList extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const MovieList({super.key, required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 200,
          child: AnimationLimiter(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: MovieCard(
                          movie: movies[index], index: index, categoryTitle: title),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
