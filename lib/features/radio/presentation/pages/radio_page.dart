
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/radio_cubit.dart';
// import '../../data/models/radio_station.dart';

class RadioPage extends StatelessWidget {
  const RadioPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetFrames Radio'),
      ),
      body: BlocBuilder<RadioCubit, RadioState>(
        builder: (context, state) {
          if (state is RadioLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RadioLoaded) {
            return Column(
              children: [
                Expanded(
                  child: _buildStationList(context, state),
                ),
                _buildSearchBar(context),
                _buildCountryChips(context, state),
              ],
            );
          } else if (state is RadioError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Welcome to Radio'));
        },
      ),
    );
  }

  Widget _buildCountryChips(BuildContext context, RadioLoaded state) {
    final List<String> allCountries = ['All', 'Favorites', ...state.allStations.map((s) => s.country).toSet()];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: allCountries.map((country) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(country),
              selected: state.selectedCountry == country,
              onSelected: (selected) {
                if (selected) {
                  context.read<RadioCubit>().filterByCountry(country);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) => context.read<RadioCubit>().search(value),
        decoration: InputDecoration(
          hintText: 'Search for a station...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  Widget _buildStationList(BuildContext context, RadioLoaded state) {
    return ListView.builder(
      itemCount: state.stations.length,
      itemBuilder: (context, index) {
        final station = state.stations[index];
        final isPlaying = state.playingStation == station;
        final isBuffering = isPlaying && state.playbackState == PlaybackState.buffering;
        final isError = isPlaying && state.playbackState == PlaybackState.error;

        return ListTile(
          tileColor: isError ? Colors.red.withOpacity(0.3) : null,
          title: Text(station.name),
          subtitle: isError ? Text('Failed to play', style: TextStyle(color: Colors.red)) : Text(station.city),
          leading: isBuffering
              ? const CircularProgressIndicator()
              : isPlaying
                  ? Icon(Icons.volume_up, color: Theme.of(context).colorScheme.secondary)
                  : const Icon(Icons.radio),
          trailing: IconButton(
            icon: Icon(
              station.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: station.isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              context.read<RadioCubit>().toggleFavorite(station);
            },
          ),
          onTap: () {
            context.read<RadioCubit>().playStation(station);
          },
        );
      },
    );
  }
}
