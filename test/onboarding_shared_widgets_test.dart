import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';

void main() {
  testWidgets('M3ExpressiveProgressHeader renders step counter and back button', (
    tester,
  ) async {
    var backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: M3ExpressiveProgressHeader(
            currentStep: 2,
            totalSteps: 5,
            onBack: () => backPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('3/5'), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    expect(backPressed, isTrue);
  });

  testWidgets('M3PillButton renders label and responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: M3PillButton(
            label: 'Weiter',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Weiter'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await tester.tap(find.byType(M3PillButton));
    expect(tapped, isTrue);
  });

  testWidgets('M3ExpressiveCard renders child with expressive shape', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: M3ExpressiveCard(
            child: Text('Card Content'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(M3ExpressiveCard),
      matching: find.byType(Container),
    ).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(28));
  });

  testWidgets('M3StepContainer renders header, content and footer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: M3StepContainer(
            header: Text('Step Header'),
            content: Text('Step Content'),
            footer: Text('Step Footer'),
          ),
        ),
      ),
    );

    expect(find.text('Step Header'), findsOneWidget);
    expect(find.text('Step Content'), findsOneWidget);
    expect(find.text('Step Footer'), findsOneWidget);
  });

  testWidgets(
    'M3StepContainer applies 28dp horizontal padding on phones and 32dp on tablets',
    (tester) async {
      // 1. Phone viewport (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(
            body: M3StepContainer(
              content: Text('Phone Content'),
            ),
          ),
        ),
      );

      final phonePaddingFinder = find.ancestor(
        of: find.text('Phone Content'),
        matching: find.byType(Padding),
      ).first;
      final phonePadding = tester.widget<Padding>(phonePaddingFinder);
      expect((phonePadding.padding as EdgeInsets).left, equals(28.0));
      expect((phonePadding.padding as EdgeInsets).right, equals(28.0));

      // 2. Tablet viewport (1024 x 768)
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pump();

      final tabletPaddingFinder = find.ancestor(
        of: find.text('Phone Content'),
        matching: find.byType(Padding),
      ).first;
      final tabletPadding = tester.widget<Padding>(tabletPaddingFinder);
      expect((tabletPadding.padding as EdgeInsets).left, equals(32.0));
      expect((tabletPadding.padding as EdgeInsets).right, equals(32.0));
    },
  );
}
