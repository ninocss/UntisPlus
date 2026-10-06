import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/app_experience.dart';
import 'package:untisplus/core/bounded_lru_cache.dart';
import 'package:untisplus/core/settings_store.dart';

void main() {
  tearDown(() {
    effectQualityNotifier.value = AppEffectQuality.full;
    interactionAnimationsEnabledNotifier.value = true;
    hapticsEnabledNotifier.value = true;
    SettingsStore.debugReset();
  });

  Future<SettingsStore> settings(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
  }

  test(
    'new installations choose balanced; existing choices stay intact',
    () async {
      final fresh = await settings({});
      await loadAppExperience(fresh);
      expect(effectQualityNotifier.value, AppEffectQuality.balanced);
      expect(fresh.preferences.getString('effectQualityV1'), 'balanced');

      final existing = await settings({
        'blurStrength': 1.7,
        'lessonBlurEnabled': true,
        'backgroundGyroscope': true,
      });
      await loadAppExperience(existing);
      expect(effectQualityNotifier.value, AppEffectQuality.full);
      await existing.write(effectQualityPreference, AppEffectQuality.reduced);
      await loadAppExperience(existing);
      expect(effectQualityNotifier.value, AppEffectQuality.reduced);
      expect(existing.preferences.getDouble('blurStrength'), 1.7);
      expect(existing.preferences.getBool('lessonBlurEnabled'), isTrue);
      expect(existing.preferences.getBool('backgroundGyroscope'), isTrue);
    },
  );

  test(
    'invalid profile is safe and global interaction choices persist',
    () async {
      final store = await settings({
        'effectQualityV1': 'unknown',
        'interactionAnimationsEnabledV1': false,
        'hapticsEnabledV1': false,
      });
      await loadAppExperience(store);
      expect(effectQualityNotifier.value, AppEffectQuality.balanced);
      expect(interactionAnimationsEnabledNotifier.value, isFalse);
      expect(hapticsEnabledNotifier.value, isFalse);
    },
  );

  test('balanced blurs only chrome, reduced disables every blur layer', () {
    for (final layer in AppEffectLayer.values) {
      expect(
        AppEffects.blurSigma(24, quality: AppEffectQuality.full, layer: layer),
        24,
      );
      expect(
        AppEffects.blurSigma(
          24,
          quality: AppEffectQuality.reduced,
          layer: layer,
        ),
        0,
      );
      expect(
        AppEffects.blurSigma(
          24,
          quality: AppEffectQuality.balanced,
          layer: layer,
        ),
        layer == AppEffectLayer.chrome ? 12 : 0,
      );
    }
    expect(AppEffects.blurSigma(5, quality: AppEffectQuality.balanced), 5);
    for (final invalid in [double.nan, double.infinity, -1.0, 0.0]) {
      expect(AppEffects.blurSigma(invalid, quality: AppEffectQuality.full), 0);
    }
  });

  test('LRU retains recently read weeks, including empty results', () {
    final cache = BoundedLruCache<String, List<int>>(capacity: 2);
    cache['empty'] = [];
    cache['old'] = [1];
    expect(cache['empty'], isEmpty);
    cache['new'] = [2];
    expect(cache.containsKey('old'), isFalse);
    expect(cache.keys, ['empty', 'new']);
    cache['empty'] = [3];
    cache['newest'] = [4];
    expect(cache.containsKey('new'), isFalse);
    expect(cache.length, 2);
  });
}
