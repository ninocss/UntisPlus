# Bug inventory — 26 October 2026

This inventory replaces the earlier list of nine allegedly open bugs. Those
entries referred to older code. A source-level correction is not, by itself,
physical-device or live-school acceptance.

## Earlier findings reconciled against current source

| Finding | Current implementation | Evidence/remaining boundary |
| --- | --- | --- |
| Repeated local AI output | Provider converts cumulative callbacks to new text and emits the final pending text | Adapter tests; real GGUF inference remains a device gate |
| Background widget overwrites homework | Background computes homework and exam summaries instead of hardcoded empty text | Widget delivery after background execution still needs Android/iOS checks |
| Absence excuse status | Parser accepts explicit status fields and checked/excused flags | Verify the school's actual payload; a checked flag alone does not establish backend parity |
| Read changes become unread | Existing change IDs are retained with putIfAbsent | Change/read-state regression; live foreground/background interleaving remains a native check |
| Smart alarm before all-day bookings | Midnight/nonpositive start times are rejected | Alarm unit tests; physical scheduling remains open |
| Locale change drops date overrides | refreshNativeCopy reapplies the date override before pushing plans | Alarm regression; native scheduler read-back remains open |
| Push preference resets | Startup hydrates progressivePush | Existing persistence tests |
| Blur preference resets | Startup hydrates blurStrength | Existing appearance/persistence tests |
| Default route transition resets | Startup accepts the complete 0–8 range | Existing preference validation |

The exam calendar-day countdown and exact lesson-end boundary also use the
corrected calendar-date/exclusive-end behavior in current source.

## Fixed by the Expressive UX implementation

- Primary navigation has stable visible destination labels, selected semantics,
  keyboard interaction and intrinsic layout space; disabling AI cannot leave an
  outdated list of animation controllers behind.
- First-run setup has two steps and cannot be blocked by optional AI setup.
  Legacy unfinished checkpoints return to school login. Completed setups remain
  completed. Initial release notes no longer interrupt first successful entry.
- Animation-disabled setup uses jumpToPage, avoiding a zero-duration scroll
  assertion found by the new regression.
- Timetable day labels and lesson-card space calculations respect text scaling in
  every theme. Past lessons retain readable opacity and are desaturated.
- Exam refresh distinguishes failed endpoints from valid empty responses and
  retains existing assignments instead of presenting failure as no exams.
- Shared homework refresh retains account-scoped cached/local data, exposes
  loading/failure state, and offers retry instead of a false empty state.
- School info separates failed and empty states, exposes read/unread labels and an
  unread filter, and provides per-attachment loading/error/retry.
- AI has execution/provider context and a stop action with per-request cancellation
  and protection against stale responses. Remote resources and local inference IDs
  are released through their existing provider APIs.
- iOS notification initialization does not request permission; enabling a
  notification feature uses the existing explicit permission flow.
- An idle refresh indicator no longer labels the entire content as refreshing.

## Explicitly open acceptance gates

- Physical Android and iPhone: installation, keyboard/back gestures, TalkBack/
  VoiceOver, haptics, widgets, notifications, background refresh and native GGUF
  cancellation.
- Live WebUntis: credentials, permissions, school-specific absence and exam data,
  account changes and real message attachments. Demo/mock tests cannot establish
  backend parity.
- Performance: matched before/after native profile captures, memory, battery and
  60/120 Hz measurements. There is no measured native performance improvement claim.

Current verification and reproducible commands are in docs/ux-implementation.md.
