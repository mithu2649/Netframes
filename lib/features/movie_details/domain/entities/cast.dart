import 'package:equatable/equatable.dart';

class Cast extends Equatable {
  final String name;
  final String profilePath;

  const Cast({required this.name, required this.profilePath});

  @override
  List<Object?> get props => [name, profilePath];
}
