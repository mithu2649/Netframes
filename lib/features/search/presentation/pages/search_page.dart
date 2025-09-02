import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netframes/features/home/data/providers/dramadrip_provider.dart';
import 'package:netframes/features/home/data/providers/jio_hotstar_provider.dart';
import 'package:netframes/features/home/data/providers/m_player_provider.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/home/data/providers/prime_video_provider.dart';
import 'package:netframes/features/home/data/providers/streaming_provider.dart';
import 'package:netframes/features/home/domain/entities/movie.dart';
import 'package:netframes/features/home/presentation/widgets/movie_card.dart';
import 'package:netframes/features/movie_details/presentation/pages/streaming_movie_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<StreamingProvider> _providers = [
    DramaDripProvider(),
    JioHotstarProvider(),
    MPlayerProvider(),
    NetflixMirrorProvider(),
    PrimeVideoProvider(),
  ];

  Map<String, List<Movie>> _searchResults = {};
  Map<String, bool> _loadingStatus = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(_searchController.text);
    });
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = {};
        _loadingStatus = {};
      });
      return;
    }

    setState(() {
      _loadingStatus = Map.fromEntries(_providers.map((p) => MapEntry(p.name, true)));
      _searchResults = {};
    });

    for (final provider in _providers) {
      provider.search(query).then((results) {
        setState(() {
          _loadingStatus[provider.name] = false;
          if (results.isNotEmpty) {
            _searchResults[provider.name] = results;
          }
        });
      }).catchError((error) {
        setState(() {
          _loadingStatus[provider.name] = false;
        });
        // Handle error if needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search movies & TV shows...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('Start typing to search'));
    }

    if (_loadingStatus.values.every((isLoading) => !isLoading) && _searchResults.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView(
      children: _providers.map((provider) {
        final providerName = provider.name;
        final isLoading = _loadingStatus[providerName] ?? false;
        final results = _searchResults[providerName];

        if (isLoading) {
          return _buildLoadingIndicator(providerName);
        }

        if (results != null && results.isNotEmpty) {
          return _buildProviderResults(providerName, results);
        }

        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildLoadingIndicator(String providerName) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(providerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderResults(String providerName, List<Movie> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(providerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final movie = results[index];
              return MovieCard(movie: movie, index: index, categoryTitle: providerName);
            },
          ),
        ),
      ],
    );
  }
}