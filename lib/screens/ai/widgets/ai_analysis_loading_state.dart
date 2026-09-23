part of '../../../main.dart';

class _AiAnalysisLoadingState extends StatelessWidget {
  final String query;

  const _AiAnalysisLoadingState({
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedSurface(
            showShadow: false,
            borderRadius: BorderRadius.circular(_aiRadius(28)),
            color: cs.surfaceContainerHigh.withValues(alpha: 0.8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(_aiRadius(15)),
                        ),
                        child: Icon(
                          Icons.manage_search_rounded,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          query.trim().isEmpty ? l.aiSearchRunning : query,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: untisThemeTextStyle(
                            context,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.aiSearchShapingDesc,
                    style: untisThemeTextStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _AiTypingIndicator(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 2; i++) ...[
            _AiSkeletonBlock(delayIndex: i),
            if (i == 0) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AiSkeletonBlock extends StatelessWidget {
  final int delayIndex;

  const _AiSkeletonBlock({required this.delayIndex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_aiReduceMotion(context)) {
      return Container(
        height: 82,
        decoration: BoxDecoration(
          color: cs.surfaceContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(_aiRadius(22)),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.75),
      duration: Duration(milliseconds: 700 + delayIndex * 120),
      curve: Curves.easeInOut,
      builder: (context, value, _) => Container(
        height: 82,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: value),
          borderRadius: BorderRadius.circular(_aiRadius(22)),
        ),
      ),
    );
  }
}
