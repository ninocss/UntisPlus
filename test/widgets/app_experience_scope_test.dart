import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';
import 'package:untisplus/widgets/app_experience_scope.dart';
import 'package:untisplus/widgets/lazy_content_list.dart';
import 'package:untisplus/features/timetable/presentation/timetable_carousel.dart';

void main() {
  tearDown(() {
    effectQualityNotifier.value = AppEffectQuality.full;
    interactionAnimationsEnabledNotifier.value = true;
    hapticsEnabledNotifier.value = true;
  });

  testWidgets(
    'system reduced motion and app pause override interaction preference',
    (tester) async {
      bool enabled = true;
      Widget probe({bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: AppExperienceScope(
            child: Builder(
              builder: (context) {
                enabled = AppMotion.enabled(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpWidget(probe());
      expect(enabled, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(enabled, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(enabled, isTrue);
      await tester.pumpWidget(probe(reduced: true));
      expect(enabled, isFalse);
      await tester.pumpWidget(probe());
      interactionAnimationsEnabledNotifier.value = false;
      await tester.pump();
      expect(enabled, isFalse);
    },
  );

  testWidgets('balanced backgrounds pause during scrolling then resume', (
    tester,
  ) async {
    effectQualityNotifier.value = AppEffectQuality.balanced;
    bool allowed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AppExperienceScope(
          child: Builder(
            builder: (context) {
              allowed = AppExperienceScope.maybeOf(context)!.backgroundAllowed;
              return ListView.builder(
                itemCount: 100,
                itemBuilder: (_, index) =>
                    SizedBox(height: 80, child: Text('$index')),
              );
            },
          ),
        ),
      ),
    );
    expect(allowed, isTrue);
    final gesture = await tester.startGesture(const Offset(300, 350));
    await gesture.moveBy(const Offset(0, -150));
    await tester.pump();
    await tester.pump();
    expect(allowed, isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));
    expect(allowed, isTrue);
  });

  testWidgets('a covered route mutes its tickers and restores on pop', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    bool active = true;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: AppExperienceScope(
          child: AppRouteActivity(
            child: Builder(
              builder: (context) {
                active = TickerMode.valuesOf(context).enabled;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    expect(active, isFalse);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(active, isTrue);
  });

  testWidgets('disabled haptics send no platform vibration requests', (
    tester,
  ) async {
    final requests = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        requests.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    hapticsEnabledNotifier.value = false;
    await AppHaptics.selection();
    await AppHaptics.confirmation();
    expect(
      requests.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
    hapticsEnabledNotifier.value = true;
    await AppHaptics.selection();
    expect(
      requests.where((call) => call.method == 'HapticFeedback.vibrate'),
      hasLength(1),
    );
  });

  for (final depth in [false, true]) {
    testWidgets('carousel drag preserves prepared children (depth: $depth)', (
      tester,
    ) async {
      final offset = ValueNotifier(0.0);
      addTearDown(offset.dispose);
      var currentBuilds = 0;
      var nextBuilds = 0;
      final current = Builder(
        builder: (_) {
          currentBuilds++;
          return const SizedBox(height: 200);
        },
      );
      final next = Builder(
        builder: (_) {
          nextBuilds++;
          return const SizedBox(height: 200);
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TimetableCarousel(
            offset: offset,
            width: 400,
            depth: depth,
            current: current,
            next: next,
          ),
        ),
      );
      for (var i = 1; i <= 30; i++) {
        offset.value = -i * 5;
        await tester.pump();
      }
      expect(currentBuilds, 1);
      expect(nextBuilds, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long content lists build only visible cards', (tester) async {
    final built = <int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: LazyContentList(
          entries: [
            for (var i = 0; i < 500; i++)
              (_) {
                built.add(i);
                return SizedBox(height: 100, child: Text('$i'));
              },
          ],
        ),
      ),
    );
    expect(built.length, lessThan(20));
    expect(built.contains(499), isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(built.contains(10), isTrue);
    expect(built.length, lessThan(35));
  });
}
