
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/radio_cubit.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RadioCubit, RadioState>(
      builder: (context, state) {
        if (state is RadioLoaded && state.playingStation != null) {
          final station = state.playingStation!;
          final playerController = state.playerController;
          final isPlaying = state.playbackState == PlaybackState.playing;
          final isBuffering = state.playbackState == PlaybackState.buffering;

          return Container(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            child: ListTile(
              leading: isBuffering
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.radio),
              title: Text(station.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(station.country, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () => context.read<RadioCubit>().playPrevious(),
                  ),
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (isPlaying) {
                        playerController?.pause();
                      } else {
                        playerController?.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => context.read<RadioCubit>().playNext(),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
