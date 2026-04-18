import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
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
          Neumorphic(
            style: NeumorphicStyle(
              shape: NeumorphicShape.flat,
              depth: 4,
              intensity: 0.6,
              color: NeumorphicTheme.baseColor(context),
            ),
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Om icon with glow
                  Neumorphic(
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.convex,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
                      depth: 3,
                      intensity: 0.7,
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: NeumorphicText(
                          'ॐ',
                          style: const NeumorphicStyle(
                            depth: 2,
                            intensity: 0.5,
                            color: AppTheme.amberFireLight,
                          ),
                          textStyle: NeumorphicTextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                  NeumorphicButton(
                    onPressed: () {
                      if (isPlaying) {
                        audioService.pause();
                      } else {
                        audioService.resume();
                      }
                    },
                    style: const NeumorphicStyle(
                      depth: 3,
                      intensity: 0.8,
                      boxShape: NeumorphicBoxShape.circle(),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: NeumorphicIcon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        size: 20,
                        style: const NeumorphicStyle(
                          depth: 1,
                          intensity: 0.9,
                          color: AppTheme.amberFire,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
