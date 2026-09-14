part of '../main.dart';

enum AppThemeId { defaultTheme, manga, glass, cyber }

extension AppThemeIdX on AppThemeId {
  String get storageKey => switch (this) {
    AppThemeId.defaultTheme => 'default',
    AppThemeId.manga => 'manga',
    AppThemeId.glass => 'glass',
    AppThemeId.cyber => 'cyber',
  };

  static AppThemeId fromStorage(String? value) => AppThemeId.values.firstWhere(
    (theme) => theme.storageKey == value,
    orElse: () => AppThemeId.defaultTheme,
  );

  static bool isSupportedStorageKey(String key) =>
      AppThemeId.values.any((theme) => theme.storageKey == key);

  static bool isRemovedStorageKey(String? value) =>
      value == 'vivid' || value == 'paper';

  static Map<String, bool> normalizeBlurPreferences(
    Map? values, {
    required bool defaultThemeBlur,
  }) {
    final normalized = <String, bool>{
      AppThemeId.defaultTheme.storageKey: defaultThemeBlur,
      AppThemeId.glass.storageKey: true,
      AppThemeId.cyber.storageKey: true,
    };
    values?.forEach((key, value) {
      if (key is String && value is bool && isSupportedStorageKey(key)) {
        normalized[key] = value;
      }
    });
    return normalized;
  }
}

@immutable
class AppThemeCapabilities {
  final bool supportsBlur;
  final bool supportsCustomBackgrounds;
  final bool supportsBackgroundMotion;
  final bool supportsMaterialYou;
  final bool supportsExpressiveComponents;
  final bool supportsAdvancedLessonStyle;

  const AppThemeCapabilities({
    required this.supportsBlur,
    required this.supportsCustomBackgrounds,
    required this.supportsBackgroundMotion,
    required this.supportsMaterialYou,
    required this.supportsExpressiveComponents,
    required this.supportsAdvancedLessonStyle,
  });
}

AppThemeCapabilities appThemeCapabilities(AppThemeId theme) => switch (theme) {
  AppThemeId.defaultTheme => const AppThemeCapabilities(
    supportsBlur: true,
    supportsCustomBackgrounds: true,
    supportsBackgroundMotion: true,
    supportsMaterialYou: true,
    supportsExpressiveComponents: true,
    supportsAdvancedLessonStyle: true,
  ),
  AppThemeId.glass => const AppThemeCapabilities(
    supportsBlur: true,
    supportsCustomBackgrounds: true,
    supportsBackgroundMotion: true,
    supportsMaterialYou: false,
    supportsExpressiveComponents: false,
    supportsAdvancedLessonStyle: false,
  ),
  AppThemeId.cyber => const AppThemeCapabilities(
    supportsBlur: true,
    supportsCustomBackgrounds: false,
    supportsBackgroundMotion: true,
    supportsMaterialYou: false,
    supportsExpressiveComponents: false,
    supportsAdvancedLessonStyle: false,
  ),
  AppThemeId.manga => const AppThemeCapabilities(
    supportsBlur: false,
    supportsCustomBackgrounds: false,
    supportsBackgroundMotion: false,
    supportsMaterialYou: false,
    supportsExpressiveComponents: false,
    supportsAdvancedLessonStyle: false,
  ),
};

@immutable
class UntisThemeTokens extends ThemeExtension<UntisThemeTokens> {
  final AppThemeId id;
  final double surfaceRadius;
  final double controlRadius;
  final double borderWidth;
  final double blurSigma;
  final Offset shadowOffset;
  final Color shadowColor;
  final Color patternColor;
  final List<Color> backdropColors;
  final bool hardShadow;
  final bool glassHighlights;
  final bool glowEffectsEnabled;
  final int motionStyle;
  final double surfaceOpacity;
  final double navigationOpacity;
  final double lessonSurfaceOpacity;

  const UntisThemeTokens({
    required this.id,
    required this.surfaceRadius,
    required this.controlRadius,
    required this.borderWidth,
    required this.blurSigma,
    required this.shadowOffset,
    required this.shadowColor,
    required this.patternColor,
    required this.backdropColors,
    required this.hardShadow,
    required this.glassHighlights,
    this.glowEffectsEnabled = false,
    required this.motionStyle,
    required this.surfaceOpacity,
    required this.navigationOpacity,
    required this.lessonSurfaceOpacity,
  });

  bool get supportsBlur => appThemeCapabilities(id).supportsBlur;
  bool get blurActive => supportsBlur && blurEnabledNotifier.value;

  factory UntisThemeTokens.forTheme(
    AppThemeId id,
    Brightness brightness,
    ColorScheme scheme,
  ) {
    final dark = brightness == Brightness.dark;
    return switch (id) {
      AppThemeId.manga => UntisThemeTokens(
        id: id,
        surfaceRadius: 2,
        controlRadius: 1,
        borderWidth: 2.5,
        blurSigma: 0,
        shadowOffset: const Offset(7, 7),
        shadowColor: dark ? const Color(0xFFEDE2CA) : const Color(0xFF17120C),
        patternColor: dark ? const Color(0x33F5EBD7) : const Color(0x2617120C),
        backdropColors: dark
            ? const [Color(0xFF171511), Color(0xFF242019)]
            : const [Color(0xFFF4ECDD), Color(0xFFECE1CD)],
        hardShadow: true,
        glassHighlights: false,
        motionStyle: 1,
        surfaceOpacity: 0.72,
        navigationOpacity: 0.66,
        lessonSurfaceOpacity: 1,
      ),
      AppThemeId.glass => UntisThemeTokens(
        id: id,
        surfaceRadius: 34,
        controlRadius: 25,
        borderWidth: 1,
        blurSigma: 32,
        shadowOffset: const Offset(0, 12),
        shadowColor: scheme.shadow.withValues(alpha: dark ? 0.26 : 0.12),
        patternColor: Colors.white.withValues(alpha: dark ? 0.08 : 0.24),
        backdropColors: dark
            ? const [Color(0xFF0B1425), Color(0xFF1A2B50), Color(0xFF3A2850)]
            : const [Color(0xFFE5F3FF), Color(0xFFF0EBFF), Color(0xFFE4FFF7)],
        hardShadow: false,
        glassHighlights: true,
        motionStyle: 3,
        surfaceOpacity: 0.68,
        navigationOpacity: 0.72,
        lessonSurfaceOpacity: 0.74,
      ),
      AppThemeId.cyber => UntisThemeTokens(
        id: id,
        surfaceRadius: 12,
        controlRadius: 8,
        borderWidth: 1.2,
        blurSigma: 10,
        shadowOffset: const Offset(0, 8),
        shadowColor: const Color(0x3300DDEB),
        patternColor: (dark ? const Color(0xFF6EEAF2) : const Color(0xFF006D75))
            .withValues(alpha: 0.08),
        backdropColors: dark
            ? const [Color(0xFF071015), Color(0xFF0B2026)]
            : const [Color(0xFFF1FBFC), Color(0xFFDCEDEF)],
        hardShadow: false,
        glassHighlights: false,
        motionStyle: 4,
        surfaceOpacity: 0.86,
        navigationOpacity: 0.88,
        lessonSurfaceOpacity: 0.88,
      ),
      AppThemeId.defaultTheme => UntisThemeTokens(
        id: id,
        surfaceRadius: 28,
        controlRadius: 24,
        borderWidth: 1,
        blurSigma: 30,
        shadowOffset: const Offset(0, 8),
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        patternColor: scheme.primary.withValues(alpha: 0.12),
        backdropColors: [scheme.surface, scheme.surfaceContainerLowest],
        hardShadow: false,
        glassHighlights: false,
        motionStyle: 0,
        surfaceOpacity: 0.72,
        navigationOpacity: 0.68,
        lessonSurfaceOpacity: 0.82,
      ),
    };
  }

  @override
  UntisThemeTokens copyWith({
    AppThemeId? id,
    double? surfaceRadius,
    double? controlRadius,
    double? borderWidth,
    double? blurSigma,
    Offset? shadowOffset,
    Color? shadowColor,
    Color? patternColor,
    List<Color>? backdropColors,
    bool? hardShadow,
    bool? glassHighlights,
    bool? glowEffectsEnabled,
    int? motionStyle,
    double? surfaceOpacity,
    double? navigationOpacity,
    double? lessonSurfaceOpacity,
  }) => UntisThemeTokens(
    id: id ?? this.id,
    surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    controlRadius: controlRadius ?? this.controlRadius,
    borderWidth: borderWidth ?? this.borderWidth,
    blurSigma: blurSigma ?? this.blurSigma,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    shadowColor: shadowColor ?? this.shadowColor,
    patternColor: patternColor ?? this.patternColor,
    backdropColors: backdropColors ?? this.backdropColors,
    hardShadow: hardShadow ?? this.hardShadow,
    glassHighlights: glassHighlights ?? this.glassHighlights,
    glowEffectsEnabled: glowEffectsEnabled ?? this.glowEffectsEnabled,
    motionStyle: motionStyle ?? this.motionStyle,
    surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
    navigationOpacity: navigationOpacity ?? this.navigationOpacity,
    lessonSurfaceOpacity: lessonSurfaceOpacity ?? this.lessonSurfaceOpacity,
  );

  @override
  UntisThemeTokens lerp(covariant UntisThemeTokens? other, double t) {
    if (other == null || other.id != id) return this;
    return UntisThemeTokens(
      id: id,
      surfaceRadius: lerpDouble(surfaceRadius, other.surfaceRadius, t)!,
      controlRadius: lerpDouble(controlRadius, other.controlRadius, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      shadowOffset: Offset.lerp(shadowOffset, other.shadowOffset, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      patternColor: Color.lerp(patternColor, other.patternColor, t)!,
      backdropColors: backdropColors,
      hardShadow: hardShadow,
      glassHighlights: glassHighlights,
      glowEffectsEnabled: t < 0.5
          ? glowEffectsEnabled
          : other.glowEffectsEnabled,
      motionStyle: motionStyle,
      surfaceOpacity: lerpDouble(surfaceOpacity, other.surfaceOpacity, t)!,
      navigationOpacity: lerpDouble(
        navigationOpacity,
        other.navigationOpacity,
        t,
      )!,
      lessonSurfaceOpacity: lerpDouble(
        lessonSurfaceOpacity,
        other.lessonSurfaceOpacity,
        t,
      )!,
    );
  }
}

ColorScheme untisThemeScheme(AppThemeId id, Brightness brightness, int seed) {
  final dark = brightness == Brightness.dark;
  final seedColor = switch (id) {
    AppThemeId.defaultTheme => Color(seed),
    AppThemeId.manga =>
      dark ? const Color(0xFFE9D9B8) : const Color(0xFF17120C),
    AppThemeId.glass =>
      dark ? const Color(0xFF9ACBFF) : const Color(0xFF2A63D5),
    AppThemeId.cyber =>
      dark ? const Color(0xFF6EEAF2) : const Color(0xFF006D75),
  };
  var scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  if (id == AppThemeId.manga) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFFF5EBD7) : const Color(0xFF17120C),
      onPrimary: dark ? const Color(0xFF17120C) : const Color(0xFFF8F0DF),
      surface: dark ? const Color(0xFF171511) : const Color(0xFFF4ECDD),
      onSurface: dark ? const Color(0xFFF5EBD7) : const Color(0xFF17120C),
      outline: dark ? const Color(0xFFF5EBD7) : const Color(0xFF17120C),
    );
  } else if (id == AppThemeId.glass) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFF9ACBFF) : const Color(0xFF2A63D5),
      primaryContainer: dark
          ? const Color(0xFF1E4778)
          : const Color(0xFFDCE8FF),
      secondary: dark ? const Color(0xFFD0BEFF) : const Color(0xFF705AAE),
      secondaryContainer: dark
          ? const Color(0xFF443764)
          : const Color(0xFFEEE7FF),
      tertiary: dark ? const Color(0xFF8DE2D0) : const Color(0xFF1D7F6D),
      tertiaryContainer: dark
          ? const Color(0xFF1B5149)
          : const Color(0xFFCFF7ED),
      surface: dark ? const Color(0xFF0B1425) : const Color(0xFFF5F8FF),
      surfaceContainerLowest: dark ? const Color(0xFF07101E) : Colors.white,
      surfaceContainerLow: dark
          ? const Color(0xFF12203A)
          : const Color(0xFFEDF4FD),
      surfaceContainer: dark
          ? const Color(0xFF192945)
          : const Color(0xFFE6EFFA),
      surfaceContainerHigh: dark
          ? const Color(0xFF233553)
          : const Color(0xFFDFEAF6),
      surfaceContainerHighest: dark
          ? const Color(0xFF2E4264)
          : const Color(0xFFD5E3F0),
      onSurface: dark ? const Color(0xFFF2F6FF) : const Color(0xFF17233B),
      onSurfaceVariant: dark
          ? const Color(0xFFC6D2E6)
          : const Color(0xFF52637D),
      outline: dark ? const Color(0xFF9AACCA) : const Color(0xFF6E809C),
      outlineVariant: dark ? const Color(0xFF435574) : const Color(0xFFC3D0E0),
    );
  } else if (id == AppThemeId.cyber) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFF6EEAF2) : const Color(0xFF006D75),
      onPrimary: dark ? const Color(0xFF002528) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF06464C)
          : const Color(0xFFBDEEF0),
      secondary: dark ? const Color(0xFFE285BF) : const Color(0xFF9B3E76),
      secondaryContainer: dark
          ? const Color(0xFF552343)
          : const Color(0xFFF8D8E8),
      tertiary: dark ? const Color(0xFFA3D7D9) : const Color(0xFF3B7075),
      tertiaryContainer: dark
          ? const Color(0xFF214044)
          : const Color(0xFFD8EFF0),
      surface: dark ? const Color(0xFF071015) : const Color(0xFFF1FBFC),
      surfaceContainerLowest: dark ? const Color(0xFF03090C) : Colors.white,
      surfaceContainerLow: dark
          ? const Color(0xFF0B1A20)
          : const Color(0xFFE8F4F5),
      surfaceContainer: dark
          ? const Color(0xFF10242B)
          : const Color(0xFFDFEFF0),
      surfaceContainerHigh: dark
          ? const Color(0xFF173139)
          : const Color(0xFFD6E8EA),
      surfaceContainerHighest: dark
          ? const Color(0xFF203E46)
          : const Color(0xFFC9DEE1),
      onSurface: dark ? const Color(0xFFE9F7F8) : const Color(0xFF10272B),
      onSurfaceVariant: dark
          ? const Color(0xFFB8CDD0)
          : const Color(0xFF426166),
      outline: dark ? const Color(0xFF78B6BB) : const Color(0xFF527D82),
      outlineVariant: dark ? const Color(0xFF2E565B) : const Color(0xFFB9D1D3),
    );
  }
  return scheme;
}

TextTheme untisThemeTextTheme(AppThemeId id, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
  final body = GoogleFonts.outfitTextTheme(base);
  if (id != AppThemeId.manga && id != AppThemeId.cyber) {
    return body;
  }
  final display = switch (id) {
    AppThemeId.manga => GoogleFonts.bebasNeueTextTheme(base),
    AppThemeId.cyber => GoogleFonts.ibmPlexMonoTextTheme(base),
    _ => body,
  };
  return body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge,
    headlineMedium: display.headlineMedium,
    headlineSmall: display.headlineSmall,
    titleLarge: display.titleLarge?.copyWith(
      letterSpacing: id == AppThemeId.cyber ? 0.8 : 0.2,
    ),
  );
}

TextStyle untisThemeTextStyle(
  BuildContext context, {
  bool display = false,
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
  Color? decorationColor,
  double? decorationThickness,
}) {
  final textTheme = Theme.of(context).textTheme;
  final base = display ? textTheme.titleLarge : textTheme.bodyMedium;
  return (base ?? const TextStyle()).copyWith(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationThickness: decorationThickness,
  );
}

UntisThemeTokens untisThemeTokensOf(BuildContext context) =>
    Theme.of(context).extension<UntisThemeTokens>() ??
    UntisThemeTokens.forTheme(
      AppThemeId.defaultTheme,
      Theme.of(context).brightness,
      Theme.of(context).colorScheme,
    );

class _ThemePatternPainter extends CustomPainter {
  final UntisThemeTokens tokens;
  const _ThemePatternPainter(this.tokens);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = tokens.patternColor;
    if (tokens.id == AppThemeId.manga) {
      paint.strokeWidth = 1;
      for (double x = 0; x < size.width; x += 54) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 54) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      for (double x = 6; x < size.width; x += 12) {
        for (double y = 6; y < size.height; y += 12) {
          canvas.drawCircle(Offset(x, y), 0.75, paint);
        }
      }
    } else if (tokens.id == AppThemeId.cyber) {
      paint.strokeWidth = 0.8;
      for (double x = 0; x < size.width; x += 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThemePatternPainter oldDelegate) =>
      oldDelegate.tokens.id != tokens.id ||
      oldDelegate.tokens.patternColor != tokens.patternColor;
}

class ThemedBackdrop extends StatelessWidget {
  final Widget child;
  final bool animate;
  final int? backgroundStyle;
  const ThemedBackdrop({
    super.key,
    required this.child,
    required this.animate,
    this.backgroundStyle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = untisThemeTokensOf(context);
    if (tokens.id == AppThemeId.defaultTheme) return child;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final themeSceneStyle = switch (tokens.id) {
      AppThemeId.glass => 0,
      AppThemeId.cyber => 8,
      _ => -1,
    };
    // Keep each art style's colors, but let every animated style use the
    // selected motion scene. This makes the appearance setting persistent
    // instead of silently disappearing after a theme switch.
    final sceneStyle = appThemeCapabilities(tokens.id).supportsBackgroundMotion
        ? (backgroundStyle ?? themeSceneStyle)
        : -1;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: tokens.backdropColors,
              ),
            ),
          ),
        ),
        if (sceneStyle >= 0 && animate && !reduceMotion)
          Positioned.fill(
            child: Opacity(
              opacity: tokens.id == AppThemeId.cyber ? 0.22 : 0.46,
              child: _AnimatedBackgroundScene(style: sceneStyle),
            ),
          ),
        if (tokens.id == AppThemeId.manga || tokens.id == AppThemeId.cyber)
          Positioned.fill(
            child: CustomPaint(painter: _ThemePatternPainter(tokens)),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}
