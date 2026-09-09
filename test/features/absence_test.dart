import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/features/absences/domain/absence.dart';

void main() {
  test('parses an excused absence defensively', () {
    final absence = Absence.fromJson({
      'id': 12,
      'date': 20260908,
      'startTime': 800,
      'endTime': 845,
      'subjectName': 'Mathematik',
      'isExcused': true,
      'absenceReason': 'Krankheit',
    });

    expect(absence.id, '12');
    expect(absence.status, AbsenceStatus.excused);
    expect(absence.subject, 'Mathematik');
    expect(absence.reason, 'Krankheit');
  });

  test('does not infer unexcused from checked alone', () {
    final absence = Absence.fromJson({
      'date': 20260908,
      'startTime': 800,
      'endTime': 845,
      'checked': true,
    });

    expect(absence.status, AbsenceStatus.unknown);
  });

  test('uses explicit unexcused status', () {
    final absence = Absence.fromJson({
      'date': 20260908,
      'startTime': 800,
      'endTime': 845,
      'status': 'unexcused',
    });

    expect(absence.status, AbsenceStatus.unexcused);
  });
}
