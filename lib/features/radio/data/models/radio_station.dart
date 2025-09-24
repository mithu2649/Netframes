
// import 'package:flutter/foundation.dart';

class RadioStation {
  final String name;
  final String city;
  final List<String> tags;
  final String streamUrl;
  final String country;
  bool isFavorite;

  RadioStation({
    required this.name,
    required this.city,
    required this.tags,
    required this.streamUrl,
    required this.country,
    this.isFavorite = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json, String country) {
    return RadioStation(
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      streamUrl: json['streamUrl'] ?? '',
      country: country,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is RadioStation &&
      other.name == name &&
      other.streamUrl == streamUrl &&
      other.country == country;
  }

  @override
  int get hashCode => name.hashCode ^ streamUrl.hashCode ^ country.hashCode;
}
