import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/widgets/progressive_edge_blur.dart';

void main() {
  testWidgets('a moving contrast edge broadens towards either bar', (
    tester,
  ) async {
    final key = GlobalKey();
    for (final top in [true, false]) {
      for (final x in [85, 100, 115]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 200,
                  height: 180,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(color: Colors.white),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: x.toDouble(),
                        child: const ColoredBox(color: Colors.black),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: top ? 0 : null,
                        bottom: top ? null : 0,
                        height: 120,
                        child: ProgressiveEdgeBlur(
                          strongAtTop: top,
                          sigma: 12,
                          tint: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          try {
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            int widthAt(int row) {
              final y = top ? row : image.height - row - 1;
              return [
                for (var i = x - 40; i < x + 40; i++)
                  data.getUint8((y * image.width + i) * 4),
              ].where((v) => v > 25 && v < 230).length;
            }

            // The first softened sample is already 64 dp away from the
            // plateau, well outside the previous 40 dp transition.
            final widths = [
              widthAt(130),
              widthAt(96),
              widthAt(66),
              widthAt(26),
            ];
            final output = Platform.environment['UNTIS_BLUR_CAPTURES'];
            if (output != null) {
              final png = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              await File(
                '$output/${top ? "header" : "navigation"}-$x.png',
              ).writeAsBytes(png.buffer.asUint8List());
            }
            expect(widths.first, 0);
            for (var i = 1; i < widths.length; i++) {
              expect(
                widths[i],
                greaterThan(widths[i - 1]),
                reason: 'top=$top x=$x: $widths',
              );
            }
          } finally {
            image.dispose();
          }
        });
        expect(tester.takeException(), isNull);
      }
    }
  });
}
