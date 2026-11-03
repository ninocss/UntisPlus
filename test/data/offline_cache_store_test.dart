import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/data/cache/offline_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('untisplus_cache_test_');
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

  test('keyFilter filters keys before decoding documents and tracks revisions',
      () async {
    final store = OfflineCacheStore.instance;
    final prefix = 'acc-test|timetableWeek|';
    await store.deletePrefix(prefix);

    final initialRevision = store.revision;
    expect(await store.hasKeyWithPrefix(prefix), isFalse);

    await store.write('${prefix}weekCacheV1|s|n|5|1|20261102', {
      'weekData': {
        '0': [
          {'date': 20261102, 'startTime': 800, 'endTime': 845},
        ],
      },
    });
    await store.write('${prefix}weekCacheV1|s|n|5|1|20261026', {
      'weekData': {
        '0': [
          {'date': 20261026, 'startTime': 800, 'endTime': 845},
        ],
      },
    });

    expect(store.revision, greaterThan(initialRevision));
    expect(await store.hasKeyWithPrefix(prefix), isTrue);

    final inspectedKeys = <String>[];
    final filtered = await store.readAllWithPrefix(
      prefix,
      keyFilter: (key) {
        inspectedKeys.add(key);
        return key.endsWith('|20261102');
      },
    );

    expect(inspectedKeys, hasLength(2));
    expect(filtered, hasLength(1));
    final weekData = filtered.single.value['weekData'] as Map;
    expect((weekData['0'] as List).single['date'], 20261102);

    final revisionBeforeDelete = store.revision;
    await store.deletePrefix(prefix);
    expect(store.revision, greaterThan(revisionBeforeDelete));
    expect(await store.hasKeyWithPrefix(prefix), isFalse);
  });
}
