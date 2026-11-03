# Material 3 Expressive Settings Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Untis+ Settings Hub and all 11 settings subpages into the Material 3 Expressive design language, featuring animated wavy sliders, wavy progress loaders, clustered 24–28 dp containers, and an app-bar integrated account badge.

**Architecture:** A component-first rollout: first build the animated squiggly primitives (`WavySliderTrackShape`, `ExpressiveWavyLinearProgressIndicator`, `ExpressiveWavyCircularProgressIndicator`) and enhance container primitives (`SettingsGroup`, `SettingsPageShell`) in `lib/core/shared_ui.dart`. Then modernize `SettingsHubPage` with an app-bar account chip, expressive search pill, and tablet split-view. Finally, roll out the clustered expressive styling and wavy controls across all 11 settings subpages.

**Tech Stack:** Flutter 3.x, Dart 3, Material 3, CustomPainter, AnimationController, ThemeExtension (`UntisThemeTokens`).

**Spec:** `docs/superpowers/specs/2026-11-03-m3-expressive-settings-design.md`

## Global Constraints

- Expressive wavy components and 24–28 dp radii are active only when `appThemeCapabilities(context).supportsExpressiveComponents` is true (`AppThemeId.defaultTheme`).
- Alternative themes (`glass`, `cyber`, `manga`) must preserve their respective token geometries, opacities, borders, and standard sliders.
- Motion curves must respect `AppMotion.enabled(context)`: freeze continuous phase animations to 0 when reduced motion is enabled.
- All existing preferences, keys, semantics labels, and test keys (`ValueKey`) must be preserved.

## Review Focus

1. **Slider Drag Stability:** Dragging a `HapticSlider` while the sinusoidal wave animates must not jitter the thumb position or lose pointer tracking.
2. **Animation Controller Lifecycle:** Continuous wave animations in sliders and progress bars must cancel tickers upon widget disposal to prevent memory and CPU leaks.
3. **Responsive App Bar Header:** On narrow mobile screens (< 380 dp), the account badge in the app bar must collapse to avatar-only without clipping or pushing the title off-center.
4. **Master-Detail Selection Sync:** Tapping the app bar account badge on tablets must accurately navigate to or highlight `SettingsAccountPage` in the detail pane.
5. **Theme Switching Mid-Session:** Switching between Default, Glass, Cyber, and Manga themes must immediately update slider track shapes and container styles without requiring an app restart.

---

### Task 1: Core Wavy Primitives (Squiggly Sliders & Wavy Progress Indicators)

**Files:**
- Create: `lib/widgets/expressive_wavy_slider.dart`
- Create: `lib/widgets/expressive_wavy_progress.dart`
- Modify: `lib/core/shared_ui.dart` (export new widgets and integrate `WavySliderTrackShape` into `HapticSlider`)
- Test: `test/widgets/wavy_components_test.dart`

**Interfaces:**
- Produces:
  - `class WavySliderTrackShape extends SliderTrackShape`
  - `class ExpressiveWavyLinearProgressIndicator extends StatefulWidget`
  - `class ExpressiveWavyCircularProgressIndicator extends StatefulWidget`
  - Updated `class HapticSlider extends StatelessWidget` utilizing `WavySliderTrackShape` when `supportsExpressiveComponents` is true.

- [ ] **Step 1: Write failing unit test for `WavySliderTrackShape` and wavy indicators**

```dart
// test/widgets/wavy_components_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untis_plus/widgets/expressive_wavy_slider.dart';
import 'package:untis_plus/widgets/expressive_wavy_progress.dart';

void main() {
  testWidgets('WavySliderTrackShape renders without exception in SliderTheme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SliderTheme(
            data: const SliderThemeData(trackShape: WavySliderTrackShape()),
            child: Slider(value: 0.5, onChanged: (_) {}),
          ),
        ),
      ),
    );
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('ExpressiveWavyLinearProgressIndicator renders with value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpressiveWavyLinearProgressIndicator(value: 0.6),
        ),
      ),
    );
    expect(find.byType(ExpressiveWavyLinearProgressIndicator), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/wavy_components_test.dart`
Expected: FAIL (files/classes not found)

- [ ] **Step 3: Implement `WavySliderTrackShape` in `lib/widgets/expressive_wavy_slider.dart`**

Implement `WavySliderTrackShape` extending `SliderTrackShape` with sinusoidal active track rendering. Animate continuous phase increment via a shared or internal ticker when `AppMotion.enabled(context)` is true. If reduced motion, phase is constant 0.

- [ ] **Step 4: Implement `ExpressiveWavyLinearProgressIndicator` & `ExpressiveWavyCircularProgressIndicator` in `lib/widgets/expressive_wavy_progress.dart`**

Implement linear wavy bar with flowing sine wave, and circular undulating loader with 3-4 soft morphing lobes.

- [ ] **Step 5: Integrate into `HapticSlider` in `lib/core/shared_ui.dart`**

Update `HapticSlider.build`: Wrap `Slider` in a `SliderTheme` that applies `WavySliderTrackShape()` when `appThemeCapabilities(context).supportsExpressiveComponents` is true.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/widgets/wavy_components_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/expressive_wavy_slider.dart lib/widgets/expressive_wavy_progress.dart lib/core/shared_ui.dart test/widgets/wavy_components_test.dart
git commit -m "feat(ui): add Material 3 Expressive wavy slider track and progress indicators"
```

---

### Task 2: Clustered Expressive Containers (`SettingsGroup` & `SettingsPageShell`)

**Files:**
- Modify: `lib/core/shared_ui.dart:194-234` (`SettingsPageShell`)
- Modify: `lib/core/shared_ui.dart:2699-2780` (`SettingsGroup`)
- Test: `test/widgets/settings_group_test.dart`

**Interfaces:**
- Consumes: `UntisThemeTokens`, `appThemeCapabilities`, `_resolvedSurfaceCornerRadius`
- Produces: Enhanced `SettingsGroup` with 24–28 dp corner radius, refined dividers, and per-item touch highlights.

- [ ] **Step 1: Write failing widget test for expressive `SettingsGroup`**

```dart
// test/widgets/settings_group_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untis_plus/core/shared_ui.dart';

void main() {
  testWidgets('SettingsGroup renders clustered container with title and children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsGroup(
            title: 'Test Section',
            children: [
              Text('Child 1'),
              Text('Child 2'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Test Section'), findsOneWidget);
    expect(find.text('Child 1'), findsOneWidget);
    expect(find.text('Child 2'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify existing/new behavior**

Run: `flutter test test/widgets/settings_group_test.dart`
Expected: Verify baseline.

- [ ] **Step 3: Refactor `SettingsGroup` and `SettingsPageShell` in `lib/core/shared_ui.dart`**

- In `SettingsGroup`:
  - When `supportsExpressiveComponents` is true, resolve surface corner radius to 26 dp (standard expressive cluster).
  - Inset dividers using `color: cs.outlineVariant.withValues(alpha: 0.22)`.
  - Ensure interactive child rows carry their own ink highlights without scaling down the outer `SettingsGroup`.
- In `SettingsPageShell`:
  - Constrain content column to max 840 dp on wide viewports (centered reading width).
  - Ensure pinned header uses `RoundedBlurAppBar` with clean back navigation.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/settings_group_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/shared_ui.dart test/widgets/settings_group_test.dart
git commit -m "feat(settings): modernize SettingsGroup and SettingsPageShell to M3 Expressive"
```

---

### Task 3: Settings Hub App Bar & Responsive Account Badge

**Files:**
- Modify: `lib/screens/settings_hub.dart:963-1180` (extract account badge into app bar action)
- Modify: `lib/screens/settings_hub.dart:1742-1785` (pass account badge action into app bar)
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `untisAccountsNotifier`, `demoModeNotifier`, `devModeNotifier`
- Produces: `_buildAppBarAccountBadge(BuildContext context, {required bool compact})` mounted in `_mainTabHeaderAppBar` actions.

- [ ] **Step 1: Inspect and update test expectations for account header presence**

Ensure existing widget tests targeting account interactions can find the account action in the app bar or via search.

- [ ] **Step 2: Implement responsive account chip in `lib/screens/settings_hub.dart`**

Build `_buildAppBarAccountBadge`:
- Avatar squircle (34x34 dp, rounded 12 dp) with initials or user/demo icon.
- Status badge dot (DEV/DEMO).
- If screen width >= 400 dp, display username text chip with chevron.
- Tapping triggers `_activateItem(context, accountItem, ...)`.
- Add the widget to `_mainTabHeaderAppBar` actions in `SettingsHubPage`.
- Remove the full-width `_buildCompactAccountHeader` from the sliver scroll list.

- [ ] **Step 3: Run existing widget test to verify header integration**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/screens/settings_hub.dart
git commit -m "feat(settings): integrate responsive account profile badge into top app bar"
```

---

### Task 4: Settings Hub Expressive List, Search Pill & Tablet Split-View

**Files:**
- Modify: `lib/screens/settings_hub.dart:1181-1780`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `_hubLabel`, `_SettingsHubItem`, `ThemedSurface`
- Produces: Modernized category cards, 28 dp search pill, expressive master-detail split-view.

- [ ] **Step 1: Upgrade search pill (`_buildSearchBar`)**

Style search field with 28 dp corner radius, `surfaceContainerHigh` tonal background, 14.5 sp outfit typography, and smooth clear icon transition.

- [ ] **Step 2: Upgrade section items (`_buildHubItem` and `_buildSection`)**

- Apply 26 dp corner radius on category container groups.
- Tile icon containers: 42x42 dp squircles (14 dp radius) with tonal semantic color background.
- High-contrast typography: `FontWeight.w700` titles (15.5 sp), `FontWeight.w500` subtitles (13 sp).
- Subtle chevron `Icons.chevron_right_rounded`.
- On tablet / expanded mode: Active category is rendered with a flowing pill container (`secondaryContainer` with `onSecondaryContainer` text).

- [ ] **Step 3: Run widget tests**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/screens/settings_hub.dart
git commit -m "feat(settings): modernize SettingsHubPage with expressive search pill and split-view"
```

---

### Task 5: Subpages Migration — Core Experience (Appearance, Timetable, Subjects)

**Files:**
- Modify: `lib/screens/settings/settings_appearance_page.dart`
- Modify: `lib/screens/settings/settings_timetable_page.dart`
- Modify: `lib/screens/settings/settings_subjects_page.dart`
- Modify: `lib/screens/settings/subject_management_pages.dart`
- Test: `test/app_theme_test.dart`

**Interfaces:**
- Consumes: `HapticSlider` (with wavy tracks), `SettingsGroup`, `SettingsPageShell`

- [ ] **Step 1: Update `settings_appearance_page.dart`**

Convert all sliders (corner radius, blur sigma, etc.) and option clusters to use M3 Expressive grouped containers.

- [ ] **Step 2: Update `settings_timetable_page.dart`**

Verify timetable sliders (card opacity, hour ranges) and card style pickers render cleanly in the 26 dp clustered containers.

- [ ] **Step 3: Update `settings_subjects_page.dart` and `subject_management_pages.dart`**

Ensure subject color pickers and sliders use the enhanced `HapticSlider` and expressive containers.

- [ ] **Step 4: Run theme and widget tests**

Run: `flutter test test/app_theme_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings/settings_appearance_page.dart lib/screens/settings/settings_timetable_page.dart lib/screens/settings/settings_subjects_page.dart lib/screens/settings/subject_management_pages.dart
git commit -m "style(settings): migrate appearance, timetable, and subjects pages to M3 Expressive"
```

---

### Task 6: Subpages Migration — Smart & Connected Features (AI, Alarm, Notifications)

**Files:**
- Modify: `lib/screens/settings/settings_ai_page.dart`
- Modify: `lib/screens/settings/settings_alarm_page.dart`
- Modify: `lib/screens/settings/settings_notifications_page.dart`
- Test: `test/services/alarm_service_test.dart`

**Interfaces:**
- Consumes: `ExpressiveWavyLinearProgressIndicator`, `HapticSlider`, `SettingsGroup`

- [ ] **Step 1: Update `settings_ai_page.dart`**

- Replace model download progress bar with `ExpressiveWavyLinearProgressIndicator`.
- Connect temperature/top_p/context sliders to `HapticSlider`.
- Wrap provider configurations and local model cards in clustered expressive containers.

- [ ] **Step 2: Update `settings_alarm_page.dart`**

Migrate wake offset, smart early-ring, and volume sliders to `HapticSlider` inside clustered containers.

- [ ] **Step 3: Update `settings_notifications_page.dart`**

Migrate lesson lead-time and notification preference controls into expressive containers.

- [ ] **Step 4: Run tests**

Run: `flutter test test/services/alarm_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings/settings_ai_page.dart lib/screens/settings/settings_alarm_page.dart lib/screens/settings/settings_notifications_page.dart
git commit -m "style(settings): migrate AI, alarm, and notifications settings to M3 Expressive"
```

---

### Task 7: Subpages Migration — Data & System (Account, Backup, About/Updates, Widgets, Studio Editor)

**Files:**
- Modify: `lib/screens/settings/settings_account_page.dart`
- Modify: `lib/screens/settings/settings_backup_page.dart`
- Modify: `lib/screens/settings/settings_about_updates_page.dart`
- Modify: `lib/screens/settings/settings_widgets_page.dart`
- Modify: `lib/screens/settings/custom_widget_editor_page.dart`
- Test: Full test suite verification (`flutter test`)

**Interfaces:**
- Consumes: `ExpressiveWavyLinearProgressIndicator`, `ExpressiveWavyCircularProgressIndicator`, `HapticSlider`, `SettingsGroup`

- [ ] **Step 1: Update `settings_account_page.dart` and `settings_backup_page.dart`**

- Account: Modernize account list items, login form tiles, and server endpoint inputs into expressive clusters.
- Backup: Replace export/import and cloud sync progress with `ExpressiveWavyLinearProgressIndicator`.

- [ ] **Step 2: Update `settings_about_updates_page.dart` and `settings_widgets_page.dart`**

- About: Use `ExpressiveWavyCircularProgressIndicator` for update checks; style version info in clean tonal cards.
- Widgets: Migrate widget options to expressive containers.

- [ ] **Step 3: Update `custom_widget_editor_page.dart`**

Update editor canvas sliders (padding, radius, opacity) to `HapticSlider` and update tool container panel radii to 24–28 dp.

- [ ] **Step 4: Run complete project test suite**

Run: `flutter test`
Expected: ALL TESTS PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings/settings_account_page.dart lib/screens/settings/settings_backup_page.dart lib/screens/settings/settings_about_updates_page.dart lib/screens/settings/settings_widgets_page.dart lib/screens/settings/custom_widget_editor_page.dart
git commit -m "style(settings): complete M3 Expressive migration across account, backup, updates, and widget editor"
```
