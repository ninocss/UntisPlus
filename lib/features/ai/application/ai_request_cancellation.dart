import 'dart:async';

class AiRequestCancelled implements Exception {
  const AiRequestCancelled();
}

/// One token per request. Cancelling stops delivery immediately and releases
/// the provider, including an HTTP request that has not produced its first byte.
class AiRequestCancellation {
  final Completer<void> _signal = Completer<void>();
  bool get isCancelled => _signal.isCompleted;

  void cancel() {
    if (!isCancelled) _signal.complete();
  }

  Stream<T> guard<T>(Stream<T> source, Future<void> Function() release) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    var ended = false;
    Future<void>? cleanup;
    Future<void> stop() => cleanup ??= () async {
      try {
        await release();
      } finally {
        await subscription?.cancel();
      }
    }();
    controller = StreamController<T>(
      onListen: () {
        if (isCancelled) {
          ended = true;
          controller.addError(const AiRequestCancelled());
          unawaited(controller.close());
          return;
        }
        subscription = source.listen(
          (value) {
            if (!ended && !isCancelled) controller.add(value);
          },
          onError: (Object error, StackTrace stack) {
            if (!ended) controller.addError(error, stack);
          },
          onDone: () {
            if (!ended) {
              ended = true;
              unawaited(controller.close());
            }
          },
        );
        _signal.future.then((_) {
          if (ended) return;
          ended = true;
          controller.addError(const AiRequestCancelled());
          unawaited(controller.close());
          // Cleanup errors must not replace the cancellation delivered above.
          unawaited(stop().catchError((Object _) {}));
        });
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        ended = true;
        return stop();
      },
    );
    return controller.stream;
  }
}
