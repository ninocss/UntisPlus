import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/widgets/expressive_wavy_slider.dart';
import 'package:untisplus/widgets/expressive_wavy_progress.dart';

void main() {
  testWidgets('WavySliderTrackShape renders without exception in SliderTheme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SliderTheme(
            data: const SliderThemeData(trackShape: WavySliderTrackShape()),
            child: Slider(value: 0.5, onChanged: (_) {}),
          ),
        ),
      ),
    );
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('ExpressiveWavyLinearProgressIndicator renders with value and indeterminate', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ExpressiveWavyLinearProgressIndicator(value: 0.6),
              ExpressiveWavyLinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(ExpressiveWavyLinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('ExpressiveWavyCircularProgressIndicator renders properly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpressiveWavyCircularProgressIndicator(),
        ),
      ),
    );
    expect(find.byType(ExpressiveWavyCircularProgressIndicator), findsOneWidget);
  });
}
