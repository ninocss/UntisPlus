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
                            ? lightDynamic
                            : ColorScheme.fromSeed(
                                seedColor: Color(seed),
                                brightness: Brightness.light,
                                dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                              );
                        final darkScheme = (useMaterialYou && darkDynamic != null)
                            ? darkDynamic
                            : ColorScheme.fromSeed(
                                seedColor: Color(seed),
                                brightness: Brightness.dark,
                                dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                              );

                        ThemeData themeFrom(ColorScheme scheme) {
                          // Standard Material 3 Typography based on GoogleFonts.outfit for brand identity
                          // but without heavy custom overrides.
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
                                borderRadius: BorderRadius.circular(28),
                              ),
                              clipBehavior: Clip.antiAlias,
                              elevation: 0,
                              color: scheme.surfaceContainerLow,
                            ),
                            dialogTheme: DialogThemeData(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            bottomSheetTheme: const BottomSheetThemeData(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32),
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
                            listTileTheme: ListTileThemeData(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
