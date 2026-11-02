# Untis+ design contract

## Stack and direction

Flutter / Material 3 Expressive, existing Untis+ themes, `ColorScheme`, shared
surfaces, typography and `AppMotion` tokens. Android and iOS are the acceptance
targets. Preserve Default, Manga, Glass and Cyber and all effect quality profiles.
Do not add a web styling framework or a second design system.

## Decisions — 2026-10-26

- Preserve the separate timetable button and the existing destination order.
  Secondary destinations are More, School info, Planner and AI. All have visible
  labels and selected semantics; the gear means Settings, never More.
- Keep expressive silhouettes and purposeful selection motion. Use themed surface
  and on-surface pairs for text. Error is reserved for failures; cached data is
  informative and remains usable while refreshing.
- First-run setup is Language → School/login (or explicit demo) → Timetable.
  Appearance, AI and the guided tutorial are optional afterwards. Preserve existing
  completed installations and account-only login. Version unfinished checkpoints.
- Screen hierarchy: title/context → section selection → status → content/action.
  Timetable uses a time grid, Planner uses dated lists, School info uses messages,
  AI uses analysis/chat. Do not flatten these into interchangeable card grids.
- Minimum interactive extent: 48 logical pixels, including iOS (exceeds 44 pt).
  Labels wrap with enlarged text. At narrow widths navigation can grow vertically;
  at tablet widths preserve the existing rail and constrain readable content.
- Respect system reduced motion, application motion and haptic preferences.
  Existing stored customizations are not overwritten by effective quality limits.

## Reference compositions

| Surface | Hierarchy and actions |
| --- | --- |
| Timetable | Date + Today; day/three-day/week selection; cached/error status; time grid; details with textual cancellation/substitution status |
| Planner | Title; Exams/Homework/Grades tabs; loading/error/empty state; dated work list; contextual add/import actions |
| School info | Title + refresh; unread filter/status; sender/date/message list; attachment action with progress or retry |
| AI | Provider/local execution status; Analysis/Chat tabs; input and contextual send/stop; preserved conversation and scroll control |
| Settings | School day; Notifications/widgets; Appearance; Account/data; About/support. Explain effective quality limits next to affected controls |

## Component inventory

- Existing shared controls and surfaces: `lib/core/shared_ui.dart`.
- Motion/quality policy: `lib/core/app_experience.dart`.
- Semantic palettes: `lib/core/design_tokens.dart` and existing theme factories.
- Shared feature feedback: `lib/widgets/feature_feedback.dart` (loading, empty,
  error, offline/context notices; ColorScheme, intrinsic text, semantic live region).
- Primary destination labels: localized separately from Planner section names so
  renaming navigation never renames the Exams tab.

## Review and evidence

Review tokens, interactive states, loading, empty, contrast, adaptive layout,
reduced motion, saved source and this inventory for every new shared component.
Use the existing Material buttons for focus/hover/press/disabled behavior.
No performance, screen-reader or native service claim without corresponding
evidence. See `docs/ux-implementation.md` for the implementation and acceptance log.
