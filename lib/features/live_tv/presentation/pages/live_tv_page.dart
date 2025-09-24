import 'package:better_player/better_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/live_tv/data/models/channel_model.dart';
import 'package:netframes/features/live_tv/data/repositories/iptv_repository.dart';
import 'package:netframes/features/live_tv/data/services/favorites_service.dart';
import 'package:netframes/features/live_tv/presentation/bloc/live_tv_bloc.dart';
import 'package:netframes/features/live_tv/presentation/bloc/live_tv_event.dart';
import 'package:netframes/features/live_tv/presentation/bloc/live_tv_state.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LiveTvPage extends StatelessWidget {
  const LiveTvPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LiveTvBloc(
        IptvRepository(FavoritesService()),
        FavoritesService(),
      )..add(FetchChannels()),
      child: const LiveTvView(),
    );
  }
}

class LiveTvView extends StatefulWidget {
  const LiveTvView({super.key});

  @override
  State<LiveTvView> createState() => _LiveTvViewState();
}

class _LiveTvViewState extends State<LiveTvView> {
  late BetterPlayerController _betterPlayerController;
  late Function(BetterPlayerEvent) _eventListener;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    BetterPlayerConfiguration betterPlayerConfiguration = const BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: false,
      handleLifecycle: true,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    _eventListener = (event) {
      final bloc = context.read<LiveTvBloc>();
      final currentState = bloc.state;

      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        bloc.add(PlayerErrorOccurred());
      } else if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        if (currentState is LiveTvLoaded && currentState.isAutoStartupSequence) {
          bloc.add(PlaybackSuccessful());
        }
      }
    };
    _betterPlayerController.addEventsListener(_eventListener);
  }

  @override
  void dispose() {
    _betterPlayerController.removeEventsListener(_eventListener);
    _betterPlayerController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('live_tv_page'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1.0 &&
            !_searchFocusNode.hasFocus) {
          context.read<LiveTvBloc>().add(LiveTvTabEntered());
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<LiveTvBloc, LiveTvState>(
            listener: (context, state) {
              if (state is LiveTvLoaded) {
                if (state.currentChannelUrl.isNotEmpty &&
                    state.currentChannelUrl !=
                        _betterPlayerController.betterPlayerDataSource?.url) {
                  BetterPlayerDataSource dataSource = BetterPlayerDataSource(
                    BetterPlayerDataSourceType.network,
                    state.currentChannelUrl,
                    liveStream: true,
                    headers: state.headers,
                  );
                  _betterPlayerController.setupDataSource(dataSource);
                  _betterPlayerController.play();
                }
              }
            },
            builder: (context, state) {
              if (state is LiveTvLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is LiveTvLoaded) {
                if (state.allChannels.isEmpty) {
                  return const Center(child: Text('No channels found.'));
                }
                final currentChannel = state.currentChannel;
                return Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        children: [
                          BetterPlayer(controller: _betterPlayerController),
                          if (state.isStreamLoading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                    NowPlaying(channel: currentChannel),
                    CategoryChips(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.filteredChannels.length,
                        itemBuilder: (context, index) {
                          final channel = state.filteredChannels[index];
                          final isPlaying = channel.id == state.currentChannel.id;
                          final isFavorite =
                              state.favoriteChannelIds.contains(channel.id);
                          return ChannelListItem(
                            channel: channel,
                            isPlaying: isPlaying,
                            isFavorite: isFavorite,
                            onTap: () {
                              context
                                  .read<LiveTvBloc>()
                                  .add(ChannelSelected(channel.url));
                            },
                            onFavorite: () {
                              context
                                  .read<LiveTvBloc>()
                                  .add(ToggleFavorite(channel.id));
                            },
                          );
                        },
                      ),
                    ),
                    SearchBar(focusNode: _searchFocusNode),
                  ],
                );
              } else if (state is LiveTvError) {
                return Center(child: Text(state.message));
              } else {
                return const Center(child: Text('Welcome to Live TV'));
              }
            },
          ),
        ),
      ),
    );
  }
}

class NowPlaying extends StatelessWidget {
  final Channel channel;

  const NowPlaying({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: channel.logo,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.tv, size: 25),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(channel.group),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTvBloc, LiveTvState>(
      builder: (context, state) {
        if (state is LiveTvLoaded) {
          return SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: state.selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        context
                            .read<LiveTvBloc>()
                            .add(CategorySelected(category));
                      }
                    },
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class SearchBar extends StatelessWidget {
  final FocusNode focusNode;

  const SearchBar({super.key, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        focusNode: focusNode,
        onChanged: (query) {
          context.read<LiveTvBloc>().add(SearchQueryChanged(query));
        },
        decoration: InputDecoration(
          hintText: 'Search channels...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }
}

class ChannelListItem extends StatefulWidget {
  final Channel channel;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const ChannelListItem({
    super.key,
    required this.channel,
    required this.isPlaying,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  _ChannelListItemState createState() => _ChannelListItemState();
}

class _ChannelListItemState extends State<ChannelListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isPlaying) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ChannelListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat(reverse: true);
      }
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isPlaying ? Colors.grey.withOpacity(0.3) : null,
      child: ListTile(
        leading: CachedNetworkImage(
          imageUrl: widget.channel.logo,
          width: 50,
          placeholder: (context, url) => const SizedBox(
            width: 50,
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.tv),
        ),
        title: Text(widget.channel.name),
        subtitle: Text(widget.channel.group),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isPlaying)
              FadeTransition(
                opacity: _animationController,
                child: const Text('Playing Now'),
              ),
            IconButton(
              icon: Icon(widget.isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: widget.onFavorite,
            ),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }
}