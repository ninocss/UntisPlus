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
                      displayLarge: baseText.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                      displayMedium: baseText.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      headlineLarge: baseText.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      headlineMedium: baseText.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                      headlineSmall: baseText.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      titleLarge: baseText.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      titleMedium: baseText.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      titleSmall: baseText.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      labelLarge: baseText.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                      bodyLarge: baseText.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
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
                      centerTitle: false,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      titleTextStyle: baseText.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        fontSize: 22,
                      ),
                    ),
                    cardTheme: CardThemeData(
                      color: scheme.surfaceContainer,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusLarge),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    navigationBarTheme: NavigationBarThemeData(
                      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                      height: 80,
                      indicatorColor: scheme.secondaryContainer,
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusLarge),
                      ),
                      labelTextStyle: WidgetStatePropertyAll(
                        baseText.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        minimumSize: const Size(64, 48),
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        minimumSize: const Size(64, 48),
                      ),
                    ),
                    outlinedButtonTheme: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                        textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        minimumSize: const Size(64, 48),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        ),
                      ),
                    ),
                    segmentedButtonTheme: SegmentedButtonThemeData(
                      style: SegmentedButton.styleFrom(
                        textStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusLarge),
                        ),
                        selectedBackgroundColor: scheme.secondaryContainer,
                        selectedForegroundColor: scheme.onSecondaryContainer,
                      ),
                    ),
                    sliderTheme: SliderThemeData(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                      activeTrackColor: scheme.primary,
                      inactiveTrackColor: scheme.surfaceContainerHighest,
                      thumbColor: scheme.primary,
                      overlayColor: scheme.primary.withValues(alpha: 0.12),
                    ),
                    switchTheme: SwitchThemeData(
                      thumbColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline),
                      trackColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest),
                    ),
                    dialogTheme: DialogThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusXLarge),
                      ),
                      backgroundColor: scheme.surfaceContainerHigh,
                      elevation: 0,
                    ),
                    bottomSheetTheme: BottomSheetThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(tokens.radiusXLarge),
                        ),
                      ),
                      backgroundColor: scheme.surfaceContainerLow,
                      elevation: 0,
                    ),
                    chipTheme: ChipThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusLarge),
                      ),
                      labelStyle: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                    listTileTheme: ListTileThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    ),
                    dividerTheme: DividerThemeData(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      thickness: 1,
                      space: 1,
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
    final scale = Tween<double>(
      begin: 0.965,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: _kSmoothBounce));
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
