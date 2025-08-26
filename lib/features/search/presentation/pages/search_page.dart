import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:netframes/core/api/movie_api_service.dart';
// import 'package:netframes/features/search/presentation/bloc/search_bloc.dart';
// import 'package:netframes/features/search/presentation/bloc/search_event.dart';
// import 'package:netframes/features/search/presentation/bloc/search_state.dart';
// import 'package:netframes/features/search/presentation/widgets/search_result_card.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: const Center(child: Text('Search Page Loaded')),
    );
  }
}