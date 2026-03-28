part of '../main.dart';

// --- HAUPT NAVIGATION ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            cs.primary.withOpacity(0.18),
                            cs.surface,
                          ),
                          Color.alphaBlend(
                            cs.tertiary.withOpacity(0.14),
                            cs.surface,
                          ),
                          cs.surface,
                        ]
                      : [
                          Color.alphaBlend(
                            cs.primary.withOpacity(0.08),
                            cs.surface,
                          ),
                          Color.alphaBlend(
                            cs.secondary.withOpacity(0.07),
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
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, ColorScheme cs) {
    final timetableSelected = _selectedIndex == 0;
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
                borderRadius: BorderRadius.circular(30),
                child: _withOptionalBackdropBlur(
                  sigmaX: 16,
                  sigmaY: 16,
                  child: const SizedBox.shrink(),
                  childBuilder: (enabled) => AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: _kSoftBounce,
                    height: 66,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: enabled
                          ? cs.surface.withOpacity(0.72)
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.42),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 9),
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
                          selected: _selectedIndex == 1,
                          onTap: () {
                            if (_selectedIndex != 1) {
                              setState(() => _selectedIndex = 1);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.campaign_outlined,
                          selectedIcon: Icons.campaign_rounded,
                          selected: _selectedIndex == 2,
                          onTap: () {
                            if (_selectedIndex != 2) {
                              setState(() => _selectedIndex = 2);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        _navIconBtn(
                          cs: cs,
                          icon: Icons.settings_outlined,
                          selectedIcon: Icons.settings_rounded,
                          selected: _selectedIndex == 3,
                          onTap: () {
                            if (_selectedIndex != 3) {
                              setState(() => _selectedIndex = 3);
                            }
                          },
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
                  onTap: () {
                    if (_selectedIndex != 0) {
                      setState(() => _selectedIndex = 0);
                    }
                  },
                  scaleTarget: 0.9,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: _kSoftBounce,
                    height: timetableSelected ? 74 : 62,
                    width: timetableSelected ? 74 : 62,
                    decoration: BoxDecoration(
                      color: timetableSelected
                          ? cs.primary
                          : cs.surfaceContainerHigh.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(
                        timetableSelected ? 24 : 20,
                      ),
                      border: Border.all(
                        color: timetableSelected
                            ? cs.primary.withOpacity(0.44)
                            : cs.outlineVariant.withOpacity(0.36),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (timetableSelected
                                      ? cs.primary
                                      : cs.surfaceContainerHigh)
                                  .withOpacity(0.38),
                          blurRadius: timetableSelected ? 22 : 14,
                          offset: Offset(0, timetableSelected ? 8 : 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: _kSmoothBounce,
                        switchOutCurve: Curves.easeInCubic,
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
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _BouncyButton(
      onTap: onTap,
      scaleTarget: 0.8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: _kSoftBounce,
        width: selected ? 60 : 48,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? Border.all(color: cs.primary.withOpacity(0.22), width: 1)
              : Border.all(color: Colors.transparent, width: 0),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: _kSmoothBounce,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return ScaleTransition(scale: anim, child: child);
          },
          child: Icon(
            selected ? selectedIcon : icon,
            key: ValueKey(selected),
            size: selected ? 27 : 25,
            color: selected
                ? cs.onPrimaryContainer
                : cs.onSurfaceVariant.withOpacity(0.8),
          ),
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
            curve: Curves.easeOutQuad,
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
