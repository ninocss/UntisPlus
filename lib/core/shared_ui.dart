part of '../main.dart';

const Curve _kSmoothBounce = Curves.easeOutCubic;
const Curve _kSoftBounce = Curves.easeOutQuad;

const AnimationStyle _kBottomSheetAnimationStyle = AnimationStyle();

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
  return Container(
    decoration: BoxDecoration(
      borderRadius: borderRadius,
      color: color ?? cs.surfaceContainerHigh,
      border: border ??
          Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.18),
            width: 1,
          ),
    ),
    child: child,
  );
}

Widget _withOptionalBackdropBlur({
  required double sigmaX,
  required double sigmaY,
  required Widget child,
  required Widget Function(bool enabled) childBuilder,
}) {
  // Disabled blur for Material 3 standard
  return childBuilder(false);
}

Widget _sheetSurface({
  required BuildContext context,
  required Widget child,
  bool blur = true,
  BorderRadiusGeometry borderRadius = const BorderRadius.vertical(
    top: Radius.circular(28),
  ),
}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    decoration: BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: borderRadius,
    ),
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
        ? (hsl.lightness + 0.05).clamp(0.0, 1.0)
        : (hsl.lightness - 0.04).clamp(0.0, 1.0),
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
  return MaterialPageRoute<T>(
    builder: (context) => page,
  );
}

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
    builder: (ctx) {
      if (outerPadding == null) {
        return child;
      }
      return Padding(padding: outerPadding, child: child);
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
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                      leading: opt.icon != null
                          ? Icon(
                              opt.icon,
                              color: opt.destructive
                                  ? cs.error
                                  : (opt.selected ? cs.primary : null),
                            )
                          : null,
                      title: Text(
                        opt.title,
                        style: TextStyle(
                          color: opt.destructive
                              ? cs.error
                              : (opt.selected ? cs.primary : null),
                          fontWeight: opt.selected ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: opt.subtitle != null ? Text(opt.subtitle!) : null,
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
      );
    },
  );
}

