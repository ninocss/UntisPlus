// settings_timetable_page.dart
part of '../../main.dart';

class SettingsTimetablePage extends StatefulWidget {
  const SettingsTimetablePage({super.key});

  @override
  State<SettingsTimetablePage> createState() => _SettingsTimetablePageState();
}

class _SettingsTimetablePageState extends State<SettingsTimetablePage> {
  int _previewState = 0; // 0 = Regular, 1 = Active (isNow with glow), 2 = Cancelled

  String _styleLabel(AppL10n l, int style) {
    switch (style) {
      case 1:
        return l.settingsLessonStyleGlass;
      case 2:
        return l.settingsLessonStyleGradient;
      case 3:
        return l.settingsLessonStyleOutline;
      case 4:
        return l.settingsLessonStyleSolid;
      case 0:
      default:
        return l.settingsLessonStyleModern;
    }
  }

  IconData _styleIcon(int style) {
    switch (style) {
      case 1:
        return Icons.blur_on_rounded;
      case 2:
        return Icons.gradient_rounded;
      case 3:
        return Icons.crop_square_rounded;
      case 4:
        return Icons.rectangle_rounded;
      case 0:
      default:
        return Icons.dashboard_customize_rounded;
    }
  }

  void _showCardStyleDialog(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsLessonStyle,
      subtitle: l.settingsLessonStyleDesc,
      options: [
        _SheetOption(
          value: 0,
          title: l.settingsLessonStyleModern,
          icon: _styleIcon(0),
          selected: lessonCardStyleNotifier.value == 0,
        ),
        _SheetOption(
          value: 1,
          title: l.settingsLessonStyleGlass,
          icon: _styleIcon(1),
          selected: lessonCardStyleNotifier.value == 1,
        ),
        _SheetOption(
          value: 2,
          title: l.settingsLessonStyleGradient,
          icon: _styleIcon(2),
          selected: lessonCardStyleNotifier.value == 2,
        ),
        _SheetOption(
          value: 3,
          title: l.settingsLessonStyleOutline,
          icon: _styleIcon(3),
          selected: lessonCardStyleNotifier.value == 3,
        ),
        _SheetOption(
          value: 4,
          title: l.settingsLessonStyleSolid,
          icon: _styleIcon(4),
          selected: lessonCardStyleNotifier.value == 4,
        ),
      ],
    ).then((value) {
      if (value != null) {
        _settingsSetLessonCardStyle(value);
      }
    });
  }

  String _glowModeLabel(AppL10n l, int mode) {
    return mode == 1
        ? l.settingsLessonGlowModeAll
        : l.settingsLessonGlowModeActive;
  }

  void _showGlowModeDialog(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsLessonGlowMode,
      options: [
        _SheetOption(
          value: 0,
          title: l.settingsLessonGlowModeActive,
          icon: Icons.flash_on_rounded,
          selected: lessonGlowModeNotifier.value == 0,
        ),
        _SheetOption(
          value: 1,
          title: l.settingsLessonGlowModeAll,
          icon: Icons.auto_awesome_rounded,
          selected: lessonGlowModeNotifier.value == 1,
        ),
      ],
    ).then((value) {
      if (value != null) {
        _settingsSetLessonGlowMode(value);
      }
    });
  }

  String _accentStyleLabel(AppL10n l, int style) {
    switch (style) {
      case 1:
        return l.settingsLessonAccentThin;
      case 2:
        return l.settingsLessonAccentDot;
      case 3:
        return l.settingsLessonAccentNone;
      case 0:
      default:
        return l.settingsLessonAccentBar;
    }
  }

  IconData _accentStyleIcon(int style) {
    switch (style) {
      case 1:
        return Icons.view_headline_rounded;
      case 2:
        return Icons.circle_rounded;
      case 3:
        return Icons.block_rounded;
      case 0:
      default:
        return Icons.view_column_rounded;
    }
  }

  void _showAccentStyleDialog(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<int>(
      context: context,
      title: l.settingsLessonAccentStyle,
      options: [
        _SheetOption(
          value: 0,
          title: l.settingsLessonAccentBar,
          icon: _accentStyleIcon(0),
          selected: lessonAccentStyleNotifier.value == 0,
        ),
        _SheetOption(
          value: 1,
          title: l.settingsLessonAccentThin,
          icon: _accentStyleIcon(1),
          selected: lessonAccentStyleNotifier.value == 1,
        ),
        _SheetOption(
          value: 2,
          title: l.settingsLessonAccentDot,
          icon: _accentStyleIcon(2),
          selected: lessonAccentStyleNotifier.value == 2,
        ),
        _SheetOption(
          value: 3,
          title: l.settingsLessonAccentNone,
          icon: _accentStyleIcon(3),
          selected: lessonAccentStyleNotifier.value == 3,
        ),
      ],
    ).then((value) {
      if (value != null) {
        _settingsSetLessonAccentStyle(value);
      }
    });
  }

  void _showCancelledColorPicker(BuildContext context, Color current) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    double red = current.r * 255.0;
    double green = current.g * 255.0;
    double blue = current.b * 255.0;

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setPickerState) {
          final preview = Color.fromARGB(
            255,
            red.round(),
            green.round(),
            blue.round(),
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.settingsCancelledColor,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${l.settingsColorRed}: ${red.round()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: red,
                  min: 0,
                  max: 255,
                  activeColor: Colors.red,
                  onChanged: (v) => setPickerState(() => red = v),
                ),
                Text(
                  '${l.settingsColorGreen}: ${green.round()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: green,
                  min: 0,
                  max: 255,
                  activeColor: Colors.green,
                  onChanged: (v) => setPickerState(() => green = v),
                ),
                Text(
                  '${l.settingsColorBlue}: ${blue.round()}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: blue,
                  min: 0,
                  max: 255,
                  activeColor: Colors.blue,
                  onChanged: (v) => setPickerState(() => blue = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        _settingsSetCancelledLessonColor(preview.toARGB32());
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        l.settingsColorApply,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLivePreview(BuildContext context, AppL10n l, ColorScheme cs, bool isDark) {
    final isCancelled = _previewState == 2;
    final isNow = _previewState == 1;

    final primaryFg = isCancelled
        ? Color(cancelledLessonColorNotifier.value)
        : (monochromeLessonsNotifier.value ? cs.primary : const Color(0xFF00B8D4));

    final primaryBg = isCancelled
        ? Color.alphaBlend(
            primaryFg.withValues(alpha: isDark ? 0.16 : 0.10),
            cs.surfaceContainerHighest,
          )
        : Color.alphaBlend(
            primaryFg.withValues(alpha: isDark ? 0.16 : 0.10),
            cs.surfaceContainerHighest,
          );

    final subject = isCancelled
        ? 'Sport'
        : (isNow ? 'Informatik' : 'Mathematik');
    final teacher = isCancelled ? 'Hr. Müller' : 'Fr. Becker';
    final room = isCancelled ? 'Halle 2' : 'R 204';

    return SettingsGroup(
      title: l.settingsLessonPreviewHeader,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text(
                        l.settingsLessonPreviewRegular,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      icon: const Icon(Icons.schedule_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text(
                        l.settingsLessonPreviewActive,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text(
                        l.settingsLessonPreviewCancelled,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      icon: const Icon(Icons.event_busy_rounded, size: 16),
                    ),
                  ],
                  selected: {_previewState},
                  onSelectionChanged: (set) {
                    HapticFeedback.selectionClick();
                    setState(() => _previewState = set.first);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 260,
                    minHeight: 88,
                  ),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      lessonCardStyleNotifier,
                      lessonGlowEnabledNotifier,
                      lessonGlowModeNotifier,
                      lessonGlowIntensityNotifier,
                      lessonBlurEnabledNotifier,
                      lessonBlurAmountNotifier,
                      lessonCardOpacityNotifier,
                      lessonBorderRadiusNotifier,
                      lessonAccentStyleNotifier,
                      lessonShowTeacherNotifier,
                      lessonShowRoomNotifier,
                      lessonCompactModeNotifier,
                      lessonCancelledPatternNotifier,
                      cancelledLessonColorNotifier,
                      monochromeLessonsNotifier,
                    ]),
                    builder: (context, _) {
                      return _buildTimetablePreviewCard(
                        context: context,
                        isCancelled: isCancelled,
                        isDark: isDark,
                        fgColor: primaryFg,
                        bgColor: primaryBg,
                        subject: subject,
                        teacher: teacher,
                        room: room,
                        isNow: isNow,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimetablePreviewCard({
    required BuildContext context,
    required bool isCancelled,
    required bool isDark,
    required Color fgColor,
    required Color bgColor,
    required String subject,
    required String teacher,
    required String room,
    required bool isNow,
  }) {
    final cs = Theme.of(context).colorScheme;
    final effectiveRadius = lessonBorderRadiusNotifier.value;
    final cardRadius = BorderRadius.circular(effectiveRadius);

    final glowEnabled = lessonGlowEnabledNotifier.value;
    final glowMode = lessonGlowModeNotifier.value;
    final glowIntensity = lessonGlowIntensityNotifier.value;
    final cardStyle = lessonCardStyleNotifier.value;
    final blurEnabled = (lessonBlurEnabledNotifier.value || cardStyle == 1) && blurEnabledNotifier.value;
    final blurSigma = lessonBlurAmountNotifier.value;
    final cardOpacity = lessonCardOpacityNotifier.value;
    final accentStyle = lessonAccentStyleNotifier.value;
    final showTeacher = lessonShowTeacherNotifier.value;
    final showRoom = lessonShowRoomNotifier.value;
    final compact = lessonCompactModeNotifier.value;
    final showPattern = isCancelled && lessonCancelledPatternNotifier.value;

    final effectivePadding = compact
        ? const EdgeInsets.fromLTRB(10, 6, 8, 6)
        : const EdgeInsets.fromLTRB(12, 9, 10, 9);

    final subjectFontSize = compact ? 13.0 : 15.0;
    final teacherFontSize = compact ? 10.5 : 12.0;
    final roomFontSize = compact ? 10.5 : 12.0;

    List<BoxShadow>? shadows;
    if (glowEnabled) {
      if (isNow) {
        shadows = [
          BoxShadow(
            color: fgColor.withValues(
              alpha: (0.38 * glowIntensity).clamp(0.0, 1.0),
            ),
            blurRadius: (14 * glowIntensity).clamp(2.0, 30.0),
            spreadRadius: (1.5 * glowIntensity).clamp(0.0, 6.0),
            offset: const Offset(0, 3),
          ),
        ];
      } else if (glowMode == 1) {
        shadows = [
          BoxShadow(
            color: fgColor.withValues(
              alpha: (0.16 * glowIntensity).clamp(0.0, 1.0),
            ),
            blurRadius: (8 * glowIntensity).clamp(2.0, 20.0),
            spreadRadius: (0.5 * glowIntensity).clamp(0.0, 4.0),
            offset: const Offset(0, 2),
          ),
        ];
      }
    }

    Color effectiveFillColor;
    Gradient? effectiveGradient;
    Border? effectiveBorder;
    Color effectiveTextColor =
        isCancelled ? fgColor.withValues(alpha: 0.6) : fgColor;
    Color effectiveSecondaryTextColor = isCancelled
        ? fgColor.withValues(alpha: 0.48)
        : fgColor.withValues(alpha: 0.75);

    switch (cardStyle) {
      case 1:
        effectiveFillColor = isCancelled
            ? bgColor.withValues(
                alpha: (0.28 * cardOpacity).clamp(0.0, 1.0),
              )
            : cs.surfaceContainerLowest.withValues(
                alpha: (0.52 * cardOpacity).clamp(0.0, 1.0),
              );
        effectiveBorder = Border.all(
          color: isCancelled
              ? fgColor.withValues(alpha: 0.40)
              : fgColor.withValues(alpha: isDark ? 0.42 : 0.28),
          width: 1.2,
        );
        break;
      case 2:
        effectiveFillColor = Colors.transparent;
        effectiveGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCancelled
              ? [
                  fgColor.withValues(
                    alpha: (0.25 * cardOpacity).clamp(0.0, 1.0),
                  ),
                  bgColor.withValues(
                    alpha: (0.45 * cardOpacity).clamp(0.0, 1.0),
                  ),
                ]
              : [
                  fgColor.withValues(
                    alpha:
                        ((isDark ? 0.35 : 0.25) * cardOpacity).clamp(0.0, 1.0),
                  ),
                  bgColor.withValues(alpha: cardOpacity.clamp(0.0, 1.0)),
                ],
        );
        effectiveBorder = Border.all(
          color: fgColor.withValues(alpha: isDark ? 0.30 : 0.18),
          width: 1.0,
        );
        break;
      case 3:
        effectiveFillColor = isCancelled
            ? cs.surfaceContainerLowest.withValues(
                alpha: (0.35 * cardOpacity).clamp(0.0, 1.0),
              )
            : cs.surfaceContainerLow.withValues(
                alpha: (0.60 * cardOpacity).clamp(0.0, 1.0),
              );
        effectiveBorder = Border.all(
          color: isCancelled
              ? fgColor.withValues(alpha: 0.50)
              : fgColor.withValues(alpha: isDark ? 0.85 : 0.70),
          width: 1.8,
        );
        break;
      case 4:
        effectiveFillColor = isCancelled
            ? fgColor.withValues(alpha: 0.45)
            : fgColor.withValues(alpha: cardOpacity.clamp(0.6, 1.0));
        effectiveBorder = null;
        final lum = effectiveFillColor.computeLuminance();
        final solidText = lum > 0.45 ? Colors.black87 : Colors.white;
        effectiveTextColor = solidText;
        effectiveSecondaryTextColor = solidText.withValues(alpha: 0.78);
        break;
      case 0:
      default:
        effectiveFillColor = isCancelled
            ? bgColor.withValues(
                alpha: (0.40 * cardOpacity).clamp(0.0, 1.0),
              )
            : bgColor.withValues(alpha: cardOpacity.clamp(0.0, 1.0));
        effectiveBorder = Border.all(
          color: fgColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.0,
        );
        break;
    }

    final double effectiveAccentWidth = accentStyle == 0
        ? 4.0
        : (accentStyle == 1 ? 1.8 : 0.0);

    Widget cardContent = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: effectiveFillColor,
            gradient: effectiveGradient,
            borderRadius: cardRadius,
            border: effectiveBorder,
          ),
        ),
        if (showPattern)
          Positioned.fill(
            child: CustomPaint(
              painter: _StripedHatchPainter(
                color: fgColor.withValues(alpha: isDark ? 0.18 : 0.12),
                stripeWidth: 2.0,
                gap: 7.0,
              ),
            ),
          ),
        if (accentStyle == 0 || accentStyle == 1)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: effectiveAccentWidth,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fgColor,
                    fgColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(effectiveRadius),
                  bottomLeft: Radius.circular(effectiveRadius),
                ),
              ),
            ),
          ),
        Padding(
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (accentStyle == 2) ...[
                    Container(
                      width: 7.5,
                      height: 7.5,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fgColor,
                        boxShadow: [
                          BoxShadow(
                            color: fgColor.withValues(alpha: 0.6),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                  Flexible(
                    child: Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: subjectFontSize,
                        fontWeight: FontWeight.w800,
                        color: effectiveTextColor,
                        decoration:
                            isCancelled ? TextDecoration.lineThrough : null,
                        decorationColor: fgColor.withValues(alpha: 0.6),
                        decorationThickness: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              if (showTeacher && teacher.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  teacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: teacherFontSize,
                    fontWeight: FontWeight.w600,
                    color: effectiveSecondaryTextColor,
                  ),
                ),
              ],
              if (showRoom && room.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: roomFontSize,
                    fontWeight: FontWeight.w600,
                    color: effectiveSecondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (blurEnabled) {
      cardContent = ClipRRect(
        borderRadius: cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: cardContent,
        ),
      );
    } else {
      cardContent = ClipRRect(
        borderRadius: cardRadius,
        child: cardContent,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        boxShadow: shadows,
      ),
      child: cardContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsLessonDesignTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            // ── LIVE PREVIEW ──
            _buildLivePreview(context, l, cs, isDark),

            // ── GROUP 1: CARD STYLE & PRESETS ──
            SettingsGroup(
              title: l.settingsLessonStyle,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: lessonCardStyleNotifier,
                  builder: (context, style, _) {
                    return SettingsTile(
                      icon: _styleIcon(style),
                      iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onPrimaryContainer,
                      title: l.settingsLessonStyle,
                      subtitle: _styleLabel(l, style),
                      onTap: () => _showCardStyleDialog(context),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: lessonCompactModeNotifier,
                  builder: (context, compact, _) {
                    return SettingsSwitchTile(
                      icon: Icons.density_small_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsLessonCompactMode,
                      subtitle: l.settingsLessonCompactModeDesc,
                      value: compact,
                      onChanged: _settingsSetLessonCompactMode,
                    );
                  },
                ),
              ],
            ),

            // ── GROUP 2: GLOW & LIGHTING ──
            SettingsGroup(
              title: l.settingsLessonGlow,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: lessonGlowEnabledNotifier,
                  builder: (context, glowEnabled, _) {
                    return SettingsSwitchTile(
                      icon: Icons.auto_awesome_rounded,
                      iconBackgroundColor: cs.tertiaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onTertiaryContainer,
                      title: l.settingsLessonGlow,
                      subtitle: l.settingsLessonGlowDesc,
                      value: glowEnabled,
                      onChanged: _settingsSetLessonGlowEnabled,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: lessonGlowEnabledNotifier,
                  builder: (context, glowEnabled, _) {
                    if (!glowEnabled) return const SizedBox.shrink();
                    return ValueListenableBuilder<int>(
                      valueListenable: lessonGlowModeNotifier,
                      builder: (context, mode, _) {
                        return SettingsTile(
                          icon: Icons.tune_rounded,
                          iconBackgroundColor: cs.tertiaryContainer.withValues(alpha: 0.7),
                          iconColor: cs.onTertiaryContainer,
                          title: l.settingsLessonGlowMode,
                          subtitle: _glowModeLabel(l, mode),
                          onTap: () => _showGlowModeDialog(context),
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: lessonGlowEnabledNotifier,
                  builder: (context, glowEnabled, _) {
                    if (!glowEnabled) return const SizedBox.shrink();
                    return ValueListenableBuilder<double>(
                      valueListenable: lessonGlowIntensityNotifier,
                      builder: (context, intensity, _) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l.settingsLessonGlowIntensity,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${(intensity * 100).round()}%',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: intensity,
                                min: 0.4,
                                max: 2.0,
                                onChanged: _settingsSetLessonGlowIntensity,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            // ── GROUP 3: FROSTED GLASS & BLUR ──
            SettingsGroup(
              title: l.settingsLessonBlur,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: lessonBlurEnabledNotifier,
                  builder: (context, blurEnabled, _) {
                    return SettingsSwitchTile(
                      icon: Icons.blur_on_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsLessonBlur,
                      subtitle: l.settingsLessonBlurDesc,
                      value: blurEnabled,
                      onChanged: _settingsSetLessonBlurEnabled,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: lessonBlurEnabledNotifier,
                  builder: (context, blurEnabled, _) {
                    if (!blurEnabled) return const SizedBox.shrink();
                    return ValueListenableBuilder<double>(
                      valueListenable: lessonBlurAmountNotifier,
                      builder: (context, amount, _) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l.settingsLessonBlurAmount,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${amount.round()} px',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: amount,
                                min: 4,
                                max: 28,
                                onChanged: _settingsSetLessonBlurAmount,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<double>(
                  valueListenable: lessonCardOpacityNotifier,
                  builder: (context, opacity, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l.settingsLessonCardOpacity,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                '${(opacity * 100).round()}%',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: opacity,
                            min: 0.30,
                            max: 1.0,
                            onChanged: _settingsSetLessonCardOpacity,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── GROUP 4: CORNERS & ACCENTS ──
            SettingsGroup(
              title: l.settingsLessonBorderRadius,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: lessonBorderRadiusNotifier,
                  builder: (context, radius, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l.settingsLessonBorderRadius,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                '${radius.round()} px',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: radius,
                            min: 4,
                            max: 26,
                            onChanged: _settingsSetLessonBorderRadius,
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Kompakt (6px)'),
                                selected: (radius - 6).abs() < 1.5,
                                onSelected: (_) => _settingsSetLessonBorderRadius(6),
                              ),
                              ChoiceChip(
                                label: const Text('Standard (12px)'),
                                selected: (radius - 12).abs() < 1.5,
                                onSelected: (_) => _settingsSetLessonBorderRadius(12),
                              ),
                              ChoiceChip(
                                label: const Text('Rund (18px)'),
                                selected: (radius - 18).abs() < 1.5,
                                onSelected: (_) => _settingsSetLessonBorderRadius(18),
                              ),
                              ChoiceChip(
                                label: const Text('Pill (24px)'),
                                selected: (radius - 24).abs() < 1.5,
                                onSelected: (_) => _settingsSetLessonBorderRadius(24),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: lessonAccentStyleNotifier,
                  builder: (context, accent, _) {
                    return SettingsTile(
                      icon: _accentStyleIcon(accent),
                      iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onPrimaryContainer,
                      title: l.settingsLessonAccentStyle,
                      subtitle: _accentStyleLabel(l, accent),
                      onTap: () => _showAccentStyleDialog(context),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: lessonShowTeacherNotifier,
                  builder: (context, showTeacher, _) {
                    return SettingsSwitchTile(
                      icon: Icons.person_outline_rounded,
                      iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsLessonShowTeacher,
                      subtitle: l.settingsLessonShowTeacherDesc,
                      value: showTeacher,
                      onChanged: _settingsSetLessonShowTeacher,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: lessonShowRoomNotifier,
                  builder: (context, showRoom, _) {
                    return SettingsSwitchTile(
                      icon: Icons.room_outlined,
                      iconBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.7),
                      iconColor: cs.onSecondaryContainer,
                      title: l.settingsLessonShowRoom,
                      subtitle: l.settingsLessonShowRoomDesc,
                      value: showRoom,
                      onChanged: _settingsSetLessonShowRoom,
                    );
                  },
                ),
              ],
            ),

            // ── GROUP 5: STATUS, CANCELLATIONS & DIMMING ──
            SettingsGroup(
              title: l.settingsSectionTimetable,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: lessonDimPastNotifier,
                  builder: (context, dimPast, _) {
                    return SettingsSwitchTile(
                      icon: Icons.timelapse_rounded,
                      iconBackgroundColor: cs.surfaceContainerHighest,
                      iconColor: cs.onSurfaceVariant,
                      title: l.settingsLessonDimPast,
                      subtitle: l.settingsLessonDimPastDesc,
                      value: dimPast,
                      onChanged: _settingsSetLessonDimPast,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: showCancelledNotifier,
                  builder: (context, value, _) {
                    return SettingsSwitchTile(
                      icon: Icons.event_busy_rounded,
                      iconBackgroundColor: cs.errorContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onErrorContainer,
                      title: l.settingsShowCancelled,
                      subtitle: l.settingsShowCancelledDesc,
                      value: value,
                      onChanged: _settingsSetShowCancelled,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: lessonCancelledPatternNotifier,
                  builder: (context, pattern, _) {
                    return SettingsSwitchTile(
                      icon: Icons.texture_rounded,
                      iconBackgroundColor: cs.errorContainer.withValues(
                        alpha: 0.7,
                      ),
                      iconColor: cs.onErrorContainer,
                      title: l.settingsLessonCancelledPattern,
                      subtitle: l.settingsLessonCancelledPatternDesc,
                      value: pattern,
                      onChanged: _settingsSetLessonCancelledPattern,
                    );
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: cancelledLessonColorNotifier,
                  builder: (context, colorValue, _) {
                    final cancelledColor = Color(colorValue);
                    return SettingsTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cancelledColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                      title: l.settingsCancelledColor,
                      subtitle: l.settingsCancelledColorDesc,
                      onTap: () => _showCancelledColorPicker(
                        context,
                        cancelledColor,
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── GROUP 6: SYNC & ACTIONS ──
            SettingsGroup(
              title: l.settingsRefreshPushWidgetNow,
              children: [
                SettingsTile(
                  icon: Icons.sync_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsRefreshPushWidgetNow,
                  subtitle: l.settingsRefreshPushWidgetNowDesc,
                  onTap: () async {
                    await updateUntisData();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.settingsBackgroundLoading),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
