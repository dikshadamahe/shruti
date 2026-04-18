import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';

/// Holds the state of what is currently playing / queued.
class CurrentDiscourseState {
  final Discourse discourse;
  final Series? series;

  const CurrentDiscourseState({
    required this.discourse,
    this.series,
  });

  CurrentDiscourseState copyWith({
    Discourse? discourse,
    Series? series,
  }) {
    return CurrentDiscourseState(
      discourse: discourse ?? this.discourse,
      series: series ?? this.series,
    );
  }
}

class CurrentDiscourseNotifier extends Notifier<CurrentDiscourseState?> {
  @override
  CurrentDiscourseState? build() => null;

  void setDiscourse(Discourse discourse, {Series? series}) {
    state = CurrentDiscourseState(discourse: discourse, series: series);
  }

  void clear() {
    state = null;
  }
}

final currentDiscourseProvider =
    NotifierProvider<CurrentDiscourseNotifier, CurrentDiscourseState?>(
  CurrentDiscourseNotifier.new,
);
