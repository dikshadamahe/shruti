import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';

class TrackTile extends StatelessWidget {
  final Discourse discourse;
  final bool isActive;
  final VoidCallback? onTap;

  const TrackTile({
    super.key,
    required this.discourse,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBroken = discourse.isBroken;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: NeumorphicButton(
        onPressed: onTap,
        style: NeumorphicStyle(
          shape: NeumorphicShape.flat,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(14)),
          depth: isActive ? -3 : 2,
          intensity: 0.6,
          color: isActive 
             ? AppTheme.amberFire.withValues(alpha: 0.05) 
             : NeumorphicTheme.baseColor(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
              children: [
                // ── Track number ───────────────────────────────
                SizedBox(
                  width: 36,
                  height: 36,
                  child: isActive
                      ? _buildPlayingIndicator()
                      : Neumorphic(
                          style: NeumorphicStyle(
                            shape: NeumorphicShape.convex,
                            boxShape: NeumorphicBoxShape.circle(),
                            depth: isBroken ? 0 : 2,
                            intensity: 0.6,
                            color: isBroken
                                ? AppTheme.surface
                                : AppTheme.surfaceLight,
                          ),
                          child: Center(
                            child: Text(
                              '${discourse.trackNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isBroken
                                    ? AppTheme.warmIvory.withValues(alpha: 0.3)
                                    : AppTheme.amberFire,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),

                // ── Title + metadata ───────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discourse.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isBroken
                                  ? AppTheme.warmIvory.withValues(alpha: 0.3)
                                  : isActive
                                      ? AppTheme.amberFire
                                      : AppTheme.warmIvory,
                              decoration: isBroken
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _formatDuration(discourse.durationSeconds),
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isBroken
                                          ? AppTheme.mutedTeal
                                              .withValues(alpha: 0.3)
                                          : null,
                                    ),
                          ),
                          if (isBroken) ...[
                            const SizedBox(width: 8),
                            _buildUnavailableBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Play icon ──────────────────────────────────
                if (!isBroken)
                  NeumorphicIcon(
                    isActive
                        ? Icons.volume_up_rounded
                        : Icons.play_arrow_rounded,
                    size: 24,
                    style: NeumorphicStyle(
                      depth: isActive ? 0 : 1,
                      intensity: 0.8,
                      color: isActive
                          ? AppTheme.amberFire
                          : AppTheme.warmIvory.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
      );
  }

  // ── Unavailable badge for broken URLs ────────────────────────────
  Widget _buildUnavailableBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Unavailable',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: AppTheme.errorRed.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  // ── Animated equalizer bars for now-playing ──────────────────────
  Widget _buildPlayingIndicator() {
    return Neumorphic(
      style: const NeumorphicStyle(
        shape: NeumorphicShape.concave,
        boxShape: NeumorphicBoxShape.circle(),
        depth: -2,
      ),
      child: const Center(
        child: Icon(
          Icons.equalizer_rounded,
          size: 20,
          color: AppTheme.amberFire,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainMins = mins % 60;
      return '${hours}h ${remainMins}m';
    }
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
