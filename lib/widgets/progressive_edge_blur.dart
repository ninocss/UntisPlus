import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paint behind the controls. [strongAtTop] selects the solid end of the edge.
class ProgressiveEdgeBlur extends StatelessWidget {
  static const chromeExtent = 88.0;

  const ProgressiveEdgeBlur({
    super.key,
    required this.strongAtTop,
    required this.sigma,
    required this.tint,
    this.transitionExtent = chromeExtent,
  });

  final bool strongAtTop;
  final double sigma;
  final Color tint;
  final double transitionExtent;

  @override
  Widget build(BuildContext context) {
    final sharp = strongAtTop ? Alignment.bottomCenter : Alignment.topCenter;
    final strong = strongAtTop ? Alignment.topCenter : Alignment.bottomCenter;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          if (height <= 0) return const SizedBox.shrink();
          final ramp = math.min(transitionExtent / height, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              // Each pass adds Gaussian variance towards the strong edge.
              // Squared sigma fractions sum to one at full strength.
              if (sigma > 0)
                for (final (start, end, factor) in const [
                  (0.0, 0.35, 0.20),
                  (0.23, 0.72, 0.48),
                  (0.58, 1.0, 0.854),
                ])
                  ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: sigma * factor,
                        sigmaY: sigma * factor,
                      ),
                      child: CustomPaint(
                        painter: _EdgeMask(
                          LinearGradient(
                            begin: sharp,
                            end: strong,
                            colors: const [Colors.transparent, Colors.white],
                            stops: [start * ramp, end * ramp],
                          ),
                        ),
                      ),
                    ),
                  ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: sharp,
                    end: strong,
                    colors: [tint.withValues(alpha: 0), tint],
                    stops: [0, ramp],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Mask the filter's own layer after it samples the scene. A ShaderMask around
// the filter would isolate it from the backdrop on raster backends.
class _EdgeMask extends CustomPainter {
  const _EdgeMask(this.gradient);
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = gradient.createShader(bounds)
        ..blendMode = BlendMode.dstIn,
    );
  }

  @override
  bool shouldRepaint(_EdgeMask oldDelegate) => gradient != oldDelegate.gradient;
}
