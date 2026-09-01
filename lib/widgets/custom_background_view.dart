part of '../main.dart';

// ── Custom Background Rendering ──────────────────────────────────────────────

class CustomBackgroundView extends StatelessWidget {
  final CustomBackgroundSpec? spec;
  final double t;
  final Offset parallax; // roughly [-1..1]

  const CustomBackgroundView({
    super.key,
    required this.spec,
    required this.t,
    required this.parallax,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveSpec =
        spec ??
        _activeCustomBackgroundOrNull() ??
        CustomBackgroundSpec.defaults(id: 'theme_aura', name: 'Theme Aura');

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CustomBackgroundPainter(
          spec: effectiveSpec,
          cs: cs,
          brightness: Theme.of(context).brightness,
          t: t,
          parallax: parallax,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CustomBackgroundPainter extends CustomPainter {
  final CustomBackgroundSpec spec;
  final ColorScheme cs;
  final Brightness brightness;
  final double t;
  final Offset parallax;

  _CustomBackgroundPainter({
    required this.spec,
    required this.cs,
    required this.brightness,
    required this.t,
    required this.parallax,
  });

  bool get _isDark => brightness == Brightness.dark;

  List<Color> _resolveColors(List<int> stored, {required bool useTheme}) {
    if (useTheme) {
      return <Color>[
        cs.primaryContainer,
        cs.tertiaryContainer,
        cs.secondaryContainer,
      ];
    }

    final decoded = stored.map((v) => Color(v)).toList();
    if (decoded.length >= 2) return decoded;
    return <Color>[cs.primaryContainer, cs.secondaryContainer];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;

    _paintBase(canvas, rect);
    _paintOrbs(canvas, rect);
    _paintPattern(canvas, rect);
    _paintNoise(canvas, rect);
    _paintVignette(canvas, rect);
  }

  void _paintBase(Canvas canvas, Rect rect) {
    final base = spec.base;
    final colors = _resolveColors(base.colors, useTheme: base.useThemeColors);
    final n = colors.length;

    final baseAlpha = base.opacity.clamp(0.0, 1.0);
    final shaded = <Color>[];
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.0 : (i / (n - 1));
      final falloff = lerpDouble(1.0, 0.18, t)!;
      final c = colors[i];
      shaded.add(c.withValues(alpha: (baseAlpha * falloff).clamp(0.0, 1.0)));
    }

    final paint = Paint()..style = PaintingStyle.fill;

    if (base.type == CustomBackgroundGradientType.radial) {
      final center = Alignment(base.centerX, base.centerY);
      paint.shader = RadialGradient(
        center: center,
        radius: base.radius,
        colors: shaded,
      ).createShader(rect);
    } else {
      final rad = (base.angleDeg % 360) * math.pi / 180.0;
      final dx = math.cos(rad);
      final dy = math.sin(rad);
      paint.shader = LinearGradient(
        begin: Alignment(-dx, -dy),
        end: Alignment(dx, dy),
        colors: shaded,
      ).createShader(rect);
    }

    canvas.drawRect(rect, paint);
  }

  void _paintOrbs(Canvas canvas, Rect rect) {
    final orbs = spec.orbs;
    if (!orbs.enabled || orbs.count <= 0) return;

    final palette = _resolveColors(orbs.colors, useTheme: orbs.useThemeColors);
    final rng = math.Random(orbs.seed);

    final speed = (spec.animate ? spec.animationSpeed : 0.0).clamp(0.0, 2.5);
    final speedMultiplier = speed <= 0 ? 0 : (speed.round() == 0 ? 1 : speed.round());
    final phase = (t * math.pi * 2 * speedMultiplier).toDouble();

    final parallaxStrength = spec.parallaxStrength.clamp(0.0, 1.0);
    final parallaxPx = Offset(
      parallax.dx * 42 * parallaxStrength,
      parallax.dy * 36 * parallaxStrength,
    );

    for (var i = 0; i < orbs.count; i++) {
      final px = rng.nextDouble();
      final py = rng.nextDouble();

      final sizeFactor =
          (1 + ((rng.nextDouble() * 2 - 1) * orbs.sizeVariance.clamp(0.0, 1.0)))
              .clamp(0.35, 1.75);
      final radius = (orbs.size * 0.5 * sizeFactor).clamp(18.0, 320.0);

      final basePos = Offset(
        rect.left + (px * rect.width),
        rect.top + (py * rect.height),
      );

      final wobble = spec.animate
          ? Offset(
              math.sin(phase + (i * 1.7) + (rng.nextDouble() * 2)) * 8,
              math.cos(phase + (i * 1.2) + (rng.nextDouble() * 2)) * 6,
            )
          : Offset.zero;

      final pos = basePos + parallaxPx + wobble;

      final color = palette[(rng.nextInt(1 << 31) + i) % palette.length];
      final orbAlpha = (orbs.opacity * (0.82 + rng.nextDouble() * 0.22)).clamp(
        0.0,
        1.0,
      );

      final softness = orbs.softness.clamp(0.0, 1.0);
      final inner = color.withValues(alpha: orbAlpha);
      final mid = color.withValues(
        alpha: (orbAlpha * (0.28 + 0.44 * softness)),
      );
      final outer = color.withValues(alpha: 0.0);

      final orbRect = Rect.fromCircle(center: pos, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [inner, mid, outer],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(orbRect);

      canvas.drawCircle(pos, radius, paint);
    }
  }

  void _paintPattern(Canvas canvas, Rect rect) {
    final pattern = spec.pattern;
    if (pattern.type == CustomBackgroundPatternType.none) return;

    final opacity = pattern.opacity.clamp(0.0, 1.0);
    if (opacity <= 0.001) return;

    final baseColor = _isDark
        ? cs.onSurface.withValues(alpha: 0.65)
        : cs.onSurface.withValues(alpha: 0.55);

    final color = baseColor.withValues(
      alpha: (opacity * 0.10).clamp(0.0, 0.12),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color;

    final scale = pattern.scale.clamp(0.5, 3.0);

    if (pattern.type == CustomBackgroundPatternType.grid) {
      final spacing = 54.0 * scale;
      for (double x = rect.left; x <= rect.right; x += spacing) {
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
      }
      for (double y = rect.top; y <= rect.bottom; y += spacing) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
      }
      return;
    }

    // Lines
    final rad = (pattern.angleDeg % 360) * math.pi / 180.0;
    final diag = math.sqrt(rect.width * rect.width + rect.height * rect.height);
    final spacing = 34.0 * scale;

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(rad);

    for (double y = -diag; y <= diag; y += spacing) {
      canvas.drawLine(Offset(-diag, y), Offset(diag, y), paint);
    }

    canvas.restore();
  }

  void _paintNoise(Canvas canvas, Rect rect) {
    final intensity = spec.noise.clamp(0.0, 0.5);
    if (intensity <= 0.001) return;

    final seed = spec.orbs.seed ^ 0x5f3759df;
    final rng = math.Random(seed);

    final pointsCount = (80 + (intensity * 900)).round().clamp(60, 520);
    final points = <Offset>[];
    for (var i = 0; i < pointsCount; i++) {
      points.add(
        Offset(
          rect.left + rng.nextDouble() * rect.width,
          rect.top + rng.nextDouble() * rect.height,
        ),
      );
    }

    final alpha = (intensity * (_isDark ? 0.18 : 0.14)).clamp(0.0, 0.12);
    final paint = Paint()
      ..color = cs.onSurface.withValues(alpha: alpha)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(PointMode.points, points, paint);
  }

  void _paintVignette(Canvas canvas, Rect rect) {
    final intensity = spec.vignette.clamp(0.0, 0.7);
    if (intensity <= 0.001) return;

    final edge = cs.shadow.withValues(
      alpha: (_isDark ? 0.55 : 0.28) * intensity,
    );
    final edge2 = cs.shadow.withValues(
      alpha: (_isDark ? 0.72 : 0.36) * intensity,
    );

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [Colors.transparent, edge, edge2],
        stops: const [0.55, 0.88, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _CustomBackgroundPainter oldDelegate) {
    return oldDelegate.spec != spec ||
        oldDelegate.cs != cs ||
        oldDelegate.brightness != brightness ||
        (oldDelegate.t - t).abs() > 0.0001 ||
        oldDelegate.parallax != parallax;
  }
}
