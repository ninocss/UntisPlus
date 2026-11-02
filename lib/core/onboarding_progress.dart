/// V1 checkpoints referred to Language/Appearance/Login/AI/Tutorial. The short
/// flow has only Language/Login, so every legacy checkpoint after Language
/// returns to Login instead of silently skipping authentication.
int shortOnboardingCheckpoint({int? checkpoint, int? schema}) {
  final saved = checkpoint ?? 0;
  if (schema == 2) return saved.clamp(0, 1);
  return saved > 0 ? 1 : 0;
}
