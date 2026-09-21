part of '../../../main.dart';

class _AiHeroSurface extends StatelessWidget {
  final _AiMode mode;
  final String title;
  final String subtitle;
  final String? status;

  const _AiHeroSurface({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = mode == _AiMode.analysis
        ? Icons.manage_search_rounded
        : Icons.auto_awesome_rounded;
    final duration = _aiMotionDuration(
      context,
      normal: const Duration(milliseconds: 340),
    );

    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: _aiMotionCurve(context),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        final dy = _aiReduceMotion(context) ? 0.0 : (1 - value) * 10;
        final scale = _aiReduceMotion(context)
            ? 1.0
            : 0.97 + (0.03 * value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: ThemedSurface(
        borderRadius: BorderRadius.circular(_aiRadius(30)),
        color: cs.primaryContainer.withValues(alpha: 0.76),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(_aiRadius(18)),
                ),
                child: Icon(icon, color: cs.primary, size: 29),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: untisThemeTextStyle(
                  context,
                  display: true,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.82),
                ),
              ),
              if (status != null && status!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  status!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
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
