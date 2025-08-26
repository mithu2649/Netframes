import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/features/search/presentation/bloc/search_event.dart';
import 'package:netframes/features/search/presentation/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final MovieApiService movieApiService;

  SearchBloc({required this.movieApiService}) : super(SearchInitial()) {
    on<SearchQueryChanged>((event, emit) async {
      if (event.query.isEmpty) {
        emit(SearchInitial());
        return;
      }
      emit(SearchLoading());
      try {
        final results = await movieApiService.searchMulti(event.query);
        emit(SearchLoaded(results));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });
  }
}
