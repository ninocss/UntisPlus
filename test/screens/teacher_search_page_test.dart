import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget() {
    return const MaterialApp(
      home: TeacherSearchPage(),
    );
  }

  setUp(() {
    demoModeNotifier.value = true;
  });

  tearDown(() {
    demoModeNotifier.value = false;
  });

  testWidgets('TeacherSearchPage renders modern cards and search bar', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Anna Becker'), findsOneWidget);
    expect(find.text('Thomas Müller'), findsOneWidget);
  });

  testWidgets('TeacherSearchPage filters teachers and selects a teacher', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Becker');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Anna Becker'), findsOneWidget);
    expect(find.text('Thomas Müller'), findsNothing);

    // Tap to select
    await tester.tap(find.widgetWithText(ListTile, 'Anna Becker'));
    await tester.pumpAndSettle();

    expect(find.text('Anna Becker'), findsAtLeastNWidgets(1));
  });
}
