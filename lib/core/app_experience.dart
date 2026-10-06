import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

import 'settings_store.dart';

enum AppEffectQuality { full, balanced, reduced }

enum AppEffectLayer { chrome, surface, lesson, background, transition }

enum AppMotionSpeed { fast, standard, calm }

final effectQualityNotifier = ValueNotifier(AppEffectQuality.full);
final interactionAnimationsEnabledNotifier = ValueNotifier(true);
final hapticsEnabledNotifier = ValueNotifier(true);

final effectQualityPreference = PreferenceBinding<AppEffectQuality>(
  key: 'effectQualityV1',
  defaultValue: AppEffectQuality.balanced,
  notifier: effectQualityNotifier,
  decoder: (raw) => AppEffectQuality.values.firstWhere(
    (quality) => quality.name == raw,
    orElse: () => AppEffectQuality.balanced,
  ),
  encoder: (quality) => quality.name,
);
final interactionAnimationsPreference = boolPreference(
  key: 'interactionAnimationsEnabledV1',
  defaultValue: true,
  notifier: interactionAnimationsEnabledNotifier,
);
final hapticsPreference = boolPreference(
  key: 'hapticsEnabledV1',
  defaultValue: true,
  notifier: hapticsEnabledNotifier,
);

Future<void> loadAppExperience(SettingsStore store) async {
  // Resolve the first-run default before startup writes version metadata.
  if (!store.preferences.containsKey(effectQualityPreference.key)) {
    await store.write(
      effectQualityPreference,
      store.preferences.getKeys().isEmpty
          ? AppEffectQuality.balanced
          : AppEffectQuality.full,
    );
  } else {
    await store.load(effectQualityPreference);
  }
  await Future.wait([
    store.load(interactionAnimationsPreference),
    store.load(hapticsPreference),
  ]);
}

/// Pure resolution: selecting a profile never rewrites personal effect values.
abstract final class AppEffects {
  static double blurSigma(
    double requested, {
    required AppEffectQuality quality,
    AppEffectLayer layer = AppEffectLayer.chrome,
    bool enabled = true,
  }) {
    if (!enabled || !requested.isFinite || requested <= 0) return 0;
    return switch (quality) {
      AppEffectQuality.full => requested,
      AppEffectQuality.balanced =>
        layer == AppEffectLayer.chrome ? math.min(requested, 12) : 0,
      AppEffectQuality.reduced => 0,
    };
  }

  static bool get full => effectQualityNotifier.value == AppEffectQuality.full;
  static bool get backgrounds =>
      effectQualityNotifier.value != AppEffectQuality.reduced;
  static bool get glow => full;
  static bool get gyroscope => full;

  static double resolveBlur(
    double requested, {
    AppEffectLayer layer = AppEffectLayer.chrome,
    bool enabled = true,
  }) => blurSigma(
    requested,
    quality: effectQualityNotifier.value,
    layer: layer,
    enabled: enabled,
  );
}

abstract final class AppMotionTokens {
  static const fastEffects = Duration(milliseconds: 120);
  static const standardEffects = Duration(milliseconds: 180);
  static const calmEffects = Duration(milliseconds: 240);

  static SpringDescription spring(AppMotionSpeed speed) => switch (speed) {
    AppMotionSpeed.fast => const SpringDescription(
      mass: 1,
      stiffness: 700,
      damping: 38,
    ),
    AppMotionSpeed.standard => const SpringDescription(
      mass: 1,
      stiffness: 500,
      damping: 30,
    ),
    AppMotionSpeed.calm => const SpringDescription(
      mass: 1,
      stiffness: 300,
      damping: 26,
    ),
  };
}
