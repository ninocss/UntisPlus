import 'dart:math' as math;

/// UI and raster work have separate budgets; their durations must not be added.
class FrameSample {
  const FrameSample({required this.buildMicros, required this.rasterMicros});
  final int buildMicros;
  final int rasterMicros;
  Map<String, int> toJson() => {
    'buildUs': buildMicros,
    'rasterUs': rasterMicros,
  };
}

Map<String, Object?> summarizeFrames(
  List<FrameSample> frames,
  double refreshHz,
) {
  if (!refreshHz.isFinite || refreshHz <= 0) {
    throw ArgumentError.value(refreshHz, 'refreshHz');
  }
  final budget = 1000000 / refreshHz;
  final build = frames.map((frame) => frame.buildMicros).toList()..sort();
  final raster = frames.map((frame) => frame.rasterMicros).toList()..sort();
  double? percentile(List<int> sorted, double fraction) {
    if (sorted.isEmpty) return null;
    return sorted[math.max(0, (sorted.length * fraction).ceil() - 1)] / 1000;
  }

  final exceeded = frames
      .where(
        (frame) => frame.buildMicros > budget || frame.rasterMicros > budget,
      )
      .length;
  return {
    'frames': frames.length,
    'refreshHz': refreshHz,
    'budgetMs': budget / 1000,
    'buildP50Ms': percentile(build, .50),
    'buildP95Ms': percentile(build, .95),
    'buildP99Ms': percentile(build, .99),
    'rasterP50Ms': percentile(raster, .50),
    'rasterP95Ms': percentile(raster, .95),
    'rasterP99Ms': percentile(raster, .99),
    'framesOverBudget': exceeded,
    'overBudgetPercent': frames.isEmpty ? null : exceeded * 100 / frames.length,
  };
}
