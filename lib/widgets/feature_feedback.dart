import 'package:flutter/material.dart';
import 'app_experience_scope.dart';

enum FeatureFeedbackKind { loading, empty, error, notice }

/// Feedback that grows with text instead of assigning a fixed card height.
/// Material controls provide focus, hover, pressed and disabled states.
class FeatureFeedback extends StatelessWidget {
  const FeatureFeedback({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.compact = false,
  });

  final FeatureFeedbackKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final error = kind == FeatureFeedbackKind.error;
    final loading = kind == FeatureFeedbackKind.loading;
    final foreground = error ? cs.onErrorContainer : cs.onSurface;
    final experience = AppExperienceScope.maybeOf(context);
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        !(experience?.interactions ?? true) ||
        !(experience?.active ?? true) ||
        !TickerMode.valuesOf(context).enabled;
    return Semantics(
      container: true,
      liveRegion: error || loading,
      child: Material(
        color: error ? cs.errorContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 16 : 24),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: loading && !reducedMotion
                        ? SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: cs.primary,
                            ),
                          )
                        : Icon(
                            icon ??
                                switch (kind) {
                                  FeatureFeedbackKind.loading =>
                                    Icons.hourglass_top_rounded,
                                  FeatureFeedbackKind.empty =>
                                    Icons.inbox_outlined,
                                  FeatureFeedbackKind.error =>
                                    Icons.cloud_off_rounded,
                                  FeatureFeedbackKind.notice =>
                                    Icons.info_outline_rounded,
                                },
                            color: foreground,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: foreground),
                        ),
                        if (message != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            message!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: foreground),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (loading && !compact) ...[
                const SizedBox(height: 24),
                ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final fraction in [1.0, 0.8, 0.6])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: fraction,
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
