import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/play_pause_morph_icon.dart';
import '../../services/audio_playback_service.dart';
import 'mini_player_bar.dart';

class PlayerPanel extends ConsumerStatefulWidget {
  const PlayerPanel({super.key});

  @override
  ConsumerState<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends ConsumerState<PlayerPanel> {
  final DraggableScrollableController _panelController =
      DraggableScrollableController();
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.12);

  @override
  void dispose() {
    _sheetExtent.dispose();
    _panelController.dispose();
    super.dispose();
  }

  Future<void> _animatePanel(double target) async {
    if (!_panelController.isAttached) return;
    await _panelController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = ref.watch(currentMediaItemProvider).value;
    if (mediaItem == null) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final collapsedExtent = (92 / screenHeight).clamp(0.10, 0.15).toDouble();
    const expandedExtent = 0.94;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final nextExtent = notification.extent
            .clamp(collapsedExtent, expandedExtent)
            .toDouble();
        if ((nextExtent - _sheetExtent.value).abs() > 0.004) {
          _sheetExtent.value = nextExtent;
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _panelController,
        expand: false,
        initialChildSize: collapsedExtent,
        minChildSize: collapsedExtent,
        maxChildSize: expandedExtent,
        snap: true,
        snapSizes: [collapsedExtent, expandedExtent],
        builder: (context, scrollController) {
          final borderRadius = BorderRadius.circular(32);

          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: RepaintBoundary(
              child: Neumorphic(
                style: NeumorphicStyle(
                  depth: 4,
                  intensity: 0.65,
                  color: AppTheme.surface.withValues(alpha: 0.82),
                  boxShape: NeumorphicBoxShape.roundRect(borderRadius),
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: _AmbientArtworkBackground(
                            artworkUrl: _artworkUrlFor(mediaItem),
                            extentListenable: _sheetExtent,
                            collapsedExtent: collapsedExtent,
                            expandedExtent: expandedExtent,
                          ),
                        ),
                      ),
                      const Positioned.fill(child: _PlayerPanelOverlay()),
                      CustomScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: ValueListenableBuilder<double>(
                                valueListenable: _sheetExtent,
                                builder: (context, extent, child) {
                                  return _PanelGrip(
                                    expansion: _normalizeExpansion(
                                      extent,
                                      collapsedExtent,
                                      expandedExtent,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                              child: RepaintBoundary(
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _sheetExtent,
                                  builder: (context, extent, child) {
                                    final expansion = _normalizeExpansion(
                                      extent,
                                      collapsedExtent,
                                      expandedExtent,
                                    );
                                    return MiniPlayerBar(
                                      isExpanded: expansion > 0.55,
                                      expansion: expansion,
                                      onToggle: () => _animatePanel(
                                        expansion > 0.5
                                            ? collapsedExtent
                                            : expandedExtent,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                              child: RepaintBoundary(
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _sheetExtent,
                                  builder: (context, extent, child) {
                                    final expansion = _normalizeExpansion(
                                      extent,
                                      collapsedExtent,
                                      expandedExtent,
                                    );
                                    return IgnorePointer(
                                      ignoring: expansion < 0.08,
                                      child: Opacity(
                                        opacity: Curves.easeOut.transform(
                                          expansion,
                                        ),
                                        child: _PlayerDetails(
                                          expansion: expansion,
                                          onCollapse: () =>
                                              _animatePanel(collapsedExtent),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: Consumer(
        builder: (context, ref, child) {
          final mediaItem = ref.watch(currentMediaItemProvider).value;

          return Stack(
            children: [
              Positioned.fill(
                child: _AmbientArtworkBackground(
                  artworkUrl: mediaItem == null
                      ? null
                      : _artworkUrlFor(mediaItem),
                  staticExpansion: 1,
                ),
              ),
              const Positioned.fill(
                child: _PlayerPanelOverlay(
                  topOpacity: 0.5,
                  midOpacity: 0.7,
                  bottomOpacity: 1,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: _PlayerDetails(
                    expansion: 1,
                    onCollapse: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerDetails extends ConsumerWidget {
  const _PlayerDetails({required this.expansion, required this.onCollapse});

  final double expansion;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlaybackProvider);
    final position = ref.watch(currentPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(currentDurationProvider).value ?? Duration.zero;
    final playerState = ref.watch(currentPlayerStateProvider).value;
    final mediaItem = ref.watch(currentMediaItemProvider).value;

    if (mediaItem == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playerState?.playing ?? false;
    final trackNumber = mediaItem.extras?['trackNumber'];
    final titleStyle = Theme.of(
      context,
    ).textTheme.displaySmall?.copyWith(fontSize: lerpDouble(22, 30, expansion));

    return Column(
      children: [
        Row(
          children: [
            NeumorphicButton(
              onPressed: onCollapse,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(10),
              style: const NeumorphicStyle(
                depth: 4,
                intensity: 0.7,
                boxShape: NeumorphicBoxShape.circle(),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.warmIvory,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'NOW PLAYING',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 3,
                      color: AppTheme.warmIvory.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mediaItem.artist ?? 'Osho Discourse',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trackNumber != null)
              Neumorphic(
                style: NeumorphicStyle(
                  depth: 3,
                  intensity: 0.7,
                  color: AppTheme.amberFire.withValues(alpha: 0.12),
                  boxShape: NeumorphicBoxShape.roundRect(
                    BorderRadius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Track $trackNumber',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.amberFireLight,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 42),
          ],
        ),
        const Spacer(),
        Transform.scale(
          scale: lerpDouble(0.92, 1.0, expansion),
          child: _ArtworkCard(mediaItem: mediaItem),
        ),
        const SizedBox(height: 26),
        Text(
          mediaItem.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
        const SizedBox(height: 10),
        Text(
          mediaItem.artist ?? 'Osho Discourse',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.warmIvory.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 28),
        _PlayerSeekBar(
          position: position,
          duration: duration,
          onSeek: (nextPosition) => audioService.seek(nextPosition),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ControlButton(
              icon: Icons.replay_10_rounded,
              onPressed: () {
                final nextPosition = position - const Duration(seconds: 10);
                audioService.seek(
                  nextPosition < Duration.zero ? Duration.zero : nextPosition,
                );
              },
            ),
            _ControlButton(
              icon: Icons.skip_previous_rounded,
              onPressed: audioService.skipToPrevious,
            ),
            NeumorphicButton(
              onPressed: () async {
                if (isPlaying) {
                  await audioService.pause();
                } else {
                  await audioService.play();
                }
              },
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(24),
              style: NeumorphicStyle(
                depth: 6,
                intensity: 0.82,
                color: isPlaying
                    ? AppTheme.surfaceLight.withValues(alpha: 0.92)
                    : AppTheme.surface.withValues(alpha: 0.92),
                boxShape: const NeumorphicBoxShape.circle(),
              ),
              child: PlayPauseMorphIcon(
                isPlaying: isPlaying,
                size: 42,
                color: AppTheme.amberFire,
              ),
            ),
            _ControlButton(
              icon: Icons.skip_next_rounded,
              onPressed: audioService.skipToNext,
            ),
            _ControlButton(
              icon: Icons.forward_30_rounded,
              onPressed: () {
                final maxPosition = duration == Duration.zero
                    ? position
                    : duration;
                final nextPosition = position + const Duration(seconds: 30);
                audioService.seek(
                  nextPosition > maxPosition ? maxPosition : nextPosition,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicButton(
              onPressed: audioService.stop,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              style: const NeumorphicStyle(
                depth: 3,
                intensity: 0.65,
                boxShape: NeumorphicBoxShape.stadium(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stop_rounded,
                    size: 18,
                    color: AppTheme.warmIvory.withValues(alpha: 0.74),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stop',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.warmIvory.withValues(alpha: 0.74),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({required this.mediaItem});

  final MediaItem mediaItem;

  @override
  Widget build(BuildContext context) {
    final artworkUrl = _artworkUrlFor(mediaItem);

    return SizedBox(
      width: 292,
      height: 292,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 262,
            height: 262,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.amberFire.withValues(alpha: 0.14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amberFire.withValues(alpha: 0.18),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          RepaintBoundary(
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: 6,
                intensity: 0.72,
                boxShape: NeumorphicBoxShape.roundRect(
                  const BorderRadius.all(Radius.circular(34)),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: SizedBox(
                  width: 248,
                  height: 248,
                  child: artworkUrl == null || artworkUrl.isEmpty
                      ? Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.surfaceLight,
                                AppTheme.deepBlack,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ॐ',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(color: AppTheme.amberFireLight),
                          ),
                        )
                      : Image.network(
                          artworkUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.surfaceLight,
                                    AppTheme.deepBlack,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'ॐ',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(color: AppTheme.amberFireLight),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSeekBar extends StatelessWidget {
  const _PlayerSeekBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final maxMillis = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds
        .clamp(0, maxMillis.toInt())
        .toDouble();

    return Column(
      children: [
        Neumorphic(
          style: const NeumorphicStyle(
            depth: -3,
            intensity: 0.7,
            boxShape: NeumorphicBoxShape.stadium(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppTheme.amberFire,
                inactiveTrackColor: AppTheme.warmIvory.withValues(alpha: 0.14),
                thumbColor: AppTheme.amberFireLight,
                overlayColor: AppTheme.amberFire.withValues(alpha: 0.12),
              ),
              child: Slider(
                min: 0,
                max: maxMillis,
                value: value,
                onChanged: (nextValue) {
                  onSeek(Duration(milliseconds: nextValue.round()));
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
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
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onPressed: onPressed,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      style: const NeumorphicStyle(
        depth: 4,
        intensity: 0.68,
        boxShape: NeumorphicBoxShape.circle(),
      ),
      child: Icon(
        icon,
        size: 24,
        color: AppTheme.warmIvory.withValues(alpha: 0.8),
      ),
    );
  }
}

class _AmbientArtworkBackground extends StatefulWidget {
  const _AmbientArtworkBackground({
    required this.artworkUrl,
    this.extentListenable,
    this.collapsedExtent,
    this.expandedExtent,
    this.staticExpansion,
  });

  final String? artworkUrl;
  final ValueListenable<double>? extentListenable;
  final double? collapsedExtent;
  final double? expandedExtent;
  final double? staticExpansion;

  @override
  State<_AmbientArtworkBackground> createState() =>
      _AmbientArtworkBackgroundState();
}

class _AmbientArtworkBackgroundState extends State<_AmbientArtworkBackground> {
  String? _currentArtwork;
  String? _previousArtwork;

  @override
  void initState() {
    super.initState();
    _currentArtwork = widget.artworkUrl;
  }

  @override
  void didUpdateWidget(covariant _AmbientArtworkBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextArtwork = widget.artworkUrl;
    if (nextArtwork != _currentArtwork) {
      _previousArtwork = _currentArtwork;
      _currentArtwork = nextArtwork;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentArtwork == null || _currentArtwork!.isEmpty) {
      return const _AmbientFallback();
    }

    final extentListenable = widget.extentListenable;
    if (extentListenable == null) {
      return _BlurredArtworkStack(
        artworkUrl: _currentArtwork!,
        previousArtworkUrl: _previousArtwork == _currentArtwork
            ? null
            : _previousArtwork,
        expansion: widget.staticExpansion ?? 1,
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: extentListenable,
      builder: (context, extent, child) {
        final expansion = _normalizeExpansion(
          extent,
          widget.collapsedExtent ?? 0.12,
          widget.expandedExtent ?? 0.94,
        );
        return _BlurredArtworkStack(
          artworkUrl: _currentArtwork!,
          previousArtworkUrl: _previousArtwork == _currentArtwork
              ? null
              : _previousArtwork,
          expansion: expansion,
        );
      },
    );
  }
}

class _BlurredArtworkStack extends StatelessWidget {
  const _BlurredArtworkStack({
    required this.artworkUrl,
    required this.expansion,
    this.previousArtworkUrl,
  });

  final String artworkUrl;
  final String? previousArtworkUrl;
  final double expansion;

  @override
  Widget build(BuildContext context) {
    final strongBlurOpacity = Curves.easeOut.transform(expansion);
    final subtleOverlayOpacity = lerpDouble(0.22, 0.12, expansion);

    final currentArtwork = _StaticBlurArtwork(
      artworkUrl: artworkUrl,
      subtleOverlayOpacity: subtleOverlayOpacity,
      strongBlurOpacity: strongBlurOpacity,
    );

    if (previousArtworkUrl == null || previousArtworkUrl == artworkUrl) {
      return currentArtwork;
    }

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 600),
      firstChild: _StaticBlurArtwork(
        artworkUrl: previousArtworkUrl!,
        subtleOverlayOpacity: subtleOverlayOpacity,
        strongBlurOpacity: strongBlurOpacity,
      ),
      secondChild: currentArtwork,
      crossFadeState: CrossFadeState.showSecond,
    );
  }
}

class _StaticBlurArtwork extends StatelessWidget {
  const _StaticBlurArtwork({
    required this.artworkUrl,
    required this.subtleOverlayOpacity,
    required this.strongBlurOpacity,
  });

  final String artworkUrl;
  final double subtleOverlayOpacity;
  final double strongBlurOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: _ImageFilteredLayer(
            artworkUrl: artworkUrl,
            sigma: 18,
            overlayOpacity: subtleOverlayOpacity,
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: strongBlurOpacity,
            child: RepaintBoundary(
              child: _ImageFilteredLayer(
                artworkUrl: artworkUrl,
                sigma: 28,
                overlayOpacity: 0.18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageFilteredLayer extends StatelessWidget {
  const _ImageFilteredLayer({
    required this.artworkUrl,
    required this.sigma,
    required this.overlayOpacity,
  });

  final String artworkUrl;
  final double sigma;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.mirror,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            artworkUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: AppTheme.deepBlack);
            },
          ),
          ColoredBox(
            color: AppTheme.deepBlack.withValues(alpha: overlayOpacity),
          ),
        ],
      ),
    );
  }
}

class _AmbientFallback extends StatelessWidget {
  const _AmbientFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.deepBlack,
            AppTheme.surface,
            AppTheme.deepBlack.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _PlayerPanelOverlay extends StatelessWidget {
  const _PlayerPanelOverlay({
    this.topOpacity = 0.48,
    this.midOpacity = 0.72,
    this.bottomOpacity = 0.96,
  });

  final double topOpacity;
  final double midOpacity;
  final double bottomOpacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.deepBlack.withValues(alpha: topOpacity),
            AppTheme.surface.withValues(alpha: midOpacity),
            AppTheme.deepBlack.withValues(alpha: bottomOpacity),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.28, 1.0],
        ),
      ),
    );
  }
}

class _PanelGrip extends StatelessWidget {
  const _PanelGrip({required this.expansion});

  final double expansion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: lerpDouble(48, 64, expansion),
        height: 5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppTheme.warmIvory.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

String? _artworkUrlFor(MediaItem mediaItem) {
  final artUri = mediaItem.artUri?.toString();
  if (artUri != null && artUri.isNotEmpty) {
    return artUri;
  }

  final coverImageUrl = mediaItem.extras?['coverImageUrl'];
  return coverImageUrl is String && coverImageUrl.isNotEmpty
      ? coverImageUrl
      : null;
}

String _formatDuration(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  return '${twoDigits(minutes)}:${twoDigits(seconds)}';
}

double lerpDouble(double begin, double end, double t) {
  return begin + (end - begin) * t;
}

double _normalizeExpansion(
  double extent,
  double collapsedExtent,
  double expandedExtent,
) {
  return ((extent - collapsedExtent) / (expandedExtent - collapsedExtent))
      .clamp(0.0, 1.0)
      .toDouble();
}
