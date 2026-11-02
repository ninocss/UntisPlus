import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/ai/application/ai_request_cancellation.dart';

void main() {
  test(
    'cancel before first response releases provider and completes',
    () async {
      final source = StreamController<String>();
      final request = AiRequestCancellation();
      var releases = 0;
      final result = request.guard(source.stream, () async {
        releases++;
        await source.close();
      }).toList();
      final assertion = expectLater(result, throwsA(isA<AiRequestCancelled>()));
      request.cancel();
      await assertion;
      expect(releases, 1);
    },
  );
  test('cancel after a partial response never delivers later text', () async {
    final source = StreamController<String>(sync: true);
    final request = AiRequestCancellation();
    final received = <String>[];
    final errors = <Object>[];
    final done = Completer<void>();
    request
        .guard(source.stream, () async {})
        .listen(received.add, onError: errors.add, onDone: done.complete);
    source.add('partial');
    await Future<void>.delayed(Duration.zero);
    request.cancel();
    source.add('late response');
    await done.future;
    await source.close();
    expect(received, ['partial']);
    expect(errors.single, isA<AiRequestCancelled>());
  });
}
