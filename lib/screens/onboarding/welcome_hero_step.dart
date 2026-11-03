part of '../../main.dart';

/// Step 0: Emotional M3 Expressive Welcome Stage with dynamic branding,
/// instant language switcher, and rapid entry actions.
class WelcomeHeroStep extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback? onTryDemo;

  const WelcomeHeroStep({
    super.key,
    required this.onGetStarted,
    this.onTryDemo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const languages = [
      ('de', 'Deutsch', '🇩🇪'),
      ('en', 'English', '🇬🇧'),
      ('fr', 'Français', '🇫🇷'),
      ('es', 'Español', '🇪🇸'),
    ];

    return ValueListenableBuilder<String>(
      valueListenable: appLocaleNotifier,
      builder: (context, currentLocale, _) {
        final l = appL10nFor(currentLocale);

        return M3StepContainer(
          content: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Expressive Emblem with squircle shape & dynamic tonal gradient
                Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryContainer,
                        colors.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/icons/icon_3D.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.auto_awesome_rounded,
                        size: 48,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Emphasized Display Headline
                Text(
                  l.onboardingWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: untisThemeTextStyle(
                    context,
                    display: true,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: colors.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l.onboardingChooseLanguageSubtitle,
                    textAlign: TextAlign.center,
                    style: untisThemeTextStyle(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Interactive Language Pill Switcher
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: languages.map((lang) {
                    final isSelected = currentLocale == lang.$1;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          AppHaptics.selection();
                          await ensureDateFormattingForLocale(lang.$1);
                          appLocaleNotifier.value = lang.$1;
                          final prefs = SettingsStore.instance.preferences;
                          await prefs.setString('appLocale', lang.$1);
                          unawaited(WidgetService.publishNativeCopy(lang.$1));
                          unawaited(AlarmService.instance.refreshNativeCopy());
                        },
                        borderRadius: BorderRadius.circular(99),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primaryContainer
                                : colors.surfaceContainerHigh.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.outlineVariant.withValues(alpha: 0.35),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(lang.$3, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                lang.$2,
                                style: untisThemeTextStyle(
                                  context,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  color: isSelected
                                      ? colors.onPrimaryContainer
                                      : colors.onSurface,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: colors.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              M3PillButton(
                label: l.onboardingNext,
                icon: Icons.arrow_forward_rounded,
                onPressed: onGetStarted,
              ),
              if (onTryDemo != null) ...[
                const SizedBox(height: 8),
                M3PillButton(
                  label: l.onboardingUseDemoMode,
                  icon: Icons.science_rounded,
                  isPrimary: false,
                  onPressed: onTryDemo,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
