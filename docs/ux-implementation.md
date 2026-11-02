# Expressive UX implementation — 26 October 2026

## Accepted scope

Android and iOS; preserve the separate timetable navigation, equal visibility of
the main destinations, current themes/profiles and all account/data formats.
Shorten first-run setup, improve navigation and common feedback, then improve the
existing timetable, planner, school info, AI and settings flows. No new major feature.

## Sequence and acceptance

1. Design contract: `DESIGN.md`, existing tokens and representative compositions.
2. Navigation: More/School info/Planner/AI, separate Timetable, visible labels,
   selected semantics, enlarged text, no destination or draft loss on switching.
3. First run: Language → Login/demo → Timetable; optional settings/tutorial later;
   preserve completed setup, safely migrate unfinished checkpoints and account-only login.
4. Main surfaces: common loading/empty/error/offline feedback, keep cached content,
   retry failed actions, useful provider/download state and grouped settings.
5. Accessibility: 48 logical pixel targets, large text, semantic state, reduced
   motion, keyboard-safe actions and existing adaptive tablet navigation.
6. Validation: analyzer; regression and focused widget tests; Android/Web builds
   where available; captured representative layouts; update stale bug inventory.

## Required regression scenarios

- New install and resumed setup; explicit demo; failed login and retry; add account.
- Main destination changes, disabled AI, account changes, drafts and scroll state.
- Timetable cached data and failed refresh; long translations; empty week.
- Planner empty/error/data; homework completion; grades without recorded values.
- Message read state and attachment loading/retry; AI setup, request cancellation.
- Appearance and effective profiles after restart, backup restoration.
- 360/412 phone widths, 800/1280 tablet widths; 1×/2× text; all four locales,
  themes and three profiles; system reduced motion.

## Evidence log

Initial inspection: clean working tree. Existing bug list is stale: local AI delta
conversion, background widget summaries, change read state and persisted appearance
settings already have fixes in current source. A planning-time analyzer attempt
timed out; this is not a successful validation. No new native/device evidence yet.

Physical Android/iPhone acceptance, TalkBack/VoiceOver, native keyboard/back
gestures, widgets, notifications, haptics and matched before/after profile runs
must be reported separately from automated Flutter tests or build success.
