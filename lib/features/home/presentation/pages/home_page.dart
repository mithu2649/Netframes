import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/widgets/shimmer_loading.dart';
import 'package:netframes/features/home/presentation/bloc/home_bloc.dart';
import 'package:netframes/features/home/presentation/bloc/home_event.dart';
import 'package:netframes/features/home/presentation/bloc/home_state.dart';
import 'package:netframes/features/home/presentation/widgets/movie_list.dart';
import 'package:netframes/features/home/presentation/widgets/shimmer_movie_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Netflix'),
                        selected: state.selectedProvider == 'Netflix',
                        avatar:
                            (state is HomeLoading &&
                                state.selectedProvider == 'Netflix')
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        showCheckmark:
                            !(state is HomeLoading &&
                                state.selectedProvider == 'Netflix'),
                        onSelected: (selected) {
                          if (selected) {
                            context.read<HomeBloc>().add(
                              const SelectProvider('Netflix'),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('JioHotstar'),
                        selected: state.selectedProvider == 'JioHotstar',
                        avatar:
                            (state is HomeLoading &&
                                state.selectedProvider == 'JioHotstar')
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        showCheckmark:
                            !(state is HomeLoading &&
                                state.selectedProvider == 'JioHotstar'),
                        onSelected: (selected) {
                          if (selected) {
                            context.read<HomeBloc>().add(
                              const SelectProvider('JioHotstar'),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Prime Video'),
                        selected: state.selectedProvider == 'PrimeVideo',
                        avatar:
                            (state is HomeLoading &&
                                state.selectedProvider == 'PrimeVideo')
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        showCheckmark:
                            !(state is HomeLoading &&
                                state.selectedProvider == 'PrimeVideo'),
                        onSelected: (selected) {
                          if (selected) {
                            context.read<HomeBloc>().add(
                              const SelectProvider('PrimeVideo'),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('DramaDrip'),
                        selected: state.selectedProvider == 'DramaDrip',
                        avatar:
                            (state is HomeLoading &&
                                state.selectedProvider == 'DramaDrip')
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        showCheckmark:
                            !(state is HomeLoading &&
                                state.selectedProvider == 'DramaDrip'),
                        onSelected: (selected) {
                          if (selected) {
                            context.read<HomeBloc>().add(
                              const SelectProvider('DramaDrip'),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('MPlayer'),
                        selected: state.selectedProvider == 'MPlayer',
                        avatar:
                            (state is HomeLoading &&
                                state.selectedProvider == 'MPlayer')
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        showCheckmark:
                            !(state is HomeLoading &&
                                state.selectedProvider == 'MPlayer'),
                        onSelected: (selected) {
                          if (selected) {
                            context.read<HomeBloc>().add(
                              const SelectProvider('MPlayer'),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('TMDB'),
                        selected: state.selectedProvider == 'TMDB',
                        avatar:
                            (state is HomeLoading &&
                                state.selectedProvider == 'TMDB')
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        showCheckmark:
                            !(state is HomeLoading &&
                                state.selectedProvider == 'TMDB'),
                        onSelected: (selected) {
                          if (selected) {
                            context.read<HomeBloc>().add(
                              const SelectProvider('TMDB'),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (state is HomeLoading)
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerMovieList(),
                        ShimmerMovieList(),
                        ShimmerMovieList(),
                      ],
                    ),
                  ),
                )
              else if (state is HomeLoaded)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: state.movies.entries.map((entry) {
                        return MovieList(title: entry.key, movies: entry.value);
                      }).toList(),
                    ),
                  ),
                )
              else if (state is HomeError)
                Expanded(child: Center(child: Text(state.message))),
            ],
          );
        },
      ),
    );
  }
}
