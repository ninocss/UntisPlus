part of '../main.dart';

// --- HAUPT NAVIGATION ---
class MainNavigationScreen extends StatefulWidget {
  final bool showTutorialOnStart;

  const MainNavigationScreen({super.key, this.showTutorialOnStart = false});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _showTutorial = false;
  int _tutorialStep = 0;
  StreamSubscription<NotificationActionEvent>? _notificationActionSub;

  static const List<int> _tutorialTargets = [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _notificationActionSub = NotificationService().actionEvents.listen(
      _handleNotificationAction,
    );
    final pending = NotificationService().consumePendingActionEvent();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleNotificationAction(pending);
      });
    }
    if (widget.showTutorialOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showTutorial = true;
          _tutorialStep = 0;
          _selectedIndex = 0;
        });
      });
    }
  }

  void _handleNotificationAction(NotificationActionEvent event) {
    if (!mounted) return;

    final actionId = event.actionId.trim().isEmpty
        ? 'open_timetable'
        : event.actionId.trim();

    pendingTimetableCurrentLessonNotifier.value = event.currentLesson;
    pendingTimetableNextLessonNotifier.value = event.nextLesson;

    if (actionId == 'open_free_rooms' || actionId == 'open_next_lesson') {
      _onNavTap(0);
      pendingTimetableActionNotifier.value = actionId;
      return;
    }

    _onNavTap(0);
    pendingTimetableActionNotifier.value = 'open_timetable';
  }

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialCompleted', true);
    if (!mounted) return;
    setState(() {
      _showTutorial = false;
      _tutorialStep = 0;
    });
  }

  Future<void> _skipTutorial() async {
    await _finishTutorial();
  }

  bool _isTutorialTarget(int index) {
    if (!_showTutorial || _tutorialStep >= _tutorialTargets.length) {
      return false;
    }
    return _tutorialTargets[_tutorialStep] == index;
  }

  void _onNavTap(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }

    if (!_showTutorial) return;
    if (_tutorialStep >= _tutorialTargets.length) return;
    if (_tutorialTargets[_tutorialStep] != index) return;

    if (_tutorialStep == _tutorialTargets.length - 1) {
      setState(() => _tutorialStep = _tutorialTargets.length);
      return;
    }

    setState(() => _tutorialStep += 1);
  }

  String _tutorialTitle(AppL10n l) {
    switch (_tutorialStep) {
      case 0:
        return l.tutorialStepWeekTitle;
      case 1:
        return l.tutorialStepExamsTitle;
      case 2:
        return l.tutorialStepInfoTitle;
      case 3:
        return l.tutorialStepSettingsTitle;
      default:
        return l.tutorialStepFinishTitle;
    }
  }

  String _tutorialDesc(AppL10n l) {
    switch (_tutorialStep) {
      case 0:
        return l.tutorialStepWeekDesc;
      case 1:
        return l.tutorialStepExamsDesc;
      case 2:
        return l.tutorialStepInfoDesc;
      case 3:
        return l.tutorialStepSettingsDesc;
      default:
        return l.tutorialStepFinishDesc;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      schoolUrl = prefs.getString('schoolUrl') ?? "";
      schoolName = prefs.getString('schoolName') ?? "";
      sessionID = prefs.getString('sessionId') ?? "";
      personType = prefs.getInt('personType') ?? 0;
      personId = prefs.getInt('personId') ?? 0;
    });
  }

  List<Widget> get _pages => <Widget>[
    WeeklyTimetablePage(key: ValueKey(sessionID)),
    const ExamsPage(),
    const SchoolNotificationsPage(),
    const SettingsHubPage(),
  ];

  @override
  void dispose() {
    _notificationActionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Color.alphaBlend(
                            cs.primary.withValues(alpha: 0.18),
                            cs.surface,
                          ),
                          Color.alphaBlend(
                            cs.tertiary.withValues(alpha: 0.14),
                            cs.surface,
                          ),
                          cs.surface,
                        ]
                      : [
                          Color.alphaBlend(
                            cs.primary.withValues(alpha: 0.08),
                            cs.surface,
                          ),
                          Color.alphaBlend(
                            cs.secondary.withValues(alpha: 0.07),
                            cs.surface,
                          ),
                          cs.surface,
                        ],
                ),
              ),
            ),
          ),
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(bottom: mq.padding.bottom + 104),
            ),
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
          Positioned.fill(
            child: ValueListenableBuilder<bool>(
              valueListenable: backgroundAnimationsNotifier,
              builder: (context, enabled, _) {
                if (!enabled) return const SizedBox.shrink();
                return ValueListenableBuilder<int>(
                  valueListenable: backgroundAnimationStyleNotifier,
                  builder: (context, style, _) {
                    return IgnorePointer(
                      ignoring: true,
                      child: Opacity(
                        opacity: isDark ? 0.28 : 0.2,
                        child: _AnimatedBackgroundScene(style: style),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Floating nav bar
          Positioned(
            left: 16,
            right: 16,
            bottom: mq.padding.bottom + 16,
            child: ValueListenableBuilder<String>(
              valueListenable: appLocaleNotifier,
              builder: (context, locale, _) {
                return _buildFloatingNavBar(context, cs);
              },
            ),
          ),
          if (_showTutorial)
            Positioned(
              left: 16,
              right: 16,
              top: mq.padding.top + 10,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school_rounded, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.tutorialTitle,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _skipTutorial,
                            child: Text(l.tutorialSkip),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tutorialTitle(l),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tutorialDesc(l),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      if (_tutorialStep >= _tutorialTargets.length) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _finishTutorial,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(l.tutorialDone),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, ColorScheme cs) {
    final timetableSelected = _selectedIndex == 0;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 560),
              curve: _kSmoothBounce,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - val) * 26),
                  child: Opacity(opacity: val.clamp(0, 1), child: child),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: _withOptionalBackdropBlur(
                  sigmaX: 16,
                  sigmaY: 16,
                  child: const SizedBox.shrink(),
                  childBuilder: (enabled) => AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: _kSoftBounce,
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: enabled
                          ? Color.alphaBlend(
                              cs.primaryContainer.withValues(alpha: 0.18),
                              cs.surface.withValues(alpha: 0.72),
                            )
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.assignment_outlined,
                          selectedIcon: Icons.assignment_rounded,
                          label: l.navExams,
                          selected: _selectedIndex == 1,
                          onTap: () => _onNavTap(1),
                          tutorialHighlight: _isTutorialTarget(1),
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.campaign_outlined,
                          selectedIcon: Icons.campaign_rounded,
                          label: l.navInfo,
                          selected: _selectedIndex == 2,
                          onTap: () => _onNavTap(2),
                          tutorialHighlight: _isTutorialTarget(2),
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.settings_outlined,
                          selectedIcon: Icons.settings_rounded,
                          label: l.navMenu,
                          selected: _selectedIndex == 3,
                          onTap: () => _onNavTap(3),
                          tutorialHighlight: _isTutorialTarget(3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 620),
              curve: _kSmoothBounce,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: Transform.scale(
                    scale: 0.92 + (value * 0.08),
                    child: Opacity(opacity: value.clamp(0, 1), child: child),
                  ),
                );
              },
              child: AnimatedScale(
                scale: timetableSelected ? 1.04 : 0.96,
                duration: const Duration(milliseconds: 360),
                curve: _kSmoothBounce,
                child: _BouncyButton(
                  onTap: () => _onNavTap(0),
                  scaleTarget: 0.9,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: _kSoftBounce,
                    height: timetableSelected ? 74 : 62,
                    width: timetableSelected ? 74 : 62,
                    decoration: BoxDecoration(
                      color: timetableSelected
                          ? cs.primary
                          : cs.surfaceContainerHigh.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(
                        timetableSelected ? 24 : 20,
                      ),
                      border: Border.all(
                        color: _isTutorialTarget(0)
                            ? cs.tertiary
                            : timetableSelected
                            ? cs.primary.withValues(alpha: 0.44)
                            : cs.outlineVariant.withValues(alpha: 0.36),
                        width: _isTutorialTarget(0) ? 2.0 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (timetableSelected
                                      ? cs.primary
                                      : cs.surfaceContainerHigh)
                                  .withValues(alpha: 0.38),
                          blurRadius: timetableSelected ? 22 : 14,
                          offset: Offset(0, timetableSelected ? 8 : 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: _kSmoothBounce,
                        switchOutCurve: _kSoftBounce,
                        transitionBuilder: (child, anim) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(anim);
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: slide,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.88,
                                  end: 1.0,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: AnimatedRotation(
                          turns: timetableSelected ? 0 : -0.04,
                          duration: const Duration(milliseconds: 360),
                          curve: _kSmoothBounce,
                          child: Icon(
                            timetableSelected
                                ? Icons.watch_later_rounded
                                : Icons.watch_later_outlined,
                            key: ValueKey('timetable_$timetableSelected'),
                            color: timetableSelected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                            size: timetableSelected ? 36 : 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIconBtn({
    required ColorScheme cs,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool tutorialHighlight = false,
  }) {
    return _BouncyButton(
      onTap: onTap,
      scaleTarget: 0.8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: _kSoftBounce,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: tutorialHighlight
              ? Border.all(color: cs.tertiary, width: 2)
              : selected
              ? Border.all(color: cs.primary.withValues(alpha: 0.22), width: 1)
              : Border.all(color: Colors.transparent, width: 0),
          boxShadow: tutorialHighlight
              ? [
                  BoxShadow(
                    color: cs.tertiary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: _kSmoothBounce,
              switchOutCurve: _kSoftBounce,
              transitionBuilder: (child, anim) {
                return ScaleTransition(scale: anim, child: child);
              },
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                size: selected ? 23 : 26,
                color: selected
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: _kSoftBounce,
              alignment: Alignment.centerLeft,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleTarget;

  const _BouncyButton({
    required this.child,
    required this.onTap,
    this.scaleTarget = 0.9,
  });

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _tapLocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleTarget)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: _kSoftBounce,
            reverseCurve: _kSmoothBounce,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (_tapLocked) return;
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTap: () {
        if (_tapLocked) return;
        _tapLocked = true;
        widget.onTap();
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 140), () {
          if (!mounted) return;
          _tapLocked = false;
        });
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
