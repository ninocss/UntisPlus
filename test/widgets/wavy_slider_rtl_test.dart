import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/widgets/expressive_wavy_slider.dart';

void main() {
  testWidgets('WavySliderTrackShape renders in RTL text direction without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SliderTheme(
              data: const SliderThemeData(trackShape: WavySliderTrackShape()),
              child: Slider(value: 0.5, onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
