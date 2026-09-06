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

  void _showAppIconDialog(BuildContext context) {
    const labels = {
      'default': 'Standard', '3d': '3D', 'chrom': 'Chrom',
      'galaxy': 'Galaxy', 'gradiant': 'Gradient', 'marmor': 'Marmor', 'paper': 'Paper',
    };
    _showUnifiedOptionSheet<String>(
      context: context,
      title: 'App-Symbol',
      options: labels.entries.map((entry) => _SheetOption(
        value: entry.key,
        title: entry.value,
        icon: Icons.app_shortcut_rounded,
        selected: appIconNotifier.value == entry.key,
      )).toList(),
    ).then((value) {
      if (value != null) _settingsSetAppIcon(value);
    });
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
    final mq = MediaQuery.of(context);

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
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            // ── GROUP 1: THEME & COLOR SCHEME ──
            SettingsGroup(
              title: l.settingsThemeMode,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeNotifier,
                    builder: (context, mode, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(
                                l.settingsThemeSystem,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              icon: const Icon(Icons.phone_android_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(
                                l.settingsThemeLight,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              icon: const Icon(Icons.light_mode_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(
                                l.settingsThemeDark,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              icon: const Icon(Icons.dark_mode_rounded, size: 18),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: (selection) {
                            HapticFeedback.selectionClick();
                            _settingsSetThemeMode(selection.first);
                          },
                        ),
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: useMaterialYouNotifier,
                  builder: (context, useMaterialYou, _) {
                    return SettingsSwitchTile(
                      icon: Icons.palette_rounded,
                      iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onPrimaryContainer,
                      title: l.settingsUseMaterialYou,
                      subtitle: l.settingsUseMaterialYouDesc,
                      value: useMaterialYou,
                      onChanged: _settingsSetUseMaterialYou,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isAmoledNotifier,
                  builder: (context, isAmoled, _) {
                    return ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (context, mode, _) {
                        final isDark = mode == ThemeMode.dark ||
                            (mode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness == Brightness.dark);
                        return SettingsSwitchTile(
                          icon: Icons.dark_mode_rounded,
                          iconBackgroundColor: cs.surfaceContainerHighest,
                          iconColor: isDark ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5),
                          title: l.settingsIsAmoled,
                          subtitle: l.settingsIsAmoledDesc,
                          value: isAmoled,
                          onChanged: isDark ? _settingsSetIsAmoled : (v) {},
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: useMaterialYouNotifier,
                  builder: (context, useMaterialYou, _) {
                    if (useMaterialYou) return const SizedBox.shrink();
                    return ValueListenableBuilder<int>(
                      valueListenable: customColorSeedNotifier,
                      builder: (context, seed, _) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.settingsCustomColorSeed,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Color(seed),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: cs.outlineVariant.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Slider(
                                      min: 0,
                                      max: 359,
                                      divisions: 359,
                                      value: (HSLColor.fromColor(
                                        Color(seed),
                                      ).hue % 360).clamp(0, 359),
                                      onChanged: (hue) {
                                        final hsl = HSLColor.fromColor(
                                          Color(seed),
                                        );
                                        final newColor = hsl
                                            .withHue(hue)
                                            .withSaturation(0.5)
                                            .withLightness(0.5)
                                            .toColor();
                                        _settingsSetCustomColorSeed(
                                          newColor.toARGB32(),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  0xFF0F766E,
                                  0xFFD32F2F,
                                  0xFF1976D2,
                                  0xFF388E3C,
                                  0xFFF57C00,
                                  0xFF7B1FA2,
                                  0xFF00796B,
                                  0xFFC2185B,
                                  0xFF455A64,
                                  0xFF5D4037,
                                ].map((color) {
                                  final selected = seed == color;
                                  final c = Color(color);
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      _settingsSetCustomColorSeed(color);
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: BorderRadius.circular(8),
                                        border: selected
                                            ? Border.all(
                                                color: cs.primary,
                                                width: 2.5,
                                              )
                                            : Border.all(
                                                color: Colors.transparent,
                                              ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            // ── GROUP 2: BACKGROUND & MOTION ──
            SettingsGroup(
              title: l.settingsBackgroundAnimations,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: backgroundAnimationsNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.auto_awesome_rounded,
                      iconBackgroundColor: cs.tertiaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onTertiaryContainer,
                      title: l.settingsBackgroundAnimations,
                      subtitle: l.settingsBackgroundAnimationsDesc,
                      value: value,
                      onChanged: _settingsSetBackgroundAnimations,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: backgroundAnimationsNotifier,
                  builder: (context, animationsEnabled, _) {
                    if (!animationsEnabled) return const SizedBox.shrink();
                    return ValueListenableBuilder<bool>(
                      valueListenable: backgroundGyroscopeNotifier,
                      builder: (context, value, _) {
                        return SettingsSwitchTile(
                          icon: Icons.screen_rotation_rounded,
                          iconBackgroundColor: cs.tertiaryContainer.withValues(alpha: 0.7),
                          iconColor: cs.onTertiaryContainer,
                          title: l.settingsBackgroundGyroscope,
                          subtitle: l.settingsBackgroundGyroscopeDesc,
                          value: value,
                          onChanged: _settingsSetBackgroundGyroscope,
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: backgroundAnimationsNotifier,
                  builder: (context, animationsEnabled, _) {
                    if (!animationsEnabled) return const SizedBox.shrink();
                    return ValueListenableBuilder<int>(
                      valueListenable: backgroundAnimationStyleNotifier,
                      builder: (context, style, _) {
                        return SettingsTile(
                          icon: Icons.style_rounded,
                          iconBackgroundColor: cs.tertiaryContainer.withValues(alpha: 0.7),
                          iconColor: cs.onTertiaryContainer,
                          title: l.settingsBackgroundStyle,
                          subtitle: _backgroundStyleLabel(l, style),
                          onTap: () => _showBackgroundStyleDialog(context),
                        );
                      },
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.wallpaper_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                  iconColor: cs.onSecondaryContainer,
                  title: l.settingsCustomBackgrounds,
                  subtitle: l.settingsCustomBackgroundsDesc,
                  onTap: () {
                    Navigator.push(
                      context,
                      _buildBouncyRoute(const CustomBackgroundEditorScreen()),
                    );
                  },
                ),
              ],
            ),

            // ── GROUP 3: INTERFACE & BEHAVIOR ──
            SettingsGroup(
              title: l.settingsGlassEffect,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: blurEnabledNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.blur_on_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsGlassEffect,
                      subtitle: l.settingsGlassEffectDesc,
                      value: value,
                      onChanged: _settingsSetBlurEnabled,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: appBgBlurEnabledNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.blur_linear_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsAppBgBlur,
                      subtitle: l.settingsAppBgBlurDesc,
                      value: value,
                      onChanged: _settingsSetAppBgBlurEnabled,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: appBgBlurEnabledNotifier,
                  builder: (context, blurEnabled, _) {
                    if (!blurEnabled) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.settingsAppBgBlurAmount,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: cs.onSurface,
                            ),
                          ),
                          ValueListenableBuilder<double>(
                            valueListenable: appBgBlurAmountNotifier,
                            builder: (context, amount, _) {
                              return Slider(
                                value: amount,
                                min: 0,
                                max: 40,
                                onChanged: _settingsSetAppBgBlurAmount,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: monochromeLessonsNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.tonality_rounded,
                      iconBackgroundColor: cs.surfaceContainerHighest,
                      iconColor: cs.onSurfaceVariant,
                      title: l.settingsMonochromeLessons,
                      subtitle: l.settingsMonochromeLessonsDesc,
                      value: value,
                      onChanged: _settingsSetMonochromeLessons,
                    );
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: pageTransitionNotifier,
                  builder: (context, transition, _) {
                    return SettingsTile(
                      icon: Icons.animation_rounded,
                      iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onPrimaryContainer,
                      title: l.settingsPageTransition,
                      subtitle: _transitionLabel(l, transition),
                      onTap: () => _showTransitionDialog(context),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.dashboard_customize_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsLessonDesignTitle,
                  subtitle: l.settingsLessonDesignDesc,
                  onTap: () {
                    Navigator.push(
                      context,
                      _buildBouncyRoute(const SettingsTimetablePage()),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.app_shortcut_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                  iconColor: cs.onSecondaryContainer,
                  title: 'App-Symbol',
                  subtitle: Platform.isAndroid ? 'Symbol für den Startbildschirm auswählen' : 'Derzeit auf Android verfügbar',
                  onTap: () => _showAppIconDialog(context),
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsLanguage,
                  subtitle: _settingsLocaleLabels[appLocaleNotifier.value] ??
                      (_settingsLocaleLabels['de'] ?? appLocaleNotifier.value),
                  onTap: () => _showLanguageDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
