import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netframes/features/home/domain/entities/video_stream.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final Map<String, String>? headers;
  final Map<String, String>? cookies;
  final List<BetterPlayerSubtitlesSource>? subtitles;
  final List<VideoStream>? videoStreams;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    this.headers,
    this.cookies,
    this.subtitles,
    this.videoStreams,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    final resolutions = <String, String>{};
    if (widget.videoStreams != null) {
      for (final stream in widget.videoStreams!) {
        resolutions[stream.quality] = stream.url;
      }
    }

    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.videoUrl,
      headers: widget.headers,
      subtitles: widget.subtitles,
      resolutions: resolutions,
    );
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.cover,
        fullScreenByDefault: true,
      ),
      betterPlayerDataSource: betterPlayerDataSource,
    );
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BetterPlayer(
        controller: _betterPlayerController,
      ),
      // body: AndroidView(
      //   viewType: 'VideoPlayerView',
      //   creationParams: {
      //     'url': widget.videoUrl,
      //     'headers': widget.headers,
      //     'cookies': widget.cookies,
      //   },
      //   creationParamsCodec: const StandardMessageCodec(),
      // ),
    );
  }
}
