part of '../../main.dart';

class SettingsAppearancePage extends StatelessWidget {
  const SettingsAppearancePage({super.key});

  String _backgroundStyleLabel(AppL10n l, int style) {
    switch (style) {
      case 1:
        return l.settingsBackgroundStyleSpace;
      case 2:
        return l.settingsBackgroundStyleBubbles;
      case 3:
        return l.settingsBackgroundStyleLines;
      case 4:
        return l.settingsBackgroundStyleThreeD;
      case 5:
        return l.settingsBackgroundStyleNebula;
      case 6:
        return l.settingsBackgroundStylePrism;
      case 7:
        return l.settingsBackgroundStyleWaves;
      case 8:
        return l.settingsBackgroundStyleGrid;
      case 9:
        return l.settingsBackgroundStyleRings;
      case 10:
        return l.settingsBackgroundStyleCustom;
      case 0:
      default:
        return l.settingsBackgroundStyleOrbs;
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsLanguage,
      options: _settingsLocaleLabels.entries
          .map(
            (entry) => _SheetOption(
              value: entry.key,
              title: entry.value,
              icon: Icons.language_rounded,
              selected: appLocaleNotifier.value == entry.key,
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) {
        _settingsSetLocale(value);
      }
    });
  }

  void _showBackgroundStyleDialog(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsBackgroundStyle,
      options: List.generate(11, (index) {
        return _SheetOption(
          value: index,
          title: _backgroundStyleLabel(l, index),
          icon: Icons.auto_awesome_rounded,
          selected: backgroundAnimationStyleNotifier.value == index,
        );
      }),
    ).then((value) {
      if (value != null) {
        _settingsSetBackgroundAnimationStyle(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsAppearance,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, mode, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.settingsThemeMode,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l.settingsThemeSystem),
                              icon: const Icon(Icons.phone_android_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l.settingsThemeLight),
                              icon: const Icon(Icons.light_mode_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l.settingsThemeDark),
                              icon: const Icon(Icons.dark_mode_rounded),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: (selection) {
                            _settingsSetThemeMode(selection.first);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(
                  l.settingsLanguage,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _settingsLocaleLabels[appLocaleNotifier.value] ?? 'Deutsch',
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showLanguageDialog(context),
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: blurEnabledNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetBlurEnabled,
                    title: Text(
                      l.settingsGlassEffect,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsGlassEffectDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: backgroundAnimationsNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetBackgroundAnimations,
                    title: Text(
                      l.settingsBackgroundAnimations,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsBackgroundAnimationsDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: backgroundGyroscopeNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetBackgroundGyroscope,
                    title: Text(
                      l.settingsBackgroundGyroscope,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsBackgroundGyroscopeDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<int>(
                valueListenable: backgroundAnimationStyleNotifier,
                builder: (context, style, _) {
                  return ListTile(
                    leading: const Icon(Icons.animation_rounded),
                    title: Text(
                      l.settingsBackgroundStyle,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _backgroundStyleLabel(l, style),
                      style: GoogleFonts.outfit(),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showBackgroundStyleDialog(context),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerLow,
              child: ListTile(
                leading: const Icon(Icons.wallpaper_rounded),
                title: Text(
                  l.settingsCustomBackgrounds,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsCustomBackgroundsDesc,
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    _buildBouncyRoute(const CustomBackgroundEditorScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
