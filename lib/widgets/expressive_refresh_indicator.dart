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
    required this.edgeOffset,
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
    with SingleTickerProviderStateMixin {
  RefreshIndicatorStatus? _status;
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  bool get _isVisible =>
      _status != null && _status != RefreshIndicatorStatus.inactive;

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _onStatusChange(RefreshIndicatorStatus? status) {
    if (status == _status) return;
    setState(() => _status = status);
    if (status == RefreshIndicatorStatus.refresh) {
      _motion.repeat();
    } else if (status == RefreshIndicatorStatus.inactive) {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRefreshing = _status == RefreshIndicatorStatus.refresh;
    final isArmed = _status == RefreshIndicatorStatus.armed;

    return RefreshIndicator.noSpinner(
      onRefresh: widget.onRefresh,
      edgeOffset: widget.edgeOffset,
      triggerMode: widget.triggerMode,
      onStatusChange: _onStatusChange,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(
            top: widget.edgeOffset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Semantics(
                liveRegion: true,
                label: 'Refreshing',
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  offset: _isVisible ? Offset.zero : const Offset(0, -0.45),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: _isVisible ? 1 : 0,
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        scale: isRefreshing || isArmed ? 1 : 0.76,
                        child: AnimatedBuilder(
                          animation: _motion,
                          builder: (context, _) => CustomPaint(
                            size: const Size.square(72),
                            painter: _ExpressiveLoaderPainter(
                              containerColor: cs.primaryContainer,
                              blobColor: cs.primary,
                              turns: _motion.value,
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
    );
  }
}

class _ExpressiveLoaderPainter extends CustomPainter {
  const _ExpressiveLoaderPainter({
    required this.containerColor,
    required this.blobColor,
    required this.turns,
  });

  final Color containerColor;
  final Color blobColor;
  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, size.width / 2, Paint()..color = containerColor);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * math.pi * 2);
    final r = size.width * 0.285;
    final pulse = 1 + math.sin(turns * math.pi * 4) * 0.055;
    canvas.scale(pulse, pulse);
    final path = Path()
      ..moveTo(0, -r)
      ..cubicTo(r * .42, -r * 1.16, r * .94, -r * .80, r * .90, -r * .28)
      ..cubicTo(r * 1.28, r * .10, r * .91, r * .44, r * .52, r * .56)
      ..cubicTo(r * .38, r * 1.10, -r * .12, r * 1.18, -r * .44, r * .78)
      ..cubicTo(-r * .90, r * .85, -r * 1.06, r * .35, -r * .86, 0)
      ..cubicTo(-r * 1.22, -r * .30, -r * .73, -r * .72, -r * .33, -r * .72)
      ..cubicTo(-r * .16, -r * 1.11, -r * .05, -r * 1.02, 0, -r)
      ..close();
    canvas.drawPath(path, Paint()..color = blobColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ExpressiveLoaderPainter oldDelegate) =>
      oldDelegate.containerColor != containerColor ||
      oldDelegate.blobColor != blobColor ||
      oldDelegate.turns != turns;
}
