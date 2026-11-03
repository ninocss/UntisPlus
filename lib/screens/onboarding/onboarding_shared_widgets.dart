part of '../../main.dart';

/// Floating M3 Expressive progress header with animated spring indicators.
class M3ExpressiveProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;

  const M3ExpressiveProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canGoBack = currentStep > 0 && onBack != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: canGoBack ? 1.0 : 0.25,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                onPressed: canGoBack ? onBack : null,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: List.generate(totalSteps, (index) {
                final isActive = index == currentStep;
                final isDone = index < currentStep;
                return Expanded(
                  flex: isActive ? 3 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.primary
                          : isDone
                              ? colors.primary.withValues(alpha: 0.5)
                              : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${currentStep + 1}/$totalSteps',
              style: untisThemeTextStyle(
                context,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// M3 Expressive card surface with 28dp smooth corners and tonal elevation.
class M3ExpressiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  const M3ExpressiveCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(28);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: radius,
        border: border ??
            Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.28),
            ),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Full-width M3 Expressive Pill Button with tactile feedback and spring curves.
class M3PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const M3PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );

    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPrimary ? colors.onPrimary : colors.primary,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: untisThemeTextStyle(
                  context,
                  display: true,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? colors.onPrimary : colors.onSecondaryContainer,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 20),
              ],
            ],
          );

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: isPrimary
          ? FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: shape,
                elevation: 0,
              ),
              child: child,
            )
          : FilledButton.tonal(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: colors.secondaryContainer.withValues(alpha: 0.8),
                foregroundColor: colors.onSecondaryContainer,
                shape: shape,
                elevation: 0,
              ),
              child: child,
            ),
    );
  }
}

/// Responsive Step Container that dynamically formats header, content, and footer.
class M3StepContainer extends StatelessWidget {
  final Widget? header;
  final Widget content;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const M3StepContainer({
    super.key,
    this.header,
    required this.content,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: 14),
            ],
            Expanded(child: content),
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
