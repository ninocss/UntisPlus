import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/core/time_utils.dart';
import 'package:untisplus/core/timetable_date_utils.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('untisplus_tt_cache_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore.initialize(preferences: prefs);
    appLocaleNotifier.value = 'de';
  });

  tearDown(() {
    demoModeNotifier.value = false;
    untisAccountsNotifier.value = [];
  });

  testWidgets('Timetable displays offline banner when displaying cached week', (
    tester,
  ) async {
    final prefs = SettingsStore.instance.preferences;

    final monday = resolveDefaultTimetableMonday(DateTime.now());
    final mondayStr = untisDateString(monday);

    schoolUrl = 'https://demo.untis.at';
    schoolName = 'demo_school';
    personId = 1234;
    personType = 5;
    activeUntisAccountId = 'acc1';
    untisAccountsNotifier.value = [
      UntisAccount(
        id: 'acc1',
        username: 'user',
        schoolUrl: 'https://demo.untis.at',
        schoolName: 'demo_school',
        password: 'pwd',
        credentialMode: 'password',
        sessionId: '',
        personId: 1234,
        personType: 5,
        lastUsedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    ];

    final cacheKey = [
      'weekCacheV1',
      schoolUrl,
      schoolName,
      '5',
      '1234',
      mondayStr,
    ].join('|');

    final cachedPayload = {
      'weekData': {
        '0': [
          {
            'id': 1,
            'date': int.parse(mondayStr),
            'startTime': 800,
            'endTime': 845,
            '_subjectShort': 'M',
            'su': [
              {'id': 10, 'name': 'M', 'longname': 'Mathematik'}
            ],
            'te': [
              {'id': 20, 'name': 'MUE'}
            ],
            'ro': [
              {'id': 30, 'name': 'R101'}
            ],
          }
        ],
        '1': [],
        '2': [],
        '3': [],
        '4': [],
      },
      'holidays': [],
    };

    await prefs.setString(cacheKey, jsonEncode(cachedPayload));

    // Build WeeklyTimetablePage
    await tester.pumpWidget(
      const MaterialApp(
        home: WeeklyTimetablePage(),
      ),
    );
    // Pump enough to exceed timeout and let cached week populate
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify offline notice banner appears
    expect(find.byKey(const ValueKey('timetable-offline-banner')), findsOneWidget);
    expect(
      find.text('Du bist offline. Dein Stundenplan ist möglicherweise nicht aktuell.'),
      findsOneWidget,
    );
  });
}
