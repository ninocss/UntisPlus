part of '../main.dart';

class UntisPlusApp extends StatelessWidget {
  final Widget startScreen;
  const UntisPlusApp({super.key, required this.startScreen});

  ThemeData _themeFrom(ColorScheme scheme, bool isAmoled, bool blurEnabled) {
    final baseText = GoogleFonts.outfitTextTheme(
      ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
      ).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: (isAmoled && scheme.brightness == Brightness.dark)
          ? Colors.black
          : scheme.surfaceContainerLowest,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 4,
        surfaceTintColor: scheme.primary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: scheme.primary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: scheme.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onSecondaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: blurEnabled
            ? scheme.surfaceContainerLow.withValues(alpha: 0.8)
            : scheme.surfaceContainerLow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: blurEnabled
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.85)
            : scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: blurEnabled
            ? scheme.surfaceContainerLow.withValues(alpha: 0.85)
            : scheme.surfaceContainerLow,
        surfaceTintColor: scheme.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
          backgroundColor: scheme.surfaceContainerHigh,
          foregroundColor: scheme.onSurface,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                final lightScheme = (useMaterialYou &&
                                        lightDynamic != null)
                                    ? lightDynamic.harmonized()
                                    : (useMaterialYou && darkDynamic != null)
                                        ? ColorScheme.fromSeed(
                                            seedColor: darkDynamic.primary,
                                            brightness: Brightness.light,
                                            dynamicSchemeVariant:
                                                DynamicSchemeVariant.vibrant,
                                          )
                                        : ColorScheme.fromSeed(
                                            seedColor: Color(seed),
                                            brightness: Brightness.light,
                                            dynamicSchemeVariant:
                                                DynamicSchemeVariant.vibrant,
                                          );

                                var darkScheme = (useMaterialYou &&
                                        darkDynamic != null)
                                    ? darkDynamic.harmonized()
                                    : (useMaterialYou && lightDynamic != null)
                                        ? ColorScheme.fromSeed(
                                            seedColor: lightDynamic.primary,
                                            brightness: Brightness.dark,
                                            dynamicSchemeVariant:
                                                DynamicSchemeVariant.vibrant,
                                          )
                                        : ColorScheme.fromSeed(
                                            seedColor: Color(seed),
                                            brightness: Brightness.dark,
                                            dynamicSchemeVariant:
                                                DynamicSchemeVariant.vibrant,
                                          );

                                if (isAmoled) {
                                  darkScheme = darkScheme.copyWith(
                                    surface: Colors.black,
                                    surfaceContainerLowest: Colors.black,
                                    surfaceContainerLow: Color.alphaBlend(
                                        darkScheme.primary.withValues(alpha: 0.08),
                                        const Color(0xFF0A0A0A)),
                                    surfaceContainer: Color.alphaBlend(
                                        darkScheme.primary.withValues(alpha: 0.12),
                                        const Color(0xFF111111)),
                                    surfaceContainerHigh: Color.alphaBlend(
                                        darkScheme.primary.withValues(alpha: 0.16),
                                        const Color(0xFF1A1A1A)),
                                    surfaceContainerHighest: Color.alphaBlend(
                                        darkScheme.primary.withValues(alpha: 0.20),
                                        const Color(0xFF222222)),
                                  );
                                }

                                final l = AppL10n.of(locale);

                                return MaterialApp(
                                  debugShowCheckedModeBanner: false,
                                  title: l.appName,
                                  theme: _themeFrom(lightScheme, isAmoled, blurEnabled),
                                  darkTheme: _themeFrom(darkScheme, isAmoled, blurEnabled),
                                  themeMode: themeMode,
                                  builder: (context, child) {
                                    final isDark = Theme.of(context).brightness ==
                                        Brightness.dark;
                                    final overlayStyle = SystemUiOverlayStyle(
                                      statusBarColor: Colors.transparent,
                                      statusBarIconBrightness:
                                          isDark ? Brightness.light : Brightness.dark,
                                      statusBarBrightness:
                                          isDark ? Brightness.dark : Brightness.light,
                                      systemNavigationBarColor: Colors.transparent,
                                      systemNavigationBarIconBrightness:
                                          isDark ? Brightness.light : Brightness.dark,
                                    );
                                    return AnnotatedRegion<SystemUiOverlayStyle>(
                                      value: overlayStyle,
                                      child: child ?? const SizedBox.shrink(),
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
  }
}
