import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../data/models/models.dart';

class SeriesCard extends StatelessWidget {
  final Series series;

  const SeriesCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        'tracks',
        pathParameters: {'id': series.id},
        extra: series,
      ),
      child: GlassContainer(
        borderRadius: 16,
        blur: 18,
        opacity: 0.06,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cover area with Om mandala placeholder ────────
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.amberFire.withValues(alpha: 0.15),
                      AppTheme.surface.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Om watermark
                    Center(
                      child: Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 56,
                          color: AppTheme.amberFire.withValues(alpha: 0.12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Language badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _buildLanguageBadge(context),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info section ─────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Series title
                    Expanded(
                      child: Text(
                        series.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontSize: 13,
                              height: 1.3,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Discourse count
                    Row(
                      children: [
                        Icon(
                          Icons.headphones_rounded,
                          size: 13,
                          color: AppTheme.mutedTeal.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${series.discourseCount} discourses',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBadge(BuildContext context) {
    final (label, color) = switch (series.language) {
      'hi' => ('हिं', AppTheme.amberFire),
      'en' => ('EN', AppTheme.mutedTeal),
      _ => ('Mix', const Color(0xFF8B5CF6)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
