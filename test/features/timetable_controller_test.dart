import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/timetable/application/timetable_controller.dart';
import 'package:untisplus/features/timetable/domain/timetable_presentation.dart';

void main() {
  test(
    'parallel refreshes coalesce and loading resets after failure',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = timetableControllerProvider(Object());
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final controller = container.read(provider.notifier);
      var calls = 0;
      final gate = Completer<void>();
      Future<void> load() async {
        calls++;
        await gate.future;
      }

      final first = controller.runExclusive('account/person/week', load);
      final second = controller.runExclusive('account/person/week', load);
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      expect(controller.isLoading, isTrue);
      gate.complete();
      await first;
      expect(controller.isLoading, isFalse);

      await expectLater(
        controller.runExclusive('account/person/week', () async {
          throw StateError('offline');
        }),
        throwsStateError,
      );
      expect(controller.isLoading, isFalse);
      await controller.runExclusive('account/person/week', () async {
        calls++;
      });
      expect(calls, 2);
    },
  );

  test('stale requests cannot become current after a newer context starts', () {
    final container = ProviderContainer();
    final provider = timetableControllerProvider(Object());
    final sub = container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier);
    final old = controller.beginRequest();
    final current = controller.beginRequest();
    expect(controller.isCurrentRequest(old), isFalse);
    expect(controller.isCurrentRequest(current), isTrue);
    sub.close();
    container.dispose();
    expect(controller.isCurrentRequest(current), isFalse);
  });

  test(
    'empty cached weeks retain their date and refresh error independently',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = timetableControllerProvider(Object());
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(provider.notifier);
      final monday = DateTime(2026, 10, 5);
      controller.update(
        week: {0: [], 1: [], 2: [], 3: [], 4: []},
        displayedMonday: monday,
        cached: true,
        loading: false,
      );
      controller.update(error: 'offline');
      expect(controller.current.cached, isTrue);
      expect(controller.current.displayedMonday, monday);
      expect(
        controller.current.week.values.every((day) => day.isEmpty),
        isTrue,
      );
      expect(controller.current.error, 'offline');
      controller.update(error: null);
      expect(controller.current.error, isNull);
    },
  );

  test(
    'lesson layout reuses overlap columns and resets for separate clusters',
    () {
      final slots = computeLessonSlots([
        {'id': 4, 'startTime': 1000, 'endTime': 1045},
        {'id': 3, 'startTime': 845, 'endTime': 930},
        {'id': 2, 'startTime': 815, 'endTime': 900},
        {'id': 1, 'startTime': 800, 'endTime': 845},
      ]);
      expect(slots.map((slot) => slot.lesson['id']), [1, 2, 3, 4]);
      expect(slots.map((slot) => slot.column), [0, 1, 0, 0]);
      expect(slots.map((slot) => slot.columnCount), [2, 2, 2, 1]);
    },
  );

  test(
    'missing lesson end crosses the hour correctly, invalid intervals are dropped',
    () {
      final slots = computeLessonSlots([
        {'startTime': 850},
        {'startTime': 900, 'endTime': 900},
        {'startTime': 930, 'endTime': 900},
        'malformed',
      ]);
      expect(slots, hasLength(1));
      expect(slots.single.startMin, 530);
      expect(slots.single.endMin, 575);
    },
  );
}
