part of '../../main.dart';

/// Step 4: Material 3 Expressive Launch & Celebration Stage with feature cards
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
      (
        Icons.auto_awesome_rounded,
        l.onboardingFeatureAiTitle,
        l.onboardingFeatureAiDesc,
        colors.tertiary,
      ),
      (
        Icons.notifications_active_rounded,
        l.onboardingFeatureNotifyTitle,
        l.onboardingFeatureNotifyDesc,
        colors.primary,
      ),
      (
        Icons.system_update_alt_rounded,
        l.onboardingFeatureUpdatesTitle,
        l.onboardingFeatureUpdatesDesc,
        colors.secondary,
      ),
      (
        Icons.backup_rounded,
        l.onboardingFeatureBackupTitle,
        l.onboardingFeatureBackupDesc,
        colors.tertiary,
      ),
    ];

    return M3StepContainer(
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Celebration Emblem
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primaryContainer, colors.tertiaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 38,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l.onboardingReadySubtitle,
                textAlign: TextAlign.center,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Expressive Feature Cards
            ...features.map((feature) {
              final (icon, title, desc, accent) = feature;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
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
                                fontSize: 14.5,
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
            const SizedBox(height: 12),
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
