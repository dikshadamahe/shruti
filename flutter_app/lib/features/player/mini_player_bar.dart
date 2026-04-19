import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/audio_playback_service.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    this.expansion = 0,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final double expansion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlaybackProvider);
    final playerState = ref.watch(currentPlayerStateProvider).value;
    final position = ref.watch(currentPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(currentDurationProvider).value ?? Duration.zero;
    final mediaItem = ref.watch(currentMediaItemProvider).value;

    if (mediaItem == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playerState?.playing ?? false;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final showSecondary = expansion > 0.35;

    return NeumorphicButton(
      onPressed: onToggle,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      style: NeumorphicStyle(
        depth: isExpanded ? -2 : 5,
        intensity: 0.65,
        color: AppTheme.surface.withValues(alpha: 0.8),
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(24)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceLight.withValues(alpha: 0.92),
              AppTheme.surface.withValues(alpha: 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _ArtworkThumb(mediaItem: mediaItem),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: showSecondary ? 1 : 0.72,
                          child: Text(
                            mediaItem.artist ?? 'Osho Discourse',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeumorphicButton(
                    onPressed: () async {
                      if (isPlaying) {
                        await audioService.pause();
                      } else {
                        await audioService.play();
                      }
                    },
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(10),
                    style: const NeumorphicStyle(
                      depth: 4,
                      intensity: 0.8,
                      boxShape: NeumorphicBoxShape.circle(),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        size: 20,
                        color: AppTheme.amberFire,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppTheme.warmIvory.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppTheme.deepBlack.withValues(alpha: 0.35),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.amberFire,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkThumb extends StatelessWidget {
  const _ArtworkThumb({required this.mediaItem});

  final MediaItem mediaItem;

  @override
  Widget build(BuildContext context) {
    final artUrl =
        mediaItem.artUri?.toString() ??
        mediaItem.extras?['coverImageUrl'] as String?;

    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 5,
        intensity: 0.75,
        boxShape: NeumorphicBoxShape.roundRect(
          BorderRadius.all(Radius.circular(18)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 56,
          height: 56,
          child: artUrl == null || artUrl.isEmpty
              ? Container(
                  color: AppTheme.surfaceLight,
                  alignment: Alignment.center,
                  child: Text(
                    'ॐ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.amberFireLight,
                    ),
                  ),
                )
              : Image.network(
                  artUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.surfaceLight,
                    alignment: Alignment.center,
                    child: Text(
                      'ॐ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.amberFireLight,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
