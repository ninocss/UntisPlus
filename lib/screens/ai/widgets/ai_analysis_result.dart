part of '../../../main.dart';

class _AiAnalysisResult extends StatelessWidget {
  final _AiSearchResult result;
  final bool thinking;
  final IconData Function(String label) metricIcon;
  final VoidCallback onSearchAgain;
  final VoidCallback onClear;

  const _AiAnalysisResult({
    super.key,
    required this.result,
    required this.thinking,
    required this.metricIcon,
    required this.onSearchAgain,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiResultEntrance(
            index: 0,
            child: ThemedSurface(
              borderRadius: BorderRadius.circular(_aiRadius(28)),
              color: cs.surfaceContainerHigh.withValues(alpha: 0.76),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(21),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(_aiRadius(15)),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 22,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            result.headline,
                            style: untisThemeTextStyle(
                              context,
                              display: true,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.summary,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (result.tags.isNotEmpty) ...[
                      const SizedBox(height: 17),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: result.tags.take(4).map((tag) {
                          return Container(
                            constraints: const BoxConstraints(minHeight: 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.66),
                              borderRadius: BorderRadius.circular(_aiRadius(14)),
                            ),
                            child: Text(
                              tag,
                              style: untisThemeTextStyle(
                                context,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (result.metrics.isNotEmpty) ...[
            const SizedBox(height: 24),
            _AiResultEntrance(
              index: 1,
              child: _AiResultSectionHeader(
                icon: Icons.bar_chart_rounded,
                title: l.aiOverview,
              ),
            ),
            const SizedBox(height: 12),
            _AiResultEntrance(
              index: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: constraints.maxWidth < 390 ? 1.35 : 1.55,
                    children: result.metrics
                        .map(
                          (metric) => _AiMetricTile(
                            metric: metric,
                            icon: metricIcon(metric.label),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ),
          ],
          if (result.lessons.isNotEmpty) ...[
            const SizedBox(height: 24),
            _AiResultEntrance(
              index: 3,
              child: _AiResultSectionHeader(
                icon: Icons.school_rounded,
                title: l.aiLessons,
              ),
            ),
            const SizedBox(height: 12),
            _AiResultEntrance(
              index: 4,
              child: Column(
                children: result.lessons
                    .map(
                      (lesson) => LessonCard(
                        subject: lesson.subject,
                        subjectShort: lesson.subjectShort,
                        room: lesson.room,
                        teacher: lesson.teacher,
                        time: lesson.time,
                        isCancelled: lesson.isCancelled,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _AiResultEntrance(
            index: 5,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onSearchAgain,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: Text(l.aiSearchAgain),
                ),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 19),
                  label: Text(l.aiClearResult),
                ),
              ],
            ),
          ),
          if (thinking) ...[
            const SizedBox(height: 14),
            const _AiTypingIndicator(),
          ],
        ],
      ),
    );
  }
}

class _AiResultSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _AiResultSectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 9),
        Text(
          title,
          style: untisThemeTextStyle(
            context,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AiResultEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const _AiResultEntrance({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (_aiReduceMotion(context)) return child;
    final duration = Duration(milliseconds: 280 + math.min(index, 4) * 35);
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
