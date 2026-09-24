part of '../main.dart';

const Curve _kSmoothBounce = Curves.easeOutCubic;
const Curve _kSoftBounce = Curves.easeOutQuad;

const AnimationStyle _kBottomSheetAnimationStyle = AnimationStyle();

<<<<<<< HEAD
class _AiImportFile {
  const _AiImportFile({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

Future<_AiImportFile?> _pickAiImportFile(
  String source, {
  required bool allowPdf,
}) async {
  if (source == 'camera' || source == 'gallery') {
    final picked = await ImagePicker().pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked == null) return null;
    return _AiImportFile(
      bytes: await picked.readAsBytes(),
      mimeType: picked.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg',
    );
  }

  final picked = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: allowPdf
        ? const ['pdf', 'png', 'jpg', 'jpeg']
        : const ['png', 'jpg', 'jpeg'],
  );
  if (picked == null) return null;
  final extension = picked.name.split('.').last.toLowerCase();
  return _AiImportFile(
    bytes: await picked.readAsBytes(),
    mimeType: extension == 'pdf'
        ? 'application/pdf'
        : extension == 'png'
        ? 'image/png'
        : 'image/jpeg',
  );
}

class SettingsPageShell extends StatelessWidget {
  const SettingsPageShell({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _settingsHeaderAppBar(context, title),
    body: _AnimatedBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.paddingOf(context).bottom + 120,
        ),
        children: children,
      ),
    ),
  );
}

class FeatureSummaryCard extends StatelessWidget {
  const FeatureSummaryCard({
    required this.icon,
    required this.title,
    this.secondary,
    this.trailing,
    this.iconShadow = true,
    super.key,
  });

  final IconData icon;
  final Widget title;
  final Widget? secondary;
  final Widget? trailing;
  final bool iconShadow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: iconShadow
                      ? _glowShadows(context, [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ])
                      : null,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (secondary != null) ...[
                      const SizedBox(height: 4),
                      secondary!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class UntisSheetScaffold extends StatelessWidget {
  const UntisSheetScaffold({
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(28),
    this.scrollable = true,
    this.showHandle = true,
    this.keyboardSafe = true,
    this.handleWidth = 40,
    this.handleSpacing = 24,
    super.key,
  });

  final Widget child;
  final Widget? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final bool showHandle;
  final bool keyboardSafe;
  final double handleWidth;
  final double handleSpacing;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHandle) ...[
          _sheetDragHandle(context, width: handleWidth),
          SizedBox(height: handleSpacing),
        ],
        if (title != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title!),
              ?trailing,
            ],
          ),
          const SizedBox(height: 24),
        ],
        child,
      ],
    );

    Widget body = scrollable
        ? SingleChildScrollView(padding: padding, child: content)
        : Padding(padding: padding, child: content);
    if (keyboardSafe) {
      body = Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: body,
      );
    }
    return _sheetSurface(context: context, child: body);
  }
}

@immutable
class LessonCardVisuals {
  const LessonCardVisuals({
    required this.radius,
    required this.cardStyle,
    required this.blurEnabled,
    required this.blurSigma,
    required this.cardOpacity,
    required this.accentStyle,
    required this.showPattern,
    required this.fillColor,
    required this.gradient,
    required this.border,
    required this.textColor,
    required this.secondaryTextColor,
    required this.shadows,
    required this.accentWidth,
  });

  final double radius;
  final int cardStyle;
  final bool blurEnabled;
  final double blurSigma;
  final double cardOpacity;
  final int accentStyle;
  final bool showPattern;
  final Color fillColor;
  final Gradient? gradient;
  final Border? border;
  final Color textColor;
  final Color secondaryTextColor;
  final List<BoxShadow>? shadows;
  final double accentWidth;

  BorderRadius get borderRadius => BorderRadius.circular(radius);
}

abstract final class LessonCardVisualsResolver {
  static LessonCardVisuals resolve({
    required BuildContext context,
    required UntisThemeTokens tokens,
    required bool isDark,
    required bool isCancelled,
    required bool isNow,
    required Color foregroundColor,
    required Color backgroundColor,
    bool isTeacherMissing = false,
    bool usePattern = true,
    double? borderRadius,
    double accentWidth = 3.5,
  }) {
    final cs = Theme.of(context).colorScheme;
    final themeOwnsStyle = tokens.id != AppThemeId.defaultTheme;
    final radius = themeOwnsStyle
        ? tokens.surfaceRadius
        : (borderRadius ?? lessonBorderRadiusNotifier.value);
    final cardStyle = themeOwnsStyle ? 3 : lessonCardStyleNotifier.value;
    final blurEnabled =
        tokens.supportsBlur &&
        blurEnabledNotifier.value &&
        (themeOwnsStyle || lessonBlurEnabledNotifier.value || cardStyle == 1);
    final blurSigma = themeOwnsStyle
        ? tokens.blurSigma
        : lessonBlurAmountNotifier.value;
    final cardOpacity = themeOwnsStyle
        ? tokens.lessonSurfaceOpacity
        : lessonCardOpacityNotifier.value;
    final accentStyle = themeOwnsStyle ? 0 : lessonAccentStyleNotifier.value;
    final showPattern =
        (isCancelled || isTeacherMissing) &&
        usePattern &&
        lessonCancelledPatternNotifier.value;

    List<BoxShadow>? shadows;
    if (tokens.glowEffectsEnabled && isNow) {
      shadows = [
        BoxShadow(
          color: foregroundColor.withValues(alpha: 0.38),
          blurRadius: 14,
          spreadRadius: 1.5,
          offset: const Offset(0, 3),
        ),
      ];
    }

    Color fillColor;
    Gradient? gradient;
    Border? border;
    Color textColor = isCancelled
        ? foregroundColor.withValues(alpha: 0.6)
        : foregroundColor;
    Color secondaryTextColor = isCancelled
        ? foregroundColor.withValues(alpha: 0.48)
        : foregroundColor.withValues(alpha: 0.75);

    switch (cardStyle) {
      case 1:
        fillColor = isCancelled
            ? backgroundColor.withValues(
                alpha: (0.28 * cardOpacity).clamp(0.0, 1.0),
              )
            : cs.surfaceContainerLowest.withValues(
                alpha: (0.52 * cardOpacity).clamp(0.0, 1.0),
              );
        border = Border.all(
          color: isCancelled
              ? foregroundColor.withValues(alpha: 0.40)
              : foregroundColor.withValues(alpha: isDark ? 0.42 : 0.28),
          width: 1.2,
        );
        break;
      case 2:
        fillColor = Colors.transparent;
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCancelled
              ? [
                  foregroundColor.withValues(
                    alpha: (0.25 * cardOpacity).clamp(0.0, 1.0),
                  ),
                  backgroundColor.withValues(
                    alpha: (0.45 * cardOpacity).clamp(0.0, 1.0),
                  ),
                ]
              : [
                  foregroundColor.withValues(
                    alpha: ((isDark ? 0.35 : 0.25) * cardOpacity).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
                  backgroundColor.withValues(
                    alpha: cardOpacity.clamp(0.0, 1.0),
                  ),
                ],
        );
        border = Border.all(
          color: foregroundColor.withValues(alpha: isDark ? 0.30 : 0.18),
          width: 1.0,
        );
        break;
      case 3:
        fillColor = isCancelled
            ? cs.surfaceContainerLowest.withValues(
                alpha: (0.35 * cardOpacity).clamp(0.0, 1.0),
              )
            : cs.surfaceContainerLow.withValues(
                alpha: (0.60 * cardOpacity).clamp(0.0, 1.0),
              );
        border = Border.all(
          color: isCancelled
              ? foregroundColor.withValues(alpha: 0.50)
              : foregroundColor.withValues(alpha: isDark ? 0.85 : 0.70),
          width: 1.8,
        );
        break;
      case 4:
        fillColor = isCancelled
            ? foregroundColor.withValues(alpha: 0.45)
            : foregroundColor.withValues(alpha: cardOpacity.clamp(0.6, 1.0));
        final solidText = fillColor.computeLuminance() > 0.45
            ? Colors.black87
            : Colors.white;
        textColor = solidText;
        secondaryTextColor = solidText.withValues(alpha: 0.78);
        break;
      case 0:
      default:
        fillColor = isCancelled
            ? backgroundColor.withValues(
                alpha: (0.40 * cardOpacity).clamp(0.0, 1.0),
              )
            : backgroundColor.withValues(alpha: cardOpacity.clamp(0.0, 1.0));
        border = Border.all(
          color: foregroundColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.0,
        );
        break;
    }

    if (tokens.id == AppThemeId.manga) {
      fillColor = cs.surfaceContainerLow;
      gradient = null;
      border = Border.all(color: cs.outline, width: tokens.borderWidth);
      textColor = cs.onSurface;
      secondaryTextColor = cs.onSurfaceVariant;
      shadows = [
        BoxShadow(
          color: tokens.shadowColor,
          offset: tokens.shadowOffset,
          blurRadius: 0,
        ),
      ];
    } else if (tokens.id == AppThemeId.cyber) {
      border = Border.all(
        color: isCancelled ? foregroundColor : cs.primary,
        width: tokens.borderWidth,
      );
    }

    return LessonCardVisuals(
      radius: radius,
      cardStyle: cardStyle,
      blurEnabled: blurEnabled,
      blurSigma: blurSigma,
      cardOpacity: cardOpacity,
      accentStyle: accentStyle,
      showPattern: showPattern,
      fillColor: fillColor,
      gradient: gradient,
      border: border,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      shadows: shadows,
      accentWidth: accentStyle == 0
          ? accentWidth
          : (accentStyle == 1 ? 1.8 : 0.0),
    );
  }
=======
/// Minimum fling velocity (in screen widths per second) to trigger a pop
/// when the drag ends before the halfway point.
const double _kMinFlingVelocity = 1.0;

/// Animation duration for the page settling after a completed or cancelled
/// swipe-back gesture.
const Duration _kDroppedSwipePageAnimationDuration = Duration(milliseconds: 350);

/// Curve used for the page settling animation after a swipe-back gesture.
const Curve _kSwipeBackAnimationCurve = Curves.fastEaseInToSlowEaseOut;

/// Computes the swipe-back gesture drag area width proportional to screen size.
/// ~5% of the shortest screen dimension, clamped to [20, 48] logical pixels.
/// Matches native iOS behavior where the edge zone scales with device size.
double _kSwipeBackGestureWidth(BuildContext context) {
  final double shortestSide = MediaQuery.sizeOf(context).shortestSide;
  return (shortestSide * 0.05).clamp(20.0, 48.0);
>>>>>>> pr-149
}

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

/// All app modal routes use the same backdrop treatment. Material's stock
/// routes can only draw a colored scrim, so the app-specific routes add a
/// backdrop filter when the active theme supports the user's Blur preference.
bool _usesModalBackdropBlur(BuildContext context) {
  final tokens = untisThemeTokensOf(context);
  return tokens.supportsBlur && blurEnabledNotifier.value;
}

double _resolvedBlurSigma(double sigma) {
  final strength = blurStrengthNotifier.value.clamp(0.25, 2.0).toDouble();
  return sigma * strength;
}

Widget _blurredModalBarrier({
  required Animation<double> animation,
  required double sigma,
  required Widget child,
}) => AnimatedBuilder(
  animation: animation,
  child: child,
  builder: (context, child) => BackdropFilter(
    filter: ImageFilter.blur(
      sigmaX: sigma * animation.value,
      sigmaY: sigma * animation.value,
    ),
    child: child!,
  ),
);

class _UntisDialogRoute<T> extends DialogRoute<T> {
  final bool useBackdropBlur;
  final double blurSigma;

  _UntisDialogRoute({
    required super.context,
    required super.builder,
    required this.useBackdropBlur,
    required this.blurSigma,
    super.themes,
    super.barrierColor,
    super.barrierDismissible,
    super.barrierLabel,
    super.useSafeArea,
    super.settings,
    super.requestFocus,
    super.anchorPoint,
    super.traversalEdgeBehavior,
    super.fullscreenDialog,
    super.animationStyle,
  });

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    if (!useBackdropBlur) return barrier;
    return _blurredModalBarrier(
      animation: animation!,
      sigma: blurSigma,
      child: barrier,
    );
  }
}

class _UntisModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  final bool useBackdropBlur;
  final double blurSigma;

  _UntisModalBottomSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    required this.useBackdropBlur,
    required this.blurSigma,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.backgroundColor,
    super.elevation,
    super.shape,
    super.clipBehavior,
    super.constraints,
    super.modalBarrierColor,
    super.isDismissible,
    super.enableDrag,
    super.showDragHandle,
    super.scrollControlDisabledMaxHeightRatio,
    super.settings,
    super.requestFocus,
    super.transitionAnimationController,
    super.anchorPoint,
    super.useSafeArea,
    super.sheetAnimationStyle,
  });

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    if (!useBackdropBlur) return barrier;
    return _blurredModalBarrier(
      animation: animation!,
      sigma: blurSigma,
      child: barrier,
    );
  }
}

Future<T?> showUntisDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool fullscreenDialog = false,
  bool? requestFocus,
  AnimationStyle? animationStyle,
}) {
  assert(debugCheckHasMaterialLocalizations(context));
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final tokens = untisThemeTokensOf(context);
  final useBackdropBlur = _usesModalBackdropBlur(context);
  final resolvedBarrierColor = useBackdropBlur
      ? Colors.transparent
      : barrierColor ??
            DialogTheme.of(context).barrierColor ??
            Theme.of(context).dialogTheme.barrierColor ??
            Colors.black54;
  return navigator.push(
    _UntisDialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierColor: resolvedBarrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      settings: routeSettings,
      requestFocus: requestFocus,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior:
          traversalEdgeBehavior ?? TraversalEdgeBehavior.closedLoop,
      fullscreenDialog: fullscreenDialog,
      animationStyle: animationStyle,
      useBackdropBlur: useBackdropBlur,
      blurSigma: _resolvedBlurSigma(tokens.blurSigma),
    ),
  );
}

extension UntisSnackBarContext on BuildContext {
  void showUntisSnackBar(
    String message, {
    SnackBarBehavior? behavior,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: behavior,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}

Future<T> runWithUntisBlockingLoader<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var loadingOpen = true;
  final dialogFuture = showUntisDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  // Allow the pushed route to become active before an immediately-completing
  // operation can reach the cleanup path.
  await Future<void>.delayed(Duration.zero);
  try {
    return await action();
  } finally {
    if (loadingOpen && navigator.mounted) {
      loadingOpen = false;
      navigator.pop();
    }
    await dialogFuture;
  }
}

Future<T?> showUntisModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9 / 16,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final localizations = MaterialLocalizations.of(context);
  final tokens = untisThemeTokensOf(context);
  final useBackdropBlur = _usesModalBackdropBlur(context);
  return navigator.push(
    _UntisModalBottomSheetRoute<T>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: isScrollControlled,
      scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
      barrierLabel: barrierLabel ?? localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(
        localizations.bottomSheetLabel,
      ),
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      modalBarrierColor: useBackdropBlur
          ? Colors.transparent
          : barrierColor ??
                Theme.of(context).bottomSheetTheme.modalBarrierColor,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      settings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      anchorPoint: anchorPoint,
      useSafeArea: useSafeArea,
      sheetAnimationStyle: sheetAnimationStyle,
      requestFocus: requestFocus,
      useBackdropBlur: useBackdropBlur,
      blurSigma: _resolvedBlurSigma(tokens.blurSigma),
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
    return showUntisModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      builder: builder,
    );
  }
  return showUntisDialog<T>(
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
  bool respectBlurStrength = true,
}) {
  return AnimatedBuilder(
    animation: Listenable.merge([blurEnabledNotifier, blurStrengthNotifier]),
    builder: (context, _) {
      if (!enabled || !blurEnabledNotifier.value) return child;
      final effectiveSigma = respectBlurStrength
          ? _resolvedBlurSigma(sigma)
          : sigma;
      return ClipRRect(
        borderRadius: borderRadius is BorderRadius
            ? borderRadius
            : BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveSigma,
            sigmaY: effectiveSigma,
          ),
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

BorderRadius _settingsSegmentRadius(
  BuildContext context, {
  required bool isFirst,
  required bool isLast,
}) {
  final tokens = untisThemeTokensOf(context);
  final outer = _resolvedSurfaceCornerRadius(tokens.surfaceRadius);
  final inner = math.min(outer, 8.0);
  final outerRadius = Radius.circular(outer);
  final innerRadius = Radius.circular(inner);

  return BorderRadius.only(
    topLeft: isFirst ? outerRadius : innerRadius,
    topRight: isFirst ? outerRadius : innerRadius,
    bottomLeft: isLast ? outerRadius : innerRadius,
    bottomRight: isLast ? outerRadius : innerRadius,
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
  final bool showShadow;

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
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        blurEnabledNotifier,
        blurStrengthNotifier,
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
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
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
                    sigmaX: _resolvedBlurSigma(sigma ?? tokens.blurSigma),
                    sigmaY: _resolvedBlurSigma(sigma ?? tokens.blurSigma),
                  ),
                  child: surface,
                )
              : surface,
        );

        return RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color:
                            !tokens.glowEffectsEnabled &&
                                tokens.id == AppThemeId.cyber
                            ? cs.shadow.withValues(alpha: 0.12)
                            : tokens.shadowColor,
                        offset: tokens.shadowOffset,
                        blurRadius: tokens.hardShadow ? 0 : 20,
                      ),
                    ]
                  : null,
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
  return switch (transitionType.clamp(0, 8)) {
    0 => const Duration(milliseconds: 430),
    1 => const Duration(milliseconds: 260),
    2 => const Duration(milliseconds: 360),
    3 => const Duration(milliseconds: 380),
    4 => const Duration(milliseconds: 400),
    5 => const Duration(milliseconds: 340),
    6 => const Duration(milliseconds: 380),
    7 => const Duration(milliseconds: 460),
    8 => Duration.zero,
    _ => const Duration(milliseconds: 360),
  };
}

Curve _pageMotionCurve(int transitionType) {
  return switch (transitionType.clamp(0, 8)) {
    0 => const Cubic(0.34, 1.56, 0.64, 1.0),
    1 => Curves.easeOutCubic,
    2 => const Cubic(0.2, 0.0, 0.0, 1.0),
    3 => const Cubic(0.2, 0.0, 0.0, 1.0),
    4 => const Cubic(0.2, 0.0, 0.0, 1.0),
    5 => const Cubic(0.22, 1.0, 0.36, 1.0),
    6 => const Cubic(0.16, 1.0, 0.3, 1.0),
    7 => const Cubic(0.16, 1.0, 0.3, 1.0),
    8 => Curves.linear,
    _ => Curves.easeOutCubic,
  };
}

Offset _pageMotionOffset(int transitionType, {double direction = 1}) {
  return switch (transitionType.clamp(0, 8)) {
    0 => const Offset(0, 0.055),
    1 => const Offset(0, 0.012),
    2 => Offset(0.12 * direction, 0),
    3 => Offset.zero,
    4 => const Offset(0, 0.025),
    5 => const Offset(0, 0.08),
    6 => Offset(0.055 * direction, 0.018),
    7 => const Offset(0, 0.10),
    8 => Offset.zero,
    _ => Offset.zero,
  };
}

double _pageMotionScale(int transitionType) {
  return switch (transitionType.clamp(0, 8)) {
    0 => 0.94,
    1 => 0.995,
    2 => 0.985,
    3 => 0.88,
    4 => 0.975,
    5 => 0.99,
    6 => 0.985,
    7 => 0.955,
    8 => 1.0,
    _ => 1.0,
  };
}

double _pageMotionBlur(int transitionType) =>
    transitionType.clamp(0, 8) == 4 ? 14.0 : 0.0;

/// Prepares the GPU blur pipeline while the app is idle. Without this tiny
/// composited layer, Android may compile the ImageFiltered pipeline during the
/// first Focus Blur route transition after a cold start.
class _FocusBlurWarmup extends StatelessWidget {
  const _FocusBlurWarmup();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pageTransitionNotifier,
      builder: (context, transitionType, _) {
        if (_pageMotionBlur(transitionType) == 0) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: const ValueKey('focus-blur-warmup'),
              child: ClipRect(
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: const ColoredBox(color: Color(0x01000000)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Route<T> _buildBouncyRoute<T>(
  Widget page, {
  Duration? duration,
  Duration? reverseDuration,
  int? transitionType,
}) {
  final selectedTransition = (transitionType ?? pageTransitionNotifier.value)
      .clamp(0, 8);

  // Use Flutter's platform route unchanged for "Default". On Android,
  // MaterialPageRoute uses the framework's predictive-back transition.
  if (selectedTransition == 8) {
    return MaterialPageRoute<T>(builder: (context) => page);
  }

  final forwardDuration = duration ?? _pageMotionDuration(selectedTransition);
  final backwardDuration =
      reverseDuration ??
      Duration(milliseconds: (forwardDuration.inMilliseconds * 0.82).round());

  final transitionsBuilder = (BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
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
  };

  // Use SwipeBackPageRoute when the gesture is enabled to support
  // native-style edge-swipe back on iOS/Android.
  if (swipeBackGestureNotifier.value) {
    return SwipeBackPageRoute<T>(
      transitionDuration: forwardDuration,
      reverseTransitionDuration: backwardDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: transitionsBuilder,
    );
  }

  return PageRouteBuilder<T>(
    transitionDuration: forwardDuration,
    reverseTransitionDuration: backwardDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
<<<<<<< HEAD
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
          position: Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).animate(motion),
          child: result,
        );
      }

      return FadeTransition(opacity: opacity, child: result);
    },
=======
    transitionsBuilder: transitionsBuilder,
>>>>>>> pr-149
  );
}

/// A controller for an iOS-style back gesture that drives the route's
/// animation controller based on drag input. Works in logical coordinates
/// where 0.0 = page dismissed and 1.0 = page fully on screen.
class _SwipeBackGestureController<T> {
  _SwipeBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
    required this.route,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final PageRoute<T> route;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = _kSwipeBackAnimationCurve;
    final bool isCurrent = getIsCurrent();

    late bool animateForward;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: _kDroppedSwipePageAnimationDuration,
        curve: animationCurve,
      ).whenCompleteOrCancel(() {
        if (navigator.mounted) navigator.didStopUserGesture();
      });
    } else {
      if (isCurrent) {
        navigator.pop();
      }

      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: _kDroppedSwipePageAnimationDuration,
          curve: animationCurve,
        ).whenCompleteOrCancel(() {
          if (navigator.mounted) navigator.didStopUserGesture();
        });
      } else {
        navigator.didStopUserGesture();
      }
    }
  }
}

/// A gesture detector widget that catches left-edge horizontal drags and
/// drives a [_SwipeBackGestureController] to implement the swipe-back
/// gesture. Mirrors Flutter's internal `_CupertinoBackGestureDetector` but
/// works with any custom PageRoute transition.
class _SwipeBackGestureDetector<T> extends StatefulWidget {
  const _SwipeBackGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<_SwipeBackGestureController<T>> onStartPopGesture;

  @override
  State<_SwipeBackGestureDetector<T>> createState() =>
      _SwipeBackGestureDetectorState<T>();
}

class _SwipeBackGestureDetectorState<T>
    extends State<_SwipeBackGestureDetector<T>> {
  _SwipeBackGestureController<T>? _backGestureController;

  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();

    if (_backGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_backGestureController?.navigator.mounted ?? false) {
          _backGestureController?.navigator.didStopUserGesture();
        }
        _backGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragEnd(
      _convertToLogical(details.velocity.pixelsPerSecond.dx / context.size!.width),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    final ui.TextDirection dir = Directionality.of(context);
    return dir == ui.TextDirection.rtl ? -value : value;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final ui.TextDirection dir = Directionality.of(context);
    final double dragAreaWidth = dir == ui.TextDirection.rtl
        ? MediaQuery.paddingOf(context).right
        : MediaQuery.paddingOf(context).left;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: math.max(dragAreaWidth, _kSwipeBackGestureWidth(context)),
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// A PageRoute subclass that supports the iOS-style edge-swipe back gesture
/// while preserving the app's custom page transitions.
class SwipeBackPageRoute<T> extends PageRoute<T> {
  SwipeBackPageRoute({
    required this.pageBuilder,
    required this.transitionsBuilder,
    super.settings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
  });

  final RoutePageBuilder pageBuilder;
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return pageBuilder(context, animation, secondaryAnimation);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool swipeInProgress =
        navigator?.userGestureInProgress == true && isCurrent;

    // During the swipe gesture, use a simple linear slide so the page
    // follows the finger 1:1. Otherwise use the app's custom transition.
    if (swipeInProgress) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.linear,
        )),
        child: child,
      );
    }

    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }

  @override
  bool get popGestureEnabled {
    if (fullscreenDialog) return false;
    if (isFirst) return false;
    if (willHandlePopInternally) return false;
    if (popDisposition == RoutePopDisposition.doNotPop) return false;
    if (animation?.isCompleted != true) return false;
    // Only enable the gesture when the feature flag is on.
    return swipeBackGestureNotifier.value;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PageRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is PageRoute;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
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
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.48)),
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

Widget _sheetDragHandle(BuildContext context, {double width = 40}) {
  final cs = Theme.of(context).colorScheme;
  return Center(
    child: Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

Widget _sheetActionIcon(
  BuildContext context,
  IconData icon, {
  Color? color,
  Color? backgroundColor,
}) {
  final cs = Theme.of(context).colorScheme;
  final foreground = color ?? cs.primary;
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: backgroundColor ?? foreground.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 20, color: foreground),
  );
}

Future<T?> _showUnifiedSheet<T>({
  required BuildContext context,
  Widget? child,
  WidgetBuilder? builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  bool showHandle = true,
  EdgeInsetsGeometry? outerPadding,
}) {
  assert(
    (child == null) != (builder == null),
    'Provide exactly one of child or builder.',
  );
  return showUntisModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    elevation: 0,
    sheetAnimationStyle: _kBottomSheetAnimationStyle,
    builder: (ctx) {
      Widget content = builder?.call(ctx) ?? child!;
      if (outerPadding != null) {
        content = Padding(padding: outerPadding, child: content);
      }
      if (showHandle) {
        content = Stack(
          children: [
            Padding(padding: const EdgeInsets.only(top: 28), child: content),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(child: _sheetDragHandle(ctx)),
            ),
          ],
        );
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
  return _showUnifiedSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;

      Widget optionList = ListView.separated(
        shrinkWrap: true,
        physics: fitContentHeight
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final opt = options[index];
          final foreground = opt.destructive
              ? cs.error
              : (opt.selected ? cs.primary : cs.onSurface);
          final iconBackground = opt.destructive
              ? cs.errorContainer.withValues(alpha: 0.78)
              : opt.selected
              ? cs.primaryContainer.withValues(alpha: 0.88)
              : cs.surfaceContainerHighest.withValues(alpha: 0.72);
          final rowBackground = opt.selected
              ? cs.primaryContainer.withValues(alpha: 0.42)
              : cs.surfaceContainerLow.withValues(alpha: 0.72);

          final leading =
              opt.leading ??
              (opt.icon == null
                  ? null
                  : _sheetActionIcon(
                      ctx,
                      opt.icon!,
                      color: foreground,
                      backgroundColor: iconBackground,
                    ));

          return Material(
            color: rowBackground,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pop(ctx, opt.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading,
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: opt.selected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: foreground,
                            ),
                          ),
                          if (opt.subtitle != null &&
                              opt.subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle!,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: opt.destructive
                                    ? cs.error.withValues(alpha: 0.78)
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (opt.selected) ...[
                      const SizedBox(width: 10),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: cs.onPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (!fitContentHeight) {
        optionList = Flexible(child: optionList);
      }

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              optionList,
            ],
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
              padding: const EdgeInsets.only(left: 12, bottom: 7, top: 4),
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < validChildren.length; i++) ...[
                    ThemedSurface(
                      borderRadius: _settingsSegmentRadius(
                        context,
                        isFirst: i == 0,
                        isLast: i == validChildren.length - 1,
                      ),
                      color: cs.surfaceContainerLow.withValues(alpha: 0.78),
                      border: Border.all(
                        color: tokens.id == AppThemeId.manga
                            ? cs.outline
                            : cs.outlineVariant.withValues(alpha: 0.30),
                        width: tokens.borderWidth,
                      ),
                      respectSurfaceCornerPreference: false,
                      showShadow: false,
                      child: Padding(
                        padding: padding ?? EdgeInsets.zero,
                        child: Material(
                          type: MaterialType.transparency,
                          child: validChildren[i],
                        ),
                      ),
                    ),
                    if (i < validChildren.length - 1) const SizedBox(height: 4),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

PreferredSizeWidget _mainTabHeaderAppBar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
  Widget? leading,
  PreferredSizeWidget? bottom,
}) {
  return RoundedBlurAppBar(
    height: 64,
    centerTitle: true,
    leading: leading,
    actions: actions,
    bottom: bottom,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: Colors.black,
      ),
    ),
  );
}

PreferredSizeWidget _mainSectionTabBar(
  BuildContext context, {
  required TabController controller,
  required List<({IconData icon, String label})> items,
  ValueChanged<int>? onTap,
}) {
  final cs = Theme.of(context).colorScheme;
  return TabBar(
    controller: controller,
    onTap: onTap,
    indicatorColor: cs.primary,
    indicatorWeight: 3,
    dividerColor: Colors.transparent,
    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
    unselectedLabelStyle: GoogleFonts.outfit(
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    tabs: [
      for (final item in items)
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(item.icon, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

PreferredSizeWidget _settingsHeaderAppBar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
  Widget? leading,
}) {
  final cs = Theme.of(context).colorScheme;
  return RoundedBlurAppBar(
    height: 64,
    centerTitle: false,
    leading: leading,
    actions: actions,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
      ),
    ),
  );
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
                  shape: BoxShape.circle,
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
                  shape: BoxShape.circle,
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
