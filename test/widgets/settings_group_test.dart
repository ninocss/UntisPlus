import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  testWidgets('SettingsGroup renders clustered container with title and children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsGroup(
            title: 'Test Section',
            children: [
              Text('Child 1'),
              Text('Child 2'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Test Section'), findsOneWidget);
    expect(find.text('Child 1'), findsOneWidget);
    expect(find.text('Child 2'), findsOneWidget);
  });

  testWidgets('SettingsPageShell renders title in header and children in scroll view', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPageShell(
          title: 'Shell Title',
          children: [
            Text('Content 1'),
          ],
        ),
      ),
    );
    expect(find.text('Shell Title'), findsOneWidget);
    expect(find.text('Content 1'), findsOneWidget);
  });
}
