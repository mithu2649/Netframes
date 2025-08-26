import 'package:equatable/equatable.dart';
import 'package:netframes/features/search/domain/entities/search_result.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object> get props => [];
}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<SearchResult> watchlist;

  const LibraryLoaded(this.watchlist);

  @override
  List<Object> get props => [watchlist];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object> get props => [message];
}
