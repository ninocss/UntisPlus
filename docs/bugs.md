# Bugs

Found 9 verified bugs (analyzer is clean; the test script couldn't run — the `objective_c` native-assets hook fails with a path-with-space parsing error, unrelated to app code).

## Critical

1. **Local AI output is garbled** — `lib/features/ai/data/local_model_provider.dart:66-88`
   The pinned fllama sends the **cumulative** full text on every callback (`src/fllama.cpp:473,483,517`). The provider treats it as deltas: the chat UI appends each chunk (`main_navigation_screen.dart:993,1099-1102`), so the answer grows roughly quadratically, and the final text on `done=true` is never emitted to the stream. `requestLocalModelText` (:157-167) likewise concatenates all prefixes → repeated output.

2. **Background task erases real widget homework data** — `lib/services/background_service.dart:862`
   Every 15 min it writes `homeworkSummary: 'Keine offenen Hausaufgaben'` unconditionally (and omits `examSummary`), while the timetable page writes real homework/exams (`weekly_timetable_page.dart:1231,1233`).

3. **Absence status can never be excused/unexcused** — `lib/features/absences/data/absence_repository.dart:69-73` + `lib/features/absences/domain/absence.dart:26-39`
   `getTimetableWithAbsences` entries only have `checked`; `Absence.fromJson` therefore always yields `unknown`/`open`.

4. **Read timetable changes silently flip back to unread** — `lib/features/changes/data/change_repository.dart:44`
   Foreground (`timetableSnapshot`) and background (`backgroundSnapshot`) baselines write the same store; `byId.update(..., (_) => change)` replaces a read change with a fresh `isRead:false`/`detectedAt:now` instance on re-detection.

5. **Smart alarm fires at ~23:15 the night before all-day bookings** — `lib/services/alarm_service.dart:319-336`
   `startTime == 0` passes the `time < 0 || time > 2359` check, producing a `00:00 − lead` wake time that wins as the earliest candidate.

6. **Language change resets alarm date overrides** — `lib/services/alarm_service.dart:680-684`
   `refreshNativeCopy()` pushes `_loadSmartPlan()` without `_applyDateOverride`, unlike `syncStoredPlans()` (:475). After switching locales the native scheduler loses the override/disabled state.

## Settings persistence (restart loses state — `lib/main.dart` seeds bindings by hand)

7. **`progressivePush` never seeded** — main.dart seeds every other push toggle but not `progressivePushNotifier`; disabling it at startup shows the switch ON (defaults `true`, `app_state.dart:596`).
8. **`blurStrength` never seeded** — runtime blur reads the notifier (`shared_ui.dart:496`), which reverts to 1.0 after restart; stored strength only reloads via backup import.
9. **"Default" page transition reverts to "Expo"** — main.dart:445-448 clamps `0..7`, but the UI/runtime use index `8` = MaterialPageRoute (`settings_appearance_page.dart:207`, `shared_ui.dart:1265`).

## Minor

- Exam "in N days" countdown off by one across a spring-DST weekend (elapsed-hours → calendar days) — `exams_page.dart:673`.
- Lesson stays "active" at the exact end minute (`currentTimeInt <= end`) — `background_service.dart:677`.
- The uncommitted `infoAttachmentLabel` l10n change is consistent (generated code matches the ARB placeholders; `flutter gen-l10n` regenerates clean).
