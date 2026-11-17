import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  testWidgets('renders buildSectionHeader with count and trailing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildSectionHeader(
              context,
              'Offene Aufgaben',
              Icons.radio_button_unchecked_rounded,
              count: 3,
              trailing: const Text('Zusatz'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Offene Aufgaben'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Zusatz'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
  });

  testWidgets('renders buildUnifiedEmptyState with icon title and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildUnifiedEmptyState(
              context: context,
              icon: Icons.assignment_turned_in_rounded,
              title: 'Keine Aufgaben',
              hint: 'Alles erledigt!',
              action: ElevatedButton(
                onPressed: () {},
                child: const Text('Neu laden'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Keine Aufgaben'), findsOneWidget);
    expect(find.text('Alles erledigt!'), findsOneWidget);
    expect(find.text('Neu laden'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_turned_in_rounded), findsOneWidget);
  });
}
