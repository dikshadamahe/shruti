import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
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

  double _sheetExtent = 0.12;

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
    final expansion =
        ((_sheetExtent - collapsedExtent) / (expandedExtent - collapsedExtent))
            .clamp(0.0, 1.0)
            .toDouble();

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final nextExtent = notification.extent
            .clamp(collapsedExtent, expandedExtent)
            .toDouble();
        if ((nextExtent - _sheetExtent).abs() > 0.001) {
          setState(() {
            _sheetExtent = nextExtent;
          });
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
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: expansion > 0.5 ? 2 : 6,
                intensity: 0.65,
                color: AppTheme.surface.withValues(alpha: 0.82),
                boxShape: NeumorphicBoxShape.roundRect(borderRadius),
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _AmbientArtworkBackground(
                        artworkUrl: _artworkUrlFor(mediaItem),
                        expansion: expansion,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.deepBlack.withValues(alpha: 0.48),
                              AppTheme.surface.withValues(alpha: 0.72),
                              AppTheme.deepBlack.withValues(alpha: 0.96),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.28, 1.0],
                          ),
                        ),
                      ),
                    ),
                    CustomScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _PanelGrip(expansion: expansion),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                            child: MiniPlayerBar(
                              isExpanded: expansion > 0.55,
                              expansion: expansion,
                              onToggle: () => _animatePanel(
                                expansion > 0.5
                                    ? collapsedExtent
                                    : expandedExtent,
                              ),
                            ),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                            child: IgnorePointer(
                              ignoring: expansion < 0.08,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: Curves.easeOut.transform(expansion),
                                child: _PlayerDetails(
                                  expansion: expansion,
                                  onCollapse: () =>
                                      _animatePanel(collapsedExtent),
                                ),
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
                  expansion: 1,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.deepBlack.withValues(alpha: 0.5),
                        AppTheme.surface.withValues(alpha: 0.7),
                        AppTheme.deepBlack,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  size: 42,
                  color: AppTheme.amberFire,
                ),
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
          Neumorphic(
            style: const NeumorphicStyle(
              depth: 6,
              intensity: 0.72,
              boxShape: NeumorphicBoxShape.roundRect(
                BorderRadius.all(Radius.circular(34)),
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
                            colors: [AppTheme.surfaceLight, AppTheme.deepBlack],
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
    required this.expansion,
  });

  final String? artworkUrl;
  final double expansion;

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
    final blurSigma = lerpDouble(18, 28, widget.expansion);
    final overlayStrength = lerpDouble(0.22, 0.12, widget.expansion);

    if (_currentArtwork == null || _currentArtwork!.isEmpty) {
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

    final currentLayer = _BackgroundLayer(
      key: ValueKey(_currentArtwork),
      artworkUrl: _currentArtwork!,
      blurSigma: blurSigma,
      overlayStrength: overlayStrength,
    );

    if (_previousArtwork == null || _previousArtwork == _currentArtwork) {
      return currentLayer;
    }

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 600),
      crossFadeState: CrossFadeState.showSecond,
      firstChild: _BackgroundLayer(
        key: ValueKey(_previousArtwork),
        artworkUrl: _previousArtwork!,
        blurSigma: blurSigma,
        overlayStrength: overlayStrength,
      ),
      secondChild: currentLayer,
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({
    super.key,
    required this.artworkUrl,
    required this.blurSigma,
    required this.overlayStrength,
  });

  final String artworkUrl;
  final double blurSigma;
  final double overlayStrength;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          artworkUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: AppTheme.deepBlack);
          },
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
            tileMode: TileMode.mirror,
          ),
          child: ColoredBox(
            color: AppTheme.deepBlack.withValues(alpha: overlayStrength),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.deepBlack.withValues(alpha: 0.2),
                AppTheme.surface.withValues(alpha: 0.3),
                AppTheme.deepBlack.withValues(alpha: 0.78),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
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
