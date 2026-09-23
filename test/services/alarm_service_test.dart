import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/services/alarm_service.dart';

void main() {
  final now = DateTime(2026, 9, 7, 6, 0);

  Map<String, dynamic> lesson({
    required int date,
    required int start,
    String? code,
    String subject = 'Mathematik',
  }) => {
    'date': date,
    'startTime': start,
    'code': ?code,
    'su': [
      {'longName': subject},
    ],
  };

  test('moves the smart alarm past a cancelled first lesson', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [
        lesson(date: 20260907, start: 800, code: 'cancelled'),
        lesson(date: 20260907, start: 945, subject: 'Englisch'),
      ],
      leadMinutes: 45,
      now: now,
    );

    expect(candidate?.at, DateTime(2026, 9, 7, 9, 0));
    expect(candidate?.label, 'Englisch');
  });

  test('activation requires exact alarms and notifications only', () {
    const readyWithoutOptionalEnhancements = AlarmReadiness(
      exactAlarms: true,
      notifications: true,
      fullScreenIntent: false,
      dndAccess: false,
    );
    const missingNotifications = AlarmReadiness(
      exactAlarms: true,
      notifications: false,
      fullScreenIntent: true,
      dndAccess: true,
    );

    expect(readyWithoutOptionalEnhancements.activationReady, isTrue);
    expect(readyWithoutOptionalEnhancements.optionalEnhancementsReady, isFalse);
    expect(missingNotifications.activationReady, isFalse);
  });

  test('date overrides do not alter recurring manual alarms', () {
    const manual = ManualAlarmConfig(
      id: 'school-days',
      timeOfDayMinutes: 420,
      weekdays: [1, 2, 3, 4, 5],
    );
    const config = AlarmConfig(
      manualAlarms: [manual],
      dateOverrides: {'20260908': AlarmDateOverride(disabled: true)},
    );

    final restored = AlarmConfig.fromJson(config.toJson());
    expect(restored.manualAlarms.single.weekdays, [1, 2, 3, 4, 5]);
    expect(restored.manualAlarms.single.enabled, isTrue);
    expect(restored.dateOverrides['20260908']?.disabled, isTrue);
  });

  test('structured scheduling result exposes paused permission state', () {
    final result = AlarmSchedulingResult.fromMap({
      'status': 'paused_missing_permission',
      'exactScheduled': false,
      'paused': true,
      'storedCount': 2,
      'scheduledCount': 0,
      'missingPermissions': ['exactAlarms'],
    });

    expect(result.status, AlarmSchedulingStatus.pausedMissingPermission);
    expect(result.paused, isTrue);
    expect(result.storedCount, 2);
    expect(result.missingPermissions, ['exactAlarms']);
  });

  test('skips a free day and picks the next active school day', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [
        lesson(date: 20260907, start: 800, code: 'cancelled'),
        lesson(date: 20260908, start: 745, subject: 'Biologie'),
      ],
      leadMinutes: 30,
      now: now,
    );

    expect(candidate?.at, DateTime(2026, 9, 8, 7, 15));
  });

  test('does not create an alarm when every future lesson is cancelled', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [lesson(date: 20260907, start: 800, code: 'cancelled')],
      leadMinutes: 30,
      now: now,
    );

    expect(candidate, isNull);
  });

  test(
    'never schedules a later lesson when the first wake time has passed',
    () {
      final candidate = AlarmPlanner.nextSmartAlarm(
        [
          lesson(date: 20260907, start: 800),
          lesson(date: 20260907, start: 1100, subject: 'Englisch'),
          lesson(date: 20260908, start: 745, subject: 'Biologie'),
        ],
        leadMinutes: 30,
        now: DateTime(2026, 9, 7, 9, 0),
      );

      expect(candidate?.at, DateTime(2026, 9, 8, 7, 15));
      expect(candidate?.label, 'Biologie');
    },
  );

  test('uses the next non-cancelled lesson when first period is cancelled', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [
        lesson(date: 20260908, start: 745, code: 'cancelled'),
        lesson(date: 20260908, start: 900, subject: 'Physik'),
      ],
      leadMinutes: 30,
      now: DateTime(2026, 9, 7, 18),
    );

    expect(candidate?.at, DateTime(2026, 9, 8, 8, 30));
  });

  test('skips a date explicitly disabled in the planner', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [
        lesson(date: 20260908, start: 800),
        lesson(date: 20260909, start: 800, subject: 'Deutsch'),
      ],
      leadMinutes: 30,
      now: DateTime(2026, 9, 7, 18),
      dateOverrides: const {'20260908': AlarmDateOverride(disabled: true)},
    );

    expect(candidate?.at, DateTime(2026, 9, 9, 7, 30));
    expect(candidate?.dateKey, '20260909');
  });

  test('uses a custom daily time and early offset', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [lesson(date: 20260908, start: 800)],
      leadMinutes: 30,
      now: DateTime(2026, 9, 7, 18),
      dateOverrides: const {
        '20260908': AlarmDateOverride(
          customTimeOfDayMinutes: 7 * 60,
          earlierMinutes: 10,
        ),
      },
    );

    expect(candidate?.at, DateTime(2026, 9, 8, 6, 50));
    expect(candidate?.baseAt, DateTime(2026, 9, 8, 7, 30));
  });

  test('uses a lead-time override for the first lesson start time', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [lesson(date: 20260908, start: 930)],
      leadMinutes: 90,
      leadMinutesByFirstLessonStart: const {9 * 60 + 30: 120},
      now: DateTime(2026, 9, 7, 18),
    );

    expect(candidate?.at, DateTime(2026, 9, 8, 7, 30));
    expect(candidate?.baseAt, DateTime(2026, 9, 8, 7, 30));
  });

  test('skips a day when its first lesson start time disables alarms', () {
    final candidate = AlarmPlanner.nextSmartAlarm(
      [
        lesson(date: 20260908, start: 930),
        lesson(date: 20260909, start: 800, subject: 'Deutsch'),
      ],
      leadMinutes: 30,
      leadMinutesByFirstLessonStart: const {9 * 60 + 30: -1},
      now: DateTime(2026, 9, 7, 18),
    );

    expect(candidate?.at, DateTime(2026, 9, 9, 7, 30));
    expect(candidate?.label, 'Deutsch');
  });
}
