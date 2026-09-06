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
      'default': 'Standard',
      '3d': '3D',
      'chrom': 'Chrom',
      'galaxy': 'Galaxy',
      'gradiant': 'Gradient',
      'marmor': 'Marmor',
      'paper': 'Paper',
    };
    _showUnifiedOptionSheet<String>(
      context: context,
      title: 'App-Symbol',
      options: labels.entries
          .map(
            (entry) => _SheetOption(
              value: entry.key,
              title: entry.value,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  entry.key == 'default'
                      ? 'assets/icons/icon.png'
                      : 'assets/icons/icon_${entry.key == '3d' ? '3D' : entry.key}.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.app_shortcut_rounded),
                  ),
                ),
              ),
              selected: appIconNotifier.value == entry.key,
            ),
          )
          .toList(),
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

  String _themeLabel(AppL10n l, AppThemeId theme) => switch (theme) {
    AppThemeId.defaultTheme => l.themeDefault,
    AppThemeId.manga => l.themeManga,
    AppThemeId.vivid => l.themeVivid,
    AppThemeId.glass => l.themeGlass,
    AppThemeId.cyber => l.themeCyber,
    AppThemeId.paper => l.themePaper,
  };

  String _themeDescription(AppL10n l, AppThemeId theme) => switch (theme) {
    AppThemeId.defaultTheme => l.themeDefaultDesc,
    AppThemeId.manga => l.themeMangaDesc,
    AppThemeId.vivid => l.themeVividDesc,
    AppThemeId.glass => l.themeGlassDesc,
    AppThemeId.cyber => l.themeCyberDesc,
    AppThemeId.paper => l.themePaperDesc,
  };

  List<Color> _themePreviewColors(AppThemeId theme, bool dark) =>
      switch (theme) {
        AppThemeId.defaultTheme => const [Color(0xFF0F766E), Color(0xFFD5F5EF)],
        AppThemeId.manga =>
          dark
              ? const [Color(0xFF171511), Color(0xFFF5EBD7)]
              : const [Color(0xFFF4ECDD), Color(0xFF17120C)],
        AppThemeId.vivid => const [
          Color(0xFFFF4FC8),
          Color(0xFF4BE4FF),
          Color(0xFFFFE04B),
        ],
        AppThemeId.glass => const [
          Color(0xFF76D6FF),
          Color(0xFFD8BCFF),
          Color(0xFFBFFFF1),
        ],
        AppThemeId.cyber =>
          dark
              ? const [Color(0xFF02050A), Color(0xFF00F5FF), Color(0xFFFF2FA8)]
              : const [Color(0xFFE9FEFF), Color(0xFF006B75), Color(0xFFFF2FA8)],
        AppThemeId.paper =>
          dark
              ? const [Color(0xFF1E2020), Color(0xFFFFC86B)]
              : const [Color(0xFFFFF9E8), Color(0xFF9A4D24)],
      };

  Widget _buildThemePicker(
    BuildContext context,
    AppL10n l,
    AppThemeId selected,
  ) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SettingsGroup(
      title: l.settingsVisualTheme,
      padding: const EdgeInsets.all(10),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Text(
                l.settingsVisualThemeDesc,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppThemeId.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.36,
              ),
              itemBuilder: (context, index) {
                final theme = AppThemeId.values[index];
                final colors = _themePreviewColors(theme, dark);
                final active = theme == selected;
                return Semantics(
                  selected: active,
                  button: true,
                  label: _themeLabel(l, theme),
                  child: InkWell(
                    key: ValueKey('theme-${theme.storageKey}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _settingsSetVisualTheme(theme);
                    },
                    child: AnimatedContainer(
                      duration: MediaQuery.of(context).disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 260),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? cs.primary : cs.outlineVariant,
                          width: active ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                theme == AppThemeId.manga ? 1 : 9,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: colors),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 8,
                                      right: 24,
                                      top: 9,
                                      child: Container(
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: colors.last,
                                          border: theme == AppThemeId.manga
                                              ? Border.all(
                                                  color: colors[1],
                                                  width: 2,
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            theme == AppThemeId.manga ? 0 : 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 8,
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: colors.first.withValues(
                                            alpha: 0.78,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            theme == AppThemeId.manga ? 0 : 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _themeLabel(l, theme),
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (active)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 17,
                                  color: cs.primary,
                                ),
                            ],
                          ),
                          Text(
                            _themeDescription(l, theme),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    final selectedTheme = visualThemeNotifier.value;
    final capabilities = appThemeCapabilities(selectedTheme);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsAppearance,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            _buildThemePicker(context, l, selectedTheme),
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
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              icon: const Icon(
                                Icons.phone_android_rounded,
                                size: 18,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(
                                l.settingsThemeLight,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              icon: const Icon(
                                Icons.light_mode_rounded,
                                size: 18,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(
                                l.settingsThemeDark,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              icon: const Icon(
                                Icons.dark_mode_rounded,
                                size: 18,
                              ),
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
                if (capabilities.supportsMaterialYou)
                  ValueListenableBuilder<bool>(
                    valueListenable: useMaterialYouNotifier,
                    builder: (context, useMaterialYou, _) {
                      return SettingsSwitchTile(
                        icon: Icons.palette_rounded,
                        iconBackgroundColor: cs.primaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        iconColor: cs.onPrimaryContainer,
                        title: l.settingsUseMaterialYou,
                        subtitle: l.settingsUseMaterialYouDesc,
                        value: useMaterialYou,
                        onChanged: _settingsSetUseMaterialYou,
                      );
                    },
                  ),
                if (selectedTheme == AppThemeId.defaultTheme)
                  ValueListenableBuilder<bool>(
                    valueListenable: isAmoledNotifier,
                    builder: (context, isAmoled, _) {
                      return ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeModeNotifier,
                        builder: (context, mode, _) {
                          final isDark =
                              mode == ThemeMode.dark ||
                              (mode == ThemeMode.system &&
                                  MediaQuery.of(context).platformBrightness ==
                                      Brightness.dark);
                          return SettingsSwitchTile(
                            icon: Icons.dark_mode_rounded,
                            iconBackgroundColor: cs.surfaceContainerHighest,
                            iconColor: isDark
                                ? cs.primary
                                : cs.onSurfaceVariant.withValues(alpha: 0.5),
                            title: l.settingsIsAmoled,
                            subtitle: l.settingsIsAmoledDesc,
                            value: isAmoled,
                            onChanged: isDark ? _settingsSetIsAmoled : (v) {},
                          );
                        },
                      );
                    },
                  ),
                if (capabilities.supportsMaterialYou)
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
                                          color: cs.outlineVariant.withValues(
                                            alpha: 0.5,
                                          ),
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
                                        value:
                                            (HSLColor.fromColor(
                                                      Color(seed),
                                                    ).hue %
                                                    360)
                                                .clamp(0, 359),
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
                                  children:
                                      [
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
            if (capabilities.supportsBackgroundMotion ||
                capabilities.supportsCustomBackgrounds)
              SettingsGroup(
                title: l.settingsBackgroundAnimations,
                children: [
                  if (capabilities.supportsBackgroundMotion)
                    ValueListenableBuilder<bool>(
                      valueListenable: backgroundAnimationsNotifier,
                      builder: (context, value, _) {
                        return SettingsSwitchTile(
                          icon: Icons.auto_awesome_rounded,
                          iconBackgroundColor: cs.tertiaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          iconColor: cs.onTertiaryContainer,
                          title: l.settingsBackgroundAnimations,
                          subtitle: l.settingsBackgroundAnimationsDesc,
                          value: value,
                          onChanged: _settingsSetBackgroundAnimations,
                        );
                      },
                    ),
                  if (capabilities.supportsBackgroundMotion)
                    ValueListenableBuilder<bool>(
                      valueListenable: backgroundAnimationsNotifier,
                      builder: (context, animationsEnabled, _) {
                        if (!animationsEnabled) return const SizedBox.shrink();
                        return ValueListenableBuilder<bool>(
                          valueListenable: backgroundGyroscopeNotifier,
                          builder: (context, value, _) {
                            return SettingsSwitchTile(
                              icon: Icons.screen_rotation_rounded,
                              iconBackgroundColor: cs.tertiaryContainer
                                  .withValues(alpha: 0.7),
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
                  if (selectedTheme == AppThemeId.defaultTheme)
                    ValueListenableBuilder<bool>(
                      valueListenable: backgroundAnimationsNotifier,
                      builder: (context, animationsEnabled, _) {
                        if (!animationsEnabled) return const SizedBox.shrink();
                        return ValueListenableBuilder<int>(
                          valueListenable: backgroundAnimationStyleNotifier,
                          builder: (context, style, _) {
                            return SettingsTile(
                              icon: Icons.style_rounded,
                              iconBackgroundColor: cs.tertiaryContainer
                                  .withValues(alpha: 0.7),
                              iconColor: cs.onTertiaryContainer,
                              title: l.settingsBackgroundStyle,
                              subtitle: _backgroundStyleLabel(l, style),
                              onTap: () => _showBackgroundStyleDialog(context),
                            );
                          },
                        );
                      },
                    ),
                  if (capabilities.supportsCustomBackgrounds)
                    SettingsTile(
                      icon: Icons.wallpaper_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsCustomBackgrounds,
                      subtitle: l.settingsCustomBackgroundsDesc,
                      onTap: () {
                        Navigator.push(
                          context,
                          _buildBouncyRoute(
                            const CustomBackgroundEditorScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),

            // ── GROUP 3: INTERFACE & BEHAVIOR ──
            SettingsGroup(
              title: capabilities.supportsBlur
                  ? l.settingsGlassEffect
                  : l.settingsAppearance,
              children: [
                if (capabilities.supportsBlur)
                  ValueListenableBuilder<bool>(
                    valueListenable: blurEnabledNotifier,
                    builder: (context, value, _) {
                      return SettingsSwitchTile(
                        icon: Icons.blur_on_rounded,
                        iconBackgroundColor: cs.secondaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        iconColor: cs.onSecondaryContainer,
                        title: l.settingsGlassEffect,
                        subtitle: l.settingsGlassEffectDesc,
                        value: value,
                        onChanged: _settingsSetBlurEnabled,
                      );
                    },
                  ),
                if (capabilities.supportsBlur)
                  ValueListenableBuilder<bool>(
                    valueListenable: appBgBlurEnabledNotifier,
                    builder: (context, value, _) {
                      return SettingsSwitchTile(
                        icon: Icons.blur_linear_rounded,
                        iconBackgroundColor: cs.secondaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        iconColor: cs.onSecondaryContainer,
                        title: l.settingsAppBgBlur,
                        subtitle: l.settingsAppBgBlurDesc,
                        value: value,
                        onChanged: _settingsSetAppBgBlurEnabled,
                      );
                    },
                  ),
                if (capabilities.supportsBlur)
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
                if (selectedTheme == AppThemeId.defaultTheme)
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
                if (selectedTheme == AppThemeId.defaultTheme)
                  ValueListenableBuilder<int>(
                    valueListenable: pageTransitionNotifier,
                    builder: (context, transition, _) {
                      return SettingsTile(
                        icon: Icons.animation_rounded,
                        iconBackgroundColor: cs.primaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        iconColor: cs.onPrimaryContainer,
                        title: l.settingsPageTransition,
                        subtitle: _transitionLabel(l, transition),
                        onTap: () => _showTransitionDialog(context),
                      );
                    },
                  ),
                SettingsTile(
                  icon: Icons.dashboard_customize_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
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
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: 'App-Symbol',
                  subtitle: Platform.isAndroid
                      ? 'Symbol für den Startbildschirm auswählen'
                      : 'Derzeit auf Android verfügbar',
                  onTap: () => _showAppIconDialog(context),
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsLanguage,
                  subtitle:
                      _settingsLocaleLabels[appLocaleNotifier.value] ??
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
