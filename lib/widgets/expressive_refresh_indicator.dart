part of '../main.dart';

/// Material's stock refresh interaction with the Material You Expressive
/// loading treatment. `RefreshIndicator.noSpinner` keeps the platform's
/// gesture, semantics, and refresh lifecycle while this widget draws the
/// expressive, organic indicator shown below the app bar.
class ExpressiveRefreshIndicator extends StatefulWidget {
  const ExpressiveRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.edgeOffset = 12,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
  });

  final Widget child;
  final RefreshCallback onRefresh;
  final double edgeOffset;
  final RefreshIndicatorTriggerMode triggerMode;

  @override
  State<ExpressiveRefreshIndicator> createState() =>
      _ExpressiveRefreshIndicatorState();
}

class _ExpressiveRefreshIndicatorState extends State<ExpressiveRefreshIndicator>
    with TickerProviderStateMixin {
  RefreshIndicatorStatus? _status;
  double _pullProgress = 0;
  late final AnimationController _contentOffset = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _isVisible =>
      _status != null && _status != RefreshIndicatorStatus.canceled;

  bool get _canAnimate =>
      TickerMode.valuesOf(context).enabled &&
      !MediaQuery.disableAnimationsOf(context);

  void _syncMotion() {
    _motion.duration =
        untisThemeTokensOf(context).expressive?.loadingCycle ??
        const Duration(milliseconds: 1600);
    final shouldRun =
        _canAnimate &&
        (_status == RefreshIndicatorStatus.snap ||
            _status == RefreshIndicatorStatus.refresh);
    if (shouldRun && !_motion.isAnimating) {
      _motion.repeat();
    } else if (!shouldRun && _motion.isAnimating) {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void dispose() {
    _contentOffset.dispose();
    _motion.dispose();
    super.dispose();
  }

  void _settleContent() {
    if (!_canAnimate) {
      _contentOffset.value = 0;
      return;
    }
    _contentOffset.animateWith(
      SpringSimulation(
        untisThemeTokensOf(context).expressive?.spatialSpring ??
            const SpringDescription(mass: 1, stiffness: 520, damping: 28),
        _contentOffset.value,
        0,
        0,
      ),
    );
  }

  void _onStatusChange(RefreshIndicatorStatus? status) {
    if (status == _status) return;
    setState(() => _status = status);
    if (status == RefreshIndicatorStatus.snap ||
        status == RefreshIndicatorStatus.refresh) {
      _syncMotion();
      _settleContent();
    } else if (status == RefreshIndicatorStatus.done ||
        status == RefreshIndicatorStatus.canceled) {
      _motion.stop();
      _settleContent();
      final delay =
          untisThemeTokensOf(context).expressive?.motionDuration(context) ??
          const Duration(milliseconds: 220);
      Future<void>.delayed(delay, () {
        if (mounted && _status == status) {
          setState(() {
            _status = null;
            _pullProgress = 0;
            _motion.value = 0;
          });
        }
      });
    }
  }

  bool _trackPullProgress(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is OverscrollNotification &&
        notification.metrics.extentBefore <= 0 &&
        notification.overscroll < 0 &&
        (_status == RefreshIndicatorStatus.drag ||
            _status == RefreshIndicatorStatus.armed)) {
      setState(() {
        _pullProgress = (_pullProgress + (-notification.overscroll / 96)).clamp(
          0.0,
          1.0,
        );
        _contentOffset.value = _pullProgress * 12;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final motion = untisThemeTokensOf(context).expressive;
    final quickDuration =
        motion?.motionDuration(context) ?? const Duration(milliseconds: 180);
    final fadeDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 140);
    final isRefreshing = _status == RefreshIndicatorStatus.refresh;
    final isArmed = _status == RefreshIndicatorStatus.armed;
    final isPulling = _status == RefreshIndicatorStatus.drag || isArmed;

    return RefreshIndicator.noSpinner(
      onRefresh: widget.onRefresh,
      triggerMode: widget.triggerMode,
      onStatusChange: _onStatusChange,
      child: NotificationListener<ScrollNotification>(
        onNotification: _trackPullProgress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _contentOffset,
              child: widget.child,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _contentOffset.value),
                child: child,
              ),
            ),
            Positioned(
              top: widget.edgeOffset,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Semantics(
                  liveRegion: true,
                  label: 'Refreshing',
                  child: AnimatedSlide(
                    duration: quickDuration,
                    curve: Curves.easeOutCubic,
                    offset: _isVisible ? Offset.zero : const Offset(0, -0.45),
                    child: AnimatedOpacity(
                      duration: fadeDuration,
                      opacity: _isVisible ? 1 : 0,
                      child: Center(
                        child: AnimatedScale(
                          duration: quickDuration,
                          curve: Curves.easeOutBack,
                          scale: isRefreshing || isArmed ? 1 : 0.76,
                          child: AnimatedBuilder(
                            animation: _motion,
                            builder: (context, _) => CustomPaint(
                              size: const Size.square(56),
                              painter: _ExpressiveLoaderPainter(
                                containerColor: cs.primaryContainer,
                                blobColor: cs.onPrimaryContainer,
                                turns: _motion.value,
                                pullProgress: isPulling ? _pullProgress : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpressiveLoaderPainter extends CustomPainter {
  const _ExpressiveLoaderPainter({
    required this.containerColor,
    required this.blobColor,
    required this.turns,
    this.pullProgress,
    this.contained = true,
  });

  final Color containerColor;
  final Color blobColor;
  final double turns;
  final double? pullProgress;
  final bool contained;

  static const _vertexCount = 12;

  /// A bounded, lightly under-damped spring (zeta = .78). It models the
  /// expressive spatial motion without the harshness of a cubic Bézier.
  static double _spring(double t) {
    const dampingRatio = .78;
    const angularFrequency = 14.0;
    final dampedFrequency =
        angularFrequency * math.sqrt(1 - dampingRatio * dampingRatio);
    final settled =
        1 -
        math.exp(-dampingRatio * angularFrequency * t) *
            (math.cos(dampedFrequency * t) +
                (dampingRatio * angularFrequency / dampedFrequency) *
                    math.sin(dampedFrequency * t));
    return settled.clamp(0.0, 1.0);
  }

  static List<Offset> _circle() =>
      List<Offset>.generate(_vertexCount, (index) => _polar(index, 1, 1));

  static List<Offset> _oval() =>
      List<Offset>.generate(_vertexCount, (index) => _polar(index, 1.18, .78));

  static List<Offset> _cookie() => List<Offset>.generate(
    _vertexCount,
    (index) =>
        _polar(index, index.isEven ? 1.16 : .69, index.isEven ? 1.16 : .69),
  );

  static List<Offset> _roundedPentagon() =>
      List<Offset>.generate(_vertexCount, (index) {
        final angle = -math.pi / 2 + math.pi * 2 * index / _vertexCount;
        // Radial sampling of a regular pentagon keeps exactly 12 matching
        // vertices while the quadratic path below provides the corner rounding.
        final sector =
            (angle + math.pi / 5).remainder(math.pi * 2 / 5) - math.pi / 5;
        final radius = math.cos(math.pi / 5) / math.cos(sector);
        return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      });

  static Offset _polar(int index, double xRadius, double yRadius) {
    final angle = -math.pi / 2 + math.pi * 2 * index / _vertexCount;
    return Offset(math.cos(angle) * xRadius, math.sin(angle) * yRadius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (contained) {
      final containerPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: size.width / 2));
      canvas.drawShadow(containerPath, Colors.black, 1, false);
      canvas.drawCircle(
        center,
        size.width / 2,
        Paint()..color = containerColor,
      );
    }

    final shapes = [_circle(), _oval(), _cookie(), _roundedPentagon()];
    late final int fromIndex;
    late final int toIndex;
    late final double t;
    late final double rotation;
    if (pullProgress case final progress?) {
      // Pulling is determinate: scroll distance morphs only from the resting
      // circle into the first target shape. Time-driven looping starts later.
      fromIndex = 0;
      toIndex = 1;
      t = progress.clamp(0.0, 1.0);
      rotation = progress * math.pi * .18;
    } else {
      // Explicit timeline: circle -> pill -> cookie -> pentagon -> circle.
      const boundaries = [0.0, .27, .57, .82, 1.0];
      final phase = List.generate(
        boundaries.length - 1,
        (index) => index,
      ).lastWhere((index) => turns >= boundaries[index], orElse: () => 0);
      fromIndex = phase;
      toIndex = (phase + 1) % shapes.length;
      final local =
          (turns - boundaries[phase]) /
          (boundaries[phase + 1] - boundaries[phase]);
      t = _spring(local.clamp(0.0, 1.0));
      rotation = turns * math.pi * 2;
    }

    final points = List<Offset>.generate(_vertexCount, (index) {
      final x = lerpDouble(
        shapes[fromIndex][index].dx,
        shapes[toIndex][index].dx,
        t,
      )!;
      final y = lerpDouble(
        shapes[fromIndex][index].dy,
        shapes[toIndex][index].dy,
        t,
      )!;
      final radius = size.width * .323;
      return Offset(x * radius, y * radius);
    });
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      if (index == 0) {
        path.moveTo(midpoint.dx, midpoint.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = blobColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ExpressiveLoaderPainter oldDelegate) =>
      oldDelegate.containerColor != containerColor ||
      oldDelegate.blobColor != blobColor ||
      oldDelegate.turns != turns ||
      oldDelegate.pullProgress != pullProgress ||
      oldDelegate.contained != contained;
}
