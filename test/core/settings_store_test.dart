import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses defaults and updates notifier on load', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = await SettingsStore.initialize(preferences: prefs);
    final notifier = ValueNotifier<int>(99);
    final binding = intPreference(
      key: 'count',
      defaultValue: 4,
      notifier: notifier,
    );

    expect(store.read(binding), 4);
    await store.load(binding);
    expect(notifier.value, 4);
  });

  test('roundtrips supported primitive and string-list values', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = await SettingsStore.initialize(preferences: prefs);

    final boolBinding = boolPreference(
      key: 'enabled',
      defaultValue: false,
      notifier: ValueNotifier(false),
    );
    final intBinding = intPreference(
      key: 'count',
      defaultValue: 0,
      notifier: ValueNotifier(0),
    );
    final doubleBinding = doublePreference(
      key: 'ratio',
      defaultValue: 0,
      notifier: ValueNotifier(0),
    );
    final stringBinding = stringPreference(
      key: 'label',
      defaultValue: '',
      notifier: ValueNotifier(''),
    );
    final listBinding = stringListPreference(
      key: 'items',
      defaultValue: const [],
      notifier: ValueNotifier<List<String>>(<String>[]),
    );

    await store.write(boolBinding, true);
    await store.write(intBinding, 7);
    await store.write(doubleBinding, 1.25);
    await store.write(stringBinding, 'value');
    await store.write(listBinding, const ['a', 'b']);

    expect(store.read(boolBinding), isTrue);
    expect(store.read(intBinding), 7);
    expect(store.read(doubleBinding), 1.25);
    expect(store.read(stringBinding), 'value');
    expect(store.read(listBinding), ['a', 'b']);
  });

  test('normalizes values before notifier and persistence update', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = await SettingsStore.initialize(preferences: prefs);
    final notifier = ValueNotifier<double>(0);
    final binding = doublePreference(
      key: 'opacity',
      defaultValue: 0.5,
      notifier: notifier,
      normalize: (value) => value.clamp(0.25, 1).toDouble(),
    );

    await store.write(binding, 2);

    expect(notifier.value, 1);
    expect(prefs.getDouble('opacity'), 1);
  });

  test('supports JSON bindings and defensive fallback', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = await SettingsStore.initialize(preferences: prefs);
    final notifier = ValueNotifier<Map<String, bool>>(<String, bool>{});
    final binding = jsonPreference<Map<String, bool>>(
      key: 'flags',
      defaultValue: const {'default': true},
      notifier: notifier,
      decodeJson: (decoded) {
        if (decoded is! Map) return const {'default': true};
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value == true),
        );
      },
      encodeJson: (value) => value,
    );

    await store.write(binding, const {'a': true, 'b': false});
    expect(jsonDecode(prefs.getString('flags')!), {
      'a': true,
      'b': false,
    });
    expect(store.read(binding), {'a': true, 'b': false});

    await prefs.setString('flags', '{broken');
    expect(store.read(binding), {'default': true});
  });

  test('account namespaces keep values isolated', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = await SettingsStore.initialize(preferences: prefs);
    final notifier = ValueNotifier<String>('');
    final binding = stringPreference(
      key: 'draft',
      defaultValue: '',
      notifier: notifier,
      accountNamespace: 'account',
    );

    await store.write(binding, 'first', accountId: 'a');
    await store.write(binding, 'second', accountId: 'b');

    expect(store.read(binding, accountId: 'a'), 'first');
    expect(store.read(binding, accountId: 'b'), 'second');
    expect(prefs.getString('account.a.draft'), 'first');
    expect(prefs.getString('account.b.draft'), 'second');
  });
}
