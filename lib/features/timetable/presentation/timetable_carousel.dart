import 'package:flutter/material.dart';

/// Only transforms rebuild during a drag. The prepared pages stay identical.
class TimetableCarousel extends StatelessWidget {
  const TimetableCarousel({
    super.key,
    required this.offset,
    required this.width,
    required this.current,
    this.previous,
    this.next,
    this.depth = false,
  });

  final ValueNotifier<double> offset;
  final double width;
  final Widget current;
  final Widget? previous;
  final Widget? next;
  final bool depth;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: offset,
    builder: (context, rawOffset, _) {
      final x = rawOffset.clamp(-width, width).toDouble();
      final progress = width <= 0 ? 0.0 : (x.abs() / width).clamp(0.0, 1.0);
      Widget page(
        String identity,
        Widget child,
        double translation, {
        bool incoming = false,
      }) {
        final content = RepaintBoundary(child: child);
        if (!depth) {
          return Transform.translate(
            key: ValueKey(identity),
            offset: Offset(translation, 0),
            child: content,
          );
        }
        return Transform.translate(
          key: ValueKey(identity),
          offset: Offset(translation, 0),
          child: Opacity(
            opacity: incoming ? 0.32 + 0.68 * progress : 1 - 0.18 * progress,
            child: Transform.scale(
              scale: incoming ? 0.92 + 0.08 * progress : 1 - 0.04 * progress,
              child: content,
            ),
          ),
        );
      }

      return ClipRect(
        child: Stack(
          children: [
            if (x > 0 && previous != null)
              page('previous', previous!, -width + x, incoming: true),
            if (x < 0 && next != null)
              page('next', next!, width + x, incoming: true),
            page('current', current, x),
          ],
        ),
      );
    },
  );
}
