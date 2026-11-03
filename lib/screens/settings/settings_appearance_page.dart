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
    final l = appL10nFor(appLocaleNotifier.value);
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
    final l = appL10nFor(appLocaleNotifier.value);
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

  void _showMonochromeLessonColorDialog(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUntisRgbColorPickerSheet(
      context: context,
      title: l.settingsCustomColor,
      initialColor: Color(monochromeLessonColorNotifier.value),
      onReset: () => _settingsSetMonochromeLessonColor(0xFF757575),
    ).then((picked) {
      if (picked != null) {
        _settingsSetMonochromeLessonColor(picked.toARGB32());
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
      case 8:
        return l.settingsPageTransitionDefault;
      default:
        return l.settingsPageTransitionBounce;
    }
  }

  String _surfaceCornerModeLabel(AppL10n l, int mode) {
    switch (mode) {
      case 1:
        return l.settingsSurfaceCornersSharper;
      case 2:
        return l.settingsSurfaceCornersCustom;
      case 0:
      default:
        return l.settingsSurfaceCornersCurrent;
    }
  }

  void _showSurfaceCornerModeDialog(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsSurfaceCorners,
      subtitle: l.settingsSurfaceCornersDesc,
      options: [
        _SheetOption(
          value: 0,
          title: l.settingsSurfaceCornersCurrent,
          icon: Icons.rounded_corner_rounded,
          selected: surfaceCornerModeNotifier.value == 0,
        ),
        _SheetOption(
          value: 1,
          title: l.settingsSurfaceCornersSharper,
          icon: Icons.crop_square_rounded,
          selected: surfaceCornerModeNotifier.value == 1,
        ),
        _SheetOption(
          value: 2,
          title: l.settingsSurfaceCornersCustom,
          icon: Icons.tune_rounded,
          selected: surfaceCornerModeNotifier.value == 2,
        ),
      ],
    ).then((value) {
      if (value != null) {
        _settingsSetSurfaceCornerMode(value);
      }
    });
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
      title: appL10nFor(appLocaleNotifier.value).appearanceAppIcon,
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
        return Icons.arrow_upward_rounded;
      case 6:
        return Icons.arrow_back_rounded;
      case 7:
        return Icons.speed_rounded;
      case 8:
        return Icons.android_rounded;
      default:
        return Icons.animation_rounded;
    }
  }

  void _showTransitionDialog(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsPageTransition,
      subtitle: l.settingsPageTransitionDesc,
      options: List.generate(9, (index) {
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
    AppThemeId.glass => l.themeGlass,
    AppThemeId.cyber => l.themeCyber,
  };

  String _themeDescription(AppL10n l, AppThemeId theme) => switch (theme) {
    AppThemeId.defaultTheme => l.themeDefaultDesc,
    AppThemeId.manga => l.themeMangaDesc,
    AppThemeId.glass => l.themeGlassDesc,
    AppThemeId.cyber => l.themeCyberDesc,
  };

  List<Color> _themePreviewColors(AppThemeId theme, bool dark) =>
      switch (theme) {
        AppThemeId.defaultTheme => const [Color(0xFF0F766E), Color(0xFFD5F5EF)],
        AppThemeId.manga =>
          dark
              ? const [Color(0xFF171511), Color(0xFFF5EBD7)]
              : const [Color(0xFFF4ECDD), Color(0xFF17120C)],
        AppThemeId.glass =>
          dark
              ? const [Color(0xFF0B1425), Color(0xFF9ACBFF), Color(0xFFD0BEFF)]
              : const [Color(0xFFF5F8FF), Color(0xFF2A63D5), Color(0xFF1D7F6D)],
        AppThemeId.cyber =>
          dark
              ? const [Color(0xFF071015), Color(0xFF6EEAF2), Color(0xFFE285BF)]
              : const [Color(0xFFF1FBFC), Color(0xFF006D75), Color(0xFF9B3E76)],
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
            ResponsiveFixedGrid(
              itemCount: AppThemeId.values.length,
              mainAxisExtent: 148,
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
                      AppHaptics.selection();
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
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    final selectedTheme = visualThemeNotifier.value;
    final capabilities = appThemeCapabilities(selectedTheme);

    return SettingsPageShell(
      title: l.settingsAppearance,
      children: [
        _buildThemePicker(context, l, selectedTheme),
        ValueListenableBuilder<bool>(
          valueListenable: useMaterialYouNotifier,
          builder: (context, useMaterialYou, _) => SettingsGroup(
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
                          icon: const Icon(Icons.light_mode_rounded, size: 18),
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
                          icon: const Icon(Icons.dark_mode_rounded, size: 18),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) {
                        AppHaptics.selection();
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
            if (capabilities.supportsMaterialYou && !useMaterialYou)
              ValueListenableBuilder<int>(
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
                                  child: HapticSlider(
                                    min: 0,
                                    max: 359,
                                    divisions: 359,
                                    value:
                                        (HSLColor.fromColor(Color(seed)).hue %
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
                                        AppHaptics.selection();
                                        _settingsSetCustomColorSeed(color);
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: c,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                  ),
          ],
        ),
        ),

        AnimatedBuilder(
          animation: Listenable.merge([
            blurEnabledNotifier,
            surfaceCornerModeNotifier,
            appBgBlurEnabledNotifier,
          ]),
          builder: (context, _) {
            final blurEnabled = blurEnabledNotifier.value;
            final cornerMode = surfaceCornerModeNotifier.value;
            final appBgBlurEnabled = appBgBlurEnabledNotifier.value;
            return SettingsGroup(
              title: l.settingsAppearanceSurfaces,
              children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l.settingsHeaderStyle,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: headerStyleNotifier,
                    builder: (context, style, _) => SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 0,
                            label: Text(l.settingsHeaderStyleDefault),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text(l.settingsHeaderStyleFade),
                          ),
                          ButtonSegment(
                            value: 2,
                            label: Text(l.settingsHeaderStyleBubbles),
                          ),
                        ],
                        selected: {style},
                        onSelectionChanged: (selection) {
                          AppHaptics.selection();
                          _settingsSetHeaderStyle(selection.first);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            if (capabilities.supportsBlur && blurEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: ValueListenableBuilder<double>(
                  valueListenable: blurStrengthNotifier,
                  builder: (context, strength, _) {
                    final percent = (strength * 100).round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.settingsGlassEffect}: $percent%',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                        HapticSlider(
                          value: strength,
                          min: 0.25,
                          max: 2.0,
                          divisions: 35,
                          label: '$percent%',
                          onChanged: _settingsSetBlurStrength,
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (capabilities.supportsBlur && blurEnabled)
              ValueListenableBuilder<bool>(
                valueListenable: surfaceBlurEnabledNotifier,
                builder: (context, value, _) {
                  return SettingsSwitchTile(
                    icon: Icons.blur_circular_rounded,
                    iconBackgroundColor: cs.secondaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    iconColor: cs.onSecondaryContainer,
                    title: l.settingsSurfaceBlur,
                    subtitle: l.settingsSurfaceBlurDesc,
                    value: value,
                    onChanged: _settingsSetSurfaceBlurEnabled,
                  );
                },
              ),
            SettingsTile(
              icon: Icons.rounded_corner_rounded,
              iconBackgroundColor: cs.primaryContainer.withValues(
                alpha: 0.7,
              ),
              iconColor: cs.onPrimaryContainer,
              title: l.settingsSurfaceCorners,
              subtitle: _surfaceCornerModeLabel(l, cornerMode),
              onTap: () => _showSurfaceCornerModeDialog(context),
            ),
            if (cornerMode == 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: ValueListenableBuilder<int>(
                  valueListenable: surfaceCornerRadiusNotifier,
                  builder: (context, radius, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.settingsSurfaceCornerRadius}: $radius px',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                        HapticSlider(
                          value: radius.toDouble(),
                          min: 0,
                          max: 48,
                          divisions: 48,
                          label: '$radius px',
                          onChanged: _settingsSetSurfaceCornerRadius,
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (capabilities.supportsBlur)
              SettingsSwitchTile(
                icon: Icons.blur_linear_rounded,
                iconBackgroundColor: cs.secondaryContainer.withValues(
                  alpha: 0.7,
                ),
                iconColor: cs.onSecondaryContainer,
                title: l.settingsAppBgBlur,
                subtitle: l.settingsAppBgBlurDesc,
                value: appBgBlurEnabled,
                onChanged: _settingsSetAppBgBlurEnabled,
              ),
            if (capabilities.supportsBlur && appBgBlurEnabled)
              Padding(
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
                        return HapticSlider(
                          value: amount,
                          min: 0,
                          max: 40,
                          onChanged: _settingsSetAppBgBlurAmount,
                        );
                      },
                    ),
                  ],
                ),
              ),
              ],
            );
          },
        ),

        if (capabilities.supportsBackgroundMotion ||
            capabilities.supportsCustomBackgrounds)
          ValueListenableBuilder<bool>(
            valueListenable: backgroundAnimationsNotifier,
            builder: (context, animationsEnabled, _) => SettingsGroup(
              title: l.settingsBackgroundAnimations,
              children: [
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
                      _buildBouncyRoute(const CustomBackgroundEditorScreen()),
                    );
                  },
                ),
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
              if (capabilities.supportsBackgroundMotion && animationsEnabled)
                ValueListenableBuilder<int>(
                  valueListenable: backgroundAnimationStyleNotifier,
                  builder: (context, style, _) {
                    return SettingsTile(
                      icon: Icons.style_rounded,
                      iconBackgroundColor: cs.tertiaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onTertiaryContainer,
                      title: l.settingsBackgroundStyle,
                      subtitle: _backgroundStyleLabel(l, style),
                      onTap: () => _showBackgroundStyleDialog(context),
                    );
                  },
                ),
              if (capabilities.supportsBackgroundMotion && animationsEnabled)
                ValueListenableBuilder<bool>(
                  valueListenable: backgroundGyroscopeNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.screen_rotation_rounded,
                      iconBackgroundColor: cs.tertiaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onTertiaryContainer,
                      title: l.settingsBackgroundGyroscope,
                      subtitle: l.settingsBackgroundGyroscopeDesc,
                      value: value,
                      onChanged: _settingsSetBackgroundGyroscope,
                    );
                  },
                ),
            ],
          ),
          ),

        SettingsGroup(
          title: l.settingsAppearanceMotion,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: glowEffectsEnabledNotifier,
              builder: (context, glowEnabled, _) {
                return SettingsSwitchTile(
                  icon: Icons.flare_rounded,
                  iconBackgroundColor: cs.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onTertiaryContainer,
                  title: l.settingsGlowEffects,
                  subtitle: l.settingsGlowEffectsDesc,
                  value: glowEnabled,
                  onChanged: _settingsSetGlowEffectsEnabled,
                );
              },
            ),
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
            ValueListenableBuilder<bool>(
              valueListenable: swipeBackGestureNotifier,
              builder: (context, enabled, _) {
                return SettingsSwitchTile(
                  icon: Icons.swipe_left_rounded,
                  iconBackgroundColor: cs.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onTertiaryContainer,
                  title: l.settingsSwipeBack,
                  subtitle: l.settingsSwipeBackDesc,
                  value: enabled,
                  onChanged: _settingsSetSwipeBackGesture,
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: mainTabFadeUpEnabledNotifier,
              builder: (context, enabled, _) {
                return SettingsSwitchTile(
                  icon: Icons.motion_photos_auto_rounded,
                  iconBackgroundColor: cs.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onTertiaryContainer,
                  title: l.settingsMainTabFadeUp,
                  subtitle: l.settingsMainTabFadeUpDesc,
                  value: enabled,
                  onChanged: _settingsSetMainTabFadeUpEnabled,
                );
              },
            ),
          ],
        ),

        ValueListenableBuilder<bool>(
          valueListenable: monochromeLessonsNotifier,
          builder: (context, monochromeEnabled, _) => SettingsGroup(
            title: l.settingsAppearanceTimetable,
            children: [
              SettingsSwitchTile(
                icon: Icons.tonality_rounded,
                iconBackgroundColor: cs.surfaceContainerHighest,
                iconColor: cs.onSurfaceVariant,
                title: l.settingsMonochromeLessons,
                subtitle: l.settingsMonochromeLessonsDesc,
                value: monochromeEnabled,
                onChanged: _settingsSetMonochromeLessons,
              ),
              if (monochromeEnabled)
                ValueListenableBuilder<int>(
                  valueListenable: monochromeLessonColorNotifier,
                  builder: (context, color, _) => SettingsTile(
                    icon: Icons.palette_rounded,
                    iconBackgroundColor: Color(color).withValues(alpha: 0.18),
                    iconColor: Color(color),
                    title: l.settingsCustomColor,
                    subtitle:
                        '#${color.toRadixString(16).substring(2).toUpperCase()}',
                    onTap: () => _showMonochromeLessonColorDialog(context),
                  ),
                ),
            ],
          ),
        ),

        SettingsGroup(
          title: l.settingsAppearanceApp,
          children: [
            SettingsTile(
              icon: Icons.app_shortcut_rounded,
              iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
              iconColor: cs.onSecondaryContainer,
              title: l.appearanceAppIcon,
              subtitle: !kIsWeb
                  ? l.appearanceIconChoose
                  : l.appearanceIconAndroidOnly,
              onTap: !kIsWeb ? () => _showAppIconDialog(context) : null,
            ),
            SettingsTile(
              icon: Icons.translate_rounded,
              iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
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
    );
  }
}
