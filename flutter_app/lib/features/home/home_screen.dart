import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/animated_entrance.dart';
import '../../data/repositories/database_repository.dart';
import 'widgets/series_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesListProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: NeumorphicTheme.baseColor(context),
        body: NeumorphicBackground(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: AnimatedEntrance(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Om symbol with glow
                              Neumorphic(
                                style: const NeumorphicStyle(
                                  shape: NeumorphicShape.convex,
                                  boxShape: NeumorphicBoxShape.circle(),
                                  depth: 4,
                                  intensity: 0.8,
                                ),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'ॐ',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: AppTheme.amberFire,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Osho',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  Text(
                                    'Audio Discourses',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          letterSpacing: 2.5,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Explore Series',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap a series to browse its discourses',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Series Grid ──────────────────────────────────
                seriesAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: _buildLoadingGrid(),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: _buildErrorState(context, ref, error),
                  ),
                  data: (seriesList) {
                    if (seriesList.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return AnimatedEntrance(
                              delay: Duration(milliseconds: 60 * index),
                              child: SeriesCard(series: seriesList[index]),
                            );
                          },
                          childCount: seriesList.length,
                        ),
                      ),
                    );
                  },
                ),

                // Bottom padding for mini-player clearance
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
    );
  }

  // ── Loading shimmer grid ─────────────────────────────────────────
  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return AnimatedEntrance(
            delay: Duration(milliseconds: 80 * index),
            child: Neumorphic(
              style: NeumorphicStyle(
                shape: NeumorphicShape.flat,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
                depth: 2,
                intensity: 0.5,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.amberFire,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppTheme.warmIvory.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load series',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => ref.invalidate(seriesListProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.amberFire,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: AppTheme.warmIvory.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No series available yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The catalog is being prepared.\nPlease check back soon.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
