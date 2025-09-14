import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';
import 'package:netframes/features/movie_details/presentation/widgets/custom_video_controls.dart';
import 'package:screen_brightness/screen_brightness.dart';

class VideoPlayerPage extends StatefulWidget {
  final String? videoUrl;
  final String? videoTitle;
  final Map<String, String>? headers;
  final List<VideoStream>? videoStreams;
  final List? subtitles;

  const VideoPlayerPage({
    super.key,
    this.videoUrl,
    this.videoTitle,
    this.headers,
    this.videoStreams,
    this.subtitles,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late BetterPlayerController _controller;
  bool _showControls = true;
  bool _isLocked = false;
  Timer? _controlsTimer;
  double _volume = 0.5;
  double _brightness = 0.5;
  String? _feedbackText;
  IconData? _seekIcon;
  double _scale = 1.0;
  double _previousScale = 1.0;
  BoxFit _fit = BoxFit.contain;
  bool _showUnlockButton = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final url = widget.videoUrl ?? widget.videoStreams!.first.url;

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      headers: widget.headers,
      useAsmsSubtitles: true,
      useAsmsAudioTracks: true,
      subtitles: widget.subtitles
          ?.map(
            (s) => BetterPlayerSubtitlesSource(
              type: BetterPlayerSubtitlesSourceType.network,
              name: s.language, // Assuming 's' has a 'language' property
              urls: [s.url],
            ),
          )
          .toList(),
    );

    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        aspectRatio: 16 / 9,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false, // disable default, we use our custom one
          enableAudioTracks: true,
        ),
      ),
      betterPlayerDataSource: dataSource,
    );

    _startControlsTimer();
  }

  void _cancelControlsTimer() {
    _controlsTimer?.cancel();
  }

  void _startControlsTimer() {
    _cancelControlsTimer();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) {
      setState(() {
        _showUnlockButton = true;
      });
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showUnlockButton = false;
          });
        }
      });
      return;
    }
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startControlsTimer();
      }
    });
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      _showControls = false;
    });
  }

  void _showFeedback(String text, {IconData? icon}) {
    setState(() {
      _feedbackText = text;
      _seekIcon = icon;
    });
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _feedbackText = null;
          _seekIcon = null;
        });
      }
    });
  }

  void _toggleFit() {
    setState(() {
      _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
      _controller.setOverriddenFit(_fit);
    });
  }

  Future<bool> _onWillPop() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    return true;
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: (details) {
            if (_isLocked) return;
            final screenWidth = MediaQuery.of(context).size.width;
            final tapPosition = details.localPosition.dx;
            final position = _controller.videoPlayerController!.value.position;
            if (tapPosition < screenWidth / 2) {
              _controller.seekTo(position - const Duration(seconds: 10));
              _showFeedback('-10s', icon: Icons.fast_rewind);
            } else {
              _controller.seekTo(position + const Duration(seconds: 10));
              _showFeedback('+10s', icon: Icons.fast_forward);
            }
          },
          onVerticalDragUpdate: (details) {
            if (_isLocked) return;
            if (details.delta.dy.abs() > details.delta.dx.abs()) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapPosition = details.localPosition.dx;
              if (tapPosition < screenWidth / 2) {
                _brightness -= details.delta.dy / 100;
                _brightness = _brightness.clamp(0.0, 1.0);
                ScreenBrightness().setScreenBrightness(_brightness);
                _showFeedback('Brightness: ${(_brightness * 100).toInt()}%');
              } else {
                _volume -= details.delta.dy / 100;
                _volume = _volume.clamp(0.0, 1.0);
                _controller.setVolume(_volume);
                _showFeedback('Volume: ${(_volume * 100).toInt()}%');
              }
            }
          },
          onScaleStart: (details) => _previousScale = _scale,
          onScaleUpdate: (details) {
            setState(() => _scale = _previousScale * details.scale);
          },
          child: Stack(
            children: [
              SizedBox.expand(
                child: Transform.scale(
                  scale: _scale,
                  child: BetterPlayer(controller: _controller),
                ),
              ),
              IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: CustomVideoControls(
                    show: _showControls,
                    controller: _controller,
                    videoStreams: widget.videoStreams,
                    videoTitle: widget.videoTitle,
                    onSourceChanged: (url) async {
                      final position =
                          _controller.videoPlayerController!.value.position;
                      await _controller.setupDataSource(
                        BetterPlayerDataSource(
                          BetterPlayerDataSourceType.network,
                          url,
                          headers: widget.headers,
                          useAsmsSubtitles: true,
                          useAsmsAudioTracks: true,
                          subtitles: widget.subtitles
                              ?.map(
                                (s) => BetterPlayerSubtitlesSource(
                                  type: BetterPlayerSubtitlesSourceType.network,
                                  name: s is BetterPlayerSubtitlesSource
                                      ? s.name
                                      : (s.label ?? "Subtitle"),
                                  urls: [
                                    s is BetterPlayerSubtitlesSource
                                        ? s.urls?.first
                                        : s.url,
                                  ],
                                  headers: widget.headers,
                                ),
                              )
                              .toList(),
                        ),
                      );
                      _controller.seekTo(position);
                    },
                    onLock: _toggleLock,
                    isLocked: _isLocked,
                    onResize: _toggleFit,
                    onBack: _onWillPop,
                    onOptionsVisibilityChanged: (visible) {
                      if (visible) {
                        _cancelControlsTimer();
                      } else {
                        _startControlsTimer();
                      }
                    },
                    onScrubStart: _cancelControlsTimer,
                    onScrubEnd: _startControlsTimer,
                  ),
                ),
              ),
              if (_feedbackText != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_seekIcon != null)
                          Icon(_seekIcon, color: Colors.white, size: 20),
                        if (_seekIcon != null) const SizedBox(width: 8),
                        Text(
                          _feedbackText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}