part of '../../../main.dart';

class _AiModeSwitch extends StatelessWidget {
  final _AiMode selectedMode;
  final ValueChanged<_AiMode> onChanged;
  final bool enabled;

  const _AiModeSwitch({
    super.key,
    required this.selectedMode,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);
    final duration = _aiMotionDuration(
      context,
      normal: _kAiExpressiveMotion,
    );
    final curve = _aiMotionCurve(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: SizedBox(
            height: 52,
            child: ThemedSurface(
              blur: true,
              showShadow: false,
              borderRadius: BorderRadius.circular(_aiRadius(28)),
              color: cs.surfaceContainerHigh.withValues(alpha: 0.72),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.28),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final segmentWidth = constraints.maxWidth / 2;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedAlign(
                        duration: duration,
                        curve: curve,
                        alignment: selectedMode == _AiMode.analysis
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SizedBox(
                            width: math.max(0, segmentWidth - 8),
                            height: 44,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(
                                  _aiRadius(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _AiModeSegment(
                              label: l.aiTabAnalysis,
                              icon: Icons.analytics_outlined,
                              selectedIcon: Icons.analytics_rounded,
                              selected: selectedMode == _AiMode.analysis,
                              enabled: enabled,
                              onTap: () => onChanged(_AiMode.analysis),
                            ),
                          ),
                          Expanded(
                            child: _AiModeSegment(
                              label: l.aiTabChat,
                              icon: Icons.chat_bubble_outline_rounded,
                              selectedIcon: Icons.chat_bubble_rounded,
                              selected: selectedMode == _AiMode.chat,
                              enabled: enabled,
                              onTap: () => onChanged(_AiMode.chat),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiModeSegment extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AiModeSegment({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_AiModeSegment> createState() => _AiModeSegmentState();
}

class _AiModeSegmentState extends State<_AiModeSegment> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final duration = _aiMotionDuration(
      context,
      normal: const Duration(milliseconds: 220),
    );
    final foreground = widget.selected ? cs.onPrimary : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          borderRadius: BorderRadius.circular(_aiRadius(24)),
          child: AnimatedScale(
            duration: duration,
            curve: Curves.easeOutCubic,
            scale: _pressed && !_aiReduceMotion(context) ? 0.97 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    widget.selected ? widget.selectedIcon : widget.icon,
                    key: ValueKey(widget.selected),
                    size: 19,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: widget.selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
