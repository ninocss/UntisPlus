part of '../main.dart';

List<Color> _subjectColorPalette(ColorScheme cs) {
  final candidates = <Color>[
    cs.primary,
    cs.secondary,
    cs.tertiary,
    cs.error,
    cs.primaryContainer,
    cs.secondaryContainer,
    cs.tertiaryContainer,
    cs.errorContainer,
    cs.inversePrimary,
    cs.surfaceTint,
  ];
  final seen = <int>{};
  return [
    for (final c in candidates)
      if (seen.add(c.value)) c,
  ];
}

Color _autoLessonColor(String subjectKey, bool isDark) {
  if (subjectKey.isEmpty) {
    return isDark ? const Color(0xFF9580FF) : const Color(0xFF6750A4);
  }
  var hash = 5381;
  for (final c in subjectKey.codeUnits) {
    hash = ((hash * 33) ^ c) & 0x7FFFFFFF;
  }
  final hue = (hash % 360).toDouble();
  final lightness = isDark ? 0.68 : 0.42;
  final saturation = isDark ? 0.52 : 0.62;
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

Widget _withOptionalBackdropBlur({
  required Widget child,
  required double sigmaX,
  required double sigmaY,
  Widget Function(bool enabled)? childBuilder,
}) {
  return ValueListenableBuilder<bool>(
    valueListenable: blurEnabledNotifier,
    builder: (context, enabled, _) {
      final content = childBuilder?.call(enabled) ?? child;
      if (!enabled) return content;
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: content,
      );
    },
  );
}

const Curve _kSmoothBounce = Cubic(0.2, 0.9, 0.26, 1.2);
const Curve _kSoftBounce = Cubic(0.2, 0.88, 0.28, 1.1);

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
          color: color ?? (enabled ? cs.surface.withOpacity(0.72) : cs.surface),
          gradient: enabled
              ? (gradient ??
                    LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surface.withOpacity(0.78),
                        cs.surfaceContainerHigh.withOpacity(0.62),
                      ],
                    ))
              : null,
          border:
              border ??
              Border.all(color: cs.outlineVariant.withOpacity(0.4), width: 1),
        ),
        child: child,
      ),
    ),
  );
}

Widget _glassFab({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onPressed,
  String? tooltip,
}) {
  final cs = Theme.of(context).colorScheme;
  return _springEntry(
    duration: const Duration(milliseconds: 420),
    offsetY: 18,
    startScale: 0.94,
    curve: _kSmoothBounce,
    child: Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: _withOptionalBackdropBlur(
          sigmaX: 16,
          sigmaY: 16,
          child: const SizedBox.shrink(),
          childBuilder: (enabled) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onPressed();
              },
              child: Ink(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: enabled
                      ? cs.primaryContainer.withOpacity(0.92)
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, color: cs.primary, size: 26),
              ),
            ),
          ),
        ),
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
      border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
    ),
    child: child,
  );
}

Future<T?> _showUnifiedSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = false,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) => _sheetSurface(
      context: ctx,
      blur: blurEnabledNotifier.value,
      child: child,
    ),
  );
}

Future<T?> _showUnifiedOptionSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<_SheetOption<T>> options,
}) {
  return _showUnifiedSheet<T>(
    context: context,
    child: Builder(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final blurOn = blurEnabledNotifier.value;
        final maxSheetHeight = MediaQuery.of(ctx).size.height * 0.72;
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
                    color: cs.onSurfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxSheetHeight),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final opt = entry.value;
                        final color = opt.destructive ? cs.error : cs.primary;
                        final iconBackground = opt.selected
                            ? color.withOpacity(blurOn ? 0.22 : 0.3)
                            : color.withOpacity(blurOn ? 0.12 : 0.2);
                        final tileGradient = opt.selected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(blurOn ? 0.24 : 0.32),
                                  cs.surface.withOpacity(blurOn ? 0.54 : 0.9),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.surfaceContainerHighest.withOpacity(
                                    blurOn ? 0.28 : 0.92,
                                  ),
                                  cs.surface.withOpacity(blurOn ? 0.18 : 0.88),
                                ],
                              );

                        return _springEntry(
                          duration: Duration(milliseconds: 240 + idx * 50),
                          offsetY: 16,
                          startScale: 0.95,
                          curve: _kSmoothBounce,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: idx == options.length - 1 ? 0 : 10,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: _withOptionalBackdropBlur(
                                sigmaX: 12,
                                sigmaY: 12,
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
                                        gradient: tileGradient,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: opt.selected
                                              ? color.withOpacity(0.52)
                                              : cs.outlineVariant.withOpacity(
                                                  blurOn ? 0.34 : 0.45,
                                                ),
                                          width: opt.selected ? 1.4 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (opt.selected
                                                    ? color
                                                    : cs.shadow)
                                                .withOpacity(
                                                  blurOn
                                                      ? (opt.selected
                                                            ? 0.14
                                                            : 0.08)
                                                      : (opt.selected
                                                            ? 0.1
                                                            : 0.06),
                                                ),
                                            blurRadius: opt.selected ? 14 : 10,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 13,
                                              vertical: 3,
                                            ),
                                        leading: opt.icon == null
                                            ? null
                                            : Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: iconBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(11),
                                                ),
                                                child: Icon(
                                                  opt.icon,
                                                  color: color,
                                                  size: 18,
                                                ),
                                              ),
                                        title: Text(
                                          opt.title,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        subtitle: opt.subtitle == null
                                            ? null
                                            : Text(
                                                opt.subtitle!,
                                                style: GoogleFonts.outfit(
                                                  color: cs.onSurfaceVariant,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
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
                                                  color: color,
                                                )
                                              : Icon(
                                                  Icons.chevron_right_rounded,
                                                  key: ValueKey(
                                                    '${opt.title}_arrow',
                                                  ),
                                                  color: cs.onSurfaceVariant
                                                      .withOpacity(0.65),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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

