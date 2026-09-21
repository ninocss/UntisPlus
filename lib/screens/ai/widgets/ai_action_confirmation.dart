part of '../../../main.dart';

class _AiActionConfirmationContent extends StatelessWidget {
  final List<_AiProposedAction> actions;

  const _AiActionConfirmationContent({
    super.key,
    required this.actions,
  });

  bool _destructive(String kind) =>
      kind.startsWith('delete_') || kind == 'complete_homework';

  IconData _icon(String kind) {
    if (kind.contains('homework')) return Icons.assignment_outlined;
    if (kind.contains('exam')) return Icons.event_note_outlined;
    if (kind.contains('grade')) return Icons.grading_outlined;
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.ui('aiApplyChangesDesc'),
          style: untisThemeTextStyle(
            context,
            fontSize: 14,
            height: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (final action in actions) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_destructive(action.kind)
                      ? cs.errorContainer
                      : cs.surfaceContainerHigh)
                  .withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(_aiRadius(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _icon(action.kind),
                  size: 20,
                  color: _destructive(action.kind)
                      ? cs.onErrorContainer
                      : cs.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.summary(l),
                    style: untisThemeTextStyle(
                      context,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: _destructive(action.kind)
                          ? cs.onErrorContainer
                          : cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
