import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/models.dart';

late final AudioHandler _audioHandler;

Future<void> initAudioPlaybackService() async {
  _audioHandler = await AudioService.init(
    builder: OshoAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.oshoapp.osho_discourses.audio_playback',
      androidNotificationChannelName: 'Osho Discourses Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

List<MediaItem> buildMediaQueue(List<Discourse> discourses, {Series? series}) {
  final coverImageUrl = series?.coverImageUrl;
  final artUri = coverImageUrl != null && coverImageUrl.isNotEmpty
      ? Uri.tryParse(coverImageUrl)
      : null;

  return discourses
      .map(
        (discourse) => MediaItem(
          id: '${series?.id ?? 'single'}::${discourse.id}',
          album: 'Osho Discourses',
          title: discourse.title,
          artist: series?.title ?? 'Osho Discourse',
          artUri: artUri,
          duration: discourse.durationSeconds > 0
              ? Duration(seconds: discourse.durationSeconds)
              : null,
          extras: {
            'audioUrl': discourse.audioUrl,
            'coverImageUrl': coverImageUrl,
            'seriesId': series?.id,
            'seriesTitle': series?.title,
            'discourseId': discourse.id,
            'trackNumber': discourse.trackNumber,
          },
        ),
      )
      .toList(growable: false);
}

Future<void> playQueue(
  AudioHandler audioHandler,
  List<Discourse> discourses, {
  required int initialIndex,
  Series? series,
}) async {
  final queue = buildMediaQueue(discourses, series: series);
  await audioHandler.updateQueue(queue);
  await audioHandler.skipToQueueItem(initialIndex);
  await audioHandler.play();
}

class OshoAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  OshoAudioHandler() {
    _player.playbackEventStream.listen((_) => _broadcastState());
    _player.currentIndexStream.listen((_) {
      _syncCurrentMediaItem();
      _broadcastState();
    });
    _player.durationStream.listen((duration) {
      if (duration == null) return;

      final index = _player.currentIndex;
      final items = queue.value;
      if (index == null || index < 0 || index >= items.length) return;

      final updatedItem = items[index].copyWith(duration: duration);
      final updatedQueue = [...items];
      updatedQueue[index] = updatedItem;

      queue.add(List.unmodifiable(updatedQueue));
      mediaItem.add(updatedItem);
    });
  }

  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    this.queue.add(List.unmodifiable(queue));

    if (queue.isEmpty) {
      await _player.stop();
      mediaItem.add(null);
      _broadcastState();
      return;
    }

    final sources = queue
        .map(
          (item) => AudioSource.uri(
            Uri.parse(item.extras!['audioUrl'] as String),
            tag: item,
          ),
        )
        .toList(growable: false);

    await _player.setAudioSources(sources, initialIndex: 0);
    _syncCurrentMediaItem();
    _broadcastState();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final items = queue.value;
    if (index < 0 || index >= items.length) return;

    await _player.seek(Duration.zero, index: index);
    _syncCurrentMediaItem();
    _broadcastState();
  }

  void _syncCurrentMediaItem() {
    final index = _player.currentIndex;
    final items = queue.value;
    if (index == null || index < 0 || index >= items.length) return;

    final current = items[index];
    final duration = _player.duration;
    if (duration != null && current.duration != duration) {
      final updatedItem = current.copyWith(duration: duration);
      final updatedQueue = [...items];
      updatedQueue[index] = updatedItem;
      queue.add(List.unmodifiable(updatedQueue));
      mediaItem.add(updatedItem);
      return;
    }

    mediaItem.add(current);
  }

  void _broadcastState() {
    final controls = <MediaControl>[
      if (_player.hasPrevious) MediaControl.skipToPrevious,
      _player.playing ? MediaControl.pause : MediaControl.play,
      MediaControl.stop,
      if (_player.hasNext) MediaControl.skipToNext,
    ];

    final compactActionIndices = <int>[
      controls.indexWhere(
        (control) =>
            control == MediaControl.play || control == MediaControl.pause,
      ),
      if (_player.hasNext) controls.indexOf(MediaControl.skipToNext),
    ].where((index) => index >= 0).toList(growable: false);

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.stop,
        },
        androidCompactActionIndices: compactActionIndices,
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }
}

final audioPlaybackProvider = Provider<AudioHandler>((ref) {
  return _audioHandler;
});

final currentPlayerStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioPlaybackProvider).playbackState;
});

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(audioPlaybackProvider).mediaItem;
});

final currentPositionProvider = StreamProvider<Duration>((ref) {
  ref.watch(audioPlaybackProvider);
  return AudioService.position;
});

final currentDurationProvider = StreamProvider<Duration?>((ref) {
  return ref
      .watch(audioPlaybackProvider)
      .mediaItem
      .map((item) => item?.duration);
});
