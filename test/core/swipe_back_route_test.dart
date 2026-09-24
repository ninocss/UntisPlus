import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart' as app;

void main() {
  group('SwipeBackPageRoute', () {
    test('popGestureEnabled returns false when feature disabled', () {
      app.swipeBackGestureNotifier.value = false;

      final route = app.SwipeBackPageRoute<void>(
        pageBuilder: (_, __, ___) => const Text('Test'),
        transitionsBuilder: (_, __, ___, child) => child,
      );

      expect(route.popGestureEnabled, false);
    });

    test('popGestureEnabled returns false when feature enabled but no navigator (first route)', () {
      app.swipeBackGestureNotifier.value = true;

      final route = app.SwipeBackPageRoute<void>(
        pageBuilder: (_, __, ___) => const Text('Test'),
        transitionsBuilder: (_, __, ___, child) => child,
      );

      // Without a navigator, the route is considered "first" and popGestureEnabled returns false
      expect(route.popGestureEnabled, false);
    });

    test('popGestureEnabled returns false for fullscreenDialog', () {
      app.swipeBackGestureNotifier.value = true;

      final route = app.SwipeBackPageRoute<void>(
        pageBuilder: (_, __, ___) => const Text('Test'),
        transitionsBuilder: (_, __, ___, child) => child,
        fullscreenDialog: true,
      );

      expect(route.popGestureEnabled, false);
    });
  });
}