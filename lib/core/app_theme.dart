part of '../main.dart';

enum AppThemeId { defaultTheme, manga, vivid, glass, cyber, paper }

extension AppThemeIdX on AppThemeId {
  String get storageKey => switch (this) {
    AppThemeId.defaultTheme => 'default',
    AppThemeId.manga => 'manga',
    AppThemeId.vivid => 'vivid',
    AppThemeId.glass => 'glass',
    AppThemeId.cyber => 'cyber',
    AppThemeId.paper => 'paper',
  };

  static AppThemeId fromStorage(String? value) => AppThemeId.values.firstWhere(
    (theme) => theme.storageKey == value,
    orElse: () => AppThemeId.defaultTheme,
  );
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
  AppThemeId.vivid => const AppThemeCapabilities(
    supportsBlur: true,
    supportsCustomBackgrounds: false,
    supportsBackgroundMotion: true,
    supportsMaterialYou: false,
    supportsExpressiveComponents: true,
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
  AppThemeId.manga || AppThemeId.paper => const AppThemeCapabilities(
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
      AppThemeId.vivid => UntisThemeTokens(
        id: id,
        surfaceRadius: 30,
        controlRadius: 26,
        borderWidth: 1.25,
        blurSigma: 22,
        shadowOffset: const Offset(0, 12),
        shadowColor: scheme.secondary.withValues(alpha: dark ? 0.22 : 0.18),
        patternColor: scheme.tertiary.withValues(alpha: dark ? 0.10 : 0.08),
        backdropColors: dark
            ? const [Color(0xFF100C1D), Color(0xFF211135), Color(0xFF082D38)]
            : const [Color(0xFFFFF7FD), Color(0xFFF4E9FF), Color(0xFFE8FBFF)],
        hardShadow: false,
        glassHighlights: false,
        motionStyle: 2,
        surfaceOpacity: 0.82,
        navigationOpacity: 0.78,
        lessonSurfaceOpacity: 0.86,
      ),
      AppThemeId.glass => UntisThemeTokens(
        id: id,
        surfaceRadius: 32,
        controlRadius: 26,
        borderWidth: 1,
        blurSigma: 38,
        shadowOffset: const Offset(0, 14),
        shadowColor: scheme.shadow.withValues(alpha: dark ? 0.30 : 0.14),
        patternColor: Colors.white.withValues(alpha: dark ? 0.12 : 0.42),
        backdropColors: dark
            ? const [Color(0xFF071421), Color(0xFF152642), Color(0xFF281C3D)]
            : const [Color(0xFFD9F2FF), Color(0xFFE9E2FF), Color(0xFFE0FFF6)],
        hardShadow: false,
        glassHighlights: true,
        motionStyle: 3,
        surfaceOpacity: 0.52,
        navigationOpacity: 0.54,
        lessonSurfaceOpacity: 0.62,
      ),
      AppThemeId.cyber => UntisThemeTokens(
        id: id,
        surfaceRadius: 10,
        controlRadius: 6,
        borderWidth: 1.5,
        blurSigma: 16,
        shadowOffset: const Offset(4, 4),
        shadowColor: const Color(0x6600E5FF),
        patternColor: (dark ? const Color(0xFF00F5FF) : const Color(0xFF005B66))
            .withValues(alpha: 0.18),
        backdropColors: dark
            ? const [Color(0xFF02050A), Color(0xFF061724)]
            : const [Color(0xFFE9FEFF), Color(0xFFDCE8F0)],
        hardShadow: true,
        glassHighlights: false,
        motionStyle: 4,
        surfaceOpacity: 0.90,
        navigationOpacity: 0.92,
        lessonSurfaceOpacity: 0.90,
      ),
      AppThemeId.paper => UntisThemeTokens(
        id: id,
        surfaceRadius: 12,
        controlRadius: 8,
        borderWidth: 1.15,
        blurSigma: 0,
        shadowOffset: const Offset(2, 5),
        shadowColor: (dark ? Colors.black : const Color(0xFF604D37)).withValues(
          alpha: 0.28,
        ),
        patternColor: (dark ? const Color(0xFFC6B99F) : const Color(0xFF8F8068))
            .withValues(alpha: dark ? 0.10 : 0.13),
        backdropColors: dark
            ? const [Color(0xFF1C1A17), Color(0xFF29251F)]
            : const [Color(0xFFFFFBF1), Color(0xFFF5EBD7)],
        hardShadow: false,
        glassHighlights: false,
        motionStyle: 5,
        surfaceOpacity: 0.97,
        navigationOpacity: 0.98,
        lessonSurfaceOpacity: 0.97,
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
    AppThemeId.vivid =>
      dark ? const Color(0xFFFF4FC8) : const Color(0xFF6C20FF),
    AppThemeId.glass =>
      dark ? const Color(0xFF76D6FF) : const Color(0xFF246BFE),
    AppThemeId.cyber =>
      dark ? const Color(0xFF00F5FF) : const Color(0xFF006B75),
    AppThemeId.paper =>
      dark ? const Color(0xFFFFC86B) : const Color(0xFF9A4D24),
  };
  var scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    dynamicSchemeVariant: id == AppThemeId.vivid
        ? DynamicSchemeVariant.expressive
        : DynamicSchemeVariant.vibrant,
  );
  if (id == AppThemeId.manga) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFFF5EBD7) : const Color(0xFF17120C),
      onPrimary: dark ? const Color(0xFF17120C) : const Color(0xFFF8F0DF),
      surface: dark ? const Color(0xFF171511) : const Color(0xFFF4ECDD),
      onSurface: dark ? const Color(0xFFF5EBD7) : const Color(0xFF17120C),
      outline: dark ? const Color(0xFFF5EBD7) : const Color(0xFF17120C),
    );
  } else if (id == AppThemeId.vivid) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFFBFA8FF) : const Color(0xFF6E37FF),
      onPrimary: dark ? const Color(0xFF251052) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF4D2A98)
          : const Color(0xFFE9DFFF),
      onPrimaryContainer: dark
          ? const Color(0xFFF0E9FF)
          : const Color(0xFF28105D),
      secondary: dark ? const Color(0xFFFF75BB) : const Color(0xFFD81B82),
      secondaryContainer: dark
          ? const Color(0xFF5D1439)
          : const Color(0xFFFFD8EA),
      tertiary: dark ? const Color(0xFF67DBE8) : const Color(0xFF007B8A),
      tertiaryContainer: dark
          ? const Color(0xFF064C54)
          : const Color(0xFFB5F2F7),
      surface: dark ? const Color(0xFF100C1D) : const Color(0xFFFFF7FD),
      surfaceContainerLowest: dark
          ? const Color(0xFF0B0815)
          : const Color(0xFFFFFBFF),
      surfaceContainerLow: dark
          ? const Color(0xFF171124)
          : const Color(0xFFFFF0FA),
      surfaceContainer: dark
          ? const Color(0xFF1E152D)
          : const Color(0xFFF9EAFB),
      surfaceContainerHigh: dark
          ? const Color(0xFF251836)
          : const Color(0xFFF3E2F7),
      surfaceContainerHighest: dark
          ? const Color(0xFF342047)
          : const Color(0xFFE9D8F2),
      onSurface: dark ? const Color(0xFFF8F1FF) : const Color(0xFF21182B),
      onSurfaceVariant: dark
          ? const Color(0xFFD6C7DE)
          : const Color(0xFF5E5066),
      outline: dark ? const Color(0xFF9B86A8) : const Color(0xFF78677F),
      outlineVariant: dark ? const Color(0xFF4F4058) : const Color(0xFFD8C6DE),
    );
  } else if (id == AppThemeId.glass) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFF8BC7FF) : const Color(0xFF195FC7),
      primaryContainer: dark
          ? const Color(0xFF173D69)
          : const Color(0xFFD8E9FF),
      secondary: dark ? const Color(0xFFC9B5FF) : const Color(0xFF7054B8),
      secondaryContainer: dark
          ? const Color(0xFF3E3261)
          : const Color(0xFFE9E0FF),
      tertiary: dark ? const Color(0xFF7ADDC7) : const Color(0xFF157866),
      tertiaryContainer: dark
          ? const Color(0xFF174D45)
          : const Color(0xFFC5F3E8),
      surface: dark ? const Color(0xFF091722) : const Color(0xFFF4FAFF),
      surfaceContainerLowest: dark ? const Color(0xFF061018) : Colors.white,
      surfaceContainerLow: dark
          ? const Color(0xFF10202E)
          : const Color(0xFFEBF5FC),
      surfaceContainer: dark
          ? const Color(0xFF172837)
          : const Color(0xFFE4F0F8),
      surfaceContainerHigh: dark
          ? const Color(0xFF203242)
          : const Color(0xFFDCEAF4),
      surfaceContainerHighest: dark
          ? const Color(0xFF2A3D4D)
          : const Color(0xFFD2E2ED),
      onSurface: dark ? const Color(0xFFF1F7FC) : const Color(0xFF17232C),
      onSurfaceVariant: dark
          ? const Color(0xFFC5D2DB)
          : const Color(0xFF4E606D),
      outline: dark ? const Color(0xFF8FA4B3) : const Color(0xFF718591),
      outlineVariant: dark ? const Color(0xFF405362) : const Color(0xFFC2D2DD),
    );
  } else if (id == AppThemeId.cyber) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFF35F0FF) : const Color(0xFF006B75),
      onPrimary: dark ? const Color(0xFF002023) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF003E45)
          : const Color(0xFFB5F3F7),
      secondary: dark ? const Color(0xFFFF59B6) : const Color(0xFFB00069),
      secondaryContainer: dark
          ? const Color(0xFF4D1234)
          : const Color(0xFFFFD8E9),
      tertiary: dark ? const Color(0xFFD0FF52) : const Color(0xFF527200),
      tertiaryContainer: dark
          ? const Color(0xFF314500)
          : const Color(0xFFDDF5A5),
      surface: dark ? const Color(0xFF02070B) : const Color(0xFFF1FCFD),
      surfaceContainerLowest: dark ? Colors.black : Colors.white,
      surfaceContainerLow: dark
          ? const Color(0xFF071016)
          : const Color(0xFFE8F5F6),
      surfaceContainer: dark
          ? const Color(0xFF0B171F)
          : const Color(0xFFDFEEF0),
      surfaceContainerHigh: dark
          ? const Color(0xFF10212B)
          : const Color(0xFFD5E8EA),
      surfaceContainerHighest: dark
          ? const Color(0xFF17303B)
          : const Color(0xFFC9DEE1),
      onSurface: dark ? const Color(0xFFE8FAFC) : const Color(0xFF10272B),
      onSurfaceVariant: dark
          ? const Color(0xFFB3C9CD)
          : const Color(0xFF425F64),
      outline: dark ? const Color(0xFF62AEB6) : const Color(0xFF557A80),
      outlineVariant: dark ? const Color(0xFF244A51) : const Color(0xFFB5CED1),
    );
  } else if (id == AppThemeId.paper) {
    scheme = scheme.copyWith(
      primary: dark ? const Color(0xFFF2A36F) : const Color(0xFF9A4D24),
      onPrimary: dark ? const Color(0xFF3B1807) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF55301D)
          : const Color(0xFFFFDCC6),
      onPrimaryContainer: dark
          ? const Color(0xFFFFE7D8)
          : const Color(0xFF3A1705),
      secondary: dark ? const Color(0xFFB9CAA2) : const Color(0xFF536844),
      secondaryContainer: dark
          ? const Color(0xFF35432C)
          : const Color(0xFFD8E8C5),
      tertiary: dark ? const Color(0xFFD6B983) : const Color(0xFF745C2F),
      tertiaryContainer: dark
          ? const Color(0xFF48391F)
          : const Color(0xFFF5DDAA),
      surface: dark ? const Color(0xFF1C1A17) : const Color(0xFFFFFBF1),
      surfaceContainerLowest: dark
          ? const Color(0xFF151310)
          : const Color(0xFFFFFEF8),
      surfaceContainerLow: dark
          ? const Color(0xFF24211C)
          : const Color(0xFFF9F1E2),
      surfaceContainer: dark
          ? const Color(0xFF2B2721)
          : const Color(0xFFF3E9D6),
      surfaceContainerHigh: dark
          ? const Color(0xFF332E27)
          : const Color(0xFFEDE2CC),
      surfaceContainerHighest: dark
          ? const Color(0xFF3D372F)
          : const Color(0xFFE5D8BF),
      onSurface: dark ? const Color(0xFFF0E7D7) : const Color(0xFF29231C),
      onSurfaceVariant: dark
          ? const Color(0xFFCFC3B1)
          : const Color(0xFF665C4F),
      outline: dark ? const Color(0xFF9B8F7E) : const Color(0xFF867966),
      outlineVariant: dark ? const Color(0xFF51493E) : const Color(0xFFD6C8B1),
    );
  }
  return scheme;
}

TextTheme untisThemeTextTheme(AppThemeId id, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
  final body = switch (id) {
    AppThemeId.cyber => GoogleFonts.outfitTextTheme(base),
    AppThemeId.paper => GoogleFonts.notoSansTextTheme(base),
    _ => GoogleFonts.outfitTextTheme(base),
  };
  if (id != AppThemeId.manga &&
      id != AppThemeId.cyber &&
      id != AppThemeId.paper) {
    return body;
  }
  final display = switch (id) {
    AppThemeId.manga => GoogleFonts.bebasNeueTextTheme(base),
    AppThemeId.cyber => GoogleFonts.ibmPlexMonoTextTheme(base),
    AppThemeId.paper => GoogleFonts.notoSerifTextTheme(base),
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
      for (double x = 0; x < size.width; x += 28) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 28) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (tokens.id == AppThemeId.paper) {
      paint.strokeWidth = 1;
      for (double y = 34; y < size.height; y += 30) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      final margin = Paint()
        ..color = const Color(0x55D65A5A)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(32, 0), Offset(32, size.height), margin);
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
      AppThemeId.vivid => 6,
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
              opacity: tokens.id == AppThemeId.cyber ? 0.36 : 0.56,
              child: _AnimatedBackgroundScene(style: sceneStyle),
            ),
          ),
        if (tokens.id == AppThemeId.manga ||
            tokens.id == AppThemeId.cyber ||
            tokens.id == AppThemeId.paper)
          Positioned.fill(
            child: CustomPaint(painter: _ThemePatternPainter(tokens)),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}
