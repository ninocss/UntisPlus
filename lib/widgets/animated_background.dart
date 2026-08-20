part of '../main.dart';

// ── Reusable animated background wrapper ───────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final Widget child;
  const _AnimatedBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: backgroundAnimationsNotifier,
      builder: (context, enabled, _) {
        if (!enabled) return child;
        return ValueListenableBuilder<int>(
          valueListenable: backgroundAnimationStyleNotifier,
          builder: (context, style, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: appBgBlurEnabledNotifier,
              builder: (context, bgBlurEnabled, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: appBgBlurAmountNotifier,
                  builder: (context, bgBlurAmount, _) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: _AnimatedBackgroundScene(style: style),
                        ),
                        if (bgBlurEnabled && bgBlurAmount > 0)
                          Positioned.fill(
                            child: _blurEffect(
                              enabled: true,
                              sigma: bgBlurAmount,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        child,
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}


class _AnimatedBackgroundScene extends StatefulWidget {
  final int style;
  const _AnimatedBackgroundScene({required this.style});

  @override
  State<_AnimatedBackgroundScene> createState() =>
      _AnimatedBackgroundSceneState();
}

class _AnimatedBackgroundSceneState extends State<_AnimatedBackgroundScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _gyroTargetX = 0;
  double _gyroTargetY = 0;
  double _gyroX = 0;
  double _gyroY = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    backgroundGyroscopeNotifier.addListener(_handleGyroscopeToggle);
    _handleGyroscopeToggle();
  }

  @override
  void dispose() {
    backgroundGyroscopeNotifier.removeListener(_handleGyroscopeToggle);
    _gyroSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _handleGyroscopeToggle() {
    if (backgroundGyroscopeNotifier.value) {
      _startGyroscope();
      return;
    }
    _stopGyroscope();
  }

  void _startGyroscope() {
    if (_gyroSub != null) return;
    try {
      _gyroSub = gyroscopeEventStream().listen((event) {
        _gyroTargetX = (event.y * 0.35).clamp(-1.0, 1.0);
        _gyroTargetY = (event.x * 0.35).clamp(-1.0, 1.0);
      }, onError: (_) {});
    } catch (_) {
      _gyroSub = null;
    }
  }

  void _stopGyroscope() {
    _gyroSub?.cancel();
    _gyroSub = null;
    _gyroTargetX = 0;
    _gyroTargetY = 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final gyroEnabled = backgroundGyroscopeNotifier.value;
        _gyroX += ((_gyroTargetX - _gyroX) * (gyroEnabled ? 0.1 : 0.06));
        _gyroY += ((_gyroTargetY - _gyroY) * (gyroEnabled ? 0.1 : 0.06));
        final breathe = math.sin(_ctrl.value * math.pi * 2);
        final scale = 1.0 + (breathe * 0.012);
        final opacity = (0.9 + ((breathe + 1) * 0.05)).clamp(0.84, 1.0);
        final sceneOffset = Offset(_gyroX * 16, _gyroY * 14);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: sceneOffset,
              child: _buildStyle(
                cs,
                _ctrl.value,
                parallax: Offset(_gyroX, _gyroY),
                gyroEnabled: gyroEnabled,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyle(
    ColorScheme cs,
    double t, {
    required Offset parallax,
    required bool gyroEnabled,
  }) {
    final style = widget.style.clamp(0, 10);
    switch (style) {
      case 1:
        return _SpaceLayer(
          t: t,
          cs: cs,
          parallax: parallax,
          gyroEnabled: gyroEnabled,
        );
      case 2:
        return _BubblesLayer(t: t, cs: cs);
      case 3:
        return _LinesLayer(t: t, cs: cs);
      case 4:
        return _ThreeDLayer(t: t, cs: cs);
      case 5:
        return _NebulaFlowLayer(t: t, cs: cs);
      case 6:
        return _PrismLayer(t: t, cs: cs);
      case 7:
        return _WavesLayer(t: t, cs: cs);
      case 8:
        return _GridLayer(t: t, cs: cs);
      case 9:
        return _RingsLayer(t: t, cs: cs);
      case 10:
        return CustomBackgroundView(spec: null, t: t, parallax: parallax);
      default:
        return _OrbsLayer(t: t, cs: cs);
    }
  }
}

class _OrbsLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _OrbsLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    final t2 = _kSmoothBounce.transform(t.clamp(0.0, 1.0));
    final t3 = _kSoftBounce.transform((1.0 - t).clamp(0.0, 1.0));
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: -80 + t * 65,
          right: -40 + t2 * 50,
          child: _orb(240, cs.primaryContainer.withValues(alpha: 0.38)),
        ),
        Positioned(
          bottom: -70 + t2 * 55,
          left: -45 + t * 40,
          child: _orb(210, cs.secondaryContainer.withValues(alpha: 0.34)),
        ),
        Positioned(
          top: 85 + t3 * 90,
          right: 15 - t2 * 30,
          child: _orb(150, cs.tertiaryContainer.withValues(alpha: 0.27)),
        ),
        Positioned(
          top: 175 + t2 * 80,
          left: 8 + t * 45,
          child: _orb(170, cs.primaryContainer.withValues(alpha: 0.20)),
        ),
        Positioned(
          bottom: 55 - t3 * 35,
          right: 35 + t * 60,
          child: _orb(125, cs.secondaryContainer.withValues(alpha: 0.22)),
        ),
        Positioned(
          top: 18 + t2 * 45,
          left: -24 + t3 * 52,
          child: _orb(108, cs.tertiaryContainer.withValues(alpha: 0.2)),
        ),
        Positioned(
          bottom: -32 + t * 34,
          left: 95 + t2 * 26,
          child: _orb(92, cs.primary.withValues(alpha: 0.12)),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _SpaceLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  final Offset parallax;
  final bool gyroEnabled;
  const _SpaceLayer({
    required this.t,
    required this.cs,
    required this.parallax,
    required this.gyroEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final centerShift = Alignment(
      (-0.25 + (parallax.dx * 0.16)).clamp(-1.0, 1.0),
      (-0.78 + (parallax.dy * 0.14)).clamp(-1.0, 1.0),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: centerShift,
                radius: 1.35,
                colors: [
                  Color.lerp(
                    cs.primaryContainer,
                    cs.tertiaryContainer,
                    0.5 + (0.5 * math.sin(t * math.pi * 2)),
                  )!.withValues(alpha: 0.27),
                  cs.surface.withValues(alpha: 0.04),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _NebulaPainter(t: t, cs: cs, parallax: parallax),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _StarfieldPainter(
              t: t,
              cs: cs,
              parallax: parallax,
              gyroEnabled: gyroEnabled,
            ),
          ),
        ),
      ],
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  final Offset parallax;
  _NebulaPainter({required this.t, required this.cs, required this.parallax});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final phase = (t * math.pi * 2) + (i * 1.5);
      final x =
          (size.width * (0.2 + i * 0.3)) +
          (math.sin(phase) * 26) +
          (parallax.dx * 22);
      final y =
          (size.height * (0.28 + i * 0.22)) +
          (math.cos(phase * 0.8) * 22) +
          (parallax.dy * 16);
      final radius = (size.shortestSide * (0.24 + i * 0.11));
      final color = Color.lerp(
        cs.primary,
        cs.secondary,
        i / 2,
      )!.withValues(alpha: 0.10);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0.02), Colors.transparent],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) => true;
}

class _BubblesLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _BubblesLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    final bubbles = List<Widget>.generate(18, (i) {
      final f = (i + 1) / 19;
      final drift = math.sin((t * math.pi * 2) + i) * 0.06;
      final x = ((i * 0.13) % 1.0).clamp(0.04, 0.96) - 0.5 + drift;
      final y = 0.6 - (((t + f) % 1.0) * 1.4);
      final size = 18.0 + (i % 5) * 11.0;
      final color = Color.lerp(
        cs.secondaryContainer,
        cs.tertiaryContainer,
        (i % 7) / 6,
      )!.withValues(alpha: 0.22);
      return Align(
        alignment: Alignment(x * 2, y * 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.92),
                color.withValues(alpha: 0.45),
                color.withValues(alpha: 0.12),
              ],
            ),
          ),
        ),
      );
    });

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.tertiaryContainer.withValues(alpha: 0.20),
                  cs.primaryContainer.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        ...bubbles,
      ],
    );
  }
}

class _LinesLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _LinesLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinesPainter(t: t, cs: cs),
    );
  }
}

class _ThreeDLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _ThreeDLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    final layers = List<Widget>.generate(6, (i) {
      final p = (t + i * 0.13) % 1.0;
      final size = 120.0 + i * 32.0;
      final x = math.sin((p * math.pi * 2) + i) * 90;
      final y = math.cos((p * math.pi * 2 * 0.7) + i) * 70;
      final color = Color.lerp(
        cs.primaryContainer,
        cs.secondaryContainer,
        i / 5,
      )!.withValues(alpha: 0.12 + i * 0.02);
      return Positioned.fill(
        child: Transform.translate(
          offset: Offset(x, y),
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX((p * math.pi) / 3)
                ..rotateZ((p * math.pi) / 2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
    return Stack(children: layers);
  }
}

class _NebulaFlowLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _NebulaFlowLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NebulaFlowPainter(t: t, cs: cs),
    );
  }
}

class _PrismLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _PrismLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PrismPainter(t: t, cs: cs),
    );
  }
}

class _WavesLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _WavesLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavesPainter(t: t, cs: cs),
    );
  }
}

class _GridLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _GridLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(t: t, cs: cs),
    );
  }
}

class _RingsLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _RingsLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingsPainter(t: t, cs: cs),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  final Offset parallax;
  final bool gyroEnabled;
  _StarfieldPainter({
    required this.t,
    required this.cs,
    required this.parallax,
    required this.gyroEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * (0.5 + (parallax.dx * 0.03)),
      size.height * (0.5 + (parallax.dy * 0.03)),
    );
    final maxRadius = size.longestSide * 0.82;
    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 180; i++) {
      final seed = i * 0.6180339;
      final angle = ((seed * 9157) % 1.0) * math.pi * 2;
      final speed = 0.34 + (i % 9) * 0.05;
      final depth = (seed * 7919) % 1.0;
      final progress = (depth + (t * speed)) % 1.0;
      final radial = math.pow(progress, 2.05).toDouble();
      final radius = radial * maxRadius;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      final gyroDrift = gyroEnabled
          ? Offset(
              parallax.dx * (12 + progress * 26),
              parallax.dy * (10 + progress * 22),
            )
          : Offset.zero;
      final pos = Offset(
        center.dx + (dx * radius) + gyroDrift.dx,
        center.dy + (dy * radius) + gyroDrift.dy,
      );

      if (pos.dx < -30 ||
          pos.dx > size.width + 30 ||
          pos.dy < -30 ||
          pos.dy > size.height + 30) {
        continue;
      }

      final twinkle =
          0.32 + 0.68 * (0.5 + 0.5 * math.sin((t * 10 + i) * math.pi));
      final r = 0.45 + (i % 3) * 0.28 + (progress * 1.9);
      starPaint.color = Color.lerp(
        cs.onSurface,
        cs.primary,
        (i % 5) / 4,
      )!.withValues(alpha: 0.10 + 0.30 * twinkle * progress);
      canvas.drawCircle(pos, r, starPaint);

      if (progress > 0.72) {
        final tailLength = 10 + ((progress - 0.72) * 60);
        final start = Offset(
          pos.dx - (dx * tailLength),
          pos.dy - (dy * tailLength),
        );
        streakPaint
          ..strokeWidth = (0.5 + (progress * 1.4)).clamp(0.5, 2.4)
          ..color = cs.primary.withValues(
            alpha: 0.06 + ((progress - 0.72) * 0.45),
          );
        canvas.drawLine(start, pos, streakPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => true;
}

class _LinesPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _LinesPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (int i = -2; i < 15; i++) {
      final y = i * 52.0 + (t * 120.0);
      final path = Path()
        ..moveTo(-40, y)
        ..lineTo(size.width + 40, y - 70);
      paint.color = Color.lerp(
        cs.primary,
        cs.tertiary,
        ((i + 2) % 6) / 5,
      )!.withValues(alpha: 0.12 + ((i + 2) % 3) * 0.05);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) => true;
}

class _NebulaFlowPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _NebulaFlowPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 5; i++) {
      final phase = (t * math.pi * 2) + (i * 0.7);
      final center = Offset(
        size.width * (0.2 + i * 0.17) + math.sin(phase) * 18,
        size.height * (0.25 + i * 0.14) + math.cos(phase * 0.8) * 14,
      );
      final radius = size.shortestSide * (0.22 + i * 0.06);
      final color = Color.lerp(
        cs.primary,
        cs.tertiary,
        i / 4,
      )!.withValues(alpha: 0.08);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0.03), Colors.transparent],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaFlowPainter oldDelegate) => true;
}

class _PrismPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _PrismPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 18; i++) {
      final p = (t + i * 0.07) % 1.0;
      final x = size.width * ((i * 0.21) % 1.0);
      final y = size.height * ((p * 1.25) % 1.0);
      final tri = 18.0 + (i % 4) * 10.0;
      final rot = (p * math.pi * 2) + (i * 0.4);
      final color = Color.lerp(
        cs.primary,
        cs.secondary,
        (i % 6) / 5,
      )!.withValues(alpha: 0.14);
      paint.color = color;

      final path = Path();
      for (int v = 0; v < 3; v++) {
        final a = rot + (v * (math.pi * 2 / 3));
        final px = x + math.cos(a) * tri;
        final py = y + math.sin(a) * tri;
        if (v == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PrismPainter oldDelegate) => true;
}

class _WavesPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _WavesPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yBase = size.height * (0.2 + i * 0.13);
      final phase = (t * math.pi * 2 * (0.8 + i * 0.1)) + i;
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 16) {
        final y =
            yBase +
            math.sin((x / size.width) * math.pi * 2 + phase) * (12 + i * 2);
        path.lineTo(x, y);
      }
      paint
        ..strokeWidth = 1.4 + (i * 0.25)
        ..color = Color.lerp(
          cs.primary,
          cs.tertiary,
          i / 5,
        )!.withValues(alpha: 0.08 + (i * 0.02));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) => true;
}

class _GridPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _GridPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const step = 44.0;
    final drift = (t * step) % step;

    for (double x = -step; x <= size.width + step; x += step) {
      paint.color = cs.primary.withValues(alpha: 0.08);
      canvas.drawLine(
        Offset(x + drift, 0),
        Offset(x + drift - 26, size.height),
        paint,
      );
    }
    for (double y = -step; y <= size.height + step; y += step) {
      paint.color = cs.secondary.withValues(alpha: 0.07);
      canvas.drawLine(
        Offset(0, y + drift),
        Offset(size.width, y + drift - 18),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}

class _RingsPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _RingsPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final paint = Paint()..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final p = ((t + i * 0.12) % 1.0);
      final radius =
          (size.shortestSide * 0.08) + (p * size.shortestSide * 0.62);
      paint
        ..strokeWidth = (1.0 + (1 - p) * 2.2)
        ..color = Color.lerp(
          cs.tertiary,
          cs.primary,
          i / 7,
        )!.withValues(alpha: (0.22 * (1 - p)).clamp(0.02, 0.22));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => true;
}
