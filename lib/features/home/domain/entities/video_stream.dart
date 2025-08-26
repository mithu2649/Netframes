class VideoStream {
  final String url;
  final String quality;
  final Map<String, String>? headers;
  final Map<String, String>? cookies;

  VideoStream({
    required this.url,
    required this.quality,
    this.headers,
    this.cookies,
  });
}
