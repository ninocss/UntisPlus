import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('untisplus_onboarding_test_');
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
    SharedPreferences.setMockInitialValues({'onboardingCheckpoint': 0});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore.initialize(preferences: prefs);
    appLocaleNotifier.value = 'de';
    demoModeNotifier.value = false;
    activeUntisAccountId = null;
  });

  tearDown(() {
    demoModeNotifier.value = false;
  });

  testWidgets(
    'OnboardingFlow applies 28dp margins on phone and is constrained to 640dp maxWidth on tablet',
    (tester) async {
      // 1. Phone Viewport (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingFlow(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final phoneHeaderFinder = find.ancestor(
        of: find.byType(M3ExpressiveProgressHeader),
        matching: find.byType(Padding),
      ).first;
      final phoneHeaderPadding = tester.widget<Padding>(phoneHeaderFinder);
      expect((phoneHeaderPadding.padding as EdgeInsets).left, equals(28.0));
      expect((phoneHeaderPadding.padding as EdgeInsets).right, equals(28.0));

      // 2. Tablet Viewport (1024 x 768)
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header margin on tablet should be 32dp
      final tabletHeaderFinder = find.ancestor(
        of: find.byType(M3ExpressiveProgressHeader),
        matching: find.byType(Padding),
      ).first;
      final tabletHeaderPadding = tester.widget<Padding>(tabletHeaderFinder);
      expect((tabletHeaderPadding.padding as EdgeInsets).left, equals(32.0));
      expect((tabletHeaderPadding.padding as EdgeInsets).right, equals(32.0));

      // Content should be constrained to 640dp maxWidth on tablet
      final constrainedBoxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox &&
            widget.constraints.maxWidth == 640.0,
      );
      expect(constrainedBoxFinder, findsOneWidget);

      final contentSize = tester.getSize(constrainedBoxFinder);
      expect(contentSize.width, lessThanOrEqualTo(640.0));
    },
  );
}
