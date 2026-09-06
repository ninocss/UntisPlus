part of '../main.dart';

const Curve _kSmoothBounce = Curves.easeOutCubic;
const Curve _kSoftBounce = Curves.easeOutQuad;

const AnimationStyle _kBottomSheetAnimationStyle = AnimationStyle();

class _StripedHatchPainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  final double gap;

  const _StripedHatchPainter({
    required this.color,
    this.stripeWidth = 2.0,
    this.gap = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    final step = stripeWidth + gap;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StripedHatchPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.stripeWidth != stripeWidth ||
      oldDelegate.gap != gap;
}

Widget _springEntry({
  Key? key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 360),
  double offsetY = 14,
  double startScale = 0.96,
  Curve curve = Curves.easeOutCubic,
}) {
  return child;
}

Widget _blurEffect({
  required Widget child,
  double sigma = 30,
  BorderRadiusGeometry borderRadius = BorderRadius.zero,
  bool enabled = true,
}) {
  return ValueListenableBuilder<bool>(
    valueListenable: blurEnabledNotifier,
    builder: (context, blurEnabled, _) {
      if (!enabled || !blurEnabled) return child;
      return ClipRRect(
        borderRadius: borderRadius is BorderRadius
            ? borderRadius
            : BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        ),
      );
    },
  );
}

class ThemedSurface extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final double? sigma;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final bool blur;

  const ThemedSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.sigma,
    this.color,
    this.gradient,
    this.border,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final radius = borderRadius ?? BorderRadius.circular(tokens.surfaceRadius);
    return ValueListenableBuilder<bool>(
      valueListenable: blurEnabledNotifier,
      builder: (context, blurEnabled, _) {
        final blurActive = blur && tokens.supportsBlur && blurEnabled;
        final translucent =
            color ??
            cs.surfaceContainerLow.withValues(
              alpha: tokens.id == AppThemeId.glass ? 0.48 : 0.72,
            );
        final opaque = Color.alphaBlend(translucent, cs.surface);
        final effectiveColor = blurActive ? translucent : opaque;
        final effectiveBorder =
            border ??
            Border.all(
              color: tokens.id == AppThemeId.manga
                  ? cs.outline
                  : (tokens.glassHighlights
                        ? Colors.white.withValues(alpha: 0.52)
                        : cs.outlineVariant.withValues(alpha: 0.46)),
              width: tokens.borderWidth,
            );
        Widget surface = DecoratedBox(
          decoration: BoxDecoration(
            color: gradient == null ? effectiveColor : null,
            gradient: gradient,
            borderRadius: radius,
            border: effectiveBorder,
          ),
          child: tokens.glassHighlights && blurActive
              ? Stack(
                  fit: StackFit.passthrough,
                  children: [
                    child,
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 1,
                      child: IgnorePointer(
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.82),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : child,
        );
        surface = ClipRRect(
          borderRadius: radius,
          child: blurActive
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: sigma ?? tokens.blurSigma,
                    sigmaY: sigma ?? tokens.blurSigma,
                  ),
                  child: surface,
                )
              : surface,
        );
        return RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: tokens.shadowColor,
                  offset: tokens.shadowOffset,
                  blurRadius: tokens.hardShadow ? 0 : 20,
                ),
              ],
            ),
            child: surface,
          ),
        );
      },
    );
  }
}

Widget _glassContainer({
  required BuildContext context,
  required Widget child,
  BorderRadiusGeometry borderRadius = const BorderRadius.all(
    Radius.circular(32),
  ),
  double sigma = 30,
  Color? color,
  Gradient? gradient,
  Border? border,
}) {
  return ThemedSurface(
    borderRadius: borderRadius,
    sigma: sigma,
    color: color,
    gradient: gradient,
    border: border,
    child: child,
  );
}

Widget _withOptionalBackdropBlur({
  double sigma = 30,
  required Widget child,
  required Widget Function(bool enabled) childBuilder,
}) {
  return ValueListenableBuilder<bool>(
    valueListenable: blurEnabledNotifier,
    builder: (context, enabled, _) {
      return _blurEffect(
        sigma: sigma,
        enabled: enabled,
        child: childBuilder(enabled),
      );
    },
  );
}

Widget _sheetSurface({
  required BuildContext context,
  required Widget child,
  bool blur = true,
  BorderRadiusGeometry borderRadius = const BorderRadius.vertical(
    top: Radius.circular(32),
  ),
}) {
  return ThemedSurface(
    borderRadius: borderRadius,
    sigma: 45,
    blur: blur,
    child: child,
  );
}

List<Color> _subjectColorPalette(ColorScheme cs) {
  return untisPlusSubjectPalette(cs);
}

Color _autoLessonColor(String subject, bool isDark) {
  final normalized = subject.trim().toLowerCase();
  final palette = untisPlusAutoLessonPalette();

  final base = palette[normalized.hashCode.abs() % palette.length];
  final hsl = HSLColor.fromColor(base);
  final adjusted = hsl.withLightness(
    isDark
        ? (hsl.lightness + 0.12).clamp(0.0, 1.0)
        : (hsl.lightness - 0.05).clamp(0.0, 1.0),
  );
  return adjusted.toColor();
}

Route<T> _buildBouncyRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 300),
  Duration reverseDuration = const Duration(milliseconds: 300),
  int? transitionType,
}) {
  // We rely on Material 3 standard page transitions now.
  // This wrapper just delegates to the standard MaterialPageRoute.
  return MaterialPageRoute<T>(builder: (context) => page);
}

class _SheetOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final bool destructive;

  const _SheetOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.selected = false,
    this.destructive = false,
  });
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
    elevation: 0,
    builder: (ctx) {
      Widget content = child;
      if (outerPadding != null) {
        content = Padding(padding: outerPadding, child: content);
      }
      return _sheetSurface(context: ctx, child: content);
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
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return _sheetSurface(
        context: ctx,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final opt = options[index];
                      return ListTile(
                        leading:
                            opt.leading ??
                            (opt.icon != null
                                ? Icon(
                                    opt.icon,
                                    color: opt.destructive
                                        ? cs.error
                                        : (opt.selected ? cs.primary : null),
                                  )
                                : null),
                        title: Text(
                          opt.title,
                          style: TextStyle(
                            color: opt.destructive
                                ? cs.error
                                : (opt.selected ? cs.primary : null),
                            fontWeight: opt.selected ? FontWeight.bold : null,
                          ),
                        ),
                        subtitle: opt.subtitle != null
                            ? Text(opt.subtitle!)
                            : null,
                        trailing: opt.selected
                            ? Icon(Icons.check, color: cs.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx, opt.value);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ── Settings UI Components (Material You Expressive Grouped Sections) ────────

class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;

  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final validChildren = children.where((w) {
      if (w is SizedBox && w.width == 0 && w.height == 0) return false;
      return true;
    }).toList();

    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6, top: 4),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: tokens.id == AppThemeId.manga ? 21 : 13,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  letterSpacing: tokens.id == AppThemeId.cyber ? 1.2 : 0.2,
                ),
              ),
            ),
          ],
          _glassContainer(
            context: context,
            borderRadius: BorderRadius.circular(tokens.surfaceRadius),
            color: cs.surfaceContainerLow.withValues(alpha: 0.5),
            border: Border.all(
              color: tokens.id == AppThemeId.manga
                  ? cs.outline
                  : cs.primary.withValues(alpha: 0.20),
              width: tokens.borderWidth,
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.surfaceRadius),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < validChildren.length; i++) ...[
                      validChildren[i],
                      if (i < validChildren.length - 1)
                        Divider(
                          height: 1,
                          indent: 58,
                          endIndent: 16,
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing = const Icon(Icons.chevron_right_rounded),
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final effectiveLeading =
        leading ??
        (icon != null
            ? Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor ??
                      (destructive
                          ? cs.errorContainer
                          : cs.primary.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color:
                      iconColor ??
                      (destructive ? cs.onErrorContainer : cs.primary),
                ),
              )
            : null);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            if (effectiveLeading != null) ...[
              effectiveLeading,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: destructive ? cs.error : cs.onSurface,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: cs.onSurfaceVariant, size: 22),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final effectiveLeading =
        leading ??
        (icon != null
            ? Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor ?? cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                ),
                child: Icon(icon, size: 20, color: iconColor ?? cs.primary),
              )
            : null);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            if (effectiveLeading != null) ...[
              effectiveLeading,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                onChanged(val);
              },
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(Icons.check, size: 14);
                }
                return const Icon(Icons.close, size: 14);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
