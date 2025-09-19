import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';

class CustomVideoControls extends StatefulWidget {
  final BetterPlayerController controller;
  final List<VideoStream>? videoStreams;
  final String? videoTitle;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onLock;
  final bool isLocked;
  final VoidCallback onResize;
  final Future<bool> Function()? onBack;
  final ValueChanged<bool> onOptionsVisibilityChanged;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final bool show;

  const CustomVideoControls({
    Key? key,
    required this.controller,
    required this.videoStreams,
    required this.videoTitle,
    required this.onSourceChanged,
    required this.onLock,
    required this.isLocked,
    required this.onResize,
    this.onBack,
    required this.onOptionsVisibilityChanged,
    this.onScrubStart,
    this.onScrubEnd,
    required this.show,
  }) : super(key: key);

  @override
  _CustomVideoControlsState createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls>
    with TickerProviderStateMixin {
  late VideoPlayerValue _latestValue;
  bool _dragging = false;
  String? _visibleOptions;

  late AnimationController _optionsAnimationController;
  late Animation<Offset> _optionsAnimation;

  late AnimationController _visibilityController;
  late Animation<Offset> _topBarAnimation;
  late Animation<Offset> _bottomBarAnimation;
  late Animation<double> _centerPlayButtonAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller.videoPlayerController!.addListener(_updateState);
    _latestValue = widget.controller.videoPlayerController!.value;

    _optionsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _optionsAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _optionsAnimationController, curve: Curves.easeIn),
        );

    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _topBarAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOut,
    ));

    _bottomBarAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOut,
    ));

    _centerPlayButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOut,
    ));

    if (widget.show) {
      _visibilityController.forward();
    }
  }

  @override
  void didUpdateWidget(CustomVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.videoPlayerController!.removeListener(_updateState);
    _optionsAnimationController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _latestValue = widget.controller.videoPlayerController!.value;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _toggleOptions(String? options) {
    if (options != null) {
      setState(() {
        _visibleOptions = options;
      });
      _optionsAnimationController.forward();
    } else {
      _optionsAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _visibleOptions = null;
          });
        }
      });
    }
    widget.onOptionsVisibilityChanged(options != null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_latestValue.isBuffering)
          const Center(child: CircularProgressIndicator())
        else
          GestureDetector(
            onTap: () {
              if (_visibleOptions != null) {
                _toggleOptions(null);
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top bar
                  SlideTransition(
                    position: _topBarAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (widget.onBack != null) {
                                  final canPop = await widget.onBack!();
                                  if (canPop && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.videoTitle ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              widget.isLocked ? Icons.lock : Icons.lock_open,
                              color: Colors.white,
                            ),
                            onPressed: widget.onLock,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Middle play/pause
                  if (_visibleOptions == null)
                    FadeTransition(
                      opacity: _centerPlayButtonAnimation,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            (_latestValue.isPlaying)
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 50,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (_latestValue.isPlaying) {
                              await widget.controller.pause();
                            } else {
                              await widget.controller.play();
                            }
                          },
                        ),
                      ),
                    ),
                  // Bottom
                  SlideTransition(
                    position: _bottomBarAnimation,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(_latestValue.position),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6.0,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 15.0,
                                    ),
                                    trackHeight: 2.0,
                                  ),
                                  child: Slider(
                                    value: _latestValue.position.inMilliseconds
                                        .toDouble(),
                                    min: 0.0,
                                    max:
                                        (_latestValue.duration?.inMilliseconds ??
                                                0)
                                            .toDouble(),
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.white70,
                                    onChanged: (value) {
                                      setState(() {
                                        _latestValue = _latestValue.copyWith(
                                          position: Duration(
                                            milliseconds: value.round(),
                                          ),
                                        );
                                      });
                                    },
                                    onChangeStart: (value) {
                                      setState(() {
                                        _dragging = true;
                                      });
                                      widget.onScrubStart?.call();
                                    },
                                    onChangeEnd: (value) {
                                      setState(() {
                                        _dragging = false;
                                      });
                                      widget.onScrubEnd?.call();
                                      widget.controller.seekTo(
                                        Duration(milliseconds: value.round()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(
                                  _latestValue.duration ?? Duration.zero,
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.videoStreams != null &&
                                widget.videoStreams!.length > 1)
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.source,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Source",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () => _toggleOptions('source'),
                              ),
                            if (widget
                                .controller
                                .betterPlayerAsmsTracks
                                .isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.high_quality,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Quality",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () => _toggleOptions('quality'),
                              ),
                            if (widget.controller.betterPlayerAsmsAudioTracks !=
                                    null &&
                                widget
                                        .controller
                                        .betterPlayerAsmsAudioTracks!
                                        .length >
                                    1)
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.audiotrack,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Audio",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () => _toggleOptions('audio'),
                              ),
                            if (widget
                                .controller
                                .betterPlayerSubtitlesSourceList
                                .isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.subtitles,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Subtitles",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () => _toggleOptions('subtitles'),
                              ),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.aspect_ratio,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Resize",
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: widget.onResize,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_visibleOptions != null)
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: _optionsAnimation,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.height * 0.7,
                  color: Colors.transparent,
                  child: _buildOptionsList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionsList() {
    switch (_visibleOptions) {
      case 'source':
        return ListView(
          children: widget.videoStreams!
              .map(
                (s) => InkWell(
                  onTap: () {
                    widget.onSourceChanged(s.url);
                    _toggleOptions(null);
                  },
                  child: RadioListTile(
                    title: Text(
                      s.quality,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: s.url,
                    groupValue: widget.controller.betterPlayerDataSource?.url,
                    onChanged: (value) {
                      widget.onSourceChanged(value.toString());
                      _toggleOptions(null);
                    },
                    selectedTileColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              )
              .toList(),
        );
      case 'quality':
        return ListView(
          children: widget.controller.betterPlayerAsmsTracks.map((track) {
            // final height = track.height ?? 0;
            final height = track.height;
            final label = (height != null && height > 0)
            ? '${height}p'
            : (track.bitrate != null && track.bitrate! > 0)
                ? '${(track.bitrate! / 1000).round()} kbps'
                : 'Auto';


            return InkWell(
              onTap: () {
                widget.controller.setTrack(track);
                _toggleOptions(null);
              },
              child: RadioListTile<BetterPlayerAsmsTrack>(
                title: Text(
                  label,
                  style: const TextStyle(color: Colors.white),
                ),
                value: track,
                groupValue: widget.controller.betterPlayerAsmsTrack,
                onChanged: (value) {
                  if (value != null) {
                    widget.controller.setTrack(value);
                  }
                  _toggleOptions(null);
                },
                selectedTileColor: Colors.white.withOpacity(0.2),
              ),
            );
          }).toList(),
        );
      case 'audio':
        return ListView(
          children: widget.controller.betterPlayerAsmsAudioTracks!.map((audio) {
            String trackName = audio.label ?? 'Unknown';
            if (trackName.toLowerCase().contains('stream')) {
              trackName = audio.language ?? trackName;
            }
            return InkWell(
              onTap: () {
                widget.controller.setAudioTrack(audio);
                _toggleOptions(null);
              },
              child: RadioListTile(
                title: Text(
                  trackName,
                  style: const TextStyle(color: Colors.white),
                ),
                value: audio,
                groupValue: widget.controller.betterPlayerAsmsAudioTrack,
                onChanged: (value) {
                  if (value != null) {
                    widget.controller.setAudioTrack(value);
                  }
                  _toggleOptions(null);
                },
                selectedTileColor: Colors.white.withOpacity(0.2),
              ),
            );
          }).toList(),
        );
      case 'subtitles':
        final subtitles = widget.controller.betterPlayerSubtitlesSourceList;
        BetterPlayerSubtitlesSource? currentSource =
            widget.controller.betterPlayerSubtitlesSource;
        if (currentSource?.type == BetterPlayerSubtitlesSourceType.none) {
          currentSource = null;
        }
        return ListView(
          children: [
            InkWell(
              onTap: () {
                widget.controller.setupSubtitleSource(
                  BetterPlayerSubtitlesSource(
                    type: BetterPlayerSubtitlesSourceType.none,
                  ),
                );
                _toggleOptions(null);
              },
              child: RadioListTile<BetterPlayerSubtitlesSource?>(
                title: const Text(
                  "None",
                  style: const TextStyle(color: Colors.white),
                ),
                value: null,
                groupValue: currentSource,
                onChanged: (value) {
                  widget.controller.setupSubtitleSource(
                    BetterPlayerSubtitlesSource(
                      type: BetterPlayerSubtitlesSourceType.none,
                    ),
                  );
                  _toggleOptions(null);
                },
                selectedTileColor: Colors.white.withOpacity(0.2),
              ),
            ),
            ...subtitles.map((subtitle) {
              return InkWell(
                onTap: () {
                  widget.controller.setupSubtitleSource(subtitle);
                  _toggleOptions(null);
                },
                child: RadioListTile<BetterPlayerSubtitlesSource?>(
                  title: Text(
                    subtitle.name ?? 'Unknown',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: subtitle,
                  groupValue: currentSource,
                  onChanged: (value) {
                    if (value != null) {
                      widget.controller..setupSubtitleSource(value);
                    }
                    _toggleOptions(null);
                  },
                  selectedTileColor: Colors.white.withOpacity(0.2),
                ),
              );
            }),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}