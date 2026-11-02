import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/widgets/primary_destination_bar.dart';

void main() {
  for (final locale in ['de', 'en', 'fr', 'es']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('labelled destinations fit $locale at ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final l = appL10nFor(locale);
        var selected = -1;
        final labels = [
          l.ux('more'),
          l.ux('schoolInfo'),
          l.ux('planner'),
          l.navAi,
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    width: 204,
                    child: PrimaryDestinationBar(
                      duration: Duration.zero,
                      selectedIndex: 2,
                      onSelected: (index) => selected = index,
                      destinations: [
                        for (final label in labels)
                          PrimaryDestination(
                            label: label,
                            icon: Icons.circle_outlined,
                            selectedIcon: Icons.check_circle,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        for (final label in labels) {
          expect(find.text(label), findsOneWidget);
        }
        final node = tester.getSemantics(
          find.bySemanticsLabel(l.ux('planner')).first,
        );
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
        await tester.tap(find.text(l.ux('schoolInfo')));
        expect(selected, 1);
        for (final element
            in find.byType(PrimaryDestinationButton).evaluate()) {
          final size = (element.findRenderObject()! as RenderBox).size;
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
  testWidgets('removing AI keeps every remaining destination tappable', (
    tester,
  ) async {
    var selected = -1;
    Widget bar(bool ai) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: PrimaryDestinationBar(
            duration: Duration.zero,
            destinations: [
              for (final label in ['More', 'Info', 'Planner', if (ai) 'AI'])
                PrimaryDestination(
                  label: label,
                  icon: Icons.circle,
                  selectedIcon: Icons.check,
                ),
            ],
            selectedIndex: -1,
            onSelected: (index) => selected = index,
          ),
        ),
      ),
    );
    await tester.pumpWidget(bar(true));
    await tester.pumpWidget(bar(false));
    expect(find.text('AI'), findsNothing);
    await tester.tap(find.text('Planner'));
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });
}
