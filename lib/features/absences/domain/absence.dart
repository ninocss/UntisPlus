enum AbsenceStatus { open, excused, unexcused, unknown }

class Absence {
  const Absence({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.subject = '',
    this.reason = '',
    this.text = '',
    this.checked = false,
  });

  final String id;
  final int date;
  final int startTime;
  final int endTime;
  final AbsenceStatus status;
  final String subject;
  final String reason;
  final String text;
  final bool checked;

  factory Absence.fromJson(Map<String, dynamic> json) {
    final checked = json['checked'] == true || json['isChecked'] == true;
    final excused = json['excused'] == true || json['isExcused'] == true;
    final statusText = (json['status'] ?? json['excuseStatus'] ?? '')
        .toString()
        .toLowerCase();
    final status = switch (statusText) {
      'excused' || 'entschuldigt' => AbsenceStatus.excused,
      'unexcused' || 'unentschuldigt' => AbsenceStatus.unexcused,
      'open' || 'offen' => AbsenceStatus.open,
      _ when excused => AbsenceStatus.excused,
      _ when statusText.isNotEmpty || checked => AbsenceStatus.unknown,
      _ => AbsenceStatus.open,
    };
    final date =
        (json['date'] as num?)?.toInt() ??
        (json['startDate'] as num?)?.toInt() ??
        0;
    final start = (json['startTime'] as num?)?.toInt() ?? 0;
    final end = (json['endTime'] as num?)?.toInt() ?? 0;
    final rawId = json['id'] ?? json['absenceId'];
    return Absence(
      id: rawId?.toString() ?? '$date|$start|$end',
      date: date,
      startTime: start,
      endTime: end,
      status: status,
      subject:
          (json['subject'] ?? json['subjectName'] ?? json['subjectId'] ?? '')
              .toString(),
      reason: (json['reason'] ?? json['absenceReason'] ?? '').toString(),
      text: (json['text'] ?? json['remark'] ?? json['user'] ?? '').toString(),
      checked: checked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'status': status.name,
    'subject': subject,
    'reason': reason,
    'text': text,
    'checked': checked,
  };
}
