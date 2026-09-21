part of '../../main.dart';

enum _AiMode { analysis, chat }

const Duration _kAiStandardMotion = Duration(milliseconds: 280);
const Duration _kAiReducedMotion = Duration(milliseconds: 120);

bool _aiReduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

Duration _aiMotionDuration(
  BuildContext context, {
  Duration normal = _kAiStandardMotion,
}) {
  return _aiReduceMotion(context) ? _kAiReducedMotion : normal;
}

Curve _aiMotionCurve(BuildContext context) =>
    _aiReduceMotion(context) ? Curves.easeOut : _kSmoothBounce;

double _aiRadius(double radius) => _resolvedSurfaceCornerRadius(radius);

double _aiContentMaxWidth(BuildContext context, _AiMode mode) {
  if (!UntisLayout.isTablet(context)) return double.infinity;
  return mode == _AiMode.chat ? 760 : 980;
}
