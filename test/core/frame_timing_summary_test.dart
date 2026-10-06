import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/core/frame_timing_summary.dart';

void main() {
  test(
    'UI and raster budgets are independent, 120 Hz uses the tighter budget',
    () {
      const frames = [
        FrameSample(buildMicros: 10000, rasterMicros: 10000),
        FrameSample(buildMicros: 18000, rasterMicros: 1000),
        FrameSample(buildMicros: 1000, rasterMicros: 17000),
        FrameSample(buildMicros: 1000, rasterMicros: 1000),
      ];
      final sixty = summarizeFrames(frames, 60);
      expect(sixty['framesOverBudget'], 2);
      expect(sixty['overBudgetPercent'], 50);
      expect(sixty['buildP95Ms'], 18);
      expect(sixty['rasterP95Ms'], 17);
      expect(summarizeFrames(frames, 120)['framesOverBudget'], 3);
    },
  );
  test(
    'empty capture never claims zero slow frames or fabricated percentiles',
    () {
      final report = summarizeFrames([], 60);
      expect(report['frames'], 0);
      expect(report['overBudgetPercent'], isNull);
      expect(report['buildP95Ms'], isNull);
      expect(() => summarizeFrames([], 0), throwsArgumentError);
    },
  );
}
