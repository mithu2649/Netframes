import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerStreamingMovieDetails extends StatelessWidget {
  const ShimmerStreamingMovieDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for movie poster/backdrop
          Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            highlightColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.05),
            child: Container(
              width: double.infinity,
              height: 250,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer for title
                Shimmer.fromColors(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  child: Container(
                    width: double.infinity,
                    height: 24,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                // Shimmer for year/runtime
                Shimmer.fromColors(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  child: Container(
                    width: 150,
                    height: 16,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                // Shimmer for plot (multiple lines)
                Shimmer.fromColors(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 200,
                        height: 16,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Shimmer for cast
                Shimmer.fromColors(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  child: Container(
                    width: double.infinity,
                    height: 16,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                // Shimmer for Seasons title (if TV show)
                Shimmer.fromColors(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  child: Container(
                    width: 100,
                    height: 24,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                // Shimmer for Season chips (horizontal list) (approximate)
                SizedBox(
                  height: 40, // Approximate height of a ChoiceChip
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3, // A few shimmering chips
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Shimmer.fromColors(
                          baseColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                          highlightColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.05),
                          child: Container(
                            width: 80, // Approximate width of a chip
                            height: 32, // Approximate height of a chip
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Shimmer for Episodes title (if TV show)
                Shimmer.fromColors(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  child: Container(
                    width: 100,
                    height: 24,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                // Shimmer for Episode list (multiple items)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3, // A few shimmering episodes
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Shimmer.fromColors(
                            baseColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            highlightColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.05),
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.1),
                                  highlightColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.05),
                                  child: Container(
                                    width: double.infinity,
                                    height: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Shimmer.fromColors(
                                  baseColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.1),
                                  highlightColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.05),
                                  child: Container(
                                    width: 150,
                                    height: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
