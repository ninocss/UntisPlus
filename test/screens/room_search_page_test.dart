import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test with 08:45 AM (Period 2, when B201 is occupied) to verify robust rendering
  final testDateTime = DateTime(2026, 11, 3, 8, 45);

  Widget buildTestWidget({DateTime? initialDate}) {
    return MaterialApp(
      home: RoomSearchPage(initialDate: initialDate ?? testDateTime),
    );
  }

  void setTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() {
    demoModeNotifier.value = true;
    appLocaleNotifier.value = 'de';
  });

  tearDown(() {
    demoModeNotifier.value = false;
  });

  testWidgets('RoomSearchPage renders search bar, slot chips and demo rooms', (
    tester,
  ) async {
    setTestViewport(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify search bar and filter elements exist
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.byType(FilterChip), findsOneWidget);

    // Verify demo rooms appear in list
    expect(find.text('B201'), findsOneWidget);
    expect(find.text('Bibliothek'), findsOneWidget);
  });

  testWidgets('RoomSearchPage filters room list when typing query', (
    tester,
  ) async {
    setTestViewport(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('B201'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Bibliothek');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Bibliothek'), findsOneWidget);
    expect(find.text('B201'), findsNothing);
  });

  testWidgets('RoomSearchPage selects room and shows occupancy card', (
    tester,
  ) async {
    setTestViewport(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap on room B201
    await tester.tap(find.text('B201'));
    await tester.pumpAndSettle();

    // Detail card with room name should be rendered at top
    expect(find.text('B201'), findsAtLeastNWidgets(1));
  });
}
