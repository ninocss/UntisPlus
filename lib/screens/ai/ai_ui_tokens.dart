part of '../../main.dart';

enum _AiMode {
  // ignore: unused_field
  analysis,
  chat,
}

const Duration _kAiFastMotion = Duration(milliseconds: 160);
const Duration _kAiStandardMotion = Duration(milliseconds: 220);
const Duration _kAiReducedMotion = Duration(milliseconds: 90);

bool _aiReduceMotion(BuildContext context) => !AppMotion.enabled(context);

Duration _aiMotionDuration(
  BuildContext context, {
  Duration normal = _kAiStandardMotion,
}) {
  return _aiReduceMotion(context) ? _kAiReducedMotion : normal;
}

Duration _aiFastMotionDuration(BuildContext context) {
  return _aiReduceMotion(context) ? _kAiReducedMotion : _kAiFastMotion;
}

Curve _aiMotionCurve(BuildContext context) =>
    _aiReduceMotion(context) ? Curves.easeOut : Curves.easeOutCubic;

double _aiRadius(double radius) => _resolvedSurfaceCornerRadius(radius);

BorderRadius _aiUserBubbleRadius() {
  return BorderRadius.only(
    topLeft: Radius.circular(_aiRadius(20)),
    topRight: Radius.circular(_aiRadius(20)),
    bottomLeft: Radius.circular(_aiRadius(20)),
    bottomRight: Radius.circular(_aiRadius(6)),
  );
}

BorderRadius _aiAssistantBubbleRadius() {
  return BorderRadius.only(
    topLeft: Radius.circular(_aiRadius(6)),
    topRight: Radius.circular(_aiRadius(20)),
    bottomLeft: Radius.circular(_aiRadius(20)),
    bottomRight: Radius.circular(_aiRadius(20)),
  );
}

double _aiContentMaxWidth(BuildContext context, [_AiMode mode = _AiMode.chat]) {
  if (!UntisLayout.isTablet(context)) return double.infinity;
  return mode == _AiMode.chat ? 760 : 980;
}
