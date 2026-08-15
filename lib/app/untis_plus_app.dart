part of '../main.dart';

class UntisPlusApp extends StatelessWidget {
  final Widget startScreen;
  const UntisPlusApp({super.key, required this.startScreen});

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
                return ValueListenableBuilder<int>(
                  valueListenable: customColorSeedNotifier,
                  builder: (context, seed, _) {
                    return DynamicColorBuilder(
                      builder: (lightDynamic, darkDynamic) {

                        final lightScheme = (useMaterialYou && lightDynamic != null)
                            ? lightDynamic.harmonized()
                            : (useMaterialYou && darkDynamic != null)
                                ? ColorScheme.fromSeed(
                                    seedColor: darkDynamic.primary,
                                    brightness: Brightness.light,
                                    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                                  )
                                : ColorScheme.fromSeed(
                                    seedColor: Color(seed),
                                    brightness: Brightness.light,
                                    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                                  );
                        final darkScheme = (useMaterialYou && darkDynamic != null)
                            ? darkDynamic.harmonized()
                            : (useMaterialYou && lightDynamic != null)
                                ? ColorScheme.fromSeed(
                                    seedColor: lightDynamic.primary,
                                    brightness: Brightness.dark,
                                    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                                  )
                                : ColorScheme.fromSeed(
                                    seedColor: Color(seed),
                                    brightness: Brightness.dark,
                                    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                                  );

                        ThemeData themeFrom(ColorScheme scheme) {
                          // Standard Material 3 Typography based on GoogleFonts.outfit for brand identity
                          final baseText = GoogleFonts.outfitTextTheme(
                            ThemeData(
                              useMaterial3: true,
                              colorScheme: scheme,
                            ).textTheme,
                          );

                          return ThemeData(
                            useMaterial3: true,
                            colorScheme: scheme,
                            scaffoldBackgroundColor: scheme.surfaceContainerLowest,
                            textTheme: baseText,
                            cardTheme: CardThemeData(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              clipBehavior: Clip.antiAlias,
                              elevation: 0,
                              color: scheme.surfaceContainerLow,
                            ),
                            dialogTheme: DialogThemeData(
                              backgroundColor: scheme.surfaceContainerHigh,
                              surfaceTintColor: scheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            bottomSheetTheme: BottomSheetThemeData(
                              backgroundColor: scheme.surfaceContainerLow,
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                            ),
                            elevatedButtonTheme: ElevatedButtonThemeData(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                elevation: 0,
                                backgroundColor: scheme.surfaceContainerHigh,
                                foregroundColor: scheme.onSurface,
                              ),
                            ),
                            outlinedButtonTheme: OutlinedButtonThemeData(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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

                        final l = AppL10n.of(locale);

                        return MaterialApp(
                          debugShowCheckedModeBanner: false,
                          title: l.appName,
                          theme: themeFrom(lightScheme),
                          darkTheme: themeFrom(darkScheme),
                          themeMode: themeMode,
                          builder: (context, child) {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            final overlayStyle = SystemUiOverlayStyle(
                              statusBarColor: Colors.transparent,
                              statusBarIconBrightness: isDark
                                  ? Brightness.light
                                  : Brightness.dark,
                              statusBarBrightness: isDark
                                  ? Brightness.dark
                                  : Brightness.light,
                              systemNavigationBarColor: Colors.transparent,
                              systemNavigationBarIconBrightness: isDark
                                  ? Brightness.light
                                  : Brightness.dark,
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
  }
}
