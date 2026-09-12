part of '../main.dart';

class UntisPlusApp extends StatelessWidget {
  final Widget startScreen;
  const UntisPlusApp({super.key, required this.startScreen});

  ThemeData _themeFrom(
    ColorScheme scheme,
    bool isAmoled,
    bool blurEnabled,
    bool glowEffectsEnabled,
    AppThemeId visualTheme,
  ) {
    final tokens = UntisThemeTokens.forTheme(
      visualTheme,
      scheme.brightness,
      scheme,
    ).copyWith(glowEffectsEnabled: glowEffectsEnabled);
    final expressive = appThemeCapabilities(
      visualTheme,
    ).supportsExpressiveComponents;
    final useBlur = blurEnabled && tokens.supportsBlur;
    final baseText = untisThemeTextTheme(visualTheme, scheme.brightness);
    final controlShape = expressive
        ? WidgetStateProperty.resolveWith<OutlinedBorder>((states) {
            if (states.contains(WidgetState.pressed)) {
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              );
            }
            return const StadiumBorder();
          })
        : WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.controlRadius),
            ),
          );
    final iconControlShape = expressive
        ? WidgetStateProperty.resolveWith<OutlinedBorder>((states) {
            if (states.contains(WidgetState.pressed)) {
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              );
            }
            return const CircleBorder();
          })
        : controlShape;
    final commonButtonStyle = ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      minimumSize: expressive
          ? const WidgetStatePropertyAll(Size(48, 48))
          : null,
      shape: controlShape,
      animationDuration: expressive ? const Duration(milliseconds: 200) : null,
    );
    TextStyle displayFont({
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
    }) {
      final base = visualTheme == AppThemeId.manga
          ? GoogleFonts.bebasNeue()
          : visualTheme == AppThemeId.cyber
          ? GoogleFonts.ibmPlexMono()
          : GoogleFonts.outfit();
      return base.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [tokens],
      scaffoldBackgroundColor:
          (isAmoled && scheme.brightness == Brightness.dark)
          ? Colors.black
          : scheme.surfaceContainerLowest,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 4,
        surfaceTintColor: scheme.primary,
        centerTitle: true,
        titleTextStyle: displayFont(
          color: scheme.primary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: scheme.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: useBlur
            ? scheme.surfaceContainer.withValues(alpha: 0.68)
            : scheme.surfaceContainer,
        height: expressive ? 76 : null,
        indicatorShape: expressive ? const StadiumBorder() : null,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onSecondaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return displayFont(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            );
          }
          return displayFont(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            expressive ? 28 : tokens.surfaceRadius,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: useBlur
            ? scheme.surfaceContainerLow.withValues(alpha: 0.8)
            : scheme.surfaceContainerLow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: useBlur
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.85)
            : scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            expressive ? 32 : tokens.surfaceRadius + 6,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: useBlur
            ? scheme.surfaceContainerLow.withValues(alpha: 0.85)
            : scheme.surfaceContainerLow,
        surfaceTintColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(expressive ? 32 : tokens.surfaceRadius + 6),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: commonButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: commonButtonStyle.copyWith(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: commonButtonStyle),
      textButtonTheme: TextButtonThemeData(style: commonButtonStyle),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: expressive
              ? const WidgetStatePropertyAll(Size(48, 48))
              : null,
          shape: iconControlShape,
          animationDuration: expressive
              ? const Duration(milliseconds: 200)
              : null,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: expressive ? 0 : null,
        focusElevation: expressive ? 0 : null,
        hoverElevation: expressive ? 1 : null,
        highlightElevation: expressive ? 0 : null,
        shape: expressive ? const CircleBorder() : null,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          shape: expressive
              ? const StadiumBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: expressive
            ? const StadiumBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.controlRadius),
              ),
        side: BorderSide(color: scheme.outlineVariant),
        padding: EdgeInsets.symmetric(
          horizontal: expressive ? 12 : 8,
          vertical: expressive ? 8 : 4,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return scheme.outline.withValues(alpha: 0.5);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: expressive ? null : scheme.primary,
        inactiveTrackColor: expressive ? null : scheme.surfaceContainerHighest,
        thumbColor: expressive ? null : scheme.primary,
        overlayColor: expressive
            ? null
            : scheme.primary.withValues(alpha: 0.12),
        // ignore: deprecated_member_use
        year2023: expressive ? false : true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.secondaryContainer,
        refreshBackgroundColor: scheme.surfaceContainerHigh,
        // Flutter 3.47 still requires this transitional flag for the latest
        // native Material progress indicator geometry.
        // ignore: deprecated_member_use
        year2023: expressive ? false : true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: expressive,
        fillColor: expressive ? scheme.surfaceContainerHighest : null,
        border: expressive
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              )
            : null,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            expressive ? 24 : tokens.controlRadius,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeId>(
      valueListenable: visualThemeNotifier,
      builder: (context, visualTheme, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLocaleNotifier,
          builder: (context, locale, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, themeMode, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: useMaterialYouNotifier,
                  builder: (context, useMaterialYou, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: isAmoledNotifier,
                      builder: (context, isAmoled, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: blurEnabledNotifier,
                          builder: (context, blurEnabled, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable: customColorSeedNotifier,
                              builder: (context, seed, _) {
                                return DynamicColorBuilder(
                                  builder: (lightDynamic, darkDynamic) {
                                    final canUseDynamic =
                                        visualTheme == AppThemeId.defaultTheme;
                                    final ColorScheme lightScheme;
                                    if (canUseDynamic &&
                                        useMaterialYou &&
                                        lightDynamic != null) {
                                      lightScheme = ColorScheme.fromSeed(
                                        seedColor: lightDynamic.primary,
                                        brightness: Brightness.light,
                                        dynamicSchemeVariant:
                                            DynamicSchemeVariant.vibrant,
                                      );
                                    } else if (canUseDynamic &&
                                        useMaterialYou &&
                                        darkDynamic != null) {
                                      lightScheme = ColorScheme.fromSeed(
                                        seedColor: darkDynamic.primary,
                                        brightness: Brightness.light,
                                        dynamicSchemeVariant:
                                            DynamicSchemeVariant.vibrant,
                                      );
                                    } else {
                                      lightScheme = untisThemeScheme(
                                        visualTheme,
                                        Brightness.light,
                                        seed,
                                      );
                                    }

                                    ColorScheme darkScheme;
                                    if (canUseDynamic &&
                                        useMaterialYou &&
                                        darkDynamic != null) {
                                      darkScheme = ColorScheme.fromSeed(
                                        seedColor: darkDynamic.primary,
                                        brightness: Brightness.dark,
                                        dynamicSchemeVariant:
                                            DynamicSchemeVariant.vibrant,
                                      );
                                    } else if (canUseDynamic &&
                                        useMaterialYou &&
                                        lightDynamic != null) {
                                      darkScheme = ColorScheme.fromSeed(
                                        seedColor: lightDynamic.primary,
                                        brightness: Brightness.dark,
                                        dynamicSchemeVariant:
                                            DynamicSchemeVariant.vibrant,
                                      );
                                    } else {
                                      darkScheme = untisThemeScheme(
                                        visualTheme,
                                        Brightness.dark,
                                        seed,
                                      );
                                    }

                                    if (isAmoled &&
                                        visualTheme ==
                                            AppThemeId.defaultTheme) {
                                      darkScheme = darkScheme.copyWith(
                                        surface: Colors.black,
                                        surfaceContainerLowest: Colors.black,
                                        surfaceContainerLow: Color.alphaBlend(
                                          darkScheme.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                          const Color(0xFF0A0A0A),
                                        ),
                                        surfaceContainer: Color.alphaBlend(
                                          darkScheme.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          const Color(0xFF111111),
                                        ),
                                        surfaceContainerHigh: Color.alphaBlend(
                                          darkScheme.primary.withValues(
                                            alpha: 0.16,
                                          ),
                                          const Color(0xFF1A1A1A),
                                        ),
                                        surfaceContainerHighest:
                                            Color.alphaBlend(
                                              darkScheme.primary.withValues(
                                                alpha: 0.20,
                                              ),
                                              const Color(0xFF222222),
                                            ),
                                      );
                                    }

                                    final l = AppL10n.of(locale);

                                    return ValueListenableBuilder<bool>(
                                      valueListenable:
                                          glowEffectsEnabledNotifier,
                                      builder: (context, glowEnabled, _) {
                                        return MaterialApp(
                                          debugShowCheckedModeBanner: false,
                                          title: l.appName,
                                          scrollBehavior:
                                              const _UntisScrollBehavior(),
                                          theme: _themeFrom(
                                            lightScheme,
                                            isAmoled,
                                            blurEnabled,
                                            glowEnabled,
                                            visualTheme,
                                          ),
                                          darkTheme: _themeFrom(
                                            darkScheme,
                                            isAmoled,
                                            blurEnabled,
                                            glowEnabled,
                                            visualTheme,
                                          ),
                                          themeMode: themeMode,
                                          themeAnimationDuration: Duration.zero,
                                          builder: (context, child) {
                                            final isDark =
                                                Theme.of(context).brightness ==
                                                Brightness.dark;
                                            final overlayStyle =
                                                SystemUiOverlayStyle(
                                                  statusBarColor:
                                                      Colors.transparent,
                                                  statusBarIconBrightness:
                                                      isDark
                                                      ? Brightness.light
                                                      : Brightness.dark,
                                                  statusBarBrightness: isDark
                                                      ? Brightness.dark
                                                      : Brightness.light,
                                                  systemNavigationBarColor:
                                                      Colors.transparent,
                                                  systemNavigationBarIconBrightness:
                                                      isDark
                                                      ? Brightness.light
                                                      : Brightness.dark,
                                                );
                                            return AnnotatedRegion<
                                              SystemUiOverlayStyle
                                            >(
                                              value: overlayStyle,
                                              child:
                                                  child ??
                                                  const SizedBox.shrink(),
                                            );
                                          },
                                          home: startScreen,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Keeps the platform scroll physics but suppresses Android's overscroll
/// glow/stretch, which otherwise flashes behind text at the end of a page.
class _UntisScrollBehavior extends MaterialScrollBehavior {
  const _UntisScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
