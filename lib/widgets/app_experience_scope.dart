import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_experience.dart';

/// Application lifecycle and scroll activity, shared by motion consumers.
class AppExperienceScope extends StatefulWidget {
  const AppExperienceScope({super.key, required this.child});
  final Widget child;

  static AppExperienceData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppExperienceData>();

  @override
  State<AppExperienceScope> createState() => _AppExperienceScopeState();
}

class _AppExperienceScopeState extends State<AppExperienceScope>
    with WidgetsBindingObserver {
  bool _active = true;
  bool _scrolling = false;
  bool _scrollStartQueued = false;
  Timer? _scrollEnd;
  late final Listenable _preferences = Listenable.merge([
    effectQualityNotifier,
    interactionAnimationsEnabledNotifier,
  ]);

  @override
  void initState() {
    super.initState();
    _active =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active != _active) setState(() => _active = active);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _scrollEnd?.cancel();
      // Scroll notifications arrive after layout; publish on the next frame.
      if (!_scrolling && !_scrollStartQueued) {
        _scrollStartQueued = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollStartQueued = false;
          if (mounted && !_scrolling) setState(() => _scrolling = true);
        });
      }
    } else if (notification is ScrollEndNotification) {
      _scrollEnd?.cancel();
      _scrollEnd = Timer(const Duration(milliseconds: 160), () {
        if (mounted && _scrolling) setState(() => _scrolling = false);
      });
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollEnd?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _preferences,
    child: widget.child,
    builder: (context, child) => AppExperienceData(
      active: _active,
      scrolling: _scrolling,
      quality: effectQualityNotifier.value,
      interactions: interactionAnimationsEnabledNotifier.value,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: child!,
      ),
    ),
  );
}

class AppExperienceData extends InheritedWidget {
  const AppExperienceData({
    super.key,
    required this.active,
    required this.scrolling,
    required this.quality,
    required this.interactions,
    required super.child,
  });
  final bool active;
  final bool scrolling;
  final AppEffectQuality quality;
  final bool interactions;

  bool get backgroundAllowed =>
      active &&
      quality != AppEffectQuality.reduced &&
      !(quality == AppEffectQuality.balanced && scrolling);

  @override
  bool updateShouldNotify(AppExperienceData oldWidget) =>
      active != oldWidget.active ||
      scrolling != oldWidget.scrolling ||
      quality != oldWidget.quality ||
      interactions != oldWidget.interactions;
}

/// A covered route pauses tickers without destroying its content or state.
class AppRouteActivity extends StatelessWidget {
  const AppRouteActivity({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled:
        (ModalRoute.isCurrentOf(context) ?? true) &&
        (AppExperienceScope.maybeOf(context)?.active ?? true),
    child: child,
  );
}
