import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const _unchanged = Object();

class TimetableUiState {
  const TimetableUiState({
    this.week = const {0: [], 1: [], 2: [], 3: [], 4: []},
    this.displayedMonday,
    this.loading = true,
    this.cached = false,
    this.refreshing = false,
    this.error,
  });

  final Map<int, List<dynamic>> week;
  final DateTime? displayedMonday;
  final bool loading;
  final bool cached;
  final bool refreshing;
  final String? error;

  TimetableUiState copyWith({
    Map<int, List<dynamic>>? week,
    Object? displayedMonday = _unchanged,
    bool? loading,
    bool? cached,
    bool? refreshing,
    Object? error = _unchanged,
  }) => TimetableUiState(
    week: week ?? this.week,
    displayedMonday: identical(displayedMonday, _unchanged)
        ? this.displayedMonday
        : displayedMonday as DateTime?,
    loading: loading ?? this.loading,
    cached: cached ?? this.cached,
    refreshing: refreshing ?? this.refreshing,
    error: identical(error, _unchanged) ? this.error : error as String?,
  );
}

final timetableControllerProvider = NotifierProvider.autoDispose
    .family<TimetableController, TimetableUiState, Object>(
      TimetableController.new,
    );

/// One controller per mounted timetable; identical loads share their lifecycle.
/// Raw WebUntis documents retain their existing representation and cache format.
class TimetableController extends Notifier<TimetableUiState> {
  TimetableController(this.owner);
  final Object owner;
  final Map<String, Future<void>> _inFlight = {};
  int _requestGeneration = 0;

  int beginRequest() => ++_requestGeneration;
  bool isCurrentRequest(int ticket) => ref.mounted && ticket == _requestGeneration;

  @override
  TimetableUiState build() => const TimetableUiState();

  TimetableUiState get current => state;
  bool get isLoading => state.refreshing;

  void update({
    Map<int, List<dynamic>>? week,
    Object? displayedMonday = _unchanged,
    bool? loading,
    bool? cached,
    Object? error = _unchanged,
  }) {
    state = state.copyWith(
      week: week == null ? null : Map<int, List<dynamic>>.unmodifiable(week),
      displayedMonday: displayedMonday,
      loading: loading,
      cached: cached,
      error: error,
    );
  }

  Future<void> runExclusive(String identity, Future<void> Function() load) {
    final active = _inFlight[identity];
    if (active != null) return active;
    // Schedule the operation after registration, including synchronous failures.
    late final Future<void> tracked;
    tracked = Future<void>(() async {
      if (!ref.mounted) return;
      state = state.copyWith(refreshing: true);
      await load();
    }).whenComplete(() {
      if (identical(_inFlight[identity], tracked)) _inFlight.remove(identity);
      if (ref.mounted) state = state.copyWith(refreshing: _inFlight.isNotEmpty);
    });
    _inFlight[identity] = tracked;
    return tracked;
  }
}
