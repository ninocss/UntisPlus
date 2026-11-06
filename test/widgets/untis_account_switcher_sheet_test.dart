import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/main.dart';
import 'package:untisplus/widgets/untis_account_switcher_sheet.dart';

UntisAccount _createAccount({
  required String id,
  required String username,
  required String schoolName,
  String schoolUrl = 'https://school.webuntis.com',
}) {
  return UntisAccount(
    id: id,
    username: username,
    schoolUrl: schoolUrl,
    schoolName: schoolName,
    password: 'password',
    credentialMode: 'password',
    sessionId: 'session-$id',
    personId: 1,
    personType: 5,
    lastUsedAt: DateTime.utc(2026, 11, 6),
  );
}

void main() {
  final account1 = _createAccount(
    id: 'acc-1',
    username: 'max.mustermann',
    schoolName: 'Gymnasium Alpha',
  );
  final account2 = _createAccount(
    id: 'acc-2',
    username: 'erika.musterfrau',
    schoolName: 'Realschule Beta',
  );

  tearDown(() {
    untisAccountsNotifier.value = [];
    activeUntisAccountId = null;
    blurEnabledNotifier.value = true;
  });

  group('UntisAccountSwitcherSheet widget', () {
    testWidgets('renders accounts and active checkmark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UntisAccountSwitcherSheet(
              accounts: [account1, account2],
              activeId: 'acc-1',
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('Konten'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify account 1
      expect(find.text('max.mustermann'), findsOneWidget);
      expect(find.text('Gymnasium Alpha'), findsOneWidget);

      // Verify account 2
      expect(find.text('erika.musterfrau'), findsOneWidget);
      expect(find.text('Realschule Beta'), findsOneWidget);

      // Verify checkmark on active account only
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Verify footer button
      expect(find.text('Konten verwalten'), findsOneWidget);
    });

    testWidgets('tapping inactive account triggers onSelectAccount callback', (
      tester,
    ) async {
      UntisAccount? selectedAccount;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UntisAccountSwitcherSheet(
              accounts: [account1, account2],
              activeId: 'acc-1',
              onSelectAccount: (acc) async {
                selectedAccount = acc;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('erika.musterfrau'));
      await tester.pumpAndSettle();

      expect(selectedAccount, isNotNull);
      expect(selectedAccount!.id, equals('acc-2'));
    });

    testWidgets('tapping active account does not trigger onSelectAccount', (
      tester,
    ) async {
      UntisAccount? selectedAccount;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UntisAccountSwitcherSheet(
              accounts: [account1, account2],
              activeId: 'acc-1',
              onSelectAccount: (acc) async {
                selectedAccount = acc;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('max.mustermann'));
      await tester.pumpAndSettle();

      expect(selectedAccount, isNull);
    });

    testWidgets('footer button triggers onManageAccounts callback', (
      tester,
    ) async {
      bool manageCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UntisAccountSwitcherSheet(
              accounts: [account1, account2],
              activeId: 'acc-1',
              onManageAccounts: () {
                manageCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Konten verwalten'));
      await tester.pumpAndSettle();

      expect(manageCalled, isTrue);
    });
  });

  group('UntisAccountSwitcherSheet.show', () {
    testWidgets('opens modal sheet reading accountsNotifier and activeId', (
      tester,
    ) async {
      untisAccountsNotifier.value = [account1, account2];
      activeUntisAccountId = 'acc-2';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UntisAccountSwitcherSheet.show(context),
                child: const Text('Open Switcher'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Gymnasium Alpha'), findsNothing);

      await tester.tap(find.text('Open Switcher'));
      await tester.pumpAndSettle();

      expect(find.text('Gymnasium Alpha'), findsOneWidget);
      expect(find.text('Realschule Beta'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tapping close button dismisses sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Gymnasium Alpha'), findsNothing);
    });

    testWidgets('selecting account in show() triggers callback and dismisses sheet', (
      tester,
    ) async {
      UntisAccount? chosen;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UntisAccountSwitcherSheet.show(
                  context,
                  accounts: [account1, account2],
                  activeId: 'acc-1',
                  onSelectAccount: (acc) async {
                    chosen = acc;
                  },
                ),
                child: const Text('Open Switcher'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Switcher'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Realschule Beta'));
      await tester.pumpAndSettle();

      expect(chosen?.id, equals('acc-2'));
      // Bottom sheet should be dismissed
      expect(find.text('Gymnasium Alpha'), findsNothing);
    });

    testWidgets('tapping manage accounts in show() dismisses sheet and navigates', (
      tester,
    ) async {
      bool manageCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UntisAccountSwitcherSheet.show(
                  context,
                  accounts: [account1, account2],
                  activeId: 'acc-1',
                  onManageAccounts: () {
                    manageCalled = true;
                  },
                ),
                child: const Text('Open Switcher'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Switcher'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Konten verwalten'));
      await tester.pumpAndSettle();

      expect(manageCalled, isTrue);
      expect(find.text('Gymnasium Alpha'), findsNothing);
    });
  });
}
