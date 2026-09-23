part of '../main.dart';

// --- DETAIL BOTTOM SHEET OPENER ---
void _showLessonDetail(
  BuildContext context,
  dynamic lesson, {
  String originalTeacher = '',
}) {
  HapticFeedback.mediumImpact();
  final subject = lesson['_subjectLong']?.toString().isNotEmpty == true
      ? lesson['_subjectLong'].toString()
      : (lesson['_subjectShort']?.toString().isNotEmpty == true
            ? lesson['_subjectShort'].toString()
            : '---');
  final subjectShort = lesson['_subjectShort']?.toString() ?? '';
  final room = lesson['_room']?.toString().isNotEmpty == true
      ? lesson['_room'].toString()
      : '---';
  final teacher = lesson['_teacher']?.toString() ?? '';
  final time =
      '${_formatUntisTime(lesson['startTime'].toString())} – ${_formatUntisTime(lesson['endTime'].toString())}';
  final isCancelled = (lesson['code'] ?? '') == 'cancelled';
  final info = (lesson['info'] ?? lesson['substText'] ?? '').toString().trim();
  final lessonNr = lesson['lsnumber']?.toString() ?? '';
  final studentNotes = (lesson['lsText'] ?? lesson['lstext'] ?? '')
      .toString()
      .trim();
  final subjectKey = lesson['_subjectShort']?.toString() ?? '';
  final eventName = lesson['_eventName']?.toString() ?? '';
  final classNames = lesson['_classNames']?.toString() ?? '';
  final activityType = lesson['_activityType']?.toString() ?? '';

  // Attach homework and class-register notes for this specific lesson. The
  // lesson id alone is not unique across dates, so match on date as well.
  final lessonId = lesson['id'] ?? lesson['lsid'];
  final dateInt = lesson['date'] as int?;

  final homework = homeworksNotifier.value
      .where((h) => h['lessonId'] == lessonId)
      .map((h) => h['text']?.toString() ?? '')
      .where((t) => t.isNotEmpty)
      .join('\n');

  final registerNotes = lessonNotesNotifier.value
      .where((n) {
        final noteLessonId = n['lessonId'];
        final noteDate = n['date'] as int?;
        return noteLessonId == lessonId &&
            (noteDate == null || noteDate == dateInt);
      })
      .map((n) => n['text']?.toString() ?? '')
      .where((t) => t.isNotEmpty)
      .join('\n');

  _showUnifiedSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (_) => _LessonDetailSheet(
      subject: subject,
      subjectShort: subjectShort,
      room: room,
      teacher: teacher,
      originalTeacher: originalTeacher,
      time: time,
      isCancelled: isCancelled,
      info: info,
      lessonNr: lessonNr,
      eventName: eventName,
      classNames: classNames,
      activityType: activityType,
      studentNotes: studentNotes,
      registerNotes: registerNotes,
      homework: homework,
      onHideSubject: () {
        Navigator.of(context).pop();
        _hideSubject(subjectKey);
      },
    ),
  );
}

class _LessonDetailSheet extends StatelessWidget {
  final String subject, subjectShort, room, teacher, time, info, lessonNr;
  final String originalTeacher;
  final String eventName, classNames, activityType;
  final String studentNotes, registerNotes, homework;
  final bool isCancelled;
  final VoidCallback? onHideSubject;

  const _LessonDetailSheet({
    required this.subject,
    required this.subjectShort,
    required this.room,
    required this.teacher,
    required this.time,
    required this.isCancelled,
    required this.info,
    required this.lessonNr,
    this.originalTeacher = '',
    this.eventName = '',
    this.classNames = '',
    this.activityType = '',
    this.studentNotes = '',
    this.registerNotes = '',
    this.homework = '',
    this.onHideSubject,
  });

  Widget _topActionButton(
    BuildContext context,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    if (value.isEmpty || value == '---') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final cancelledColor = Color(
      cancelledLessonColorNotifier.value,
    ).harmonizeWith(cs.primary);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cancelledColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: cancelledColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.detailCancelled,
                        style: GoogleFonts.outfit(
                          color: cancelledColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: cs.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.detailRegular,
                        style: GoogleFonts.outfit(
                          color: cs.tertiary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              _topActionButton(
                context,
                Icons.visibility_off_outlined,
                cs.onSurface.withValues(alpha: 0.6),
                onTap: onHideSubject,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            subject,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          if (subjectShort.isNotEmpty)
            Text(
              subjectShort,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.primary.withValues(alpha: 0.7),
              ),
            ),

          const SizedBox(height: 24),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 16),

          _row(context, Icons.access_time_rounded, l.detailTime, time),
          _row(context, Icons.person_rounded, l.detailTeacher, teacher),
          if (originalTeacher.isNotEmpty && originalTeacher != teacher)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.tertiary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: cs.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.detailOriginalTeacher,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          originalTeacher,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: cs.tertiary.withValues(alpha: 0.7),
                            decorationThickness: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _row(context, Icons.room_rounded, l.detailRoom, room),
          if (classNames.isNotEmpty)
            _row(context, Icons.group_rounded, l.detailClass, classNames),
          if (activityType.isNotEmpty && activityType != 'Unterricht')
            _row(context, Icons.category_rounded, 'Art', activityType),
          if (lessonNr.isNotEmpty && lessonNr != '0')
            _row(context, Icons.tag_rounded, l.detailLesson, lessonNr),
          if (studentNotes.isNotEmpty)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  _buildBouncyRoute(
                    StudentNotesPage(
                      notes: studentNotes,
                      registerNotes: registerNotes,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: _row(
                context,
                Icons.notes_rounded,
                l.detailNotesForStudents,
                studentNotes,
              ),
            ),
          if (registerNotes.isNotEmpty)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  _buildBouncyRoute(
                    StudentNotesPage(
                      notes: studentNotes,
                      registerNotes: registerNotes,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: _row(
                context,
                Icons.book_rounded,
                l.detailLessonNotes,
                registerNotes,
                iconColor: cs.primary,
              ),
            ),
          if (homework.isNotEmpty)
            InkWell(
              onTap: () {
                Navigator.of(
                  context,
                ).push(_buildBouncyRoute(const HomeworkPage()));
              },
              borderRadius: BorderRadius.circular(16),
              child: _row(
                context,
                Icons.assignment_rounded,
                l.detailHomework,
                homework,
              ),
            ),
          if (info.isNotEmpty)
            _row(
              context,
              Icons.info_outline_rounded,
              l.detailInfo,
              info,
              iconColor: cs.tertiary,
            ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// --- NOTIZEN DETAIL SEITE ---

class StudentNotesPage extends StatelessWidget {
  /// Planned lesson text from the timetable (`lsText`).
  final String notes;

  /// Actual notes from the class register (WebUntis lessonNotes).
  final String registerNotes;

  const StudentNotesPage({
    super.key,
    required this.notes,
    this.registerNotes = '',
  });

  Widget _noteSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.detailNotesForStudents,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _AnimatedBackground(child: const SizedBox.expand()),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: _withOptionalBackdropBlur(
                sigma: 24,
                child: const SizedBox.shrink(),
                childBuilder: (enabled) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notes.isNotEmpty) ...[
                        _noteSectionHeader(
                          context,
                          icon: Icons.notes_rounded,
                          title: l.detailNotesForStudents,
                          iconColor: cs.tertiary,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          notes,
                          style: GoogleFonts.outfit(
                            fontSize: 17.5,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                      if (notes.isNotEmpty && registerNotes.isNotEmpty)
                        const SizedBox(height: 36),
                      if (registerNotes.isNotEmpty) ...[
                        _noteSectionHeader(
                          context,
                          icon: Icons.book_rounded,
                          title: l.detailLessonNotes,
                          iconColor: cs.primary,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          registerNotes,
                          style: GoogleFonts.outfit(
                            fontSize: 17.5,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- EXPRESSIVE CARD DESIGN ---
class LessonCard extends StatelessWidget {
  final String subject, subjectShort, room, teacher, time;
  final bool isCancelled;
  final VoidCallback? onTap;
  final VoidCallback? onHideSubject;

  const LessonCard({
    super.key,
    required this.subject,
    this.subjectShort = "",
    required this.room,
    this.teacher = "",
    required this.time,
    this.isCancelled = false,
    this.onTap,
    this.onHideSubject,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = untisThemeTokensOf(context);
    final themeOwnsStyle = tokens.id != AppThemeId.defaultTheme;
    final cancelledColor = Color(
      cancelledLessonColorNotifier.value,
    ).harmonizeWith(cs.primary);

    final effectiveRadius = themeOwnsStyle
        ? tokens.surfaceRadius
        : (lessonBorderRadiusNotifier.value * 2.0).clamp(16.0, 36.0);
    final cardRadius = BorderRadius.circular(effectiveRadius);

    final showTeacher = lessonShowTeacherNotifier.value;
    final showRoom = lessonShowRoomNotifier.value;
    final cardStyle = themeOwnsStyle ? 3 : lessonCardStyleNotifier.value;
    final blurEnabled =
        tokens.supportsBlur &&
        blurEnabledNotifier.value &&
        (themeOwnsStyle || lessonBlurEnabledNotifier.value || cardStyle == 1);
    final blurSigma = themeOwnsStyle
        ? tokens.blurSigma
        : lessonBlurAmountNotifier.value;
    final cardOpacity = themeOwnsStyle ? 0.84 : lessonCardOpacityNotifier.value;
    final glowEnabled = tokens.glowEffectsEnabled;
    final accentStyle = themeOwnsStyle ? 0 : lessonAccentStyleNotifier.value;

    final primaryColor = isCancelled ? cancelledColor : cs.primary;

    List<BoxShadow>? shadows;
    if (glowEnabled) {
      shadows = [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.18),
          blurRadius: 12,
          spreadRadius: 0.8,
          offset: const Offset(0, 3),
        ),
      ];
    }

    Color surfaceColor;
    Border? border;
    if (isCancelled) {
      surfaceColor = cancelledColor.withValues(
        alpha: (0.16 * cardOpacity).clamp(0.0, 1.0),
      );
      border = Border.all(
        color: cancelledColor.withValues(alpha: 0.40),
        width: 1.5,
      );
    } else if (cardStyle == 1 || blurEnabled) {
      surfaceColor = cs.surfaceContainerLowest.withValues(
        alpha: (0.65 * cardOpacity).clamp(0.0, 1.0),
      );
      border = Border.all(
        color: cs.outlineVariant.withValues(alpha: 0.45),
        width: 1.5,
      );
    } else if (cardStyle == 3) {
      surfaceColor = cs.surfaceContainerLow.withValues(
        alpha: (0.75 * cardOpacity).clamp(0.0, 1.0),
      );
      border = Border.all(
        color: primaryColor.withValues(alpha: isDark ? 0.70 : 0.50),
        width: 2.0,
      );
    } else {
      surfaceColor = cs.surfaceContainerLow.withValues(
        alpha: cardOpacity.clamp(0.4, 1.0),
      );
      border = Border.all(
        color: cs.outlineVariant.withValues(alpha: 0.35),
        width: 1.5,
      );
    }

    if (tokens.id == AppThemeId.manga) {
      surfaceColor = cs.surfaceContainerLow;
      border = Border.all(color: cs.outline, width: tokens.borderWidth);
      shadows = [
        BoxShadow(
          color: tokens.shadowColor,
          offset: tokens.shadowOffset,
          blurRadius: 0,
        ),
      ];
    } else if (tokens.id == AppThemeId.cyber) {
      border = Border.all(color: primaryColor, width: tokens.borderWidth);
    }

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: cardRadius,
        border: border,
      ),
      child: Stack(
        children: [
          if (accentStyle == 0 || accentStyle == 1)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: accentStyle == 0 ? 5.0 : 2.5,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(effectiveRadius),
                    bottomLeft: Radius.circular(effectiveRadius),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                if (accentStyle == 2) ...[
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: _glowShadows(context, [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.outfit(
                          color: isCancelled ? cancelledColor : cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isCancelled ? cancelledColor : null,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: cancelledColor.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      if (subjectShort.isNotEmpty)
                        Text(
                          subjectShort,
                          style: GoogleFonts.outfit(
                            color: isCancelled
                                ? cancelledColor.withValues(alpha: 0.7)
                                : cs.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (showRoom && room.isNotEmpty) ...[
                            Icon(
                              Icons.room_outlined,
                              size: 15,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (showTeacher && teacher.isNotEmpty) ...[
                            if (showRoom && room.isNotEmpty)
                              const SizedBox(width: 12),
                            Icon(
                              Icons.person_outline_rounded,
                              size: 15,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              teacher,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCancelled)
                  Badge(
                    label: Text(
                      appL10nFor(appLocaleNotifier.value).detailCancelledBadge,
                    ),
                    backgroundColor: cancelledColor,
                    textColor: cs.onError,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (blurEnabled) {
      cardBody = ClipRRect(
        borderRadius: cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: cardBody,
        ),
      );
    } else {
      cardBody = ClipRRect(borderRadius: cardRadius, child: cardBody);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(borderRadius: cardRadius, boxShadow: shadows),
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        onTapDown: (_) => HapticFeedback.selectionClick(),
        child: cardBody,
      ),
    );
  }
}
