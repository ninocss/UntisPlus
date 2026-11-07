part of '../../main.dart';

/// Step 0: Emotional M3 Expressive Welcome Stage with dynamic branding,
/// vertical language selector cards, and rapid entry actions.
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
                const SizedBox(height: 16),
                // App Icon emblem with squircle container & subtle glow
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryContainer,
                        colors.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icons/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.school_rounded,
                        size: 48,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                // Emphasized Display Headline
                Text(
                  l.onboardingWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: untisThemeTextStyle(
                    context,
                    display: true,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: colors.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l.onboardingChooseLanguageSubtitle,
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
                const SizedBox(height: 24),
                // Vertical Language Selection Cards
                for (int i = 0; i < languages.length; i++) ...[
                  _buildLanguageCard(
                    context,
                    code: languages[i].$1,
                    name: languages[i].$2,
                    flag: languages[i].$3,
                    isSelected: currentLocale == languages[i].$1,
                    colors: colors,
                  ),
                  if (i < languages.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
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

  Widget _buildLanguageCard(
    BuildContext context, {
    required String code,
    required String name,
    required String flag,
    required bool isSelected,
    required ColorScheme colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          AppHaptics.selection();
          await ensureDateFormattingForLocale(code);
          appLocaleNotifier.value = code;
          final prefs = SettingsStore.instance.preferences;
          await prefs.setString('appLocale', code);
          unawaited(WidgetService.publishNativeCopy(code));
          unawaited(AlarmService.instance.refreshNativeCopy());
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer.withValues(alpha: 0.85)
                : colors.surfaceContainerHigh.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.35),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(flag, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 15.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('checked'),
                        color: colors.primary,
                        size: 22,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('unchecked'),
                        color: colors.outlineVariant.withValues(alpha: 0.7),
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
