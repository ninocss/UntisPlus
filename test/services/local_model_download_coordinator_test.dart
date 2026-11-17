import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  test('download coordinator exposes immutable idle state after cancel', () {
    final coordinator = LocalModelDownloadCoordinator.instance;
    coordinator.cancel('test-model');

    final state = coordinator.stateFor('test-model');
    expect(state.phase, LocalModelDownloadPhase.idle);
    expect(state.isDownloading, isFalse);
    expect(state.hasError, isFalse);
    expect(
      () =>
          coordinator.value['another-model'] = const LocalModelDownloadState(),
      throwsUnsupportedError,
    );
  });
}
