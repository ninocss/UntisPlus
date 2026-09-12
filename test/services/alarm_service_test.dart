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
}
