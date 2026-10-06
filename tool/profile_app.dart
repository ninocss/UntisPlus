// Native device entry point. Example commands and scenario are documented in
// docs/app_experience.md. No account content or credentials enter the report.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untisplus/core/frame_timing_summary.dart';
import 'package:untisplus/main.dart' as app;

void main() {
  if (!kProfileMode || kIsWeb) {
    throw StateError(
      'Run this entry point on a native device in profile mode.',
    );
  }
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final startup = Stopwatch()..start();
  final frames = <FrameSample>[];
  final memory = <Map<String, int>>[];
  const requested = String.fromEnvironment(
    'PROFILE_QUALITY',
    defaultValue: 'balanced',
  );
  final quality = app.AppEffectQuality.values.byName(requested);
  const captureSeconds = int.fromEnvironment(
    'PROFILE_SECONDS',
    defaultValue: 90,
  );
  if (captureSeconds <= 0 || captureSeconds > 300) {
    throw ArgumentError('PROFILE_SECONDS must be between 1 and 300.');
  }
  var recording = false;
  void record(List<FrameTiming> timings) {
    if (!recording) return;
    for (final timing in timings) {
      frames.add(
        FrameSample(
          buildMicros: timing.buildDuration.inMicroseconds,
          rasterMicros: timing.rasterDuration.inMicroseconds,
        ),
      );
    }
  }

  binding.addTimingsCallback(record);
  app.main();
  unawaited(
    binding.waitUntilFirstFrameRasterized.then((_) async {
      final firstFrameMs = startup.elapsedMilliseconds;
      // In-memory override; the user's saved settings remain untouched.
      app.effectQualityNotifier.value = quality;
      await Future<void>.delayed(const Duration(seconds: 10));
      final display = binding.platformDispatcher.views.first.display;
      final actualHz = display.refreshRate;
      final refreshHz = actualHz.isFinite && actualHz > 0 ? actualHz : 60.0;
      final capture = Stopwatch()..start();
      recording = true;
      void sampleMemory() => memory.add({
        'elapsedMs': capture.elapsedMilliseconds,
        'residentBytes': ProcessInfo.currentRss,
      });
      sampleMemory();
      final memoryTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => sampleMemory(),
      );
      debugPrint(
        'UNTIS_PROFILE_START quality=$requested seconds=$captureSeconds',
      );
      await Future<void>.delayed(const Duration(seconds: captureSeconds));
      recording = false;
      memoryTimer.cancel();
      sampleMemory();
      binding.removeTimingsCallback(record);
      final report = {
        'schemaVersion': 1,
        'recordedAt': DateTime.now().toUtc().toIso8601String(),
        'mode': 'profile',
        'deviceLabel': const String.fromEnvironment(
          'PROFILE_DEVICE_LABEL',
          defaultValue: 'unspecified',
        ),
        'platform': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'dartVersion': Platform.version,
        'quality': requested,
        'theme': app.visualThemeNotifier.value.storageKey,
        'warmupSeconds': 10,
        'captureSeconds': captureSeconds,
        'reportedRefreshHz': actualHz,
        'startupToFirstRasterMs': firstFrameMs,
        'summary': summarizeFrames(frames, refreshHz),
        'rawFrames': frames.map((frame) => frame.toJson()).toList(),
        'processMemory': memory,
      };
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/untis-profile-$requested-${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );
      debugPrint('UNTIS_PROFILE_REPORT ${file.path}');
      debugPrint(jsonEncode(report['summary']));
    }),
  );
}
