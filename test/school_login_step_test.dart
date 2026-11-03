import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untisplus/core/settings_store.dart';
import 'package:untisplus/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.initialize(
      preferences: await SharedPreferences.getInstance(),
    );
    appLocaleNotifier.value = 'de';
  });

  testWidgets('SchoolLoginStep renders search, manual entry, demo button and credentials', (
    tester,
  ) async {
    final serverCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final twoFactorCtrl = TextEditingController();

    var demoSelected = false;
    var loginCalled = false;
    var loginKey = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SchoolLoginStep(
                serverController: serverCtrl,
                schoolController: schoolCtrl,
                userController: userCtrl,
                passwordController: passCtrl,
                twoFactorController: twoFactorCtrl,
                isLoggingIn: false,
                requiresTwoFactor: false,
                useLoginKey: loginKey,
                onUseLoginKeyChanged: (val) => setState(() => loginKey = val),
                onLogin: () async => loginCalled = true,
                onDemoModeSelected: () => demoSelected = true,
              );
            },
          ),
        ),
      ),
    );

    // Initial search view
    expect(find.byType(TextField), findsOneWidget); // School search field
    expect(find.text('Demo-Modus starten'), findsOneWidget);
    expect(find.text('Manuelle Eingabe'), findsOneWidget);

    // Tap Demo
    await tester.tap(find.text('Demo-Modus starten'));
    expect(demoSelected, isTrue);

    // Switch to manual school entry
    await tester.tap(find.text('Manuelle Eingabe'));
    await tester.pumpAndSettle();

    // Now credentials view is visible with server, school, username, password fields
    expect(find.byType(TextField), findsNWidgets(4));

    // Tap login button
    await tester.tap(find.text('Loslegen'));
    expect(loginCalled, isTrue);
  });
}
