import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore.initialize(preferences: prefs);
    appLocaleNotifier.value = 'de';
    demoModeNotifier.value = true;
  });

  tearDown(() {
    demoModeNotifier.value = false;
  });

  testWidgets(
    '5-day week view allows swiping to next week on standard 360dp phone screen',
    (tester) async {
      // Set phone screen width to 360dp (like Samsung S24)
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 dp
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const UntisPlusApp(startScreen: WeeklyTimetablePage()));
      await tester.pumpAndSettle();

      // Switch to 5-day week view (viewMode = 2)
      final toggle = find.byKey(const ValueKey('timetable-view-toggle'));
      expect(toggle, findsOneWidget);

      // Toggle from day view (0) -> 3-day view (1)
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Toggle from 3-day view (1) -> 5-day week view (2)
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      final currentMondayTextFinder = find.byWidgetPredicate((widget) {
        if (widget is KeyedSubtree && widget.key is ValueKey<String>) {
          final val = (widget.key as ValueKey<String>).value;
          return val.startsWith('carousel-');
        }
        return false;
      });
      expect(currentMondayTextFinder, findsOneWidget);
      final initialKey = (tester.widget<KeyedSubtree>(currentMondayTextFinder).key as ValueKey<String>).value;

      // Swipe left on the timetable to navigate to the next week
      await tester.drag(find.byType(WeeklyTimetablePage), const Offset(-250, 0));
      await tester.pumpAndSettle();

      final afterSwipeFinder = find.byWidgetPredicate((widget) {
        if (widget is KeyedSubtree && widget.key is ValueKey<String>) {
          final val = (widget.key as ValueKey<String>).value;
          return val.startsWith('carousel-');
        }
        return false;
      });
      expect(afterSwipeFinder, findsOneWidget);
      final afterSwipeKey = (tester.widget<KeyedSubtree>(afterSwipeFinder).key as ValueKey<String>).value;

      // The week should have changed after swiping left!
      expect(afterSwipeKey, isNot(equals(initialKey)), reason: 'Swiping left in 5-day view should switch to the next week');

      // Swipe right on the timetable to navigate back to the original week
      await tester.drag(find.byType(WeeklyTimetablePage), const Offset(250, 0));
      await tester.pumpAndSettle();

      final finalFinder = find.byWidgetPredicate((widget) {
        if (widget is KeyedSubtree && widget.key is ValueKey<String>) {
          final val = (widget.key as ValueKey<String>).value;
          return val.startsWith('carousel-');
        }
        return false;
      });
      final finalKey = (tester.widget<KeyedSubtree>(finalFinder).key as ValueKey<String>).value;
      expect(finalKey, equals(initialKey), reason: 'Swiping right should return to original week');
    },
  );

  testWidgets(
    '3-day view allows swiping to next week on standard 360dp phone screen',
    (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1080, 2340);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const UntisPlusApp(startScreen: WeeklyTimetablePage()));
      await tester.pumpAndSettle();

      // Switch to 3-day view (viewMode = 1)
      final toggle = find.byKey(const ValueKey('timetable-view-toggle'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      final currentMondayTextFinder = find.byWidgetPredicate((widget) {
        if (widget is KeyedSubtree && widget.key is ValueKey<String>) {
          final val = (widget.key as ValueKey<String>).value;
          return val.startsWith('carousel-');
        }
        return false;
      });
      final initialKey = (tester.widget<KeyedSubtree>(currentMondayTextFinder).key as ValueKey<String>).value;

      await tester.drag(find.byType(WeeklyTimetablePage), const Offset(-250, 0));
      await tester.pumpAndSettle();

      final afterSwipeFinder = find.byWidgetPredicate((widget) {
        if (widget is KeyedSubtree && widget.key is ValueKey<String>) {
          final val = (widget.key as ValueKey<String>).value;
          return val.startsWith('carousel-');
        }
        return false;
      });
      final afterSwipeKey = (tester.widget<KeyedSubtree>(afterSwipeFinder).key as ValueKey<String>).value;
      expect(afterSwipeKey, isNot(equals(initialKey)));
    },
  );
}
