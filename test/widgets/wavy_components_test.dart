import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/widgets/expressive_wavy_slider.dart';

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

  testWidgets('ExpressiveWavySlider renders properly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpressiveWavySlider(
            value: 0.5,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(ExpressiveWavySlider), findsOneWidget);
  });
}
