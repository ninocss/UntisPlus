import '../../../core/time_utils.dart';
import '../../../data/webuntis/webuntis_client.dart';

class WebUntisExamRepository {
  WebUntisExamRepository({WebUntisClient? client})
    : _client = client ?? WebUntisClient();

  final WebUntisClient _client;

  Future<List<Map<String, dynamic>>> fetch({
    required WebUntisRequestContext context,
    required int personId,
    required DateTime start,
    required DateTime end,
  }) async {
    final query =
        'startDate=${formatUntisDate(start)}&endDate=${formatUntisDate(end)}';
    final paths = <String>[
      '/WebUntis/api/exams',
      '/WebUntis/api/classreg/exams',
      if (personId != 0) '/WebUntis/api/exams/student/$personId',
    ];

    for (final path in paths) {
      try {
        final decoded = await _client.getJson(
          uri: Uri.parse('https://${context.schoolUrl}$path?$query'),
          headers: {
            'Accept': 'application/json',
            if (context.sessionId.isNotEmpty)
              'Cookie':
                  'JSESSIONID=${context.sessionId}; schoolname=${context.schoolName}',
          },
        );
        final exams = _decodeExamList(decoded);
        if (exams.isNotEmpty) return exams;
      } catch (_) {
        // Older WebUntis installations expose only one of these endpoints.
      }
    }
    return const [];
  }

  List<Map<String, dynamic>> _decodeExamList(dynamic decoded) {
    final raw = switch (decoded) {
      List<dynamic> values => values,
      Map<dynamic, dynamic> values =>
        values['data'] ?? values['exams'] ?? values['result'] ?? const [],
      _ => const [],
    };
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList(growable: false);
  }
}
