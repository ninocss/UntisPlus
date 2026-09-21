part of '../../../main.dart';

class _AiSuggestionCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const _AiSuggestionCard({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_AiSuggestionCard> createState() => __AiSuggestionCardState();
}

class __AiSuggestionCardState extends State<_AiSuggestionCard> {
  bool _pressed = false;

  void _press(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final duration = _aiMotionDuration(
      context,
      normal: const Duration(milliseconds: 240),
    );

    if (widget.compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_aiRadius(18)),
          onTap: widget.onTap,
          onTapDown: (_) => _press(true),
          onTapCancel: () => _press(false),
          onTapUp: (_) => _press(false),
          child: AnimatedScale(
            duration: duration,
            scale: _pressed && !_aiReduceMotion(context) ? 0.975 : 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (_pressed
                        ? cs.primaryContainer
                        : cs.surfaceContainerHigh)
                    .withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(_aiRadius(18)),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 17, color: cs.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_aiRadius(22)),
          onTap: widget.onTap,
          onTapDown: (_) => _press(true),
          onTapCancel: () => _press(false),
          onTapUp: (_) => _press(false),
          child: AnimatedScale(
            duration: duration,
            curve: Curves.easeOutCubic,
            scale: _pressed && !_aiReduceMotion(context) ? 0.975 : 1,
            child: AnimatedContainer(
              duration: duration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: (_pressed
                        ? cs.primaryContainer
                        : cs.surfaceContainerHigh)
                    .withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(_aiRadius(22)),
                border: Border.all(
                  color: (_pressed ? cs.primary : cs.outlineVariant)
                      .withValues(alpha: _pressed ? 0.25 : 0.18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(_aiRadius(14)),
                    ),
                    child: Icon(widget.icon, size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
