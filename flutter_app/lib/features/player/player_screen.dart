import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/audio_playback_service.dart';
import '../../services/current_discourse_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlaybackProvider);
    final positionAsync = ref.watch(currentPositionProvider);
    final durationAsync = ref.watch(currentDurationProvider);
    final playerStateAsync = ref.watch(currentPlayerStateProvider);
    final currentState = ref.watch(currentDiscourseProvider);

    final position = positionAsync.value ?? Duration.zero;
    final duration = durationAsync.value ?? Duration.zero;
    final isPlaying = playerStateAsync.value?.playing ?? false;
    final discourse = currentState?.discourse;
    final series = currentState?.series;

    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      body: NeumorphicBackground(
        child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      NeumorphicButton(
                        style: const NeumorphicStyle(
                          depth: 3,
                          intensity: 0.6,
                          boxShape: NeumorphicBoxShape.circle(),
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 24, color: AppTheme.warmIvory),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 3,
                                    fontSize: 9,
                                  ),
                            ),
                            if (series != null)
                              Text(
                                series.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Om Mandala Art ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      child: Neumorphic(
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.convex,
                          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(28)),
                          depth: 6,
                          intensity: 0.7,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric Neumorphic rings
                            ...List.generate(2, (i) {
                              final scale = 0.6 + (i * 0.25);
                              return Neumorphic(
                                style: NeumorphicStyle(
                                  depth: -2.0 + i,
                                  intensity: 0.5,
                                  boxShape: NeumorphicBoxShape.circle(),
                                ),
                                child: SizedBox(
                                  width: 240 * scale,
                                  height: 240 * scale,
                                ),
                              );
                            }),
                            // Om symbol
                            NeumorphicText(
                              'ॐ',
                              style: NeumorphicStyle(
                                depth: 3,
                                intensity: 0.8,
                                color: isPlaying ? AppTheme.amberFire : AppTheme.amberFireLight,
                              ),
                              textStyle: NeumorphicTextStyle(
                                fontSize: 84,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Track info ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Text(
                        discourse?.title ?? 'No Track Selected',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (discourse != null)
                        Text(
                          'Discourse ${discourse.trackNumber}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Seek bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      NeumorphicSlider(
                        height: 8,
                        style: const SliderStyle(
                          depth: -2,
                          accent: AppTheme.amberFire,
                          variant: AppTheme.amberFireLight,
                        ),
                        value: position.inMilliseconds
                            .toDouble()
                            .clamp(0, duration.inMilliseconds.toDouble()),
                        min: 0,
                        max: duration.inMilliseconds.toDouble() > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          audioService
                              .seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              _formatDuration(duration),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Controls ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Rewind 10s
                      _buildControlButton(
                        icon: Icons.replay_10_rounded,
                        size: 24,
                        onTap: () {
                          final newPos = position - const Duration(seconds: 10);
                          audioService.seek(
                              newPos < Duration.zero ? Duration.zero : newPos);
                        },
                      ),

                      // Previous
                      _buildControlButton(
                        icon: Icons.skip_previous_rounded,
                        size: 28,
                        onTap: () {},
                      ),

                      // Play / Pause
                      NeumorphicButton(
                        onPressed: () {
                          if (isPlaying) {
                            audioService.pause();
                          } else {
                            audioService.resume();
                          }
                        },
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.convex,
                          boxShape: const NeumorphicBoxShape.circle(),
                          depth: 6,
                          intensity: 0.8,
                          color: isPlaying ? AppTheme.surfaceLight : AppTheme.surface,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: NeumorphicIcon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            key: ValueKey(isPlaying),
                            size: 40,
                            style: NeumorphicStyle(
                              depth: 2,
                              intensity: 0.9,
                              color: isPlaying ? AppTheme.amberFire : AppTheme.warmIvory,
                            ),
                          ),
                        ),
                      ),

                      // Next
                      _buildControlButton(
                        icon: Icons.skip_next_rounded,
                        size: 28,
                        onTap: () {},
                      ),

                      // Forward 30s
                      _buildControlButton(
                        icon: Icons.forward_30_rounded,
                        size: 24,
                        onTap: () {
                          final newPos = position + const Duration(seconds: 30);
                          audioService.seek(
                              newPos > duration ? duration : newPos);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return NeumorphicButton(
      onPressed: onTap,
      style: const NeumorphicStyle(
        shape: NeumorphicShape.convex,
        boxShape: NeumorphicBoxShape.circle(),
        depth: 4,
        intensity: 0.6,
      ),
      padding: const EdgeInsets.all(14),
      child: Icon(
        icon,
        size: size,
        color: AppTheme.warmIvory.withValues(alpha: 0.8),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
