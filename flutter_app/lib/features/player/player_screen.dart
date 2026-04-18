import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_container.dart';
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
      backgroundColor: AppTheme.deepBlack,
      body: Stack(
        children: [
          // ── Ambient background glow orbs ────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: _buildGlowOrb(
              size: 320,
              color: AppTheme.amberFire,
              opacity: isPlaying ? 0.18 : 0.10,
            ),
          ),
          Positioned(
            bottom: -60,
            left: -100,
            child: _buildGlowOrb(
              size: 280,
              color: AppTheme.mutedTeal,
              opacity: 0.08,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: -120,
            child: _buildGlowOrb(
              size: 200,
              color: AppTheme.amberFire,
              opacity: 0.06,
            ),
          ),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 30),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.warmIvory,
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
                      child: GlassContainer(
                        borderRadius: 28,
                        blur: 24,
                        opacity: 0.08,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.amberFire.withValues(alpha: isPlaying ? 0.12 : 0.06),
                                Colors.transparent,
                              ],
                              radius: 0.8,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Concentric circles
                              ...List.generate(3, (i) {
                                final scale = 0.5 + (i * 0.2);
                                return Container(
                                  width: 200 * scale,
                                  height: 200 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.amberFire.withValues(
                                        alpha: 0.08 - (i * 0.02),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              // Om symbol
                              Text(
                                'ॐ',
                                style: TextStyle(
                                  fontSize: 72,
                                  color: AppTheme.amberFire.withValues(
                                    alpha: isPlaying ? 0.6 : 0.3,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
                      SliderTheme(
                        data: Theme.of(context).sliderTheme.copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5),
                            ),
                        child: Slider(
                          value: position.inMilliseconds
                              .toDouble()
                              .clamp(0, duration.inMilliseconds.toDouble()),
                          max: duration.inMilliseconds.toDouble() > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            audioService
                                .seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
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
                        size: 28,
                        onTap: () {
                          final newPos = position - const Duration(seconds: 10);
                          audioService.seek(
                              newPos < Duration.zero ? Duration.zero : newPos);
                        },
                      ),

                      // Previous
                      _buildControlButton(
                        icon: Icons.skip_previous_rounded,
                        size: 32,
                        onTap: () {},
                      ),

                      // Play / Pause
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            audioService.pause();
                          } else {
                            audioService.resume();
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.amberGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.amberFire.withValues(alpha: 0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              key: ValueKey(isPlaying),
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Next
                      _buildControlButton(
                        icon: Icons.skip_next_rounded,
                        size: 32,
                        onTap: () {},
                      ),

                      // Forward 30s
                      _buildControlButton(
                        icon: Icons.forward_30_rounded,
                        size: 28,
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
        ],
      ),
    );
  }

  Widget _buildGlowOrb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: size,
          color: AppTheme.warmIvory.withValues(alpha: 0.8),
        ),
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
