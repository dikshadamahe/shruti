import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../services/audio_playback_service.dart';
import '../../services/current_discourse_provider.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlaybackProvider);
    final playerStateAsync = ref.watch(currentPlayerStateProvider);
    final positionAsync = ref.watch(currentPositionProvider);
    final durationAsync = ref.watch(currentDurationProvider);
    final currentState = ref.watch(currentDiscourseProvider);

    final isPlaying = playerStateAsync.value?.playing ?? false;
    final hasAudio = currentState != null;

    if (!hasAudio) return const SizedBox.shrink();

    final position = positionAsync.value ?? Duration.zero;
    final duration = durationAsync.value ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    final discourse = currentState.discourse;
    final series = currentState.series;

    return GestureDetector(
      onTap: () => context.pushNamed('player'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Progress line at top edge ─────────────────────────
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 2,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amberFire),
          ),

          // ── Mini player content ──────────────────────────────
          GlassContainer(
            height: 64,
            borderRadius: 0,
            blur: 14,
            opacity: 0.15,
            fillColor: AppTheme.deepBlack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Om icon with glow
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.amberFire.withValues(alpha: 0.25),
                          AppTheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppTheme.amberFire.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Track info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discourse.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 13,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          series?.title ?? 'Osho Discourse',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Play/pause button
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        audioService.pause();
                      } else {
                        audioService.resume();
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.amberFire.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppTheme.amberFire.withValues(alpha: 0.3),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(isPlaying),
                          size: 22,
                          color: AppTheme.amberFire,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
