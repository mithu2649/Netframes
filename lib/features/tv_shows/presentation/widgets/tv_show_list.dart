import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:netframes/features/tv_shows/domain/entities/tv_show.dart';
import 'package:netframes/features/tv_shows/presentation/widgets/tv_show_card.dart';

class TvShowList extends StatelessWidget {
  final String title;
  final List<TvShow> tvShows;

  const TvShowList({super.key, required this.title, required this.tvShows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(
          height: 200,
          child: AnimationLimiter(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tvShows.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: TvShowCard(tvShow: tvShows[index]),
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
