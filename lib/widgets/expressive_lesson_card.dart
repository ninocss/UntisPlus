import 'package:flutter/material.dart';

/// The 7 distinct asymmetric corner radius variants from the Figma preview.
enum ExpressiveShapeVariant {
  shape0, // ma: 34, 34, 12, 34
  shape1, // de: 12, 34, 34, 34
  shape2, // en: 30, 10, 30, 30
  shape3, // if: 10, 30, 30, 30
  shape4, // ch: 34, 34, 14, 14
  shape5, // sp: 12, 38, 12, 38
  shape6; // ge: 38, 14, 38, 14

  BorderRadius get cardRadius {
    switch (this) {
      case ExpressiveShapeVariant.shape0:
        return const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(34),
        );
      case ExpressiveShapeVariant.shape1:
        return const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(34),
          bottomRight: Radius.circular(34),
          bottomLeft: Radius.circular(34),
        );
      case ExpressiveShapeVariant.shape2:
        return const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        );
      case ExpressiveShapeVariant.shape3:
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        );
      case ExpressiveShapeVariant.shape4:
        return const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        );
      case ExpressiveShapeVariant.shape5:
        return const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(38),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(38),
        );
      case ExpressiveShapeVariant.shape6:
        return const BorderRadius.only(
          topLeft: Radius.circular(38),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(38),
          bottomLeft: Radius.circular(14),
        );
    }
  }

  BorderRadius get badgeRadius {
    switch (this) {
      case ExpressiveShapeVariant.shape0:
      case ExpressiveShapeVariant.shape4:
        return const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(8),
          bottomLeft: Radius.circular(24),
        );
      case ExpressiveShapeVariant.shape1:
      case ExpressiveShapeVariant.shape3:
        return const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        );
      case ExpressiveShapeVariant.shape2:
      case ExpressiveShapeVariant.shape6:
        return const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(8),
        );
      case ExpressiveShapeVariant.shape5:
        return const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(8),
          bottomLeft: Radius.circular(24),
        );
    }
  }

  static ExpressiveShapeVariant fromKey(String key) {
    if (key.isEmpty) return ExpressiveShapeVariant.shape0;
    final hash = key.toLowerCase().codeUnits.fold(0, (acc, c) => acc + c);
    return ExpressiveShapeVariant.values[hash % ExpressiveShapeVariant.values.length];
  }
}

/// Color tones defined in the Figma preview.
class ExpressiveTone {
  final Color cardColor;
  final Color inkColor;

  const ExpressiveTone({
    required this.cardColor,
    required this.inkColor,
  });

  static const mint = ExpressiveTone(
    cardColor: Color(0xFFDFE7C6),
    inkColor: Color(0xFF344500),
  );

  static const blue = ExpressiveTone(
    cardColor: Color(0xFFDCE5FF),
    inkColor: Color(0xFF294477),
  );

  static const amber = ExpressiveTone(
    cardColor: Color(0xFFFFDEA5),
    inkColor: Color(0xFF604800),
  );

  static const rose = ExpressiveTone(
    cardColor: Color(0xFFFFD8E4),
    inkColor: Color(0xFF633B48),
  );

  static ExpressiveTone resolve({
    required Color? customColor,
    required bool isDark,
    required bool isCancelled,
    String? subjectKey,
  }) {
    if (isCancelled) {
      return rose;
    }

    if (customColor != null) {
      final hsv = HSVColor.fromColor(customColor);
      if (isDark) {
        final darkCard = Color.alphaBlend(
          customColor.withValues(alpha: 0.18),
          const Color(0xFF1E201A),
        );
        final brightInk = hsv.withSaturation(0.45).withValue(0.95).toColor();
        return ExpressiveTone(cardColor: darkCard, inkColor: brightInk);
      } else {
        final lightCard = Color.alphaBlend(
          customColor.withValues(alpha: 0.12),
          const Color(0xFFF9F9F4),
        );
        final deepInk = hsv.withSaturation(0.95).withValue(0.35).toColor();
        return ExpressiveTone(cardColor: lightCard, inkColor: deepInk);
      }
    }

    final key = subjectKey?.toLowerCase().trim() ?? '';
    final code = key.codeUnits.fold(0, (sum, c) => sum + c);
    final tones = [mint, blue, amber, rose];
    final selectedTone = tones[code % tones.length];

    if (isDark) {
      final darkCard = Color.alphaBlend(
        selectedTone.cardColor.withValues(alpha: 0.22),
        const Color(0xFF1F201B),
      );
      final brightInk = Color.alphaBlend(
        selectedTone.cardColor.withValues(alpha: 0.8),
        Colors.white,
      );
      return ExpressiveTone(cardColor: darkCard, inkColor: brightInk);
    }
    return selectedTone;
  }
}

/// A custom painter for the 45-degree diagonal stripe pattern used on cancelled cards.
class _ExpressiveHatchPainter extends CustomPainter {
  final Color color;

  const _ExpressiveHatchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const gap = 10.0;
    final total = size.width + size.height;
    for (double i = -size.height; i < total; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExpressiveHatchPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// The interactive Material 3 Expressive Lesson Card faithfully modeling the
/// Figma preview in `New_Lesson_screen_preview` and deeply integrated with Untis+.
class ExpressiveLessonCard extends StatefulWidget {
  final String subject;
  final String teacher;
  final String room;
  final bool isCancelled;
  final bool isNow;
  final bool isSubstitution;
  final bool hasHomework;
  final bool hasExam;
  final bool isTeacherMissing;
  final ExpressiveShapeVariant shapeVariant;
  final ExpressiveTone? tone;
  final Color? fgColor;
  final Color? bgColor;
  final bool isDark;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? availableWidth;
  final double? availableHeight;
  final IconData? subjectIcon;

  const ExpressiveLessonCard({
    super.key,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.isCancelled,
    this.isNow = false,
    this.isSubstitution = false,
    this.hasHomework = false,
    this.hasExam = false,
    this.isTeacherMissing = false,
    this.shapeVariant = ExpressiveShapeVariant.shape0,
    this.tone,
    this.fgColor,
    this.bgColor,
    this.isDark = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.availableWidth,
    this.availableHeight,
    this.subjectIcon,
  });

  @override
  State<ExpressiveLessonCard> createState() => _ExpressiveLessonCardState();
}

class _ExpressiveLessonCardState extends State<ExpressiveLessonCard> {
  bool _isPressed = false;

  void _handlePointerDown() {
    if (!_isPressed) {
      setState(() => _isPressed = true);
    }
  }

  void _handlePointerUp() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = widget.isDark;

    // Harmonize colors with Untis+ theme and subject color
    final primaryColor = widget.fgColor ?? widget.tone?.inkColor ?? cs.primary;
    final resolvedTone = widget.tone ??
        ExpressiveTone.resolve(
          customColor: widget.fgColor,
          isDark: isDark,
          isCancelled: widget.isCancelled,
          subjectKey: widget.subject,
        );

    final cardBackgroundColor = widget.isCancelled
        ? (isDark
            ? Color.alphaBlend(const Color(0xFF633B48).withValues(alpha: 0.22), const Color(0xFF1E1F1A))
            : const Color(0xFFFFEEF2))
        : (widget.fgColor != null
            ? (isDark
                ? Color.alphaBlend(primaryColor.withValues(alpha: 0.16), const Color(0xFF1E201B))
                : Color.alphaBlend(primaryColor.withValues(alpha: 0.11), cs.surfaceContainerLowest))
            : resolvedTone.cardColor);

    final cardInkColor = widget.isCancelled
        ? const Color(0xFF633B48)
        : (widget.fgColor != null
            ? (isDark
                ? Color.alphaBlend(primaryColor.withValues(alpha: 0.85), Colors.white)
                : Color.alphaBlend(Colors.black.withValues(alpha: 0.65), primaryColor))
            : resolvedTone.inkColor);

    // Subject badge background: vibrant solid accent in light, tinted container in dark
    final badgeBgColor = widget.isCancelled
        ? const Color(0xFF633B48)
        : (widget.fgColor != null
            ? (isDark
                ? Color.alphaBlend(primaryColor.withValues(alpha: 0.38), cs.surfaceContainerHighest)
                : primaryColor)
            : resolvedTone.inkColor);

    final badgeTextColor = widget.isCancelled
        ? const Color(0xFFFFD8E4)
        : (widget.fgColor != null
            ? (isDark ? primaryColor : Colors.white)
            : resolvedTone.cardColor);

    final effectiveRadius = _isPressed
        ? BorderRadius.circular(20)
        : widget.shapeVariant.cardRadius;

    final backgroundColor = widget.selected
        ? Color.alphaBlend(cardInkColor.withValues(alpha: 0.12), cardBackgroundColor)
        : cardBackgroundColor;

    final height = widget.availableHeight;
    final isHeightCompact = height != null && height < 58;
    final isHeightMinimal = height != null && height < 42;
    final isWidthNarrow = widget.availableWidth != null && widget.availableWidth! < 70;

    final badgeSize = isHeightMinimal
        ? 24.0
        : (isHeightCompact ? 30.0 : 40.0);
    final badgeFontSize = isHeightMinimal
        ? 9.5
        : (isHeightCompact ? 11.0 : 13.5);

    final teacherFontSize = isHeightCompact ? 10.5 : 12.5;
    final roomFontSize = isHeightCompact ? 9.0 : 10.5;

    final effectivePadding = isHeightMinimal
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : (isHeightCompact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 11, vertical: 7));

    Widget content;
    if (isHeightMinimal) {
      content = Row(
        children: [
          _buildBadge(badgeSize, badgeFontSize, badgeBgColor, badgeTextColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.teacher.isNotEmpty ? widget.teacher : widget.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cardInkColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                decoration: widget.isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (widget.room.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              widget.room,
              maxLines: 1,
              style: TextStyle(
                color: cardInkColor.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
                fontSize: 9,
                decoration: widget.isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ],
      );
    } else if (isWidthNarrow) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge(26, 10, badgeBgColor, badgeTextColor),
          const SizedBox(height: 3),
          Text(
            widget.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cardInkColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              decoration: widget.isCancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          if (widget.room.isNotEmpty)
            Text(
              widget.room,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cardInkColor.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
                fontSize: 8.5,
              ),
            ),
        ],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildBadge(badgeSize, badgeFontSize, badgeBgColor, badgeTextColor),
          SizedBox(width: isHeightCompact ? 8 : 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.teacher.isNotEmpty ? widget.teacher : widget.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cardInkColor,
                    fontWeight: FontWeight.w700,
                    fontSize: teacherFontSize,
                    letterSpacing: -0.1,
                    decoration: widget.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                SizedBox(height: isHeightCompact ? 2 : 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      key: const ValueKey('expressive-lesson-room-icon'),
                      size: isHeightCompact ? 10.5 : 12.0,
                      color: cardInkColor.withValues(
                        alpha: widget.isCancelled ? 0.45 : 0.72,
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    Flexible(
                      child: Text(
                        widget.room.isNotEmpty ? widget.room : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cardInkColor.withValues(
                            alpha: widget.isCancelled ? 0.45 : 0.72,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: roomFontSize,
                          decoration: widget.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (widget.isSubstitution) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: isHeightCompact ? 10.5 : 12.0,
                        color: cardInkColor.withValues(alpha: 0.85),
                      ),
                    ],
                    if (widget.hasHomework || widget.hasExam) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.hasExam
                            ? Icons.assignment_turned_in_rounded
                            : Icons.assignment_rounded,
                        size: isHeightCompact ? 10.0 : 11.5,
                        color: cardInkColor.withValues(alpha: 0.85),
                      ),
                    ],
                    if (widget.isTeacherMissing) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.person_off_rounded,
                        size: isHeightCompact ? 10.0 : 11.5,
                        color: Colors.deepOrange.withValues(alpha: 0.9),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: '${widget.subject}, ${widget.teacher}, ${widget.room}${widget.isCancelled ? ', fällt aus' : ''}',
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _handlePointerDown(),
        onPointerUp: (_) => _handlePointerUp(),
        onPointerCancel: (_) => _handlePointerUp(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: widget.isCancelled
                    ? const Color(0xFF633B48).withValues(alpha: 0.3)
                    : primaryColor.withValues(alpha: isDark ? 0.32 : 0.18),
                width: 1.0,
              ),
              boxShadow: widget.isNow
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: isDark ? 0.40 : 0.28),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: effectiveRadius,
              child: Stack(
                children: [
                  if (widget.isCancelled)
                    Positioned.fill(
                      child: CustomPaint(
                        key: const ValueKey('expressive-lesson-hatch-pattern'),
                        painter: _ExpressiveHatchPainter(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  if (_isPressed)
                    Positioned.fill(
                      child: Container(
                        color: cardInkColor.withValues(alpha: 0.09),
                      ),
                    ),
                  Padding(
                    padding: effectivePadding,
                    child: content,
                  ),
                  if (widget.isCancelled && !isHeightMinimal)
                    Positioned(
                      top: 7,
                      right: 8,
                      child: Container(
                        key: const ValueKey('expressive-lesson-cancelled-pill'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF633B48) : Colors.white).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF633B48).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Entfällt',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF633B48),
                            fontSize: 8.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(double size, double fontSize, Color bg, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.2, 0.0, 0.0, 1.0),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _isPressed
            ? BorderRadius.circular(size * 0.38)
            : widget.shapeVariant.badgeRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        widget.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
