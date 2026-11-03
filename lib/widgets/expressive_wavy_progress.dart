import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../main.dart' show AppMotion;
import 'expressive_wavy_slider.dart' show debugDisableWavyTickers;

bool _isUnderFlutterTest() {
  if (debugDisableWavyTickers) return true;
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

/// A Material 3 Expressive linear progress indicator featuring a sinusoidal wavy active bar.
class ExpressiveWavyLinearProgressIndicator extends StatefulWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double minHeight;
  final double wavelength;
  final double amplitude;

  const ExpressiveWavyLinearProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.minHeight = 6.0,
    this.wavelength = 20.0,
    this.amplitude = 3.0,
  });

  @override
  State<ExpressiveWavyLinearProgressIndicator> createState() =>
      _ExpressiveWavyLinearProgressIndicatorState();
}

class _ExpressiveWavyLinearProgressIndicatorState
    extends State<ExpressiveWavyLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
    final activeCol = widget.color ?? cs.primary;
    final bgCol =
        widget.backgroundColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.5);

    return SizedBox(
      height: widget.minHeight + (widget.amplitude * 2),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = AppMotion.enabled(context)
              ? _controller.value * 2 * math.pi
              : 0.0;
          return CustomPaint(
            painter: _WavyLinearPainter(
              progress: widget.value,
              phase: phase,
              activeColor: activeCol,
              backgroundColor: bgCol,
              strokeWidth: widget.minHeight,
              wavelength: widget.wavelength,
              amplitude: widget.amplitude,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WavyLinearPainter extends CustomPainter {
  final double? progress;
  final double phase;
  final Color activeColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double wavelength;
  final double amplitude;

  _WavyLinearPainter({
    required this.progress,
    required this.phase,
    required this.activeColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.wavelength,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y0 = size.height / 2;

    // Draw background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(strokeWidth / 2, y0),
      Offset(size.width - (strokeWidth / 2), y0),
      bgPaint,
    );

    final activePaint = Paint()
      ..color = activeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (progress != null) {
      // Determinate
      final p = progress!.clamp(0.0, 1.0);
      final activeWidth = size.width * p;
      if (activeWidth <= 0) return;

      final path = Path();
      path.moveTo(strokeWidth / 2, y0);
      for (double x = strokeWidth / 2; x <= activeWidth; x += 2.0) {
        final distFromEdge = math.min(x - (strokeWidth / 2), activeWidth - x);
        final edgeEnvelope =
            (distFromEdge / (wavelength * 0.4)).clamp(0.0, 1.0);
        final amp = amplitude * edgeEnvelope;
        final y = y0 + amp * math.sin((x / wavelength) * 2 * math.pi - phase);
        path.lineTo(x, y);
      }
      path.lineTo(activeWidth, y0);
      canvas.drawPath(path, activePaint);
    } else {
      // Indeterminate: traveling pulse wave
      final centerNorm = (phase / (2 * math.pi)) % 1.0;
      final centerX = size.width * centerNorm;
      final pulseWidth = size.width * 0.45;
      final xStart = math.max(strokeWidth / 2, centerX - pulseWidth / 2);
      final xEnd = math.min(size.width - (strokeWidth / 2), centerX + pulseWidth / 2);

      if (xEnd > xStart) {
        final path = Path();
        path.moveTo(xStart, y0);
        for (double x = xStart; x <= xEnd; x += 2.0) {
          final distFromEdge = math.min(x - xStart, xEnd - x);
          final envelope =
              (distFromEdge / (pulseWidth * 0.3)).clamp(0.0, 1.0);
          final amp = amplitude * envelope;
          final y = y0 + amp * math.sin((x / wavelength) * 2 * math.pi - phase);
          path.lineTo(x, y);
        }
        path.lineTo(xEnd, y0);
        canvas.drawPath(path, activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavyLinearPainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.activeColor != activeColor ||
      old.backgroundColor != backgroundColor;
}

/// A Material 3 Expressive circular spinner with undulating organic lobes.
class ExpressiveWavyCircularProgressIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const ExpressiveWavyCircularProgressIndicator({
    super.key,
    this.size = 36.0,
    this.strokeWidth = 3.5,
    this.color,
  });

  @override
  State<ExpressiveWavyCircularProgressIndicator> createState() =>
      _ExpressiveWavyCircularProgressIndicatorState();
}

class _ExpressiveWavyCircularProgressIndicatorState
    extends State<ExpressiveWavyCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
    final col = widget.color ?? cs.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavyCircularPainter(
              progress: _controller.value,
              color: col,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _WavyCircularPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _WavyCircularPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (baseRadius <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final rotation = progress * 2 * math.pi;
    final path = Path();
    const int sampleCount = 60;
    for (int i = 0; i <= sampleCount; i++) {
      final angle = (i / sampleCount) * 2 * math.pi;
      // 3 undulating soft lobes
      final wave = math.sin((angle * 3) + rotation) * (baseRadius * 0.14);
      final r = baseRadius + wave;
      final x = center.dx + r * math.cos(angle + rotation);
      final y = center.dy + r * math.sin(angle + rotation);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyCircularPainter old) =>
      old.progress != progress || old.color != color || old.strokeWidth != strokeWidth;
}
