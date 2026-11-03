# Design Document: Material 3 Expressive Settings Redesign

**Date:** 2026-11-03  
**Status:** In Review (Brainstorming completed)  
**Target:** Untis+ Settings Architecture (Hub & 11 Subpages)  

---

## 1. Intent & Purpose

Transform the entire Settings experience in Untis+ into the **Material 3 Expressive** design language. The goal is to provide a playful yet mature, tactile, and highly legible settings interface that feels completely native to modern Android / Material 3 while honoring the existing design language of Untis+ (such as the bottom navigation bar and expressive refresh indicators).

Key experiential pillars:
- **Expressive Shapes & Containers:** 24–28 dp corner radii, tonal surface container hierarchy, and seamless clustered groups.
- **Iconic Squiggly Lines:** Continuously flowing, smooth sine-wave active tracks for sliders, plus wavy progress bars and undulating circular spinners.
- **De-cluttered Hierarchy:** Moving the account profile badge into the top app bar to elevate settings categories into immediate focus.
- **Disciplined Motion:** Tactile spring curves and soft corner/color morphs on touch, without noisy icon rotations, respecting reduced motion settings.

---

## 2. Invariants & Scope

### Goals
1. Redesign the Settings Hub (`lib/screens/settings_hub.dart`) with modernized expressive list grouping, expressive search bar pill, and account integration directly inside the top app bar.
2. Build reusable M3 Expressive primitives in `lib/core/shared_ui.dart`:
   - `WavySliderTrackShape` / `HapticSlider`: Continuously and subtly flowing sine wave on the active track when `supportsExpressiveComponents` is active.
   - `ExpressiveWavyLinearProgressIndicator`: Sine-wave horizontal progress/indeterminate indicator.
   - `ExpressiveWavyCircularProgressIndicator`: Undulating circular wavy spinner.
   - `SettingsGroup`: Refactored to provide unified clustered expressive containers (24–28 dp radius, subtle separators, soft press morphs).
   - `SettingsPageShell`: Refactored header/scaffolding aligned with the expressive visual system.
3. Migrate and polish all 11 subpages to use the unified clustered container structure and squiggly components:
   - `settings_appearance_page.dart`
   - `settings_timetable_page.dart`
   - `settings_account_page.dart`
   - `settings_ai_page.dart`
   - `settings_alarm_page.dart`
   - `settings_notifications_page.dart`
   - `settings_subjects_page.dart` / `subject_management_pages.dart`
   - `settings_widgets_page.dart`
   - `custom_widget_editor_page.dart`
   - `settings_backup_page.dart`
   - `settings_about_updates_page.dart`
4. Support responsive master-detail layout on tablet and wide screens with expressive split-view.

### Non-Goals
- Altering any underlying preferences, business logic, storage keys, backup formats, sync protocols, or AI inference mechanics.
- Replacing the navigation model (push/pop stack and master-detail routing remains functionally identical).
- Modifying alternative themes (Glass, Cyber, Manga) to force squiggly lines onto them.

### Anti-Goals
- Avoid gratuitous visual noise: No bouncing icon-wiggle rotations on settings item taps.
- Avoid inconsistent container padding or nested cards with conflicting corner radii.
- Avoid performance regressions from unconstrained canvas repaints (wavy painter must be lightweight, cached where appropriate, and respect ticker lifecycle).

---

## 3. Considered Approaches & Chosen Path

### Approach 1: Component-Centric Staging (Chosen)
* **Phase 1:** Core Primitives & Squiggly Components in `lib/core/shared_ui.dart` (`WavySliderTrackShape`, `ExpressiveWavyLinearProgressIndicator`, `ExpressiveWavyCircularProgressIndicator`, `SettingsGroup`, `SettingsPageShell`).
* **Phase 2:** Settings Hub (`lib/screens/settings_hub.dart`), including app-bar account integration, expressive search pill, and tablet split-view.
* **Phase 3:** Rollout across all 11 subpages.
* **Why chosen:** Establishes the foundation first. Once `SettingsGroup` and `HapticSlider` are enhanced, all subpages immediately inherit the expressive baseline, preventing code duplication and allowing incremental visual verification.

### Approach 2: Top-Down (Hub First, Subpages Later)
* Focus on `settings_hub.dart` first, then primitives, then subpages.
* *Rejected:* Leaves subpages in an inconsistent state during development and requires duplicate styling before unifying primitives.

### Approach 3: Monolithic Refactor
* Attempting to rewrite all 12 files simultaneously in one commit.
* *Rejected:* High blast radius, hard to debug regressions, difficult to review.

---

## 4. Detailed Component Design

### 4.1 Squiggily Lines & Wavy Components
- **`WavySliderTrackShape`:**
  - Implements `SliderTrackShape`.
  - In `Default` theme (`supportsExpressiveComponents == true`):
    - Inactive track: Standard smooth pill/rounded line using `scheme.surfaceContainerHighest`.
    - Active track (from min to thumb): A smooth sinusoidal curve \( y = A \cdot \sin(2\pi \frac{x}{\lambda} - \phi) \) centered vertically on the track, rendered with `Paint.strokeCap = StrokeCap.round`.
    - Motion: An internal phase angle \( \phi \) slowly increments via an `AnimationController` (flowing continuously at ~0.5–1 Hz) to give the signature living wave feeling.
    - Reduced motion (`AppMotion.enabled == false`): Phase is frozen at 0, rendering a static wave without CPU/GPU animation overhead.
  - In `Glass`, `Cyber`, `Manga` themes (`supportsExpressiveComponents == false`):
    - Falls back cleanly to the existing classic slider track shape.
- **`ExpressiveWavyLinearProgressIndicator`:**
  - For linear progress (e.g. AI model downloads, backup progress, app update check).
  - Determinate mode: Sine wave fills up to progress value \( p \in [0, 1] \) with continuous wave flow.
  - Indeterminate mode: A traveling wave pulse traversing the track.
- **`ExpressiveWavyCircularProgressIndicator`:**
  - For inline spinners and loading states.
  - Circular track with 3 to 4 undulating lobes slowly rotating and morphing smoothly.

### 4.2 Settings Hub Anatomy (`settings_hub.dart`)
- **App Bar with Integrated Account:**
  - `_mainTabHeaderAppBar`: Right/trailing action hosts an expressive account badge:
    - Responsive account chip: On compact phone screens (< 400 dp), collapses gracefully to an avatar squircle (34x34 dp, initials/icon) with dev/demo badge dot; on larger screens, displays the avatar + compact username chip.
    - Tap on account badge opens `SettingsAccountPage` (or in tablet master-detail, updates the detail pane with two-way active highlight on the badge).
    - Removes the bulky top account card from the scrollable list, pulling search and categories directly into view.
    - *Builder Call:* Account is also retained as a searchable item in the "Daten, App & Support" category to preserve direct index access and search compatibility.
- **Expressive Search Pill:**
  - 28 dp corner radius, `surfaceContainerHigh` tonal fill, `Icons.search_rounded`.
  - Smooth expansion and clear button transitions.
- **Modernized Grouped Sections:**
  - Vertical list of `ThemedSurface` containers with 24–28 dp corner radius.
  - List tiles: 14–16 dp padding, tonal icon containers (rounded squircle), high-contrast outfit typography (`FontWeight.w700` titles, `w500` subtitles), subtle chevrons (`Icons.chevron_right_rounded`).
  - Dividers: Inset hairline dividers with low opacity (`outlineVariant.withValues(alpha: 0.22)`).
- **Tablet / Master-Detail:**
  - Left master pane: Selected category is highlighted with a prominent pill container (`secondaryContainer` or `primaryContainer`).
  - Right detail pane: Embedded inside a smooth, rounded surface with `AnimatedSwitcher` transitions.

### 4.3 Subpage Anatomy & Container Hierarchy
- **`SettingsPageShell`:**
  - Pinned blurred app bar (`RoundedBlurAppBar`) with back button and title.
  - Responsive max width on large screens (centered reading column ~720–840 dp).
- **Clustered Expressive Containers (`SettingsGroup`):**
  - All switches (`SwitchListTile`), sliders, pickers, and options live within `SettingsGroup` containers.
  - Surface radius: 24–28 dp (scaled by `UntisThemeTokens.surfaceRadius` / corner preference).
  - *Builder Call:* Touch feedback (soft color highlight and corner morph) applies per-tile on interactive navigation rows. The outer enclosing `SettingsGroup` remains stable and does not scale down on inner slider scrubs or switch toggles, preventing layout jitter.
- **Studio Editor Exception (`custom_widget_editor_page.dart`):**
  - *Builder Call:* The custom widget editor retains its specialized two-pane studio canvas and toolbar layout. It adopts the wavy slider tracks (`HapticSlider`), wavy progress indicators, and 24–28 dp tool container radii, without being forced into a standard list shell.

### 4.4 Theme Adaptation & Capabilities
- Gated via `appThemeCapabilities(context).supportsExpressiveComponents`.
- `AppThemeId.defaultTheme`: Full M3 Expressive (wavy sliders, wavy loaders, 24–28 dp radii, tonal containers).
- `AppThemeId.glass`: Frosted glass opacity, blur sigma, standard linear sliders.
- `AppThemeId.cyber`: Hard rectangular/cyber borders, neon contrast, straight technical sliders.
- `AppThemeId.manga`: Black & white ink borders, manga typography, flat straight sliders.

---

## 5. What is Left to the Builder
- Precise pixel tuning of sine-wave wavelength (\(\lambda \approx 20\)–24 dp) and amplitude (\(A \approx 3\)–4 dp) for optimal visual clarity at standard 48 dp touch target heights.
- Ensuring `SingleTickerProviderStateMixin` / ticker disposal in custom painters to avoid memory leaks.
- Preserving all existing widget keys and semantics attributes for automated tests (`widget_test.dart`, `app_theme_test.dart`).
