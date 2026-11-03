import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/data/cache/offline_cache_store.dart';
import 'package:untisplus/data/webuntis/untis_endpoint.dart';
import 'package:untisplus/data/webuntis/webuntis_client.dart';
import 'package:untisplus/features/timetable/data/room_search_service.dart';
import 'package:untisplus/features/timetable/data/timetable_repository.dart';
import 'package:untisplus/features/timetable/domain/room_schedule.dart';
import 'package:untisplus/services/demo_mode_service.dart';

class _FakeClient extends WebUntisClient {
  _FakeClient({
    this.classes = const [],
    this.rooms = const [],
    this.timetables = const {},
  });

  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> rooms;
  final Map<String, List<dynamic>> timetables;

  @override
  Future<Map<String, dynamic>> rpc({
    required WebUntisRequestContext context,
    required String method,
    required Object params,
    String requestId = 'untisplus',
    bool internal = false,
  }) async {
    if (method == 'getKlassen') {
      return {'result': classes};
    }
    if (method == 'getRooms') {
      return {'result': rooms};
    }
    if (method == 'getTimetable' && params is Map) {
      final options = params['options'] as Map<String, dynamic>?;
      final element = options?['element'] as Map<String, dynamic>?;
      final key = '${element?['type']}_${element?['id']}';
      return {'result': timetables[key] ?? const <dynamic>[]};
    }
    return {'result': const <dynamic>[]};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoModeService demoRooms', () {
    test('provides demo rooms and realistic sample schedules', () {
      final rooms = DemoModeService.demoRooms();
      expect(rooms, isNotEmpty);
      expect(rooms.first['name'], isNotEmpty);

      final lessons = DemoModeService.demoRoomLessons(
        roomId: rooms.first['id'] as int,
        date: DateTime.now(),
      );
      expect(lessons, isA<List<dynamic>>());
    });
  });

  group('RoomSearchService', () {
    final context = WebUntisRequestContext(
      schoolUrl: 'https://test.webuntis.com',
      schoolName: 'TestSchool',
      sessionId: 'test_session',
    );

    test('refreshes index with direct getRooms and class timetables fallback', () async {
      final fakeClient = _FakeClient(
        classes: [
          {'id': 101, 'name': '10A'},
        ],
        rooms: [
          {'id': 201, 'name': 'R101', 'longName': 'Raum 101'},
          {'id': 202, 'name': 'R102', 'longName': 'Raum 102'},
        ],
        timetables: {
          '1_101': [
            {
              'date': 20260924,
              'startTime': 800,
              'endTime': 845,
              'su': [{'name': 'Mathe'}],
              'te': [{'name': 'Müller'}],
              'ro': [{'id': 201, 'name': 'R101'}],
              'kl': [{'name': '10A'}],
            },
          ],
        },
      );

      final repo = TimetableRepository(client: fakeClient);
      final service = RoomSearchService(repository: repo);

      final index = await service.buildIndexFromCatalogAndRooms(
        context: context,
        date: DateTime(2026, 9, 24),
      );

      expect(index.rooms.length, 2);
      expect(index.rooms.map((r) => r.name), containsAll(['R101', 'R102']));
      expect(index.lessonsByRoomId[201], hasLength(1));
    });
  });
}
