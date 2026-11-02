import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/core/onboarding_progress.dart';

void main() {
  test('legacy checkpoints never skip school login in the short flow', () {
    expect(shortOnboardingCheckpoint(), 0);
    expect(shortOnboardingCheckpoint(checkpoint: 0), 0);
    for (final checkpoint in [1, 2, 3, 4, 100]) {
      expect(shortOnboardingCheckpoint(checkpoint: checkpoint), 1);
    }
  });
  test('short-flow checkpoints restore and invalid values stay in bounds', () {
    expect(shortOnboardingCheckpoint(checkpoint: 1, schema: 2), 1);
    expect(shortOnboardingCheckpoint(checkpoint: -5, schema: 2), 0);
    expect(shortOnboardingCheckpoint(checkpoint: 100, schema: 2), 1);
  });
}
