import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../main.dart' show AppMotion;

bool _isUnderFlutterTest() {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

/// A Material 3 Expressive slider track shape that draws a sinusoidal wave
/// along the active track and a straight pill along the inactive track.
class WavySliderTrackShape extends SliderTrackShape {
  final double phase;
  final double wavelength;
  final double amplitude;
  final double trackHeight;

  const WavySliderTrackShape({
    this.phase = 0.0,
    this.wavelength = 24.0,
    this.amplitude = 3.5,
    this.trackHeight = 6.0,
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double thumbWidth =
        sliderTheme.thumbShape?.getPreferredSize(isEnabled, isDiscrete).width ??
        20.0;
    final double height = sliderTheme.trackHeight ?? trackHeight;
    final double trackLeft = offset.dx + thumbWidth / 2;
    final double trackTop = offset.dy + (parentBox.size.height - height) / 2;
    final double trackWidth = math.max(0.0, parentBox.size.width - thumbWidth);
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    if (sliderTheme.trackHeight != null && sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Canvas canvas = context.canvas;
    final double y0 = trackRect.center.dy;
    final double strokeW = sliderTheme.trackHeight ?? trackHeight;

    final Color activeColor = isEnabled
        ? (sliderTheme.activeTrackColor ?? Colors.blue)
        : (sliderTheme.disabledActiveTrackColor ?? Colors.grey);
    final Color inactiveColor = isEnabled
        ? (sliderTheme.inactiveTrackColor ?? Colors.grey.shade300)
        : (sliderTheme.disabledInactiveTrackColor ?? Colors.grey.shade400);

    final Paint activePaint = Paint()
      ..color = activeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;

    final Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;

    final double x0 = trackRect.left;
    final double x1 = thumbCenter.dx.clamp(x0, trackRect.right);
    final double xEnd = trackRect.right;

    // Draw inactive track (straight line right of thumb)
    if (x1 < xEnd) {
      final Path inactivePath = Path();
      inactivePath.moveTo(x1, y0);
      inactivePath.lineTo(xEnd, y0);
      canvas.drawPath(inactivePath, inactivePaint);
    }

    // Draw active track (wavy sine line left of thumb)
    if (x1 > x0) {
      final Path activePath = Path();
      activePath.moveTo(x0, y0);

      const double step = 2.0;
      final double totalActive = x1 - x0;
      for (double x = x0; x <= x1; x += step) {
        final double distFromEdge = math.min(x - x0, x1 - x);
        final double edgeEnvelope =
            (distFromEdge / (wavelength * 0.4)).clamp(0.0, 1.0);
        final double currentAmp = amplitude * edgeEnvelope;
        final double wave =
            currentAmp *
            math.sin(((x - x0) / wavelength) * 2 * math.pi - phase);
        activePath.lineTo(x, y0 + wave);
      }
      activePath.lineTo(x1, y0);
      canvas.drawPath(activePath, activePaint);
    }
  }
}

/// An animated Material 3 Expressive slider whose active track features a
/// continuously flowing sinusoidal wave.
class ExpressiveWavySlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final String Function(double)? semanticFormatterCallback;

  const ExpressiveWavySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.semanticFormatterCallback,
  });

  @override
  State<ExpressiveWavySlider> createState() => _ExpressiveWavySliderState();
}

class _ExpressiveWavySliderState extends State<ExpressiveWavySlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.enabled(context) && !_isUnderFlutterTest()) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeCol = widget.activeColor ?? cs.primary;
    final inactiveCol =
        widget.inactiveColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final thCol = widget.thumbColor ?? activeCol;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = AppMotion.enabled(context)
            ? _controller.value * 2 * math.pi
            : 0.0;
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackShape: WavySliderTrackShape(
              phase: phase,
              wavelength: 22.0,
              amplitude: 3.5,
              trackHeight: 6.0,
            ),
            thumbColor: thCol,
            activeTrackColor: activeCol,
            inactiveTrackColor: inactiveCol,
            overlayColor: activeCol.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: widget.value,
            onChanged: widget.onChanged,
            onChangeStart: widget.onChangeStart,
            onChangeEnd: widget.onChangeEnd,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: widget.label,
            semanticFormatterCallback: widget.semanticFormatterCallback,
          ),
        );
      },
    );
  }
}
