# AI Tab Redesign Plan — Material 3 Expressive

> Revision 2026-09-21: Analysis/Chat now uses the shared `_mainSectionTabBar(...)` pattern, identical to the other section tabs in Untis+. The earlier custom expressive mode-switch proposal is superseded; Material 3 Expressive styling remains in the AI content, composer, cards and motion.

Branch: design/ai-tab-m3-expressive-redesign

Implementation UI specification: docs/ai-tab-ui-spec.md
Implementation plan: docs/ai-tab-implementation-plan.md

## Goal

Redesign the AI tab so it feels native to the current Untis+ visual system and much more Material 3 Expressive, while keeping all existing AI capabilities and data flows unchanged.

This is a UI/UX refactor only. Provider logic, prompts, chat persistence, attachments, AI actions, timetable/exam context, search parsing and settings behavior remain functionally equivalent.

## Current state

The AI experience currently lives mostly inside lib/screens/main_navigation_screen.dart in AiAssistantPage.

Existing functionality that must be preserved:

- Analysis/search mode with contextual prompt chips.
- Chat mode with streaming responses.
- Chat history and new-chat flow.
- File attachments in chat.
- Markdown rendering.
- AI-proposed Untis actions with confirmation before applying changes.
- AI settings and prompt editor navigation.
- Context-aware suggestions based on timetable/exams.
- Structured AI result cards, metrics and lesson cards.
- Loading, error and empty states.
- Haptic feedback.
- Tablet width constraints.
- Existing theme/background support.

Existing shared UI that should be reused rather than duplicated:

- _mainTabHeaderAppBar(...) for the same centered tab-header treatment as the rest of the app.
- ThemedSurface for blur, opacity, theme tokens and user-configurable surface behavior.
- _showUnifiedSheet(...) / shared sheet helpers where a modal surface is needed.
- Existing page motion/token helpers and app haptics.
- Existing Material 3 Expressive spring/bounce language from _ExpressiveNavBar.

## Design direction

### 1. Clearer information hierarchy

Keep the top-level title visually identical to the other main tabs.

Below the title, replace the current conventional underline TabBar with an expressive two-state mode switch:

- Analysis
- Chat

Use a rounded tonal pill/segmented surface with animated selection movement, icon morph/scale and strong selected-state contrast.

Do not hide either mode behind a menu.

### 2. Expressive AI home state

The empty state becomes a real AI landing surface rather than a plain column:

- Large AI identity/hero surface using auto_awesome_rounded.
- Short contextual heading and subtitle.
- Context-aware suggestion cards/chips directly below.
- Suggestions grouped visually instead of a long flat list.
- Use asymmetric but controlled Material 3 shapes and tonal containers.
- No decorative UI that competes with the timetable background.

Analysis and Chat can share the same visual foundation but use mode-specific content.

### 3. Unified composer

Turn _buildSearchBar into one shared expressive composer used by both modes.

Structure:

- Main tonal surface with a clear focus state.
- Attachment button only when supported.
- Attachment chips shown in a compact row above the text field.
- Send/Search becomes a circular or rounded-square expressive action button.
- Button should animate between idle, active and loading states.
- Focus should subtly expand/elevate the composer rather than only changing font weight.
- Keyboard inset handling must remain correct.

The composer should feel anchored to the bottom, not like an unrelated form field.

### 4. Analysis results

Replace the current large generic result container with a more modular result stack:

- Primary answer/summary card.
- Metric tiles using tonal hierarchy and semantic icons.
- Lesson cards remain the existing shared LessonCard.
- Tags become supporting assist chips.
- Related actions such as re-run/clear should be available contextually without opening the history drawer.

Result cards should enter progressively rather than all appearing at once.

### 5. Chat experience

Keep the existing message model and Markdown behavior, but redesign presentation:

- User messages: compact primary/secondary tonal bubbles.
- Assistant messages: less speech-bubble-like, more surface/card-like so long Markdown answers read better.
- Better vertical rhythm between messages.
- Streaming indicator integrated into the assistant surface.
- Preserve selectable Markdown.
- Long content should prioritize readability over decorative effects.

For AI-proposed Untis actions, keep the existing confirmation requirement. The confirmation UI can be visually modernized with shared Material 3 dialog/sheet styling, but must never auto-apply changes.

### 6. Chat history / navigation

Keep all current history behavior, but improve the sidebar:

- Use the same surface/blur language as the rest of the app.
- Stronger selected-chat state.
- New Chat as the primary expressive action.
- Group destructive/history-management actions away from normal navigation.
- On compact layouts, consider the existing drawer behavior acceptable; if changed to a sheet, use the centralized shared sheet implementation.
- Tablet layout may optionally keep history persistently visible only if this can be done without changing navigation semantics.

### 7. Material 3 Expressive motion

Motion should communicate state, not decorate every element.

Use:

- Spring/pill morph when switching Analysis <-> Chat.
- Shared-axis/fade+scale transition for mode content.
- Staggered result-card entrance after an analysis completes.
- Soft scale/tonal response for suggestion cards.
- Composer focus expansion.
- Send/Search icon morph.
- Streaming assistant surface fade/expand.
- Chat-history selection morph.
- Smooth attachment-chip insertion/removal.

Durations should generally stay in the existing ~200–450 ms language used elsewhere in the app.

Respect MediaQuery.disableAnimations and any existing app animation preferences. Reduced-motion mode should remove translation/spring overshoot and retain only minimal fades where useful.

### 8. Material/shape system

Avoid hardcoded one-off visual rules where shared tokens already exist.

Prefer:

- ColorScheme.surfaceContainer*
- primaryContainer / secondaryContainer / tertiaryContainer
- ThemedSurface
- existing theme token radii
- existing blur and opacity preferences

Use expressive shape contrast:

- Larger radius for primary AI surfaces.
- Medium radius for result cards.
- Smaller/compact radius for chips and attachments.

The AI tab must still look correct under all supported app themes, not only the default theme.

## Proposed component refactor

The current AI UI is too concentrated in lib/screens/main_navigation_screen.dart. During implementation, extract presentation widgets without moving service/business logic unnecessarily.

Suggested structure:

    lib/screens/ai/
      ai_assistant_page.dart
      widgets/
        ai_mode_switch.dart
        ai_composer.dart
        ai_empty_state.dart
        ai_analysis_result.dart
        ai_chat_message.dart
        ai_chat_history.dart
        ai_typing_indicator.dart
        ai_suggestion_card.dart

If splitting the screen would create excessive coupling with existing private helpers, first extract only reusable presentation widgets and keep state/business logic in AiAssistantPage.

## State-by-state UX checklist

### Loading initial context
- Keep app header visible.
- Replace centered generic spinner with a lightweight AI skeleton/tonal loading state.

### Empty Analysis
- AI hero.
- Contextual suggestions immediately visible.
- Composer ready at bottom.

### Analysis running
- Preserve submitted query visibly.
- Animated but calm thinking state.
- No layout jump when results arrive.

### Analysis result
- Summary first.
- Metrics second.
- Lessons/details after.
- Re-run and clear available with low visual priority.

### Empty Chat
- AI hero plus 3 suggested prompts.
- New Chat/history remains accessible.

### Chat streaming
- User message appears immediately.
- Assistant surface streams progressively.
- Composer enters disabled/loading state without changing dimensions.

### Attachment selected
- File chip appears above composer.
- Clear remove affordance.
- Existing 3-file limit and size validation remain unchanged.

### Error
- Keep the error attached to the relevant result/message.
- Provide retry when possible.
- Do not replace the whole page with an error screen for recoverable failures.

### Proposed Untis actions
- Preserve explicit confirmation.
- Clearly distinguish AI suggestion from applied change.
- Destructive actions need the same or stronger confirmation clarity as today.

## Responsive behavior

Phone:
- Single-column content.
- Bottom composer.
- History via drawer/shared modal surface.

Tablet:
- Keep the existing max content width.
- Use available width to improve result grids and message reading width.
- Optional two-pane history/chat layout only after the phone redesign is stable.

Do not make tablet a stretched phone layout.

## Accessibility

- Minimum interactive target ~48 dp.
- Semantics/tooltips for icon-only actions.
- Sufficient contrast in all ColorScheme states.
- Do not communicate state only through color.
- Preserve text scaling without clipped mode labels or composer controls.
- Reduced motion support is required.
- Maintain keyboard/focus behavior for the composer.

## Implementation phases

### Phase 1 — structure and shared styling
- Extract AI presentation components where safe.
- Introduce one internal AI surface/shape style layer based on app tokens.
- Keep behavior unchanged.

### Phase 2 — header, mode switch and empty states
- Keep _mainTabHeaderAppBar.
- Replace underline tabs with expressive mode switch.
- Redesign Analysis/Chat empty states and suggestions.

### Phase 3 — composer
- Replace current composer visuals.
- Preserve send, search, attachment, clear, keyboard and loading behavior.
- Add focus/send state motion.

### Phase 4 — chat
- Redesign bubbles/messages and typing state.
- Improve Markdown reading layout.
- Restyle history drawer without changing persistence behavior.

### Phase 5 — analysis results
- Redesign result summary, metrics, tags and loading transition.
- Reuse LessonCard.
- Add staged result entrance.

### Phase 6 — polish
- Reduced-motion pass.
- Theme compatibility pass.
- Tablet pass.
- Accessibility pass.
- Golden/widget tests where practical.

## Acceptance criteria

The redesign is complete when:

1. Every existing AI function still works.
2. Analysis and Chat remain equally discoverable.
3. The header matches the other main tabs.
4. UI uses existing app surface/theme primitives instead of duplicating them.
5. The AI tab visually reads as Material 3 Expressive: stronger shapes, tonal hierarchy and meaningful motion.
6. Animations respect reduced-motion settings.
7. Composer dimensions stay stable while sending/loading.
8. Streaming remains smooth and does not cause excessive rebuild/jank.
9. AI actions still require explicit confirmation.
10. Layout works on phone and tablet.
11. Light/dark mode and all app themes remain usable.
12. No provider/prompt/history persistence behavior changes as part of the redesign.

## Likely files touched during implementation

Primary:
- lib/screens/main_navigation_screen.dart
- new lib/screens/ai/... UI files if extraction is practical

Possible shared UI updates:
- lib/core/shared_ui.dart only when a genuinely reusable expressive control/surface is needed

Localization:
- lib/l10n.dart only if new explanatory labels are necessary; existing strings should be reused where possible

Tests:
- relevant widget/unit test files for AI state transitions and preserved behavior

## Non-goals

- Changing AI providers or API behavior.
- Changing system-prompt semantics.
- Changing action parsing/application logic.
- Changing attachment limits.
- Reworking timetable/exam data sources.
- Adding new AI features during the visual redesign.
