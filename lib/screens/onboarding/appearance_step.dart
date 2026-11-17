part of '../../main.dart';

/// Step 1: Material 3 Expressive Appearance Stage with live morphing timetable
/// preview card, theme selector, dark/light mode toggle, and motion controls.
class AppearanceStep extends StatelessWidget {
  final VoidCallback onNext;

  const AppearanceStep({
    super.key,
    required this.onNext,
  });

  static List<Color> _themeColors(AppThemeId theme) => switch (theme) {
    AppThemeId.defaultTheme => const [Color(0xFF0F766E), Color(0xFFD5F5EF)],
    AppThemeId.manga => const [Color(0xFFF4ECDD), Color(0xFF17120C)],
    AppThemeId.glass => const [Color(0xFF2A63D5), Color(0xFF8DE2D0)],
    AppThemeId.cyber => const [Color(0xFF071015), Color(0xFF6EEAF2)],
  };

  static String _themeName(AppL10n l, AppThemeId theme) => switch (theme) {
    AppThemeId.defaultTheme => l.themeDefault,
    AppThemeId.manga => l.themeManga,
    AppThemeId.glass => l.themeGlass,
    AppThemeId.cyber => l.themeCyber,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);

    return M3StepContainer(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Header
            Text(
              l.onboardingAppearanceTitle,
              style: untisThemeTextStyle(
                context,
                display: true,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.onboardingAppearanceSubtitle,
              style: untisThemeTextStyle(
                context,
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Live Timetable Preview Card
            ValueListenableBuilder<AppThemeId>(
              valueListenable: visualThemeNotifier,
              builder: (context, currentTheme, _) {
                final previewColors = _themeColors(currentTheme);
                final isSharp = currentTheme == AppThemeId.manga ||
                    currentTheme == AppThemeId.cyber;
                final cardRadius = isSharp ? 6.0 : 28.0;

                return AnimatedContainer(
                  key: const ValueKey('onboarding-theme-preview'),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  height: 138,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: previewColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.45),
                      width: isSharp ? 2.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _themeName(l, currentTheme),
                              style: untisThemeTextStyle(
                                context,
                                display: true,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: colors.primary,
                            size: 22,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Simulated timetable lesson chips
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(
                                  isSharp ? 4 : 14,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      switch (l.locale) {
                                        'en' => 'Mathematics',
                                        'fr' => 'Mathématiques',
                                        'es' => 'Matemáticas',
                                        _ => 'Mathematik',
                                      },
                                      overflow: TextOverflow.ellipsis,
                                      style: untisThemeTextStyle(
                                        context,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(
                                  isSharp ? 4 : 14,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'R204',
                                style: untisThemeTextStyle(
                                  context,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 22),
            // Theme Grid Picker (Height fixed to 64 per item)
            ValueListenableBuilder<AppThemeId>(
              valueListenable: visualThemeNotifier,
              builder: (context, selectedTheme, _) {
                return ResponsiveFixedGrid(
                  itemCount: AppThemeId.values.length,
                  mainAxisExtent: 64,
                  spacing: 10,
                  itemBuilder: (context, index) {
                    final theme = AppThemeId.values[index];
                    final isActive = theme == selectedTheme;
                    final preview = _themeColors(theme);
                    final isSharp = theme == AppThemeId.manga ||
                        theme == AppThemeId.cyber;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('onboarding-theme-${theme.storageKey}'),
                        onTap: () {
                          AppHaptics.selection();
                          unawaited(_settingsSetVisualTheme(theme));
                        },
                        borderRadius: BorderRadius.circular(isSharp ? 4 : 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh.withValues(
                              alpha: 0.75,
                            ),
                            borderRadius: BorderRadius.circular(isSharp ? 4 : 16),
                            border: Border.all(
                              color: isActive
                                  ? colors.primary
                                  : colors.outlineVariant.withValues(alpha: 0.35),
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: preview,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    isSharp ? 4 : 10,
                                  ),
                                  border: Border.all(
                                    color: colors.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _themeName(l, theme),
                                  style: untisThemeTextStyle(
                                    context,
                                    fontSize: 14.5,
                                    fontWeight: isActive
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isActive
                                        ? colors.primary
                                        : colors.onSurface,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: colors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
            // Theme Mode Row (System / Light / Dark)
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, currentMode, _) {
                final modes = [
                  (ThemeMode.system, l.settingsThemeSystem, Icons.brightness_auto_rounded),
                  (ThemeMode.light, l.settingsThemeLight, Icons.light_mode_rounded),
                  (ThemeMode.dark, l.settingsThemeDark, Icons.dark_mode_rounded),
                ];

                return Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: modes.map((m) {
                      final isSel = currentMode == m.$1;
                      return Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              AppHaptics.selection();
                              unawaited(_settingsSetThemeMode(m.$1));
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: isSel ? colors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color: colors.shadow.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    m.$3,
                                    size: 16,
                                    color: isSel ? colors.primary : colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      m.$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: untisThemeTextStyle(
                                        context,
                                        fontSize: 12.5,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        color: isSel ? colors.primary : colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),
            // Toggles: Background Animations & Blur
            ValueListenableBuilder<bool>(
              valueListenable: backgroundAnimationsNotifier,
              builder: (context, bgActive, _) {
                return _buildM3Toggle(
                  context,
                  title: l.settingsBackgroundAnimations,
                  subtitle: l.settingsBackgroundAnimationsDesc,
                  icon: Icons.animation_rounded,
                  value: bgActive,
                  onChanged: (val) {
                    AppHaptics.selection();
                    unawaited(_settingsSetBackgroundAnimations(val));
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<bool>(
              valueListenable: blurEnabledNotifier,
              builder: (context, blurActive, _) {
                return _buildM3Toggle(
                  context,
                  title: l.settingsGlassEffect,
                  subtitle: l.settingsGlassEffectDesc,
                  icon: Icons.blur_on_rounded,
                  value: blurActive,
                  onChanged: (val) {
                    AppHaptics.selection();
                    unawaited(_settingsSetBlurEnabled(val));
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      footer: M3PillButton(
        label: l.onboardingNext,
        icon: Icons.arrow_forward_rounded,
        onPressed: onNext,
      ),
    );
  }

  Widget _buildM3Toggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
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
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
