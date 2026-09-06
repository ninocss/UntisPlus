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
  final bool supportsAdvancedLessonStyle;

  const AppThemeCapabilities({
    required this.supportsBlur,
    required this.supportsCustomBackgrounds,
    required this.supportsBackgroundMotion,
    required this.supportsMaterialYou,
    required this.supportsAdvancedLessonStyle,
  });
}

AppThemeCapabilities appThemeCapabilities(AppThemeId theme) => switch (theme) {
  AppThemeId.defaultTheme => const AppThemeCapabilities(
    supportsBlur: true,
    supportsCustomBackgrounds: true,
    supportsBackgroundMotion: true,
    supportsMaterialYou: true,
    supportsAdvancedLessonStyle: true,
  ),
  AppThemeId.glass => const AppThemeCapabilities(
    supportsBlur: true,
    supportsCustomBackgrounds: true,
    supportsBackgroundMotion: true,
    supportsMaterialYou: false,
    supportsAdvancedLessonStyle: false,
  ),
  AppThemeId.vivid || AppThemeId.cyber => const AppThemeCapabilities(
    supportsBlur: true,
    supportsCustomBackgrounds: false,
    supportsBackgroundMotion: true,
    supportsMaterialYou: false,
    supportsAdvancedLessonStyle: false,
  ),
  AppThemeId.manga || AppThemeId.paper => const AppThemeCapabilities(
    supportsBlur: false,
    supportsCustomBackgrounds: false,
    supportsBackgroundMotion: false,
    supportsMaterialYou: false,
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
  final int motionStyle;

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
    required this.motionStyle,
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
      ),
      AppThemeId.vivid => UntisThemeTokens(
        id: id,
        surfaceRadius: 28,
        controlRadius: 22,
        borderWidth: 1.5,
        blurSigma: 24,
        shadowOffset: const Offset(0, 10),
        shadowColor: scheme.primary.withValues(alpha: 0.28),
        patternColor: scheme.tertiary.withValues(alpha: 0.12),
        backdropColors: dark
            ? const [Color(0xFF19002E), Color(0xFF001F39), Color(0xFF311000)]
            : const [Color(0xFFFFE04B), Color(0xFFFF6BCA), Color(0xFF4BE4FF)],
        hardShadow: false,
        glassHighlights: false,
        motionStyle: 2,
      ),
      AppThemeId.glass => UntisThemeTokens(
        id: id,
        surfaceRadius: 30,
        controlRadius: 24,
        borderWidth: 1,
        blurSigma: 34,
        shadowOffset: const Offset(0, 12),
        shadowColor: scheme.shadow.withValues(alpha: dark ? 0.34 : 0.16),
        patternColor: Colors.white.withValues(alpha: dark ? 0.16 : 0.5),
        backdropColors: dark
            ? const [Color(0xFF071A34), Color(0xFF301750), Color(0xFF073B3B)]
            : const [Color(0xFFB9E7FF), Color(0xFFE8CCFF), Color(0xFFBFFFF1)],
        hardShadow: false,
        glassHighlights: true,
        motionStyle: 3,
      ),
      AppThemeId.cyber => UntisThemeTokens(
        id: id,
        surfaceRadius: 8,
        controlRadius: 5,
        borderWidth: 1.5,
        blurSigma: 18,
        shadowOffset: const Offset(5, 5),
        shadowColor: const Color(0x9900F5FF),
        patternColor: (dark ? const Color(0xFF00F5FF) : const Color(0xFF005B66))
            .withValues(alpha: 0.18),
        backdropColors: dark
            ? const [Color(0xFF02050A), Color(0xFF061724)]
            : const [Color(0xFFE9FEFF), Color(0xFFDCE8F0)],
        hardShadow: true,
        glassHighlights: false,
        motionStyle: 4,
      ),
      AppThemeId.paper => UntisThemeTokens(
        id: id,
        surfaceRadius: 6,
        controlRadius: 4,
        borderWidth: 1.4,
        blurSigma: 0,
        shadowOffset: const Offset(4, 6),
        shadowColor: (dark ? Colors.black : const Color(0xFF604D37)).withValues(
          alpha: 0.28,
        ),
        patternColor: (dark ? const Color(0xFF90A8C0) : const Color(0xFF6686A6))
            .withValues(alpha: 0.20),
        backdropColors: dark
            ? const [Color(0xFF1E2020), Color(0xFF292824)]
            : const [Color(0xFFFFF9E8), Color(0xFFF5E8C9)],
        hardShadow: false,
        glassHighlights: false,
        motionStyle: 5,
      ),
      AppThemeId.defaultTheme => UntisThemeTokens(
        id: id,
        surfaceRadius: 22,
        controlRadius: 18,
        borderWidth: 1,
        blurSigma: 30,
        shadowOffset: const Offset(0, 8),
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        patternColor: scheme.primary.withValues(alpha: 0.12),
        backdropColors: [scheme.surface, scheme.surfaceContainerLowest],
        hardShadow: false,
        glassHighlights: false,
        motionStyle: 0,
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
    int? motionStyle,
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
    motionStyle: motionStyle ?? this.motionStyle,
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
      motionStyle: motionStyle,
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
  } else if (id == AppThemeId.cyber) {
    scheme = scheme.copyWith(
      secondary: const Color(0xFFFF2FA8),
      tertiary: const Color(0xFFC8FF00),
      surface: dark ? const Color(0xFF02050A) : const Color(0xFFE9FEFF),
    );
  }
  return scheme;
}

TextTheme untisThemeTextTheme(AppThemeId id, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
  final body = switch (id) {
    AppThemeId.cyber => GoogleFonts.ibmPlexMonoTextTheme(base),
    AppThemeId.paper => GoogleFonts.notoSansTextTheme(base),
    _ => GoogleFonts.outfitTextTheme(base),
  };
  if (id != AppThemeId.manga) return body;
  final display = GoogleFonts.bebasNeueTextTheme(base);
  return body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge,
    headlineMedium: display.headlineMedium,
    headlineSmall: display.headlineSmall,
    titleLarge: display.titleLarge?.copyWith(letterSpacing: 0.4),
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
  const ThemedBackdrop({super.key, required this.child, required this.animate});

  @override
  Widget build(BuildContext context) {
    final tokens = untisThemeTokensOf(context);
    if (tokens.id == AppThemeId.defaultTheme) return child;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final sceneStyle = switch (tokens.id) {
      AppThemeId.vivid => 6,
      AppThemeId.glass => 0,
      AppThemeId.cyber => 8,
      _ => -1,
    };
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
