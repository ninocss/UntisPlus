part of '../main.dart';

@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  final Color lessonAccent;
  final Color lessonAccent2;
  final Color lessonAccent3;
  final Color lessonAccent4;
  final Color lessonAccent5;
  final Color lessonAccent6;
  final Color lessonAccent7;
  final Color lessonAccent8;
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final double radiusXLarge;

  const AppDesignTokens({
    required this.lessonAccent,
    required this.lessonAccent2,
    required this.lessonAccent3,
    required this.lessonAccent4,
    required this.lessonAccent5,
    required this.lessonAccent6,
    required this.lessonAccent7,
    required this.lessonAccent8,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusXLarge,
  });

  factory AppDesignTokens.fromScheme(ColorScheme scheme) {
    return AppDesignTokens(
      lessonAccent: scheme.primary,
      lessonAccent2: scheme.secondary,
      lessonAccent3: scheme.tertiary,
      lessonAccent4: scheme.error,
      lessonAccent5: const Color(0xFF4F7CFF),
      lessonAccent6: const Color(0xFF00B8D4),
      lessonAccent7: const Color(0xFF00C853),
      lessonAccent8: const Color(0xFFFFA000),
      radiusSmall: 10,
      radiusMedium: 16,
      radiusLarge: 20,
      radiusXLarge: 28,
    );
  }

  List<Color> get lessonPalette => <Color>[
    lessonAccent,
    lessonAccent2,
    lessonAccent3,
    lessonAccent4,
    lessonAccent5,
    lessonAccent6,
    lessonAccent7,
    lessonAccent8,
  ];

  @override
  AppDesignTokens copyWith({
    Color? lessonAccent,
    Color? lessonAccent2,
    Color? lessonAccent3,
    Color? lessonAccent4,
    Color? lessonAccent5,
    Color? lessonAccent6,
    Color? lessonAccent7,
    Color? lessonAccent8,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusXLarge,
  }) {
    return AppDesignTokens(
      lessonAccent: lessonAccent ?? this.lessonAccent,
      lessonAccent2: lessonAccent2 ?? this.lessonAccent2,
      lessonAccent3: lessonAccent3 ?? this.lessonAccent3,
      lessonAccent4: lessonAccent4 ?? this.lessonAccent4,
      lessonAccent5: lessonAccent5 ?? this.lessonAccent5,
      lessonAccent6: lessonAccent6 ?? this.lessonAccent6,
      lessonAccent7: lessonAccent7 ?? this.lessonAccent7,
      lessonAccent8: lessonAccent8 ?? this.lessonAccent8,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      radiusXLarge: radiusXLarge ?? this.radiusXLarge,
    );
  }

  @override
  AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      lessonAccent: Color.lerp(lessonAccent, other.lessonAccent, t)!,
      lessonAccent2: Color.lerp(lessonAccent2, other.lessonAccent2, t)!,
      lessonAccent3: Color.lerp(lessonAccent3, other.lessonAccent3, t)!,
      lessonAccent4: Color.lerp(lessonAccent4, other.lessonAccent4, t)!,
      lessonAccent5: Color.lerp(lessonAccent5, other.lessonAccent5, t)!,
      lessonAccent6: Color.lerp(lessonAccent6, other.lessonAccent6, t)!,
      lessonAccent7: Color.lerp(lessonAccent7, other.lessonAccent7, t)!,
      lessonAccent8: Color.lerp(lessonAccent8, other.lessonAccent8, t)!,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      radiusXLarge: lerpDouble(radiusXLarge, other.radiusXLarge, t)!,
    );
  }
}

const appSpacing = _AppSpacing();

class _AppSpacing {
  const _AppSpacing();

  final double xxs = 4;
  final double xs = 8;
  final double sm = 12;
  final double md = 16;
  final double lg = 20;
  final double xl = 24;
  final double xxl = 32;
}

  const appAlphaValues = _AppAlphaValues();

  class _AppAlphaValues {
    const _AppAlphaValues();

    final double cardAlphaBlur = 0.82;
    final double cardAlphaNoBlur = 0.96;
    final double sheetAlphaBlur = 0.72;
  }

List<Color> untisPlusSubjectPalette(ColorScheme cs) {
  final tokens = AppDesignTokens.fromScheme(cs);
  return tokens.lessonPalette;
}

List<Color> untisPlusAutoLessonPalette() {
  return <Color>[
    const Color(0xFF4F7CFF),
    const Color(0xFF00B8D4),
    const Color(0xFF00C853),
    const Color(0xFFFFA000),
    const Color(0xFFFF5252),
    const Color(0xFF7C4DFF),
    const Color(0xFFE91E63),
    const Color(0xFF009688),
  ];
}
