import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppTheme.amberFire.withValues(alpha: 0.08),
          highlightColor: AppTheme.amberFire.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.amberFire.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(
                      color: AppTheme.amberFire.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              children: [
                // ── Track number ───────────────────────────────
                SizedBox(
                  width: 36,
                  height: 36,
                  child: isActive
                      ? _buildPlayingIndicator()
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isBroken
                                ? AppTheme.surface
                                : AppTheme.amberFire.withValues(alpha: 0.12),
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
                  Icon(
                    isActive
                        ? Icons.volume_up_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 24,
                    color: isActive
                        ? AppTheme.amberFire
                        : AppTheme.warmIvory.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.amberFire.withValues(alpha: 0.15),
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
