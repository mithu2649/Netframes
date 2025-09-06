import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:netframes/core/widgets/shimmer_loading.dart';

class ShimmerMovieList extends StatelessWidget {
  const ShimmerMovieList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            highlightColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.05),
            child: Container(
              width: 150, // Placeholder for title
              height: 24, // Placeholder for title
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Display a few shimmering cards
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ShimmerLoading(
                  width:
                      122.67, // width for 2/3 aspect ratio with height 184 (200 - 16 padding)
                  height: 184,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
