part of '../main.dart';

const Curve _kSmoothBounce = Curves.easeOutCubic;
const Curve _kSoftBounce = Curves.easeOutQuad;

const AnimationStyle _kBottomSheetAnimationStyle = AnimationStyle();

/// Shared width vocabulary for layouts that need to work from a phone to a
/// desktop-sized tablet. Keep breakpoints here instead of letting individual
/// pages make subtly different tablet decisions.
abstract final class UntisLayout {
  static const double tabletBreakpoint = 720;
  static const double expandedBreakpoint = 1000;
  static const double contentMaxWidth = 1180;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedBreakpoint;

  static EdgeInsets pagePadding(
    BuildContext context, {
    double bottom = 32,
    double compactHorizontal = 16,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= expandedBreakpoint
        ? 28.0
        : width >= tabletBreakpoint
        ? 24.0
        : compactHorizontal;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, bottom);
  }

  static BoxConstraints dialogConstraints(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return BoxConstraints(
      maxWidth: width >= expandedBreakpoint ? 640 : 560,
      maxHeight: MediaQuery.sizeOf(context).height * 0.84,
    );
  }

  static Widget constrainContent({
    required Widget child,
    double maxWidth = contentMaxWidth,
  }) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Presents short actions as a bottom sheet on a phone and as a focused,
/// keyboard-safe dialog on a tablet. The content and actions are identical;
/// only the surrounding surface adapts to the available space.
Future<T?> showUntisAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = false,
}) {
  if (!UntisLayout.isTablet(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: UntisLayout.dialogConstraints(dialogContext),
        child: SingleChildScrollView(child: builder(dialogContext)),
      ),
    ),
  );
}

List<BoxShadow>? _glowShadows(BuildContext context, List<BoxShadow> shadows) =>
    untisThemeTokensOf(context).glowEffectsEnabled ? shadows : null;

bool _usesExpressiveComponents(BuildContext context) => appThemeCapabilities(
  untisThemeTokensOf(context).id,
).supportsExpressiveComponents;

OutlinedBorder? _legacyButtonShape(BuildContext context, double radius) =>
    _usesExpressiveComponents(context)
    ? null
    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

double _expressiveRadius(
  BuildContext context,
  double legacyRadius, {
  required double expressiveRadius,
}) => _usesExpressiveComponents(context) ? expressiveRadius : legacyRadius;

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

double _resolvedSurfaceCornerRadius(double baseRadius) {
  switch (surfaceCornerModeNotifier.value) {
    case 1:
      return math.min(baseRadius, 12.0);
    case 2:
      return surfaceCornerRadiusNotifier.value.clamp(0, 48).toDouble();
    case 0:
    default:
      return baseRadius;
  }
}

BorderRadiusGeometry _resolvedSurfaceBorderRadius(
  BorderRadiusGeometry baseRadius,
) {
  final mode = surfaceCornerModeNotifier.value;
  if (mode == 0) return baseRadius;

  if (baseRadius is! BorderRadius) {
    return BorderRadius.circular(
      mode == 1
          ? 12
          : surfaceCornerRadiusNotifier.value.clamp(0, 48).toDouble(),
    );
  }

  Radius resolve(Radius original) {
    if (original.x == 0 && original.y == 0) return Radius.zero;
    if (mode == 1) {
      return Radius.elliptical(
        math.min(original.x, 12),
        math.min(original.y, 12),
      );
    }
    final radius = surfaceCornerRadiusNotifier.value.clamp(0, 48).toDouble();
    return Radius.circular(radius);
  }

  return BorderRadius.only(
    topLeft: resolve(baseRadius.topLeft),
    topRight: resolve(baseRadius.topRight),
    bottomLeft: resolve(baseRadius.bottomLeft),
    bottomRight: resolve(baseRadius.bottomRight),
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
  final bool respectSurfaceBlurPreference;
  final bool respectSurfaceCornerPreference;

  const ThemedSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.sigma,
    this.color,
    this.gradient,
    this.border,
    this.blur = true,
    this.respectSurfaceBlurPreference = true,
    this.respectSurfaceCornerPreference = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        blurEnabledNotifier,
        surfaceBlurEnabledNotifier,
        surfaceCornerModeNotifier,
        surfaceCornerRadiusNotifier,
      ]),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tokens = untisThemeTokensOf(context);
        final baseRadius =
            borderRadius ?? BorderRadius.circular(tokens.surfaceRadius);
        final radius = respectSurfaceCornerPreference
            ? _resolvedSurfaceBorderRadius(baseRadius)
            : baseRadius;
        final blurActive =
            blur &&
            tokens.supportsBlur &&
            blurEnabledNotifier.value &&
            (!respectSurfaceBlurPreference || surfaceBlurEnabledNotifier.value);
        final translucent =
            color ??
            cs.surfaceContainerLow.withValues(alpha: tokens.surfaceOpacity);
        final opaque = Color.alphaBlend(translucent, cs.surface);
        final effectiveColor = blurActive ? translucent : opaque;
        final effectiveBorder =
            border ??
            Border.all(
              color: tokens.id == AppThemeId.manga
                  ? cs.outline
                  : (tokens.glassHighlights
                        ? Colors.white.withValues(
                            alpha: Theme.of(context).brightness == Brightness.dark
                                ? 0.34
                                : 0.56,
                          )
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
                                Colors.white.withValues(alpha: 0.60),
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
                  color: !tokens.glowEffectsEnabled &&
                          tokens.id == AppThemeId.cyber
                      ? cs.shadow.withValues(alpha: 0.12)
                      : tokens.shadowColor,
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
    respectSurfaceBlurPreference: false,
    respectSurfaceCornerPreference: false,
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

Duration _pageMotionDuration(int transitionType) {
  return switch (transitionType.clamp(0, 7)) {
    0 => const Duration(milliseconds: 430),
    1 => const Duration(milliseconds: 260),
    2 => const Duration(milliseconds: 360),
    3 => const Duration(milliseconds: 380),
    4 => const Duration(milliseconds: 400),
    5 => const Duration(milliseconds: 340),
    6 => const Duration(milliseconds: 380),
    7 => const Duration(milliseconds: 460),
    _ => const Duration(milliseconds: 360),
  };
}

Curve _pageMotionCurve(int transitionType) {
  return switch (transitionType.clamp(0, 7)) {
    0 => const Cubic(0.34, 1.56, 0.64, 1.0),
    1 => Curves.easeOutCubic,
    2 => const Cubic(0.2, 0.0, 0.0, 1.0),
    3 => const Cubic(0.2, 0.0, 0.0, 1.0),
    4 => const Cubic(0.2, 0.0, 0.0, 1.0),
    5 => const Cubic(0.22, 1.0, 0.36, 1.0),
    6 => const Cubic(0.16, 1.0, 0.3, 1.0),
    7 => const Cubic(0.16, 1.0, 0.3, 1.0),
    _ => Curves.easeOutCubic,
  };
}

Offset _pageMotionOffset(int transitionType, {double direction = 1}) {
  return switch (transitionType.clamp(0, 7)) {
    0 => const Offset(0, 0.055),
    1 => const Offset(0, 0.012),
    2 => Offset(0.12 * direction, 0),
    3 => Offset.zero,
    4 => const Offset(0, 0.025),
    5 => const Offset(0, 0.08),
    6 => Offset(0.055 * direction, 0.018),
    7 => const Offset(0, 0.10),
    _ => Offset.zero,
  };
}

double _pageMotionScale(int transitionType) {
  return switch (transitionType.clamp(0, 7)) {
    0 => 0.94,
    1 => 0.995,
    2 => 0.985,
    3 => 0.88,
    4 => 0.975,
    5 => 0.99,
    6 => 0.985,
    7 => 0.955,
    _ => 1.0,
  };
}

double _pageMotionBlur(int transitionType) =>
    transitionType.clamp(0, 7) == 4 ? 14.0 : 0.0;

Route<T> _buildBouncyRoute<T>(
  Widget page, {
  Duration? duration,
  Duration? reverseDuration,
  int? transitionType,
}) {
  final selectedTransition =
      (transitionType ?? pageTransitionNotifier.value).clamp(0, 7);
  final forwardDuration = duration ?? _pageMotionDuration(selectedTransition);
  final backwardDuration =
      reverseDuration ??
      Duration(
        milliseconds: (forwardDuration.inMilliseconds * 0.82).round(),
      );

  return PageRouteBuilder<T>(
    transitionDuration: forwardDuration,
    reverseTransitionDuration: backwardDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        return child;
      }

      final curve = _pageMotionCurve(selectedTransition);
      final motion = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: Curves.easeInCubic,
      );
      final opacity = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.82, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeInCubic,
      );
      final offset = _pageMotionOffset(selectedTransition);
      final scale = _pageMotionScale(selectedTransition);
      final blur = _pageMotionBlur(selectedTransition);

      Widget result = child;

      if (blur > 0) {
        result = AnimatedBuilder(
          animation: motion,
          child: result,
          builder: (context, child) {
            final sigma = (1 - motion.value.clamp(0.0, 1.0)) * blur;
            return ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            );
          },
        );
      }

      if (scale != 1) {
        result = ScaleTransition(
          scale: Tween<double>(begin: scale, end: 1).animate(motion),
          alignment: Alignment.center,
          child: result,
        );
      }

      if (offset != Offset.zero) {
        result = SlideTransition(
          position: Tween<Offset>(begin: offset, end: Offset.zero).animate(
            motion,
          ),
          child: result,
        );
      }

      return FadeTransition(opacity: opacity, child: result);
    },
  );
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

MenuStyle _untisMenuStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return MenuStyle(
    backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
    surfaceTintColor: WidgetStatePropertyAll(cs.surfaceTint),
    elevation: const WidgetStatePropertyAll(8),
    shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.22)),
    minimumSize: const WidgetStatePropertyAll(Size(224, 0)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_resolvedSurfaceCornerRadius(22)),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
    ),
  );
}

Widget _untisDropdownMenu({
  required BuildContext context,
  required List<Widget> menuChildren,
  required MenuAnchorChildBuilder builder,
  MenuController? controller,
  Offset? alignmentOffset = Offset.zero,
  bool consumeOutsideTap = false,
  bool useRootOverlay = false,
  Widget? child,
}) {
  return MenuAnchor(
    controller: controller,
    style: _untisMenuStyle(context),
    alignmentOffset: alignmentOffset,
    consumeOutsideTap: consumeOutsideTap,
    useRootOverlay: useRootOverlay,
    animated: !MediaQuery.of(context).disableAnimations,
    menuChildren: menuChildren,
    builder: builder,
    child: child,
  );
}

/// A Material 3 anchored menu styled like the app's filled form controls.
///
/// Keeping the trigger in the sheet lets the menu open next to the field rather
/// than presenting another bottom sheet on top of the current one.
Widget _m3SelectionMenu({
  required BuildContext context,
  required String value,
  required List<String> entries,
  required ValueChanged<String> onSelected,
  required IconData icon,
}) {
  final cs = Theme.of(context).colorScheme;
  return _untisDropdownMenu(
    context: context,
    menuChildren: [
      for (final entry in entries)
        MenuItemButton(
          onPressed: () => onSelected(entry),
          leadingIcon: Icon(icon),
          trailingIcon: entry == value
              ? Icon(Icons.check_rounded, color: cs.primary)
              : null,
          child: Text(entry),
        ),
    ],
    builder: (context, controller, child) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.open,
        borderRadius: BorderRadius.circular(20),
        child: InputDecorator(
          isEmpty: value.isEmpty,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
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
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
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
                        ),
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

/// A non-scrolling choice grid whose cards keep a predictable height on every
/// form factor. Using an aspect ratio here made the theme cards grow vertically
/// with the width of a tablet.
class ResponsiveFixedGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double mainAxisExtent;
  final double maxWidth;
  final double spacing;

  const ResponsiveFixedGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.mainAxisExtent,
    this.maxWidth = 960,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final requestedColumns =
                screenWidth >= 1000 && constraints.maxWidth >= 840
                ? 4
                : screenWidth >= 720 && constraints.maxWidth >= 360
                ? 3
                : 2;
            final columns = math.min(requestedColumns, math.max(1, itemCount));
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: itemBuilder,
            );
          },
        ),
      ),
    );
  }
}

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
          AnimatedBuilder(
            animation: Listenable.merge([
              surfaceCornerModeNotifier,
              surfaceCornerRadiusNotifier,
            ]),
            builder: (context, _) {
              final radius = _resolvedSurfaceBorderRadius(
                BorderRadius.circular(tokens.surfaceRadius),
              );
              return _glassContainer(
                context: context,
                borderRadius: radius,
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
                    shape: RoundedRectangleBorder(borderRadius: radius),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _settingsTooltip({
  required String? message,
  required Widget child,
  bool showInline = false,
}) {
  final text = message?.trim() ?? '';
  if (text.isEmpty || showInline) return child;
  return Tooltip(
    message: text,
    triggerMode: TooltipTriggerMode.longPress,
    showDuration: const Duration(seconds: 4),
    preferBelow: false,
    verticalOffset: 28,
    child: child,
  );
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
  final bool showSubtitle;

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
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final effectiveLeading =
        leading ??
        (icon != null
            ? Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor ??
                      (destructive
                          ? cs.errorContainer
                          : cs.primary.withValues(alpha: 0.14)),
                  borderRadius: BorderRadius.circular(
                    _expressiveRadius(
                      context,
                      tokens.controlRadius,
                      expressiveRadius: 15,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color:
                      iconColor ??
                      (destructive ? cs.onErrorContainer : cs.primary),
                ),
              )
            : null);

    final tile = Semantics(
      button: onTap != null,
      label: hasSubtitle ? '$title. $subtitle' : title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          _expressiveRadius(context, 16, expressiveRadius: 20),
        ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: destructive ? cs.error : cs.onSurface,
                      ),
                    ),
                    if (showSubtitle && hasSubtitle) ...[
                      const SizedBox(height: 3),
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
      ),
    );

    return _settingsTooltip(
      message: subtitle,
      showInline: showSubtitle,
      child: tile,
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
  final bool showSubtitle;

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
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final effectiveLeading =
        leading ??
        (icon != null
            ? Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor ?? cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(
                    _expressiveRadius(
                      context,
                      tokens.controlRadius,
                      expressiveRadius: 15,
                    ),
                  ),
                ),
                child: Icon(icon, size: 21, color: iconColor ?? cs.primary),
              )
            : null);

    final tile = Semantics(
      toggled: value,
      label: hasSubtitle ? '$title. $subtitle' : title,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(
          _expressiveRadius(context, 16, expressiveRadius: 20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    if (showSubtitle && hasSubtitle) ...[
                      const SizedBox(height: 3),
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
              Switch(
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
      ),
    );

    return _settingsTooltip(
      message: subtitle,
      showInline: showSubtitle,
      child: tile,
    );
  }
}
