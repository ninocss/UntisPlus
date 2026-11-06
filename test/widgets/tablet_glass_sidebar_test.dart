import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';
import 'package:untisplus/widgets/tablet_glass_sidebar.dart';
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

  setUp(() {
    untisAccountsNotifier.value = [];
    activeUntisAccountId = null;
    unreadTimetableChangesNotifier.value = 0;
    unreadInboxMessagesNotifier.value = 0;
    blurEnabledNotifier.value = true;
  });

  tearDown(() {
    untisAccountsNotifier.value = [];
    activeUntisAccountId = null;
    unreadTimetableChangesNotifier.value = 0;
    unreadInboxMessagesNotifier.value = 0;
    blurEnabledNotifier.value = true;
  });

  Widget buildSidebarHarness({
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
    bool showAi = true,
    Map<int, GlobalKey>? tutorialKeys,
    Map<int, GlobalKey>? tutorialLabelKeys,
    VoidCallback? onAccountTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TabletGlassSidebar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          showAi: showAi,
          tutorialKeys: tutorialKeys,
          tutorialLabelKeys: tutorialLabelKeys,
          onAccountTap: onAccountTap,
        ),
      ),
    );
  }

  group('TabletGlassSidebar', () {
    testWidgets('renders header, all 5 destinations, and footer avatar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final l = appL10nFor(appLocaleNotifier.value);

      await tester.pumpWidget(
        buildSidebarHarness(selectedIndex: 0, showAi: true),
      );

      // Header logo
      expect(find.byKey(const ValueKey('tablet-sidebar-header')), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);

      // Selected timetable icon (active)
      expect(find.byIcon(Icons.watch_later_rounded), findsOneWidget);
      expect(find.byTooltip(l.timetableTitle), findsOneWidget);

      // Inactive destinations
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.byTooltip(l.examsTitle), findsOneWidget);

      expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      expect(find.byTooltip(l.navInfo), findsOneWidget);

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byTooltip(l.navMenu), findsOneWidget);

      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
      expect(find.byTooltip(l.navAi), findsOneWidget);

      // Footer avatar fallback icon when no active account
      expect(find.byKey(const ValueKey('tablet-sidebar-account-avatar')), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('tapping destinations invokes onDestinationSelected callback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? tappedIndex;

      await tester.pumpWidget(
        buildSidebarHarness(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            tappedIndex = index;
          },
        ),
      );

      final l = appL10nFor(appLocaleNotifier.value);

      // Tap Exams (1)
      await tester.tap(find.byTooltip(l.examsTitle));
      await tester.pump();
      expect(tappedIndex, equals(1));

      // Tap Info (2)
      await tester.tap(find.byTooltip(l.navInfo));
      await tester.pump();
      expect(tappedIndex, equals(2));

      // Tap Menu (3)
      await tester.tap(find.byTooltip(l.navMenu));
      await tester.pump();
      expect(tappedIndex, equals(3));

      // Tap AI (4)
      await tester.tap(find.byTooltip(l.navAi));
      await tester.pump();
      expect(tappedIndex, equals(4));

      // Tap Timetable (0)
      await tester.tap(find.byTooltip(l.timetableTitle));
      await tester.pump();
      expect(tappedIndex, equals(0));
    });

    testWidgets(
      'renders red dot badge on Timetable item when unreadTimetableChangesNotifier > 0',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        unreadTimetableChangesNotifier.value = 3;

        await tester.pumpWidget(buildSidebarHarness());

        expect(
          find.byKey(const ValueKey('tablet-sidebar-timetable-badge')),
          findsOneWidget,
        );

        // Clear unread timetable changes and verify badge disappears
        unreadTimetableChangesNotifier.value = 0;
        await tester.pump();

        expect(
          find.byKey(const ValueKey('tablet-sidebar-timetable-badge')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders badge count on Info item when unreadInboxMessagesNotifier > 0',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        unreadInboxMessagesNotifier.value = 4;

        await tester.pumpWidget(buildSidebarHarness());

        expect(
          find.byKey(const ValueKey('tablet-sidebar-info-badge')),
          findsOneWidget,
        );
        expect(find.text('4'), findsOneWidget);

        // High count displays '99+'
        unreadInboxMessagesNotifier.value = 120;
        await tester.pump();

        expect(find.text('99+'), findsOneWidget);

        // 0 count removes badge
        unreadInboxMessagesNotifier.value = 0;
        await tester.pump();

        expect(
          find.byKey(const ValueKey('tablet-sidebar-info-badge')),
          findsNothing,
        );
      },
    );

    testWidgets('hides AI destination when showAi is false', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final l = appL10nFor(appLocaleNotifier.value);

      await tester.pumpWidget(buildSidebarHarness(showAi: false));

      expect(find.byTooltip(l.navAi), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);

      // Remaining 4 destinations still present
      expect(find.byTooltip(l.timetableTitle), findsOneWidget);
      expect(find.byTooltip(l.examsTitle), findsOneWidget);
      expect(find.byTooltip(l.navInfo), findsOneWidget);
      expect(find.byTooltip(l.navMenu), findsOneWidget);
    });

    testWidgets(
      'footer displays account initials and school/username tooltip when account active',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        untisAccountsNotifier.value = [account1];
        activeUntisAccountId = 'acc-1';

        await tester.pumpWidget(buildSidebarHarness());

        // Initials 'MM' from max.mustermann
        expect(find.text('MM'), findsOneWidget);
        expect(find.byIcon(Icons.person_rounded), findsNothing);

        // Tooltip contains school and username
        expect(
          find.byTooltip('Gymnasium Alpha (max.mustermann)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping footer avatar triggers UntisAccountSwitcherSheet.show', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      untisAccountsNotifier.value = [account1, account2];
      activeUntisAccountId = 'acc-1';

      await tester.pumpWidget(buildSidebarHarness());

      expect(find.byType(UntisAccountSwitcherSheet), findsNothing);

      await tester.tap(find.byKey(const ValueKey('tablet-sidebar-account-avatar')));
      await tester.pumpAndSettle();

      expect(find.byType(UntisAccountSwitcherSheet), findsOneWidget);
      expect(find.text('Gymnasium Alpha'), findsOneWidget);
      expect(find.text('Realschule Beta'), findsOneWidget);
    });

    testWidgets('attaches tutorialKeys and tutorialLabelKeys to destinations', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tutKey0 = GlobalKey();
      final tutKey1 = GlobalKey();
      final tutLabelKey0 = GlobalKey();

      await tester.pumpWidget(
        buildSidebarHarness(
          tutorialKeys: {0: tutKey0, 1: tutKey1},
          tutorialLabelKeys: {0: tutLabelKey0},
        ),
      );

      expect(find.byKey(tutKey0), findsOneWidget);
      expect(find.byKey(tutKey1), findsOneWidget);
      expect(find.byKey(tutLabelKey0), findsOneWidget);
    });
  });
}
