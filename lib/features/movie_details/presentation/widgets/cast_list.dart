import 'package:flutter/material.dart';
import 'package:netframes/features/movie_details/domain/entities/cast.dart';
import 'package:netframes/features/movie_details/presentation/widgets/cast_card.dart';

class CastList extends StatelessWidget {
  final List<Cast> cast;

  const CastList({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        itemBuilder: (context, index) {
          return CastCard(cast: cast[index]);
        },
      ),
    );
  }
}