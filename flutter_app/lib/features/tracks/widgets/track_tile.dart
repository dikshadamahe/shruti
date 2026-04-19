import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.discourse,
    this.isActive = false,
    this.onTap,
  });

  final Discourse discourse;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isBroken = discourse.isBroken;
    final baseColor = isActive
        ? AppTheme.surfaceLight.withValues(alpha: 0.95)
        : AppTheme.surface.withValues(alpha: 0.92);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: NeumorphicButton(
        onPressed: onTap,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        style: NeumorphicStyle(
          depth: isActive ? -2 : 4,
          intensity: 0.65,
          color: baseColor,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(22)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [baseColor, AppTheme.deepBlack.withValues(alpha: 0.92)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isActive
                  ? AppTheme.amberFire.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _TrackLeading(
                trackNumber: discourse.trackNumber,
                isActive: isActive,
                isBroken: isBroken,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discourse.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isBroken
                            ? AppTheme.warmIvory.withValues(alpha: 0.34)
                            : isActive
                            ? AppTheme.amberFireLight
                            : AppTheme.warmIvory,
                        decoration: isBroken
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _formatDuration(discourse.durationSeconds),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isBroken
                                    ? AppTheme.mutedTeal.withValues(alpha: 0.3)
                                    : AppTheme.mutedTeal,
                              ),
                        ),
                        if (isBroken) ...[
                          const SizedBox(width: 8),
                          _UnavailableBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _TrackAction(isActive: isActive, isBroken: isBroken),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainderSeconds = seconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
    return '$minutes:${remainderSeconds.toString().padLeft(2, '0')}';
  }
}

class _TrackLeading extends StatelessWidget {
  const _TrackLeading({
    required this.trackNumber,
    required this.isActive,
    required this.isBroken,
  });

  final int trackNumber;
  final bool isActive;
  final bool isBroken;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: isActive
          ? const Neumorphic(
              style: NeumorphicStyle(
                depth: -2,
                intensity: 0.8,
                color: AppTheme.surfaceLight,
                boxShape: NeumorphicBoxShape.circle(),
              ),
              child: Icon(Icons.graphic_eq_rounded, color: AppTheme.amberFire),
            )
          : Neumorphic(
              style: NeumorphicStyle(
                depth: isBroken ? 0 : 4,
                intensity: 0.68,
                color: isBroken ? AppTheme.surface : AppTheme.surfaceLight,
                boxShape: const NeumorphicBoxShape.circle(),
              ),
              child: Center(
                child: Text(
                  '$trackNumber',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isBroken
                        ? AppTheme.warmIvory.withValues(alpha: 0.34)
                        : AppTheme.amberFireLight,
                  ),
                ),
              ),
            ),
    );
  }
}

class _TrackAction extends StatelessWidget {
  const _TrackAction({required this.isActive, required this.isBroken});

  final bool isActive;
  final bool isBroken;

  @override
  Widget build(BuildContext context) {
    if (isBroken) {
      return Icon(
        Icons.block_rounded,
        color: AppTheme.errorRed.withValues(alpha: 0.55),
        size: 18,
      );
    }

    return Neumorphic(
      style: NeumorphicStyle(
        depth: isActive ? -1 : 3,
        intensity: 0.7,
        color: AppTheme.surfaceLight,
        boxShape: const NeumorphicBoxShape.circle(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          isActive ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
          color: isActive ? AppTheme.amberFire : AppTheme.warmIvory,
          size: 20,
        ),
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.22)),
      ),
      child: Text(
        'Unavailable',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.errorRed.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
