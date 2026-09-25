import '../../../core/time_utils.dart';
import '../../../core/sync_state.dart';
import '../../../data/webuntis/webuntis_client.dart';
import '../../../data/webuntis/webuntis_session_manager.dart';

class WebUntisExamRepository {
  WebUntisExamRepository({WebUntisClient? client})
    : _client = client ?? WebUntisClient();

  final WebUntisClient _client;
  late final WebUntisSessionManager _sessions = WebUntisSessionManager(
    client: _client,
  );

  Future<List<Map<String, dynamic>>> fetch({
    required WebUntisRequestContext context,
    required int personId,
    required DateTime start,
    required DateTime end,
    WebUntisAccountLogin? account,
  }) async {
    final query =
        'startDate=${formatUntisDate(start)}&endDate=${formatUntisDate(end)}';
    final paths = <String>[
      '/WebUntis/api/exams',
      '/WebUntis/api/classreg/exams',
      if (personId != 0) '/WebUntis/api/exams/student/$personId',
    ];

    Future<List<Map<String, dynamic>>> request(
      WebUntisRequestContext requestContext,
    ) async {
      for (final path in paths) {
        try {
          final decoded = await _client.getJson(
            uri: Uri.parse('https://${requestContext.schoolUrl}$path?$query'),
            headers: {
              'Accept': 'application/json',
              if (requestContext.sessionId.isNotEmpty)
                'Cookie':
                    'JSESSIONID=${requestContext.sessionId}; '
                    'schoolname=${requestContext.cookieSchoolName ?? requestContext.schoolName}',
            },
          );
          final exams = _decodeExamList(decoded);
          if (exams.isNotEmpty) return exams;
        } on WebUntisFailure catch (failure) {
          if (failure.kind == WebUntisFailureKind.authentication) rethrow;
          // Older WebUntis installations expose only one of these endpoints.
        } catch (_) {
          // Older WebUntis installations expose only one of these endpoints.
        }
      }
      return const [];
    }

    if (account != null) {
      try {
        return await _sessions.runAuthenticated(
          account: account,
          currentSessionId: context.sessionId,
          request: request,
        );
      } catch (_) {
        return const [];
      }
    }
    return request(context);
  }

  List<Map<String, dynamic>> _decodeExamList(dynamic decoded) {
    dynamic findList(dynamic value, [int depth = 0]) {
      if (value is List) return value;
      if (value is! Map || depth >= 5) return null;
      for (final key in const [
        'exams',
        'examList',
        'items',
        'rows',
        'result',
        'data',
      ]) {
        if (value.containsKey(key)) {
          final result = findList(value[key], depth + 1);
          if (result is List) return result;
        }
      }
      return null;
    }

    final raw = findList(decoded);
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((value) {
      final exam = Map<String, dynamic>.from(value);
      final date = exam['date'] ?? exam['examDate'] ?? exam['startDate'];
      if (date != null) {
        exam.putIfAbsent('date', () => date.toString().replaceAll('-', ''));
      }
      final subject = exam['subject'] ?? exam['subjectName'] ?? exam['name'];
      if (subject != null) exam.putIfAbsent('subject', () => subject);
      return exam;
    }).toList(growable: false);
  }
}
