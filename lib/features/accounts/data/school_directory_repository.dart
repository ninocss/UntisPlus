import '../../../core/school_models.dart';
import '../../../core/sync_state.dart';
import '../../../data/webuntis/webuntis_client.dart';

class SchoolDirectoryRepository {
  SchoolDirectoryRepository({WebUntisClient? client})
    : _client = client ?? WebUntisClient();

  static final Uri endpoint = Uri.parse(
    'https://mobile.webuntis.com/ms/schoolquery2',
  );

  final WebUntisClient _client;

  Future<List<SchoolSearchResult>> search(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3) return const <SchoolSearchResult>[];

    final payload = await _client.postJson(
      uri: endpoint,
      body: <String, Object?>{
        'id': '1',
        'method': 'searchSchool',
        'params': <Object?>[
          <String, Object?>{'search': normalizedQuery},
        ],
        'jsonrpc': '2.0',
      },
    );
    if (payload['error'] != null) {
      throw WebUntisFailure(
        WebUntisFailureKind.server,
        payload['error'].toString(),
      );
    }

    final result = payload['result'];
    final schools = result is Map ? result['schools'] : null;
    if (schools == null) return const <SchoolSearchResult>[];
    if (schools is! List) {
      throw const WebUntisFailure(
        WebUntisFailureKind.invalidData,
        'WebUntis returned an invalid school directory response.',
      );
    }

    return schools
        .whereType<Map>()
        .map(
          (school) => SchoolSearchResult.fromJson(
            school.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where(
          (school) =>
              school.loginName.isNotEmpty && school.serverUrl.isNotEmpty,
        )
        .toList(growable: false);
  }

  void close() => _client.close();
}
