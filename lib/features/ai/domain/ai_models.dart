import '../../../l10n.dart';

class AiMetric {
  const AiMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class AiLessonCardData {
  const AiLessonCardData({
    required this.subject,
    required this.subjectShort,
    required this.room,
    required this.teacher,
    required this.time,
    required this.isCancelled,
  });

  final String subject;
  final String subjectShort;
  final String room;
  final String teacher;
  final String time;
  final bool isCancelled;
}

class AiSearchResult {
  const AiSearchResult({
    required this.query,
    required this.headline,
    required this.summary,
    required this.tags,
    required this.metrics,
    required this.lessons,
    required this.rawReply,
  });

  final String query;
  final String headline;
  final String summary;
  final List<String> tags;
  final List<AiMetric> metrics;
  final List<AiLessonCardData> lessons;
  final String rawReply;
}

class AiChatSession {
  AiChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.timestamp,
  });

  final String id;
  String title;
  final List<Map<String, String>> messages;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AiChatSession.fromJson(Map<String, dynamic> json) {
    return AiChatSession(
      id: json['id'] as String,
      title: json['title']?.toString() ?? 'Chat',
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((message) => Map<String, String>.from(message as Map))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class AiProposedAction {
  const AiProposedAction(this.data);

  final Map<String, dynamic> data;

  String get kind => data['kind']?.toString() ?? '';
  String get id => data['id']?.toString() ?? '';
  String get subject => data['subject']?.toString().trim() ?? '';
  String get text =>
      (data['text'] ?? data['description'] ?? data['title'] ?? '')
          .toString()
          .trim();
  int? get date => int.tryParse(
    (data['date'] ?? data['dueDate'] ?? data['examDate'] ?? '')
        .toString()
        .replaceAll('-', ''),
  );
  double? get gradeValue => double.tryParse(
    (data['value'] ?? data['grade'] ?? '').toString().replaceAll(',', '.'),
  );
  double get gradeWeight =>
      double.tryParse(
        (data['weight'] ?? '1').toString().replaceAll(',', '.'),
      ) ??
      1;
  String get gradeType => data['type']?.toString().trim() ?? '';

  String summary(AppL10n l) {
    final values = {
      'subject': subject,
      'text': text,
      'id': id,
      'value': gradeValue,
    };
    return switch (kind) {
      'create_homework' => l.uiFormat('aiActionCreateHomework', values),
      'update_homework' => l.uiFormat('aiActionUpdateHomework', values),
      'delete_homework' => l.uiFormat('aiActionDeleteHomework', values),
      'complete_homework' => l.uiFormat('aiActionCompleteHomework', values),
      'create_exam' => l.uiFormat('aiActionCreateExam', values),
      'update_exam' => l.uiFormat('aiActionUpdateExam', values),
      'delete_exam' => l.uiFormat('aiActionDeleteExam', values),
      'create_grade' => l.uiFormat('aiActionCreateGrade', values),
      'update_grade' => l.uiFormat('aiActionUpdateGrade', values),
      'delete_grade' => l.uiFormat('aiActionDeleteGrade', values),
      _ => l.ui('aiActionUnknown'),
    };
  }

  bool get isSupported => const {
    'create_homework',
    'update_homework',
    'delete_homework',
    'complete_homework',
    'create_exam',
    'update_exam',
    'delete_exam',
    'create_grade',
    'update_grade',
    'delete_grade',
  }.contains(kind);
}
