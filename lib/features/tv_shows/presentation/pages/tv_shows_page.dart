import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:netframes/core/api/movie_api_service.dart'; // No longer needed here
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_bloc.dart';
// import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_event.dart'; // No longer needed here
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_state.dart';
import 'package:netframes/features/tv_shows/presentation/widgets/tv_show_list.dart';

class TvShowsPage extends StatelessWidget {
  const TvShowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TvShowsBloc, TvShowsState>(
        builder: (context, state) {
          if (state is TvShowsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TvShowsLoaded) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvShowList(
                    title: 'Popular TV Shows',
                    tvShows: state.popularTvShows,
                  ),
                  TvShowList(
                    title: 'Top Rated TV Shows',
                    tvShows: state.topRatedTvShows,
                  ),
                ],
              ),
            );
          } else if (state is TvShowsError) {
            return Center(child: Text(state.message));
          }
          return Container();
        },
      ),
    );
  }
}
