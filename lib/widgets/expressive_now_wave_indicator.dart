import 'package:flutter/material.dart';

/// The animated sine wave "now" indicator faithfully modeling the SVG pattern
/// and CSS animation from `New_Lesson_screen_preview`.
class ExpressiveNowWaveIndicator extends StatefulWidget {
  final Color color;
  final double height;

  const ExpressiveNowWaveIndicator({
    super.key,
    required this.color,
    this.height = 12.0,
  });

  @override
  State<ExpressiveNowWaveIndicator> createState() =>
      _ExpressiveNowWaveIndicatorState();
}

class _ExpressiveNowWaveIndicatorState extends State<ExpressiveNowWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.value = 0.0;
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular dot on the timeline rail
            Container(
              key: const ValueKey('expressive-now-wave-dot'),
              width: 4.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            // Masked sine wave line
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  if (bounds.width <= 24) {
                    return const LinearGradient(
                      colors: [Colors.white, Colors.transparent],
                    ).createShader(bounds);
                  }
                  final fadeStart = ((bounds.width - 24) / bounds.width).clamp(0.0, 1.0);
                  return LinearGradient(
                    colors: const [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, fadeStart, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: disableAnimations
                    ? CustomPaint(
                        size: Size.infinite,
                        painter: _ExpressiveWavePainter(
                          phase: 0.0,
                          color: widget.color,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: _ExpressiveWavePainter(
                              phase: _controller.value,
                              color: widget.color,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpressiveWavePainter extends CustomPainter {
  final double phase;
  final Color color;

  const _ExpressiveWavePainter({
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const wavelength = 40.0;
    final midY = size.height / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Phase advances from 0 to 1, moving the wave rightward smoothly
    double x = -wavelength + (phase * wavelength);
    path.moveTo(x, midY);

    while (x < size.width + wavelength) {
      // Replicate SVG path M0 5 Q10 -1 20 5 T40 5 where height is 10
      path.quadraticBezierTo(x + 10.0, midY - 6.0, x + 20.0, midY);
      path.quadraticBezierTo(x + 30.0, midY + 6.0, x + 40.0, midY);
      x += 40.0;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpressiveWavePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}
