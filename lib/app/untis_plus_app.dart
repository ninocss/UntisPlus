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
                  final tokens = AppDesignTokens.fromScheme(scheme);

                  return ThemeData(
                    useMaterial3: true,
                    colorScheme: scheme,
                    extensions: <ThemeExtension<dynamic>>[tokens],
                    scaffoldBackgroundColor: Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.04),
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
                        TargetPlatform.android: _BouncyPageTransitionsBuilder(),
                        TargetPlatform.iOS: _BouncyPageTransitionsBuilder(),
                        TargetPlatform.windows: _BouncyPageTransitionsBuilder(),
                        TargetPlatform.macOS: _BouncyPageTransitionsBuilder(),
                        TargetPlatform.linux: _BouncyPageTransitionsBuilder(),
                      },
                    ),
                    appBarTheme: AppBarTheme(
                      centerTitle: true,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      titleTextStyle: baseText.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
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
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 
                        0.6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
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
                      labelTextStyle: WidgetStatePropertyAll(
                        baseText.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        textStyle: baseText.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            tokens.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        textStyle: baseText.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    chipTheme: ChipThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          tokens.radiusMedium,
                        ),
                      ),
                      labelStyle: baseText.labelLarge,
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

class _BouncyPageTransitionsBuilder extends PageTransitionsBuilder {
  const _BouncyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: _kSoftBounce);
    final scale = Tween<double>(begin: 0.965, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: _kSmoothBounce),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.028),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: _kSmoothBounce));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }
}

