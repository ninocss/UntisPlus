enum SyncSource { none, cache, network }

enum SyncPhase { idle, loading, refreshing, ready, failed }

enum WebUntisFailureKind {
  offline,
  timeout,
  authentication,
  permission,
  unsupported,
  server,
  invalidData,
  unknown,
}

class WebUntisFailure implements Exception {
  const WebUntisFailure(this.kind, this.message, {this.statusCode, this.cause});

  final WebUntisFailureKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}

/// Data plus freshness metadata used by every offline-first feature.
class SyncState<T> {
  const SyncState({
    required this.data,
    this.phase = SyncPhase.idle,
    this.source = SyncSource.none,
    this.lastSuccessfulSync,
    this.failure,
    this.isStale = false,
  });

  final T data;
  final SyncPhase phase;
  final SyncSource source;
  final DateTime? lastSuccessfulSync;
  final WebUntisFailure? failure;
  final bool isStale;

  bool get hasData => source != SyncSource.none;
  bool get isRefreshing => phase == SyncPhase.refreshing;

  SyncState<T> copyWith({
    T? data,
    SyncPhase? phase,
    SyncSource? source,
    DateTime? lastSuccessfulSync,
    WebUntisFailure? failure,
    bool clearFailure = false,
    bool? isStale,
  }) {
    return SyncState<T>(
      data: data ?? this.data,
      phase: phase ?? this.phase,
      source: source ?? this.source,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      failure: clearFailure ? null : failure ?? this.failure,
      isStale: isStale ?? this.isStale,
    );
  }
}
