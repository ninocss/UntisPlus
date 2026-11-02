import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/widgets/feature_feedback.dart';

void main() {
  testWidgets('error copy wraps at large text and retry is accessible', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: FeatureFeedback(
                  kind: FeatureFeedbackKind.error,
                  title: 'Daten konnten nicht aktualisiert werden',
                  message: 'Deine gespeicherten Daten bleiben verfügbar.',
                  actionLabel: 'Erneut versuchen',
                  onAction: () => retries++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erneut versuchen'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion loading has static progress and a label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: FeatureFeedback(
              kind: FeatureFeedbackKind.loading,
              title: 'Wird geladen',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Wird geladen'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
  });
}
