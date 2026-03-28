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
            return Stack(
              children: [
                Positioned.fill(child: _AnimatedBackgroundScene(style: style)),
                child,
              ],
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final breathe = math.sin(_ctrl.value * math.pi * 2);
        final scale = 1.0 + (breathe * 0.012);
        final opacity = (0.9 + ((breathe + 1) * 0.05)).clamp(0.84, 1.0);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: _buildStyle(cs, _ctrl.value)),
        );
      },
    );
  }

  Widget _buildStyle(ColorScheme cs, double t) {
    final style = widget.style.clamp(0, 5);
    switch (style) {
      case 1:
        return _SpaceLayer(t: t, cs: cs);
      case 2:
        return _BubblesLayer(t: t, cs: cs);
      case 3:
        return _LinesLayer(t: t, cs: cs);
      case 4:
        return _ThreeDLayer(t: t, cs: cs);
      case 5:
        return _AuroraLayer(t: t, cs: cs);
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
    final t2 = Curves.easeInOutCubicEmphasized.transform(t);
    final t3 = Curves.slowMiddle.transform(1.0 - t);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: -80 + t * 65,
          right: -40 + t2 * 50,
          child: _orb(240, cs.primaryContainer.withOpacity(0.38)),
        ),
        Positioned(
          bottom: -70 + t2 * 55,
          left: -45 + t * 40,
          child: _orb(210, cs.secondaryContainer.withOpacity(0.34)),
        ),
        Positioned(
          top: 85 + t3 * 90,
          right: 15 - t2 * 30,
          child: _orb(150, cs.tertiaryContainer.withOpacity(0.27)),
        ),
        Positioned(
          top: 175 + t2 * 80,
          left: 8 + t * 45,
          child: _orb(170, cs.primaryContainer.withOpacity(0.20)),
        ),
        Positioned(
          bottom: 55 - t3 * 35,
          right: 35 + t * 60,
          child: _orb(125, cs.secondaryContainer.withOpacity(0.22)),
        ),
        Positioned(
          top: 18 + t2 * 45,
          left: -24 + t3 * 52,
          child: _orb(108, cs.tertiaryContainer.withOpacity(0.2)),
        ),
        Positioned(
          bottom: -32 + t * 34,
          left: 95 + t2 * 26,
          child: _orb(92, cs.primary.withOpacity(0.12)),
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
  const _SpaceLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.8),
                radius: 1.35,
                colors: [
                  cs.primaryContainer.withOpacity(0.24),
                  cs.surface.withOpacity(0.04),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _StarfieldPainter(t: t, cs: cs),
          ),
        ),
      ],
    );
  }
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
      )!.withOpacity(0.22);
      return Align(
        alignment: Alignment(x * 2, y * 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.92),
                color.withOpacity(0.45),
                color.withOpacity(0.12),
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
                  cs.tertiaryContainer.withOpacity(0.20),
                  cs.primaryContainer.withOpacity(0.10),
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
      )!.withOpacity(0.12 + i * 0.02);
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
                    color: cs.onSurface.withOpacity(0.08),
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

class _AuroraLayer extends StatelessWidget {
  final double t;
  final ColorScheme cs;
  const _AuroraLayer({required this.t, required this.cs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraPainter(t: t, cs: cs),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _StarfieldPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 120; i++) {
      final seed = i * 0.6180339;
      final x = ((seed * 9973) % 1.0) * size.width;
      final yBase = ((seed * 6967) % 1.0) * size.height;
      final y = (yBase + (t * (10 + (i % 7)))) % size.height;
      final twinkle =
          0.25 + 0.75 * (0.5 + 0.5 * math.sin((t * 8 + i) * math.pi));
      final r = 0.5 + (i % 3) * 0.5;
      starPaint.color = Color.lerp(
        cs.onSurface,
        cs.primary,
        (i % 5) / 4,
      )!.withOpacity(0.08 + 0.20 * twinkle);
      canvas.drawCircle(Offset(x, y), r, starPaint);
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
      )!.withOpacity(0.12 + ((i + 2) % 3) * 0.05);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) => true;
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final ColorScheme cs;
  _AuroraPainter({required this.t, required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cs.primaryContainer.withOpacity(0.15),
          cs.secondaryContainer.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final phase = t * math.pi * 2 + i * 0.8;
      final top = 60.0 + i * 65.0;
      path.moveTo(0, top + math.sin(phase) * 18);
      for (double x = 0; x <= size.width; x += 20) {
        final y =
            top +
            math.sin((x / size.width) * math.pi * 2 + phase) * (20 + i * 4);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = Color.lerp(
          cs.primary,
          cs.tertiary,
          i / 3,
        )!.withOpacity(0.09 + i * 0.03);
      canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => true;
}
