part of '../main.dart';

enum AppFontId { googleSansFlex, outfit, robotoFlex }

extension AppFontIdX on AppFontId {
  String get storageKey => switch (this) {
    AppFontId.googleSansFlex => 'googleSansFlex',
    AppFontId.outfit => 'outfit',
    AppFontId.robotoFlex => 'robotoFlex',
  };

  String get family => switch (this) {
    AppFontId.googleSansFlex => 'Google Sans Flex',
    AppFontId.outfit => 'Outfit',
    AppFontId.robotoFlex => 'Roboto Flex',
  };

  static AppFontId fromStorage(String? value) => AppFontId.values.firstWhere(
    (font) => font.storageKey == value,
    orElse: () => AppFontId.googleSansFlex,
  );
}

final appFontFamilyNotifier = ValueNotifier(AppFontId.googleSansFlex);

void loadAppFont(SharedPreferences prefs) {
  appFontFamilyNotifier.value = AppFontIdX.fromStorage(
    prefs.getString('appFontFamily'),
  );
}

Future<void> setAppFontFamily(AppFontId font) async {
  appFontFamilyNotifier.value = font;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('appFontFamily', font.storageKey);
}

/// Axis ranges verified against the bundled files' fvar tables (see fonts README).
abstract final class AppTypography {
  static List<FontVariation> variations(AppFontId font, double size) => [
    if (font != AppFontId.outfit)
      FontVariation(
        'opsz',
        size.clamp(font == AppFontId.googleSansFlex ? 6 : 8, 144),
      ),
  ];

  static TextStyle role(
    TextStyle base,
    AppFontId font,
    double size,
    double lineHeight,
    FontWeight weight,
    double tracking,
  ) => base.copyWith(
    fontFamily: font.family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: tracking,
    fontVariations: variations(font, size),
  );

  static TextTheme expressive(TextTheme base, AppFontId font) => base.copyWith(
    displayLarge: role(
      base.displayLarge!,
      font,
      57,
      64,
      FontWeight.w600,
      -0.25,
    ),
    displayMedium: role(base.displayMedium!, font, 45, 52, FontWeight.w600, 0),
    displaySmall: role(base.displaySmall!, font, 36, 44, FontWeight.w600, 0),
    headlineLarge: role(base.headlineLarge!, font, 32, 40, FontWeight.w600, 0),
    headlineMedium: role(
      base.headlineMedium!,
      font,
      28,
      36,
      FontWeight.w600,
      0,
    ),
    headlineSmall: role(base.headlineSmall!, font, 24, 32, FontWeight.w600, 0),
    titleLarge: role(base.titleLarge!, font, 22, 28, FontWeight.w500, 0),
    titleMedium: role(base.titleMedium!, font, 16, 24, FontWeight.w500, 0.15),
    titleSmall: role(base.titleSmall!, font, 14, 20, FontWeight.w500, 0.1),
    bodyLarge: role(base.bodyLarge!, font, 16, 24, FontWeight.w400, 0.5),
    bodyMedium: role(base.bodyMedium!, font, 14, 20, FontWeight.w400, 0.25),
    bodySmall: role(base.bodySmall!, font, 12, 16, FontWeight.w400, 0.4),
    labelLarge: role(base.labelLarge!, font, 14, 20, FontWeight.w500, 0.1),
    labelMedium: role(base.labelMedium!, font, 12, 16, FontWeight.w500, 0.5),
    labelSmall: role(base.labelSmall!, font, 11, 16, FontWeight.w500, 0.5),
  );

  /// Compatibility styles for older presentation code.
  ///
  /// They deliberately read the selected app font instead of pinning Outfit so
  /// screens that have not yet been assigned a more specific text role still
  /// follow the global preference immediately.
  static TextStyle legacyText({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? decorationThickness,
  }) {
    final font = appFontFamilyNotifier.value;
    final size = fontSize ?? 14;
    return TextStyle(
      color: color,
      fontFamily: font.family,
      fontSize: size,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      fontVariations: variations(font, size),
    );
  }
}

/// Compatibility adapter for legacy text call sites.
///
/// All legacy Outfit calls now resolve through [AppTypography.legacyText], so
/// the persisted app-wide font selection is respected while each screen is
/// migrated to semantic [TextTheme] roles. Monospace and markdown code retain
/// their explicitly chosen code faces.
abstract final class GoogleFonts {
  static TextStyle outfit({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? decorationThickness,
  }) => AppTypography.legacyText(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationThickness: decorationThickness,
  );

  static TextStyle jetBrainsMono({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) => google_fonts.GoogleFonts.jetBrainsMono(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );

  static TextStyle inter({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) => google_fonts.GoogleFonts.inter(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
  );

  static TextStyle firaCode({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    Color? backgroundColor,
  }) => google_fonts.GoogleFonts.firaCode(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    backgroundColor: backgroundColor,
  );
}

@immutable
class ExpressiveThemeTokens {
  const ExpressiveThemeTokens();
  double get largeSurfaceRadius => 32;
  double get smallContainerRadius => 20;
  double get pressedControlRadius => 14;
  OutlinedBorder get largeSurfaceShape => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(largeSurfaceRadius),
  );
  OutlinedBorder get buttonShape => const StadiumBorder();
  OutlinedBorder get iconButtonShape => const CircleBorder();
  double get minimumTouchTarget => 48;
  double get standardActionSize => 48;
  double get emphasizedActionSize => 56;
  double get heroActionSize => 64;
  Duration get quickMotion => const Duration(milliseconds: 200);
  Duration get containerMotion => const Duration(milliseconds: 400);
  Duration get loadingCycle => const Duration(milliseconds: 1600);
  Duration get progressCycle => const Duration(milliseconds: 1400);
  Curve get motionCurve => Curves.easeInOutCubicEmphasized;
  SpringDescription get spatialSpring =>
      const SpringDescription(mass: 1, stiffness: 520, damping: 28);
  double get hoveredStateLayerOpacity => 0.08;
  double get focusedStateLayerOpacity => 0.12;
  double get pressedStateLayerOpacity => 0.12;
  Duration motionDuration(BuildContext context, {bool container = false}) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : container
      ? containerMotion
      : quickMotion;
}

/// Called once at startup. Legacy call sites also use bundled assets only.
void configureBundledFonts() {
  google_fonts.GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final entry in const {
      'Google Sans Flex': 'googlesansflex/OFL.txt',
      'Outfit': 'outfit/OFL.txt',
      'Roboto Flex': 'robotoflex/OFL.txt',
      'Inter': 'legacy/inter-OFL.txt',
      'JetBrains Mono': 'legacy/jetbrainsmono-OFL.txt',
      'Fira Code': 'legacy/firacode-OFL.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString('assets/fonts/${entry.value}'));
    }
  });
}
