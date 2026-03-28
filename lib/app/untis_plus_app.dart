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
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                final lightScheme =
                    lightDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: const Color(0xFF0F766E),
                      brightness: Brightness.light,
                    );
                final darkScheme =
                    darkDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: const Color(0xFF0F766E),
                      brightness: Brightness.dark,
                    );

                ThemeData themeFrom(ColorScheme scheme) {
                  final baseText =
                      GoogleFonts.outfitTextTheme(
                        ThemeData(
                          useMaterial3: true,
                          colorScheme: scheme,
                        ).textTheme,
                      ).apply(
                        bodyColor: scheme.onSurface,
                        displayColor: scheme.onSurface,
                      );

                  return ThemeData(
                    useMaterial3: true,
                    colorScheme: scheme,
                    scaffoldBackgroundColor: Color.alphaBlend(
                      scheme.primary.withOpacity(0.04),
                      scheme.surface,
                    ),
                    textTheme: baseText.copyWith(
                      headlineMedium: baseText.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      titleLarge: baseText.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                      titleMedium: baseText.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    pageTransitionsTheme: const PageTransitionsTheme(
                      builders: {
                        TargetPlatform.android: ZoomPageTransitionsBuilder(),
                        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                      },
                    ),
                    appBarTheme: AppBarTheme(
                      centerTitle: true,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      titleTextStyle: GoogleFonts.outfit(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -0.4,
                      ),
                    ),
                    cardTheme: CardThemeData(
                      color: scheme.surfaceContainer,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: scheme.outlineVariant.withOpacity(0.35),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withOpacity(
                        0.6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withOpacity(0.45),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withOpacity(0.45),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: scheme.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                    navigationBarTheme: NavigationBarThemeData(
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      height: 80,
                      indicatorColor: scheme.secondaryContainer,
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelTextStyle: WidgetStateProperty.all(
                        GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Untis+',
                  theme: themeFrom(lightScheme),
                  darkTheme: themeFrom(darkScheme),
                  themeMode: themeMode,
                  builder: (context, child) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
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
  }
}

