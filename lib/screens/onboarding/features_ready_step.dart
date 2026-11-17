part of '../../main.dart';

/// Step 4: Material 3 Expressive Launch & Celebration Stage with clean highlights
/// and completion action leading smoothly into the main application.
class FeaturesReadyStep extends StatelessWidget {
  final VoidCallback onComplete;

  const FeaturesReadyStep({
    super.key,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);

    final features = [
      (
        Icons.calendar_month_rounded,
        l.onboardingFeatureTimetableTitle,
        l.onboardingFeatureTimetableDesc,
        colors.primary,
      ),
      (
        Icons.draw_rounded,
        l.onboardingFeatureExamsTitle,
        l.onboardingFeatureExamsDesc,
        colors.secondary,
      ),
    ];

    return M3StepContainer(
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Celebration Emblem
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primaryContainer, colors.tertiaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 42,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l.onboardingReadyTitle,
              textAlign: TextAlign.center,
              style: untisThemeTextStyle(
                context,
                display: true,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l.onboardingReadySubtitle,
                textAlign: TextAlign.center,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Clean, essential highlight cards
            ...features.map((feature) {
              final (icon, title, desc, accent) = feature;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, size: 22, color: accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: untisThemeTextStyle(
                                context,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: untisThemeTextStyle(
                                context,
                                fontSize: 12.5,
                                color: colors.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
      footer: M3PillButton(
        label: l.onboardingFinishSetup,
        icon: Icons.check_rounded,
        onPressed: onComplete,
      ),
    );
  }
}
