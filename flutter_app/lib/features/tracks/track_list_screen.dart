import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/animated_entrance.dart';
import '../../data/models/models.dart';
import '../../data/repositories/database_repository.dart';
import '../../services/audio_playback_service.dart';
import 'widgets/track_tile.dart';

class TrackListScreen extends ConsumerWidget {
  final String seriesId;
  final Series? series;

  const TrackListScreen({super.key, required this.seriesId, this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoursesAsync = ref.watch(discourseListProvider(seriesId));
    final currentMediaItem = ref.watch(currentMediaItemProvider).value;

    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      body: NeumorphicBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Collapsing Header ────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              leading: NeumorphicButton(
                margin: const EdgeInsets.all(8),
                style: const NeumorphicStyle(
                  depth: 3,
                  intensity: 0.7,
                  boxShape: NeumorphicBoxShape.circle(),
                ),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildSeriesHeader(context, ref),
                collapseMode: CollapseMode.parallax,
              ),
            ),

            // ── Track count info ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: AnimatedEntrance(
                  child: discoursesAsync.when(
                    data: (discourses) => Row(
                      children: [
                        Text(
                          '${discourses.length} Discourses',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const Spacer(),
                        // Play all button
                        if (discourses.any((d) => !d.isBroken))
                          NeumorphicButton(
                            onPressed: () {
                              final playable = discourses
                                  .where((d) => !d.isBroken)
                                  .toList();
                              if (playable.isNotEmpty) {
                                _playDiscourse(ref, playable, playable.first);
                              }
                            },
                            style: NeumorphicStyle(
                              depth: 3,
                              intensity: 0.8,
                              boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                  color: AppTheme.amberFire,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Play All',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.amberFire,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ── Divider ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.06),
                indent: 20,
                endIndent: 20,
              ),
            ),

            // ── Track list ───────────────────────────────────
            discoursesAsync.when(
              loading: () => SliverToBoxAdapter(child: _buildLoadingState()),
              error: (error, stack) => SliverToBoxAdapter(
                child: _buildErrorState(context, ref, error),
              ),
              data: (discourses) {
                if (discourses.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyState(context));
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final discourse = discourses[index];
                      final playableDiscourses = discourses
                          .where((d) => !d.isBroken)
                          .toList();
                      final isActive =
                          currentMediaItem?.extras?['seriesId'] == seriesId &&
                          currentMediaItem?.extras?['discourseId'] ==
                              discourse.id;
                      return AnimatedEntrance(
                        delay: Duration(milliseconds: 40 * index),
                        child: TrackTile(
                          discourse: discourse,
                          isActive: isActive,
                          onTap: discourse.isBroken
                              ? null
                              : () => _playDiscourse(
                                  ref,
                                  playableDiscourses,
                                  discourse,
                                ),
                        ),
                      );
                    }, childCount: discourses.length),
                  ),
                );
              },
            ),

            // Bottom padding for mini-player
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Series header with cover art ─────────────────────────────────
  Widget _buildSeriesHeader(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.amberFire.withValues(alpha: 0.2),
            AppTheme.surface.withValues(alpha: 0.8),
            AppTheme.deepBlack,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Om mandala placeholder
              Neumorphic(
                style: NeumorphicStyle(
                  shape: NeumorphicShape.convex,
                  boxShape: NeumorphicBoxShape.roundRect(
                    BorderRadius.circular(16),
                  ),
                  depth: 4,
                  intensity: 0.7,
                ),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: NeumorphicText(
                      'ॐ',
                      style: const NeumorphicStyle(
                        depth: 2,
                        intensity: 0.5,
                        color: AppTheme.amberFireLight,
                      ),
                      textStyle: NeumorphicTextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Series title
              Text(
                series?.title ?? 'Loading...',
                style: Theme.of(context).textTheme.displaySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Language tag
              if (series != null)
                Row(
                  children: [
                    _buildLanguageChip(series!.language),
                    const SizedBox(width: 8),
                    Text(
                      '${series!.discourseCount} discourses',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String language) {
    final (label, color) = switch (language) {
      'hi' => ('Hindi', AppTheme.amberFire),
      'en' => ('English', AppTheme.mutedTeal),
      _ => ('Mixed', const Color(0xFF8B5CF6)),
    };

    return Neumorphic(
      style: NeumorphicStyle(
        depth: 2,
        intensity: 0.8,
        color: color.withValues(alpha: 0.2),
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  Future<void> _playDiscourse(
    WidgetRef ref,
    List<Discourse> discourses,
    Discourse discourse,
  ) async {
    final startIndex = discourses.indexWhere((item) => item.id == discourse.id);
    if (startIndex < 0) return;

    await playQueue(
      ref.read(audioPlaybackProvider),
      discourses,
      initialIndex: startIndex,
      series: series,
    );
  }

  // ── Loading state ────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Neumorphic(
              style: NeumorphicStyle(
                shape: NeumorphicShape.flat,
                boxShape: NeumorphicBoxShape.roundRect(
                  BorderRadius.circular(12),
                ),
                depth: 2,
                intensity: 0.5,
              ),
              child: const SizedBox(
                height: 64,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.amberFire,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.warmIvory.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load discourses',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => ref.invalidate(discourseListProvider(seriesId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.amberFire),
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
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 48,
              color: AppTheme.warmIvory.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No discourses found',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
