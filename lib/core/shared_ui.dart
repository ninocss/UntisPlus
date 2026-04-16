part of '../main.dart';

const Curve _kSmoothBounce = Cubic(0.16, 0.94, 0.22, 1.24);
const Curve _kSoftBounce = Cubic(0.18, 0.9, 0.26, 1.14);

Widget _withOptionalBackdropBlur({
  required double sigmaX,
  required double sigmaY,
  required Widget child,
  required Widget Function(bool enabled) childBuilder,
}) {
  if (!blurEnabledNotifier.value) {
    return childBuilder(false);
  }

  return ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: childBuilder(true),
    ),
  );
}

List<Color> _subjectColorPalette(ColorScheme cs) {
  return <Color>[
    cs.primary,
    cs.secondary,
    cs.tertiary,
    cs.error,
    const Color(0xFF4F7CFF),
    const Color(0xFF00B8D4),
    const Color(0xFF00C853),
    const Color(0xFFFFA000),
    const Color(0xFFE91E63),
    const Color(0xFF7C4DFF),
    const Color(0xFF6D4C41),
    const Color(0xFF009688),
  ];
}

Color _autoLessonColor(String subject, bool isDark) {
  final normalized = subject.trim().toLowerCase();
  final palette = <Color>[
    const Color(0xFF4F7CFF),
    const Color(0xFF00B8D4),
    const Color(0xFF00C853),
    const Color(0xFFFFA000),
    const Color(0xFFFF5252),
    const Color(0xFF7C4DFF),
    const Color(0xFFE91E63),
    const Color(0xFF009688),
  ];

  final base = palette[normalized.hashCode.abs() % palette.length];
  final hsl = HSLColor.fromColor(base);
  final adjusted = hsl.withLightness(
    isDark
        ? (hsl.lightness + 0.05).clamp(0.0, 1.0)
        : (hsl.lightness - 0.04).clamp(0.0, 1.0),
  );
  return adjusted.toColor();
}

Route<T> _buildBouncyRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 520),
  Duration reverseDuration = const Duration(milliseconds: 360),
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final opacity = CurvedAnimation(parent: animation, curve: _kSoftBounce);
      final scale = Tween<double>(
        begin: 0.96,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: _kSmoothBounce));
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.03),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: _kSmoothBounce));

      return FadeTransition(
        opacity: opacity,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(scale: scale, child: child),
        ),
      );
    },
  );
}

Widget _springEntry({
  Key? key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 360),
  double offsetY = 14,
  double startScale = 0.96,
  Curve curve = _kSmoothBounce,
}) {
  return TweenAnimationBuilder<double>(
    key: key,
    tween: Tween(begin: 0.0, end: 1.0),
    duration: duration,
    curve: curve,
    builder: (context, t, child) {
      final clamped = t.clamp(0.0, 1.0);
      final overshoot = t > 1.0 ? (t - 1.0) : 0.0;
      final scale = lerpDouble(startScale, 1.0, clamped)! + (overshoot * 0.08);
      return Transform.translate(
        offset: Offset(0, (1 - t) * offsetY),
        child: Transform.scale(
          scale: scale,
          child: Opacity(opacity: clamped, child: child),
        ),
      );
    },
    child: child,
  );
}

Widget _glassContainer({
  required BuildContext context,
  required Widget child,
  BorderRadiusGeometry borderRadius = const BorderRadius.all(
    Radius.circular(28),
  ),
  double sigmaX = 22,
  double sigmaY = 22,
  Color? color,
  Gradient? gradient,
  Border? border,
}) {
  final cs = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: borderRadius,
    child: _withOptionalBackdropBlur(
      sigmaX: sigmaX,
      sigmaY: sigmaY,
      child: const SizedBox.shrink(),
      childBuilder: (enabled) => Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color:
              color ??
              (enabled ? cs.surface.withValues(alpha: 0.72) : cs.surface),
          gradient: enabled
              ? (gradient ??
                    LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surface.withValues(alpha: 0.78),
                        cs.surfaceContainerHigh.withValues(alpha: 0.62),
                      ],
                    ))
              : null,
          border:
              border ??
              Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
        ),
        child: child,
      ),
    ),
  );
}

const AnimationStyle _kBottomSheetAnimationStyle = AnimationStyle(
  duration: Duration(milliseconds: 420),
  reverseDuration: Duration(milliseconds: 280),
);

class _SheetOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final bool destructive;

  const _SheetOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.selected = false,
    this.destructive = false,
  });
}

Widget _sheetSurface({
  required BuildContext context,
  required Widget child,
  bool blur = true,
  BorderRadiusGeometry borderRadius = const BorderRadius.vertical(
    top: Radius.circular(32),
  ),
}) {
  final cs = Theme.of(context).colorScheme;
  if (blur) {
    return _glassContainer(
      context: context,
      borderRadius: borderRadius,
      child: child,
    );
  }

  return Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: borderRadius,
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
    ),
    child: child,
  );
}

Future<T?> _showUnifiedSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  EdgeInsetsGeometry? outerPadding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) {
      final content = _sheetSurface(
        context: ctx,
        blur: blurEnabledNotifier.value,
        child: child,
      );
      if (outerPadding == null) {
        return content;
      }
      return Padding(padding: outerPadding, child: content);
    },
  );
}

Future<T?> _showUnifiedOptionSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<_SheetOption<T>> options,
  bool fitContentHeight = false,
  double bottomMargin = 0,
}) {
  return _showUnifiedSheet<T>(
    context: context,
    isScrollControlled: true,
    outerPadding: bottomMargin > 0
        ? EdgeInsets.only(bottom: bottomMargin)
        : null,
    child: Builder(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final blurOn = blurEnabledNotifier.value;
        final isLightMode = Theme.of(ctx).brightness == Brightness.light;
        final mq = MediaQuery.of(ctx);

        // Reserve enough vertical space for header chrome and keep menu list scrollable.
        final safeViewportHeight =
            mq.size.height -
            mq.padding.top -
            mq.padding.bottom -
            mq.viewInsets.bottom;
        final maxListHeight = (safeViewportHeight *
            (subtitle == null ? 0.74 : 0.68))
          .clamp(220.0, 520.0)
          .toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: _springEntry(
            duration: const Duration(milliseconds: 380),
            offsetY: 14,
            startScale: 0.95,
            curve: _kSoftBounce,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.builder(
                    shrinkWrap: fitContentHeight,
                    primary: false,
                    physics: fitContentHeight
                        ? const ClampingScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                    padding: EdgeInsets.only(bottom: mq.padding.bottom + 12),
                    itemCount: options.length,
                    itemBuilder: (listCtx, idx) {
                        final opt = options[idx];
                        final color = opt.destructive ? cs.error : cs.primary;
                        final iconBackground = opt.selected
                            ? color.withValues(alpha: isLightMode ? 0.22 : 0.26)
                            : color.withValues(alpha: isLightMode ? 0.1 : 0.14);
                        final backgroundColor = opt.selected
                            ? color.withValues(
                                alpha: isLightMode
                                    ? (blurOn ? 0.2 : 0.14)
                                    : (blurOn ? 0.24 : 0.28),
                              )
                            : (isLightMode
                                  ? cs.surfaceContainerHigh.withValues(
                                      alpha: blurOn ? 0.82 : 0.88,
                                    )
                                  : cs.surfaceContainerHighest.withValues(
                                      alpha: blurOn ? 0.76 : 0.84,
                                    ));
                        final borderColor = opt.selected
                            ? color.withValues(
                                alpha: isLightMode
                                    ? (blurOn ? 0.42 : 0.3)
                                    : (blurOn ? 0.58 : 0.48),
                              )
                            : cs.outlineVariant.withValues(
                                alpha: isLightMode
                                    ? (blurOn ? 0.58 : 0.44)
                                    : (blurOn ? 0.58 : 0.5),
                              );
                        final titleColor = opt.selected
                            ? (opt.destructive
                                  ? cs.error
                                  : (isLightMode
                                        ? cs.primary.withValues(alpha: 1)
                                        : cs.onSurface.withValues(alpha: 1)))
                            : cs.onSurface.withValues(
                                alpha: isLightMode ? 0.99 : 1,
                              );
                        final subtitleColor = opt.selected
                            ? cs.onSurface.withValues(
                                alpha: isLightMode ? 0.88 : 0.9,
                              )
                            : cs.onSurfaceVariant.withValues(
                                alpha: isLightMode ? 0.94 : 0.9,
                              );
                        final leadingIconColor = opt.selected
                            ? (opt.destructive
                                  ? cs.error
                                  : (isLightMode
                                        ? cs.primary.withValues(alpha: 1)
                                        : cs.primary.withValues(alpha: 0.95)))
                            : cs.onSurface.withValues(
                                alpha: isLightMode ? 0.9 : 0.94,
                              );
                        final trailingIconColor = opt.selected
                            ? leadingIconColor
                            : cs.onSurfaceVariant.withValues(
                                alpha: isLightMode ? 0.88 : 0.82,
                              );
                        final shadowColor = (opt.selected ? color : cs.shadow)
                            .withValues(
                              alpha: isLightMode
                                  ? (opt.selected
                                        ? (blurOn ? 0.11 : 0.08)
                                        : (blurOn ? 0.04 : 0.03))
                                  : (blurOn
                                        ? (opt.selected ? 0.16 : 0.1)
                                        : (opt.selected ? 0.1 : 0.06)),
                            );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _withOptionalBackdropBlur(
                              sigmaX: 10,
                              sigmaY: 10,
                              child: const SizedBox.shrink(),
                              childBuilder: (_) => Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.pop(ctx, opt.value);
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: opt.selected
                                          ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                backgroundColor,
                                                color.withValues(
                                                  alpha: isLightMode
                                                      ? 0.12
                                                      : 0.18,
                                                ),
                                              ],
                                            )
                                          : null,
                                      color: opt.selected
                                          ? null
                                          : backgroundColor,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: borderColor,
                                        width: opt.selected ? 1.4 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: shadowColor,
                                          blurRadius: opt.selected ? 15 : 9,
                                          offset: Offset(0, blurOn ? 6 : 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      minTileHeight: 56,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 2,
                                          ),
                                      leading: opt.icon == null
                                          ? null
                                          : Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: iconBackground,
                                                border: Border.all(
                                                  color: borderColor.withValues(
                                                    alpha: isLightMode
                                                        ? 0.9
                                                        : 0.75,
                                                  ),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                              ),
                                              child: Icon(
                                                opt.icon,
                                                color: leadingIconColor,
                                                size: 19,
                                              ),
                                            ),
                                      title: Text(
                                        opt.title,
                                        style: GoogleFonts.outfit(
                                          fontWeight: opt.selected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          fontSize: 15.4,
                                          letterSpacing: 0.08,
                                          color: titleColor,
                                        ),
                                      ),
                                      subtitle: opt.subtitle == null
                                          ? null
                                          : Text(
                                              opt.subtitle!,
                                              style: GoogleFonts.outfit(
                                                color: subtitleColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.05,
                                              ),
                                            ),
                                      trailing: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        transitionBuilder:
                                            (child, animation) {
                                              return ScaleTransition(
                                                scale: animation,
                                                child: FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                ),
                                              );
                                            },
                                        child: opt.selected
                                            ? Icon(
                                                Icons.check_circle_rounded,
                                                key: ValueKey(
                                                  '${opt.title}_selected',
                                                ),
                                                color: trailingIconColor,
                                                size: 22,
                                              )
                                            : Icon(
                                                Icons.chevron_right_rounded,
                                                key: ValueKey(
                                                  '${opt.title}_arrow',
                                                ),
                                                color: trailingIconColor,
                                                size: 20,
                                              ),
                                      ),
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
              ],
            ),
          ),
        );
      },
    ),
  );
}
