import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/animated_entrance.dart';
import '../../data/models/models.dart';
import '../../data/repositories/database_repository.dart';
import '../../services/audio_playback_service.dart';
import '../../services/current_discourse_provider.dart';
import 'widgets/track_tile.dart';

class TrackListScreen extends ConsumerWidget {
  final String seriesId;
  final Series? series;

  const TrackListScreen({
    super.key,
    required this.seriesId,
    this.series,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoursesAsync = ref.watch(discourseListProvider(seriesId));
    final currentDiscourse = ref.watch(currentDiscourseProvider);

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: Stack(
        children: [
          // ── Ambient glow ─────────────────────────────────────
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.amberFire.withValues(alpha: 0.12),
                    AppTheme.amberFire.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Collapsing Header ────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.deepBlack,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.deepBlack.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
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
                            TextButton.icon(
                              onPressed: () {
                                final playable =
                                    discourses.where((d) => !d.isBroken).toList();
                                if (playable.isNotEmpty) {
                                  _playDiscourse(ref, playable.first);
                                }
                              },
                              icon: const Icon(Icons.play_circle_filled_rounded,
                                  size: 20),
                              label: const Text('Play All'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.amberFire,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
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
                loading: () => SliverToBoxAdapter(
                  child: _buildLoadingState(),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: _buildErrorState(context, ref, error),
                ),
                data: (discourses) {
                  if (discourses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final discourse = discourses[index];
                          final isActive =
                              currentDiscourse?.discourse.id == discourse.id;
                          return AnimatedEntrance(
                            delay: Duration(milliseconds: 40 * index),
                            child: TrackTile(
                              discourse: discourse,
                              isActive: isActive,
                              onTap: discourse.isBroken
                                  ? null
                                  : () => _playDiscourse(ref, discourse),
                            ),
                          );
                        },
                        childCount: discourses.length,
                      ),
                    ),
                  );
                },
              ),

              // Bottom padding for mini-player
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.amberFire.withValues(alpha: 0.3),
                      AppTheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    'ॐ',
                    style: TextStyle(
                      fontSize: 36,
                      color: AppTheme.amberFire.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _playDiscourse(WidgetRef ref, Discourse discourse) {
    ref.read(currentDiscourseProvider.notifier).setDiscourse(
          discourse,
          series: series,
        );
    ref.read(audioPlaybackProvider).playDiscourse(discourse);
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
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
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
    );
  }

  // ── Error state ──────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.warmIvory.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Failed to load discourses',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(discourseListProvider(seriesId)),
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
            Icon(Icons.music_off_rounded,
                size: 48, color: AppTheme.warmIvory.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No discourses found',
                style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
