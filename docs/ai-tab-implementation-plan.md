# AI Tab Implementation Plan

Status: ready for implementation
Branch: design/ai-tab-m3-expressive-redesign
Source specification: docs/ai-tab-ui-spec.md
Scope: UI/UX redesign only; existing AI behavior remains unchanged.

## 1. Implementation strategy

The redesign should be implemented incrementally so each commit leaves the AI tab functional.

The repository currently uses one large Dart library composed through part files from lib/main.dart. The AI redesign should follow that architecture for this branch instead of introducing an unrelated import/module boundary.

New AI presentation files should therefore use part of '../../main.dart' or part of '../../../main.dart' depending on depth, and must be registered in lib/main.dart.

Do not move provider, persistence, parsing or action-application logic during the visual redesign unless a move is strictly mechanical and behavior-preserving.

No new pub dependency is required for the planned UI. Flutter animation primitives, existing Material APIs, ThemedSurface, Google Fonts and flutter_markdown_plus are sufficient.

## 2. Architectural boundary

Keep these responsibilities in AiAssistantPage / existing state layer:

- _loading
- _thinking
- _chatMode
- _chatMessages
- _attachments
- _chatHistory
- _currentChatId
- _latestQuery
- _latestResult
- TabController/state coordination
- context loading
- prompt construction
- provider calls
- streaming lifecycle
- chat persistence
- attachment picking/validation
- AI action parsing/application
- navigation to AI settings/prompt editor
- haptic orchestration where it represents behavior

Move or create only presentation responsibilities in new files:

- layout
- Material 3 Expressive styling
- local press/focus animations
- selected/unselected visuals
- message/result rendering
- loading visuals
- responsive presentation
- accessibility semantics

Presentation widgets receive state and callbacks. They must not call AI providers, SharedPreferences or school-data services directly.

## 3. Target file structure

Add:

    lib/screens/ai/
      ai_ui_tokens.dart
      widgets/
        ai_mode_switch.dart
        ai_hero_surface.dart
        ai_suggestion_card.dart
        ai_attachment_chip.dart
        ai_composer.dart
        ai_typing_indicator.dart
        ai_chat_message.dart
        ai_metric_tile.dart
        ai_analysis_loading_state.dart
        ai_analysis_result.dart
        ai_chat_history_panel.dart
        ai_action_confirmation.dart

Add tests:

    test/screens/ai/
      ai_mode_switch_test.dart
      ai_composer_test.dart
      ai_chat_message_test.dart
      ai_analysis_result_test.dart
      ai_assistant_page_test.dart

Modify:

- lib/main.dart
- lib/screens/main_navigation_screen.dart
- lib/core/shared_ui.dart only if a helper is genuinely reusable outside AI
- lib/l10n.dart only when an existing localized string cannot express the specified UI
- test/widget_test.dart only for integration coverage that already belongs there

Optional final cleanup, only after all behavior is stable:

- Move AiAssistantPage itself from lib/screens/main_navigation_screen.dart to lib/screens/ai/ai_assistant_page.dart as a mechanical extraction.
- Do not combine this extraction with visual behavior changes.

## 4. Dependency graph

Core sequence:

    WP0 Baseline / guardrails
      ↓
    WP1 AI UI foundation
      ↓
    WP2 Mode switch + screen shell
      ├──────────────┐
      ↓              ↓
    WP3 Empty states WP4 Composer
      ↓              ↓
      ├──────┬───────┘
      ↓      ↓
    WP5 Chat WP6 Analysis
      ├──────┤
      ↓      ↓
    WP7 History / action confirmation
      ↓
    WP8 Motion + reduced motion pass
      ↓
    WP9 Responsive + accessibility pass
      ↓
    WP10 Regression tests + cleanup

WP3 and WP4 can be developed in parallel after WP2.
WP5 and WP6 can be developed in parallel once WP1 and the shared visual primitives exist.
WP7 should reuse patterns proven in WP3–WP6 rather than inventing another surface language.

## 5. Work packages

### WP0 — Baseline and behavior guardrails

Goal:
Establish a known-good baseline before visual refactoring.

Files:
- test/screens/ai/ai_assistant_page_test.dart (new, minimal behavior harness)
- existing test files only if shared setup is needed
- no production behavior changes

Tasks:

1. Run flutter analyze on the branch.
2. Run flutter test or the repository helper tool/test_without_local_ai.ps1 where appropriate.
3. Capture current behavior expectations:
   - Analysis is default mode.
   - Switching to Chat preserves current semantics.
   - New Chat clears current session state.
   - Existing session loading works.
   - Composer refuses empty requests.
   - Thinking state blocks duplicate sends.
   - Attachments remain Chat-only and keep current limits.
   - Streaming uses one assistant turn.
   - Proposed Untis actions require confirmation.
4. Add a small integration/widget harness around AiAssistantPage where feasible without network calls.
5. Document any pre-existing failing tests before changing UI.

Dependencies:
None.

Definition of done:

- Existing test suite baseline is known.
- At least critical mode/state behavior has regression coverage or an explicit manual test checklist.
- No production UI has changed.

Suggested commit:
test: establish AI tab redesign baseline

### WP1 — AI presentation foundation

Goal:
Create reusable AI-only visual primitives and register part files without changing the visible screen.

Files:
- lib/main.dart
- lib/screens/ai/ai_ui_tokens.dart
- initial widget files as empty/small implementations where useful
- lib/screens/main_navigation_screen.dart only for type adaptation if required

Tasks:

1. Register new part files in lib/main.dart.
2. Add a private presentation enum such as _AiMode { analysis, chat }.
3. Keep _chatMode as existing behavioral state initially; adapt it at the UI boundary:
   - _chatMode ? _AiMode.chat : _AiMode.analysis
4. Add AI-specific presentation constants/helpers for:
   - spacing
   - preferred max widths
   - default expressive radii
   - motion durations
   - reduced-motion resolution
5. Resolve radii and surfaces through existing Untis+ theme tokens where possible.
6. Do not duplicate app-wide helpers already available from shared_ui.dart.
7. Add one shared helper for AI section entrance only if it cannot be expressed cleanly inside components.

Dependencies:
WP0.

Definition of done:

- New AI UI files compile as part of the existing main.dart library.
- No provider/state behavior moved.
- No visible UI regression.
- No new pub dependency.

Suggested commit:
refactor(ai): add presentation foundation

### WP2 — Screen shell, header and expressive mode switch

Goal:
Replace the standard underline TabBar with the Material 3 Expressive mode switch and stabilize the screen shell.

Files:
- lib/screens/ai/widgets/ai_mode_switch.dart
- lib/screens/main_navigation_screen.dart
- test/screens/ai/ai_mode_switch_test.dart

Tasks:

1. Keep _mainTabHeaderAppBar as the top-level header.
2. Prefer a stable localized AI page title in the header.
3. Move current-chat title into Chat content/history context if needed instead of changing the app-bar identity.
4. Remove the visible standard TabBar.
5. Add AiModeSwitch below the app bar/content top edge.
6. Keep the existing TabController temporarily as state coordinator if this minimizes risk.
7. Ensure tapping Analysis/Chat still calls the existing _selectAiTab behavior.
8. Implement:
   - selected pill
   - icon state
   - selected/unselected typography
   - light haptic through existing callback/state flow
   - spring/morph motion
   - reduced-motion fallback
9. Add content transition wrapper around Analysis/Chat body without altering child state.

Dependencies:
WP1.

Definition of done:

- Analysis and Chat remain equally discoverable.
- Switching modes preserves all existing behavior.
- No underline TabBar remains.
- Selected state is semantically exposed.
- Reduced motion removes overshoot/translation.
- Widget tests cover both mode states and tap behavior.

Suggested commit:
feat(ai): add expressive analysis chat switch

### WP3 — Empty states and contextual suggestions

Goal:
Implement the new AI landing experience for empty Analysis and empty Chat.

Files:
- lib/screens/ai/widgets/ai_hero_surface.dart
- lib/screens/ai/widgets/ai_suggestion_card.dart
- lib/screens/main_navigation_screen.dart
- test/screens/ai/ai_assistant_page_test.dart

Tasks:

1. Replace _buildEmptyState visual implementation with AiHeroSurface plus mode-specific suggestions.
2. Reuse existing localized strings:
   - aiEmptyPromptTitle
   - aiEmptyPromptSubtitle
   - aiChatTitle
   - aiChatSubtitle
   - aiTryIt
   - existing suggestion strings
3. Preserve _buildContextualChips logic and _sendQuickPrompt callback behavior.
4. Analysis:
   - render compact contextual prompt controls
   - keep first/relevant suggestion fully readable
5. Chat:
   - render up to three larger suggestion cards with semantic icons
6. Implement pressed tonal/scale state and reduced-motion fallback.
7. Ensure large text does not clip hero/suggestion content.

Dependencies:
WP2.

Definition of done:

- Empty Analysis and Chat match the UI spec.
- Suggestion taps still execute the same prompt flow.
- No contextual suggestion logic is duplicated in presentation widgets.
- Works with light/dark and at least one non-default theme.

Suggested commit:
feat(ai): redesign empty states and suggestions

### WP4 — Unified composer and attachment chips

Goal:
Replace _buildSearchBar with the shared expressive composer without changing request behavior.

Files:
- lib/screens/ai/widgets/ai_composer.dart
- lib/screens/ai/widgets/ai_attachment_chip.dart
- lib/screens/main_navigation_screen.dart
- test/screens/ai/ai_composer_test.dart

Tasks:

1. Create AiComposer with explicit inputs/callbacks:
   - controller
   - focusNode
   - mode
   - thinking
   - attachments
   - hintText
   - onAttach
   - onRemoveAttachment
   - onSend
   - onClear
2. Keep _inputController and _promptFocusNode owned by AiAssistantPage.
3. Keep _pickAssistantAttachment and all validation in AiAssistantPage.
4. Show attachment control only in Chat.
5. Preserve current attachment limit and accepted file types.
6. Replace current InputChip rendering with AiAttachmentChip.
7. Keep composer dimensions stable between idle and thinking states.
8. Implement:
   - unfocused state
   - focused state
   - text-present state
   - disabled/thinking state
   - attachments state
   - keyboard-open state
9. Keep keyboard inset behavior correct with resizeToAvoidBottomInset: false.
10. Verify newest chat message is not hidden behind the composer.
11. Ensure send/search semantics and TextInputAction behavior remain correct.

Dependencies:
WP1.
Recommended after WP2 so screen spacing is final.

Definition of done:

- Same callback paths are used for send/search/attachment/remove/clear.
- Empty request is still rejected.
- Duplicate send is still blocked while thinking.
- Composer height does not jump when loader replaces the send icon.
- One and three attachment states work.
- Keyboard and safe-area spacing are correct.
- Widget tests cover focus, disabled, attachment and mode-specific controls.

Suggested commit:
feat(ai): add unified expressive composer

### WP5 — Chat message and streaming presentation

Goal:
Redesign Chat reading experience while preserving message data and streaming semantics.

Files:
- lib/screens/ai/widgets/ai_chat_message.dart
- lib/screens/ai/widgets/ai_typing_indicator.dart
- lib/screens/main_navigation_screen.dart
- test/screens/ai/ai_chat_message_test.dart
- test/screens/ai/ai_assistant_page_test.dart

Tasks:

1. Replace _buildChatBubble with AiChatMessage.
2. Replace visual typing bubble with AiTypingIndicator inside the assistant message surface.
3. Preserve current List<Map<String, String>> message model.
4. Preserve MarkdownBody/selectable behavior.
5. User messages:
   - right aligned
   - compact width
   - primary/primaryContainer treatment
6. Assistant messages:
   - left aligned
   - reading-focused surface
   - wider max width than user messages
   - calmer styling for long Markdown
7. Preserve one assistant surface while content streams.
8. Do not animate each stream chunk.
9. Preserve current scroll-to-bottom behavior.
10. Preserve current streaming haptic throttling.
11. Ensure error text remains attached to the failed assistant turn.

Dependencies:
WP1.
Benefits from WP4 because composer/chat spacing can be tested together.

Definition of done:

- Short chat, long Markdown, streaming and error turns render correctly.
- No duplicate assistant typing/message card.
- Markdown remains selectable.
- Streaming does not restart entrance animation on every chunk.
- Tablet chat width remains readable.

Suggested commit:
feat(ai): redesign chat messages and streaming state

### WP6 — Analysis loading and result presentation

Goal:
Replace generic Analysis loading/results with modular expressive result components.

Files:
- lib/screens/ai/widgets/ai_analysis_loading_state.dart
- lib/screens/ai/widgets/ai_analysis_result.dart
- lib/screens/ai/widgets/ai_metric_tile.dart
- lib/screens/main_navigation_screen.dart
- test/screens/ai/ai_analysis_result_test.dart

Tasks:

1. Keep _AiSearchResult, _AiMetric and _AiLessonCardData behavior unchanged.
2. Create AiAnalysisLoadingState:
   - submitted query remains visible
   - calm tonal loading surface
   - optional skeleton placeholders
3. Create AiAnalysisResult:
   - summary card
   - assist/tag chips
   - metrics
   - lessons
   - low-priority re-run/clear actions
4. Reuse existing LessonCard directly.
5. Move _metricIcon mapping only if it is purely presentation logic; otherwise pass resolved icon from parent.
6. Preserve all existing fallback parsing behavior.
7. Add staged entrance for sections without delaying access to content.
8. Make result actions call current _handleMenuAction / _sendQuickPrompt / _clearCurrentResult paths.
9. Add inline recoverable error treatment if current error state can be separated cleanly without changing provider behavior.

Dependencies:
WP1.
Recommended after WP4 so the final bottom spacing/composer geometry is known.

Definition of done:

- Summary-only results render.
- Tags/metrics/lessons combinations render independently.
- Lesson cards are shared, not cloned.
- Re-run and clear use current behavior.
- Result layout uses 2 columns on phone and 3 where width permits.
- No parsing/provider logic moved into widgets.

Suggested commit:
feat(ai): redesign analysis loading and results

### WP7 — History panel and AI action confirmation

Goal:
Bring secondary AI surfaces into the same visual system.

Files:
- lib/screens/ai/widgets/ai_chat_history_panel.dart
- lib/screens/ai/widgets/ai_action_confirmation.dart
- lib/screens/main_navigation_screen.dart
- tests in test/screens/ai/ai_assistant_page_test.dart or dedicated files

Part A — Chat history:

1. Replace _buildSidebar internal presentation with AiChatHistoryPanel.
2. Keep Drawer behavior on phone for this implementation.
3. Keep callbacks in parent:
   - _startNewChat
   - _loadSession
   - _removeChatSession
   - _openPromptEditor
   - _openSettings
   - _handleMenuAction
4. Make New Chat the primary expressive action.
5. Separate navigation, destructive actions and settings visually.
6. Preserve selected-chat state.

Part B — AI action confirmation:

1. Keep _actionsFromReply and _applyActions unchanged.
2. Keep explicit confirmation mandatory.
3. Replace bullet-only presentation with structured rows/cards where practical.
4. Add semantic icon mapping by action kind.
5. Apply error semantic styling to destructive actions.
6. Cancel remains always visible.
7. Dismissal must not imply approval.
8. Do not apply actions optimistically before confirmation.

Dependencies:
WP1.
Prefer after WP3–WP6 so visual tokens and component language are established.

Definition of done:

- History persistence and selection behavior are unchanged.
- New Chat/session/delete/settings actions still use existing callbacks.
- Proposed actions remain blocked until explicit Apply.
- Destructive proposals are clearly distinguished.
- No new modal implementation bypasses shared Untis dialog/sheet behavior.

Suggested commits:
feat(ai): redesign chat history panel
feat(ai): improve action confirmation presentation

### WP8 — Motion and reduced-motion consolidation

Goal:
Make animation behavior coherent across components and ensure accessibility.

Files:
- lib/screens/ai/ai_ui_tokens.dart
- all AI presentation widgets
- lib/screens/main_navigation_screen.dart
- possibly lib/core/shared_ui.dart only if a reusable motion helper benefits multiple app areas
- tests where deterministic state can be asserted

Tasks:

1. Audit all AI animations against the UI spec.
2. Standardize:
   - mode switch: 320–420 ms
   - content transition: 220–320 ms
   - suggestion press/release
   - composer focus
   - send/loading morph
   - attachment insertion/removal
   - result stagger
   - chat insertion
   - history selection
3. Use MediaQuery.disableAnimations as required.
4. Also respect existing app animation preferences if they apply to UI motion.
5. Reduced motion:
   - no overshoot
   - no wiggle
   - minimal/no translation
   - no information-delaying stagger
   - static/low-motion loading
6. Verify no multiple large spring animations compete at once.
7. Verify streaming chunks do not trigger full message animation.

Dependencies:
WP2–WP7.

Definition of done:

- Motion durations/curves are centralized enough to remain consistent.
- Reduced-motion mode has no spring overshoot or unnecessary movement.
- No animation blocks input or delays important content.

Suggested commit:
refactor(ai): unify expressive motion and reduced motion

### WP9 — Responsive, themes and accessibility pass

Goal:
Validate the redesigned screen under non-default conditions.

Files:
- AI presentation widgets
- lib/screens/main_navigation_screen.dart
- tests/screens/ai/*
- lib/l10n.dart only if semantics/labels require missing copy

Tasks:

1. Compact phone validation.
2. Large phone/foldable narrow width validation.
3. Tablet validation:
   - chat reading width around 760 dp
   - analysis width up to existing ~980 dp
   - 3-column metrics when appropriate
   - composer follows reading column, not full device
4. Light mode.
5. Dark mode.
6. Default theme.
7. At least Manga or another strongly different theme.
8. Large text scale.
9. Verify minimum 48 dp interactive targets.
10. Add semantics/tooltips for:
    - mode switch
    - menu/history
    - attach
    - remove attachment
    - send/search
    - clear
    - session delete
11. Verify selected mode is communicated beyond color.
12. Verify focus order on platforms supporting keyboard focus.
13. Verify error treatment includes icon/text, not color alone.

Dependencies:
WP2–WP8.

Definition of done:

- No clipping at supported text scaling.
- Phone and tablet are intentionally laid out.
- Non-default themes remain readable.
- Icon-only actions have accessible labels.
- Touch targets meet the planned size.

Suggested commit:
fix(ai): polish responsive and accessible states

### WP10 — Regression suite, cleanup and optional extraction

Goal:
Finish with behavior safety and remove obsolete UI code.

Files:
- test/screens/ai/*
- test/widget_test.dart where integration coverage fits
- lib/screens/main_navigation_screen.dart
- lib/main.dart
- optionally lib/screens/ai/ai_assistant_page.dart
- docs/ai-tab-implementation-plan.md status section

Tasks:

1. Add/finish widget tests for:
   - Analysis empty
   - Chat empty
   - mode switching
   - composer focused
   - 1 and 3 attachments
   - Analysis loading
   - summary-only result
   - result with tags/metrics/lessons
   - short chat
   - long Markdown
   - streaming state
   - error state
   - history selected item
   - normal/destructive action confirmation
   - reduced motion
   - tablet width
2. Run flutter analyze.
3. Run flutter test.
4. Run tool/test_without_local_ai.ps1 when local-model native dependencies would otherwise interfere.
5. Remove obsolete private UI builders only after replacements are covered:
   - old _buildSearchBar body
   - old _buildChatBubble
   - old _buildTypingBubble visuals
   - old result card rendering
   - old suggestion-card presentation
6. Remove dead styles/constants.
7. Check that no new localization key is unused.
8. Optional: mechanically extract AiAssistantPage from main_navigation_screen.dart into lib/screens/ai/ai_assistant_page.dart.
9. If doing the extraction:
   - one separate commit
   - no visual/behavior changes
   - rerun full tests afterward

Dependencies:
All prior packages.

Definition of done:

- flutter analyze passes.
- flutter test passes or only documented pre-existing failures remain.
- All existing AI functional invariants still hold.
- Old duplicate AI presentation code is removed.
- No unused new components remain.
- Optional page extraction is behavior-neutral.

Suggested commits:
test(ai): cover redesigned assistant states
refactor(ai): remove legacy AI presentation
refactor(ai): extract assistant page (optional, separate commit)

## 6. File-by-file change map

### lib/main.dart

Change:
Register all new part files.

Risk:
Low, but missing/incorrect part paths fail compilation immediately.

Dependency:
WP1 and any later newly added component file.

### lib/screens/main_navigation_screen.dart

Change:
Primary integration point throughout the redesign.

Keep:
- AiAssistantPage state
- provider/prompt/persistence/action logic
- data loading
- callbacks

Replace gradually:
- TabBar
- empty-state builders
- search/composer builder
- chat bubble/typing presentation
- result rendering
- sidebar presentation
- action-confirmation presentation

Risk:
High because this file currently mixes UI and behavior.

Mitigation:
Small commits, one visual area at a time; do not combine provider/state refactors with UI replacement.

### lib/screens/ai/ai_ui_tokens.dart

Change:
AI-local spacing/shape/motion constants and small presentation helpers.

Risk:
Low.

Rule:
Do not recreate app-level theme tokens already available through untisThemeTokensOf(context).

### lib/screens/ai/widgets/ai_mode_switch.dart

Depends on:
WP1.

Consumes:
selected mode, callback, enabled/reduced motion.

Must not own:
AI mode business state.

### lib/screens/ai/widgets/ai_hero_surface.dart

Depends on:
WP1.

Consumes:
title, subtitle, icon/status.

Must not know:
timetable/exam context logic.

### lib/screens/ai/widgets/ai_suggestion_card.dart

Depends on:
WP1.

Consumes:
text, icon, tap callback.

Must not:
construct prompts or call _sendQuickPrompt directly.

### lib/screens/ai/widgets/ai_attachment_chip.dart

Depends on:
WP1.

Consumes:
attachment display data and remove callback.

Must not:
pick/read files.

### lib/screens/ai/widgets/ai_composer.dart

Depends on:
WP1, existing controller/focus state.

Consumes:
controller, focusNode, mode, thinking, attachments and callbacks.

Must not:
perform send/provider/file-picker logic.

### lib/screens/ai/widgets/ai_typing_indicator.dart

Depends on:
WP1.

Pure presentation.

### lib/screens/ai/widgets/ai_chat_message.dart

Depends on:
WP1, flutter_markdown_plus already present.

Consumes:
role/content/streaming state.

Must preserve:
selectable Markdown and reading width.

### lib/screens/ai/widgets/ai_metric_tile.dart

Depends on:
WP1.

Pure presentation.

### lib/screens/ai/widgets/ai_analysis_loading_state.dart

Depends on:
WP1.

Consumes:
query/localized copy/reduced-motion state.

No provider logic.

### lib/screens/ai/widgets/ai_analysis_result.dart

Depends on:
WP1 and existing result data types.

Consumes:
result, actions/callbacks.

May reuse:
LessonCard.

Must not:
parse raw AI output.

### lib/screens/ai/widgets/ai_chat_history_panel.dart

Depends on:
WP1.

Consumes:
sessions, selected id, callbacks.

Must not:
read/write SharedPreferences.

### lib/screens/ai/widgets/ai_action_confirmation.dart

Depends on:
WP1 and existing proposed-action model.

Consumes:
actions and localized summaries.

Must not:
apply changes itself; it only returns/communicates user approval.

### lib/core/shared_ui.dart

Default:
No change.

Only change if:
A helper becomes clearly useful beyond the AI tab.

Examples that may justify shared placement:
- a generic expressive segmented control later reused elsewhere
- a reusable reduced-motion animation helper

Do not move AI-only tokens here.

### lib/l10n.dart

Default:
Reuse existing keys.

Only add keys for:
- new accessible labels not covered by MaterialLocalizations/existing copy
- a genuinely new visible state description

Avoid rewriting translation copy as part of the visual refactor.

### test/screens/ai/*

Purpose:
Component and integration regression coverage.

No new test package is required; flutter_test is already available.

## 7. Critical dependencies and constraints

### Existing shared UI

The redesign depends on:

- _mainTabHeaderAppBar
- ThemedSurface
- untisThemeTokensOf(context)
- existing ColorScheme
- existing haptic helpers
- existing bottom-sheet/dialog wrappers
- existing responsive helper UntisLayout
- existing LessonCard

Do not fork these concepts inside AI.

### Current AI state model

The first implementation should adapt the existing bool _chatMode instead of replacing state management.

Reason:
A simultaneous state-model rewrite would make visual regressions harder to isolate.

### Current TabController

May remain during WP2 as a compatibility bridge.

After all UI is stable:
If TabController no longer provides value, it can be removed in a separate cleanup commit.

### Current monolithic Dart library

All part files share private identifiers. This makes low-risk presentation extraction possible.

Constraint:
Every new part file must be registered in main.dart and use the correct relative part-of path.

### Network/provider tests

The UI tests should not call actual remote/local AI providers.

Use controlled widget state or existing test seams. If a new seam is needed, prefer callback/state injection over adding a mock package solely for this redesign.

## 8. Commit strategy

Keep commits reviewable and reversible:

1. test: establish AI tab redesign baseline
2. refactor(ai): add presentation foundation
3. feat(ai): add expressive analysis chat switch
4. feat(ai): redesign empty states and suggestions
5. feat(ai): add unified expressive composer
6. feat(ai): redesign chat messages and streaming state
7. feat(ai): redesign analysis loading and results
8. feat(ai): redesign chat history panel
9. feat(ai): improve action confirmation presentation
10. refactor(ai): unify expressive motion and reduced motion
11. fix(ai): polish responsive and accessible states
12. test(ai): cover redesigned assistant states
13. refactor(ai): remove legacy AI presentation
14. refactor(ai): extract assistant page (optional)

Do not squash all work into one implementation commit while developing. The boundaries above allow regressions to be bisected.

## 9. Validation gates

Gate A — after WP2:
- App builds.
- Mode switching works.
- No AI request behavior changed.

Gate B — after WP4:
- Composer works in Analysis and Chat.
- Keyboard/attachments verified.
- Empty input/duplicate send guards still work.

Gate C — after WP6:
- Chat streaming and Analysis results both work.
- Existing parsing/provider logic untouched.

Gate D — after WP7:
- History and action confirmation work.
- AI actions still require explicit approval.

Gate E — after WP9:
- Reduced motion.
- phone/tablet.
- light/dark.
- non-default theme.
- large text.
- semantics.

Gate F — final:
- flutter analyze.
- flutter test.
- manual smoke test with a configured AI provider.
- manual smoke test without a configured provider/error path.

## 10. Manual smoke-test script

Analysis:
1. Open AI tab.
2. Verify header and Analysis selected state.
3. Tap contextual suggestion.
4. Verify thinking state.
5. Verify result summary.
6. Verify metrics/lessons if present.
7. Search again.
8. Clear result.

Chat:
1. Switch to Chat.
2. Tap suggestion.
3. Verify user turn inserts immediately.
4. Verify one assistant streaming surface.
5. Verify long Markdown is readable/selectable.
6. Start a new chat.
7. Open previous session.
8. Delete a session.

Attachments:
1. Add supported text/image/PDF file.
2. Remove file.
3. Add up to current limit.
4. Verify oversize/current validation behavior.
5. Send with attachment.

Actions:
1. Produce a supported Untis action.
2. Verify raw action block is hidden as today.
3. Verify confirmation appears.
4. Cancel and verify no data change.
5. Repeat and Apply.
6. Verify change is applied only after confirmation.

Accessibility/responsive:
1. Enable reduced motion.
2. Increase text scale.
3. Test dark mode.
4. Test non-default theme.
5. Test phone width.
6. Test tablet width.

## 11. Non-goals during implementation

Do not include in these work packages:

- new AI features
- new provider APIs
- provider refactors
- prompt redesign
- chat-history storage migration
- Riverpod migration of AiAssistantPage
- attachment-limit changes
- action protocol changes
- timetable/exam data-source changes
- general app navigation redesign
- broad shared_ui cleanup unrelated to AI

These can be separate follow-up projects after the redesigned UI is stable.

## 12. Recommended first implementation slice

Start with WP0 → WP1 → WP2.

That slice is intentionally small:
- behavior guardrails first
- presentation infrastructure second
- one highly visible but isolated UI replacement third

Once the expressive mode switch is stable, implement WP3 and WP4. The composer is the highest-risk visual change because it touches focus, keyboard, loading and attachments, so it should be complete before chat/result polish is finalized.
