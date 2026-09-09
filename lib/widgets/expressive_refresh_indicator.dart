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
  final ValueNotifier<double> _pullProgressNotifier = ValueNotifier<double>(0.0);
  Timer? _resetTimer;
  late final AnimationController _contentOffset =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void dispose() {
    _resetTimer?.cancel();
    _pullProgressNotifier.dispose();
    _contentOffset.dispose();
    _motion.dispose();
    super.dispose();
  }

  void _settleContent() {
    if (!mounted) return;
    _contentOffset.stop();
    if (_contentOffset.value.abs() < 0.01) {
      _contentOffset.value = 0;
      return;
    }
    _contentOffset.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 520, damping: 28),
        _contentOffset.value,
        0,
        0,
      ),
    );
  }

  void _onStatusChange(RefreshIndicatorStatus? status) {
    if (!mounted || status == _status) return;
    _resetTimer?.cancel();
    setState(() => _status = status);
    if (status == RefreshIndicatorStatus.snap ||
        status == RefreshIndicatorStatus.refresh) {
      if (context.mounted &&
          !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
        if (!_motion.isAnimating) {
          _motion.repeat();
        }
      }
      _settleContent();
    } else if (status == RefreshIndicatorStatus.done ||
        status == RefreshIndicatorStatus.canceled ||
        status == null) {
      _settleContent();
      // Keep motion spinning smoothly until fade-out finishes (200ms)
      _resetTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          if (_motion.isAnimating) {
            _motion.stop();
            _motion.value = 0;
          }
          setState(() {
            _status = null;
          });
          _pullProgressNotifier.value = 0.0;
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
      final newPull = (_pullProgressNotifier.value + (-notification.overscroll / 96))
          .clamp(0.0, 1.0);
      if (newPull != _pullProgressNotifier.value) {
        _pullProgressNotifier.value = newPull;
        _contentOffset.value = newPull * 12;
      }
    } else if (notification is ScrollEndNotification ||
        (notification is ScrollUpdateNotification &&
            notification.metrics.extentBefore > 0)) {
      if (_status == RefreshIndicatorStatus.drag && _pullProgressNotifier.value > 0) {
        _pullProgressNotifier.value = 0.0;
        _settleContent();
      }
    }
    return false;
  }

  Future<void> _handleRefresh() async {
    try {
      await widget.onRefresh();
    } catch (e) {
      debugPrint('ExpressiveRefreshIndicator refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSpinning =
        _status == RefreshIndicatorStatus.snap ||
        _status == RefreshIndicatorStatus.refresh;
    final isArmed = _status == RefreshIndicatorStatus.armed;

    return RefreshIndicator.noSpinner(
      onRefresh: _handleRefresh,
      triggerMode: widget.triggerMode,
      onStatusChange: _onStatusChange,
      child: NotificationListener<ScrollNotification>(
        onNotification: _trackPullProgress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _contentOffset,
                child: widget.child,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _contentOffset.value),
                  child: child,
                ),
              ),
            ),
            Positioned(
              top: widget.edgeOffset,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: Semantics(
                    liveRegion: true,
                    label: 'Refreshing',
                    child: ValueListenableBuilder<double>(
                      valueListenable: _pullProgressNotifier,
                      builder: (context, pullProgress, _) {
                        final isPulling =
                            _status == RefreshIndicatorStatus.drag || isArmed;
                        final isVisible = _status != null &&
                            _status != RefreshIndicatorStatus.canceled &&
                            (_status == RefreshIndicatorStatus.snap ||
                                _status == RefreshIndicatorStatus.refresh ||
                                _status == RefreshIndicatorStatus.done ||
                                pullProgress > 0.08);
                        final effectiveOpacity = isVisible
                            ? (isSpinning || isArmed
                                ? 1.0
                                : (pullProgress * 1.6).clamp(0.0, 1.0))
                            : 0.0;

                        return AnimatedSlide(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          offset: isVisible ? Offset.zero : const Offset(0, -0.45),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 140),
                            opacity: effectiveOpacity,
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutBack,
                                scale: isSpinning || isArmed ? 1.0 : 0.76,
                                child: AnimatedBuilder(
                                  animation: _motion,
                                  builder: (context, _) => CustomPaint(
                                    size: const Size.square(56),
                                    painter: _ExpressiveLoaderPainter(
                                      containerColor: cs.primaryContainer,
                                      blobColor: cs.onPrimaryContainer,
                                      turns: _motion.value,
                                      pullProgress:
                                          isPulling ? pullProgress : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
  });

  final Color containerColor;
  final Color blobColor;
  final double turns;
  final double? pullProgress;

  static const _vertexCount = 12;

  static final List<Offset> _circleShape = List<Offset>.generate(
    _vertexCount,
    (index) => _polar(index, 1, 1),
  );

  static final List<Offset> _ovalShape = List<Offset>.generate(
    _vertexCount,
    (index) => _polar(index, 1.16, .82),
  );

  // 4-lobed expressive organic shape (symmetric with 12 vertices: 12 % 4 == 0)
  static final List<Offset> _cookieShape = List<Offset>.generate(
    _vertexCount,
    (index) {
      final angle = -math.pi / 2 + math.pi * 2 * index / _vertexCount;
      final r = 0.98 + 0.16 * math.cos(4 * (angle + math.pi / 2));
      return Offset(math.cos(angle) * r, math.sin(angle) * r);
    },
  );

  // 3-lobed soft clover/squircle (symmetric with 12 vertices: 12 % 3 == 0)
  static final List<Offset> _cloverShape = List<Offset>.generate(
    _vertexCount,
    (index) {
      final angle = -math.pi / 2 + math.pi * 2 * index / _vertexCount;
      final r = 0.96 + 0.16 * math.cos(3 * (angle + math.pi / 2));
      return Offset(math.cos(angle) * r, math.sin(angle) * r);
    },
  );

  static final List<List<Offset>> _shapes = [
    _circleShape,
    _ovalShape,
    _cookieShape,
    _cloverShape,
  ];

  static Offset _polar(int index, double xRadius, double yRadius) {
    final angle = -math.pi / 2 + math.pi * 2 * index / _vertexCount;
    return Offset(math.cos(angle) * xRadius, math.sin(angle) * yRadius);
  }

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

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final containerRadius = (size.width / 2) - 1.0;
    final containerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: containerRadius));
    canvas.drawShadow(containerPath, Colors.black, 2, false);
    canvas.drawCircle(center, containerRadius, Paint()..color = containerColor);

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
      // Explicit timeline: circle -> pill -> cookie -> clover -> circle.
      const boundaries = [0.0, .27, .57, .82, 1.0];
      final safeTurns = (turns.isFinite ? (turns % 1.0) : 0.0).clamp(0.0, 1.0);
      final phase = List.generate(boundaries.length - 1, (index) => index)
          .lastWhere(
            (index) => safeTurns >= boundaries[index],
            orElse: () => 0,
          );
      fromIndex = phase.clamp(0, _shapes.length - 1);
      toIndex = (phase + 1) % _shapes.length;
      final span = boundaries[fromIndex + 1] - boundaries[fromIndex];
      final local = span > 0 ? (safeTurns - boundaries[fromIndex]) / span : 0.0;
      t = _spring(local.clamp(0.0, 1.0));
      rotation = safeTurns * math.pi * 2;
    }

    final fromList = _shapes[fromIndex];
    final toList = _shapes[toIndex];
    final radius = size.width * .30;

    final points = List<Offset>.generate(_vertexCount, (index) {
      final fromPt = fromList[index];
      final toPt = toList[index];
      final x = lerpDouble(fromPt.dx, toPt.dx, t) ?? fromPt.dx;
      final y = lerpDouble(fromPt.dy, toPt.dy, t) ?? fromPt.dy;
      return Offset(x * radius, y * radius);
    });

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Continuous closed spline through midpoints: avoids cut-off straight line at index 0.
    final path = Path();
    final firstMidpoint = Offset(
      (points[0].dx + points[points.length - 1].dx) / 2,
      (points[0].dy + points[points.length - 1].dy) / 2,
    );
    path.moveTo(firstMidpoint.dx, firstMidpoint.dy);

    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
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
      oldDelegate.pullProgress != pullProgress;
}
