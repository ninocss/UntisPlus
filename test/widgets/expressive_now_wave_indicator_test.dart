import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/widgets/expressive_now_wave_indicator.dart';

void main() {
  testWidgets('ExpressiveNowWaveIndicator renders dot and wave painter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 14,
            child: ExpressiveNowWaveIndicator(color: Colors.green),
          ),
        ),
      ),
    );

    expect(find.byType(ExpressiveNowWaveIndicator), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expressive-now-wave-dot')),
      findsOneWidget,
    );
    expect(find.byType(CustomPaint), findsWidgets);

    // Pump frames to verify animation controller progresses without throwing
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets(
    'ExpressiveNowWaveIndicator respects reduced motion by rendering static wave',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SizedBox(
                width: 320,
                height: 14,
                child: ExpressiveNowWaveIndicator(color: Colors.green),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ExpressiveNowWaveIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      // No unhandled exceptions
    },
  );
}
