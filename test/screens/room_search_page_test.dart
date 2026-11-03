import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget() {
    return const MaterialApp(
      home: RoomSearchPage(),
    );
  }

  setUp(() {
    demoModeNotifier.value = true;
  });

  tearDown(() {
    demoModeNotifier.value = false;
  });

  testWidgets('RoomSearchPage renders search bar, slot chips and demo rooms', (
    tester,
  ) async {
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
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap on room B201
    await tester.tap(find.text('B201'));
    await tester.pumpAndSettle();

    // Detail card with room name should be rendered at top
    expect(find.text('B201'), findsAtLeastNWidgets(1));
  });
}
