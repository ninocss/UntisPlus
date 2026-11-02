import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/widgets/attachment_download_tile.dart';

void main() {
  testWidgets(
    'download shows progress, prevents duplicates and retries inline',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentDownloadTile(
              name: 'Information.pdf',
              icon: Icons.picture_as_pdf,
              loadingLabel: 'Wird geladen',
              errorLabel: 'Download fehlgeschlagen',
              retryLabel: 'Erneut herunterladen',
              onDownload: () async {
                calls++;
                if (calls == 1) await pending.future;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Information.pdf'));
      await tester.pump();
      expect(find.text('Wird geladen'), findsOneWidget);
      await tester.tap(find.text('Information.pdf'));
      expect(calls, 1);
      pending.completeError(StateError('offline'));
      await tester.pump();
      expect(find.text('Download fehlgeschlagen'), findsOneWidget);
      await tester.tap(find.text('Erneut herunterladen'));
      await tester.pump();
      expect(calls, 2);
      expect(find.text('Download fehlgeschlagen'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
