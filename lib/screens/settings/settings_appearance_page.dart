// settings_appearance_page.dart
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

  String _transitionLabel(AppL10n l, int index) {
    switch (index) {
      case 0:
        return l.settingsPageTransitionBounce;
      case 1:
        return l.settingsPageTransitionFade;
      case 2:
        return l.settingsPageTransitionSlide;
      case 3:
        return l.settingsPageTransitionZoom;
      case 4:
        return l.settingsPageTransitionBlur;
      case 5:
        return l.settingsPageTransitionEaseIn;
      case 6:
        return l.settingsPageTransitionEaseOut;
      case 7:
        return l.settingsPageTransitionExpo;
      default:
        return l.settingsPageTransitionBounce;
    }
  }

  IconData _transitionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.animation_rounded;
      case 1:
        return Icons.opacity_rounded;
      case 2:
        return Icons.swipe_rounded;
      case 3:
        return Icons.zoom_in_rounded;
      case 4:
        return Icons.blur_on_rounded;
      case 5:
        return Icons.arrow_forward_rounded;
      case 6:
        return Icons.arrow_back_rounded;
      case 7:
        return Icons.speed_rounded;
      default:
        return Icons.animation_rounded;
    }
  }

  void _showTransitionDialog(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsPageTransition,
      subtitle: l.settingsPageTransitionDesc,
      options: List.generate(8, (index) {
        return _SheetOption(
          value: index,
          title: _transitionLabel(l, index),
          icon: _transitionIcon(index),
          selected: pageTransitionNotifier.value == index,
        );
      }),
    ).then((value) {
      if (value != null) {
        _settingsSetPageTransition(value);
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(
                  l.settingsLanguage,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _settingsLocaleLabels[appLocaleNotifier.value] ??
                      (_settingsLocaleLabels['de'] ?? appLocaleNotifier.value),
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showLanguageDialog(context),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<int>(
                valueListenable: pageTransitionNotifier,
                builder: (context, transition, _) {
                  return ListTile(
                    leading: const Icon(Icons.compare_arrows_rounded),
                    title: Text(
                      l.settingsPageTransition,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _transitionLabel(l, transition),
                      style: GoogleFonts.outfit(),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showTransitionDialog(context),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: ValueListenableBuilder<bool>(
                valueListenable: tabTransitionNotifier,
                builder: (context, value, _) {
                  return SwitchListTile.adaptive(
                    value: value,
                    onChanged: _settingsSetTabTransition,
                    title: Text(
                      l.settingsTabTransition,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l.settingsTabTransitionDesc,
                      style: GoogleFonts.outfit(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
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