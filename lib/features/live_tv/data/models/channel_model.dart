class Channel {
  final String id;
  final String name;
  final String logo;
  final String group;
  final String url;
  final bool isZee;

  Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.group,
    required this.url,
    this.isZee = false,
  });
}
