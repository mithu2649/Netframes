import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/core/services/watchlist_service.dart';
import 'package:netframes/features/library/presentation/bloc/library_bloc.dart';
import 'package:netframes/features/library/presentation/bloc/library_event.dart';
import 'package:netframes/features/library/presentation/bloc/library_state.dart';
import 'package:netframes/features/search/presentation/widgets/search_result_card.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryBloc(
        watchlistService: WatchlistService(),
        movieApiService: MovieApiService(),
      )..add(FetchWatchlist()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, state) {
            if (state is LibraryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is LibraryLoaded) {
              if (state.watchlist.isEmpty) {
                return const Center(child: Text('Your watchlist is empty.'));
              }
              return ListView.builder(
                itemCount: state.watchlist.length,
                itemBuilder: (context, index) {
                  return SearchResultCard(result: state.watchlist[index]);
                },
              );
            } else if (state is LibraryError) {
              return Center(child: Text(state.message));
            }
            return Container();
          },
        ),
      ),
    );
  }
}
