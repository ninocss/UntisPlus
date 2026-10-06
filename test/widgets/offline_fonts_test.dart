import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets(
    'every bundled font variant loads with runtime fetching disabled',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);
      final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(
        assets.listAssets().where(
          (asset) =>
              asset.startsWith('assets/fonts/') && asset.endsWith('.ttf'),
        ),
        hasLength(24),
      );
      final styles = <TextStyle>[
        for (final weight in FontWeight.values)
          GoogleFonts.outfit(fontWeight: weight),
        GoogleFonts.bebasNeue(),
        for (final weight in FontWeight.values.take(7)) ...[
          GoogleFonts.ibmPlexMono(fontWeight: weight),
          GoogleFonts.ibmPlexMono(
            fontWeight: weight,
            fontStyle: FontStyle.italic,
          ),
        ],
      ];
      await tester.runAsync(() => GoogleFonts.pendingFonts(styles));
      expect(tester.takeException(), isNull);
    },
  );
}
