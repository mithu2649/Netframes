import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/home/presentation/bloc/home_bloc.dart';
import 'package:netframes/features/home/presentation/bloc/home_event.dart';
import 'package:netframes/features/home/presentation/bloc/home_state.dart';
import 'package:netframes/features/home/presentation/widgets/movie_list.dart';

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Netflix'),
                      selected: state.selectedProvider == 'Netflix',
                      onSelected: (selected) {
                        if (selected) {
                          context.read<HomeBloc>().add(const SelectProvider('Netflix'));
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('JioHotstar'),
                      selected: state.selectedProvider == 'JioHotstar',
                      onSelected: (selected) {
                        if (selected) {
                          context.read<HomeBloc>().add(const SelectProvider('JioHotstar'));
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Prime Video'),
                      selected: state.selectedProvider == 'PrimeVideo',
                      onSelected: (selected) {
                        if (selected) {
                          context.read<HomeBloc>().add(const SelectProvider('PrimeVideo'));
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('DramaDrip'),
                      selected: state.selectedProvider == 'DramaDrip',
                      onSelected: (selected) {
                        if (selected) {
                          context.read<HomeBloc>().add(const SelectProvider('DramaDrip'));
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('TMDB'),
                      selected: state.selectedProvider == 'TMDB',
                      onSelected: (selected) {
                        if (selected) {
                          context.read<HomeBloc>().add(const SelectProvider('TMDB'));
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (state is HomeLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
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
                Expanded(
                  child: Center(
                    child: Text(state.message),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
