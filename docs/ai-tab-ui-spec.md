# AI Tab UI Specification — Material 3 Expressive

Status: implementation-ready UI/UX specification  
Branch: design/ai-tab-m3-expressive-redesign  
Implementation plan: docs/ai-tab-implementation-plan.md  
Scope: visual structure, interaction, component states and motion. Existing AI behavior stays unchanged.

## 1. Product intent

The AI tab should feel like a native part of Untis+, not a separate chatbot embedded in the app.

The experience should be:

- Fast to understand.
- Visually expressive without becoming noisy.
- Context-aware.
- Comfortable for both short school-related queries and long Markdown answers.
- Consistent with Untis+ surfaces, blur, shapes, typography and navigation.
- Motion-rich where motion explains a state change.
- Fully usable with reduced motion, text scaling, dark mode and custom themes.

Material 3 Expressive is used as a design language, not as a reason to replace established Untis+ patterns. Existing app primitives remain the source of truth.

## 2. Functional invariants

The redesign must not change:

- Analysis/search behavior.
- Chat behavior and streaming.
- AI provider selection or provider APIs.
- Prompt construction.
- Chat history persistence.
- File attachment rules, limits or validation.
- Markdown support.
- Context from timetable/exams.
- Structured analysis parsing.
- AI-proposed Untis actions.
- Explicit confirmation before applying AI-proposed actions.
- AI settings and prompt editor behavior.
- Existing lesson card behavior.
- Existing haptics unless a UI interaction is being replaced with an equivalent interaction.

## 3. Screen anatomy

### 3.1 Phone layout

Vertical order:

1. Shared main-tab header.
2. Expressive AI mode switch.
3. Scrollable mode content.
4. Bottom composer.

Conceptual layout:

    ┌──────────────────────────────────┐
    │          AI Assistant            │  Shared RoundedBlurAppBar
    │                                  │
    │    [ Analysis ]   [ Chat ]       │  Expressive mode switch
    ├──────────────────────────────────┤
    │                                  │
    │  Mode content                    │
    │  - hero / suggestions            │
    │  - result cards                  │
    │  - chat messages                 │
    │                                  │
    │                                  │
    ├──────────────────────────────────┤
    │  attachments                     │
    │  [ Ask something...        ][↗]  │  Composer
    └──────────────────────────────────┘

The composer remains visually attached to the bottom of the AI experience while avoiding the system navigation/keyboard inset.

### 3.2 Tablet layout

Primary tablet layout remains centered with a maximum content width close to the current 980 dp constraint.

Recommended behavior:

- Header spans available content as today.
- Mode switch max width: 420 dp.
- Chat reading column max width: 760 dp.
- Analysis result column max width: 900–980 dp.
- Metric grid may use 3 columns when width permits.
- Do not stretch assistant messages to full tablet width.

A persistent chat-history rail is optional future polish, not required for the first implementation.

## 4. Global visual tokens for AI UI

These are component-level targets. They should be resolved through existing Untis+ theme primitives wherever possible.

### 4.1 Spacing

Use a compact 4 dp base rhythm:

- 4 dp: icon/text micro-gap.
- 8 dp: related controls.
- 12 dp: compact component internal gap.
- 16 dp: standard horizontal screen padding.
- 20 dp: large component internal padding.
- 24 dp: section separation.
- 32 dp: hero separation.

Phone screen horizontal padding: 16 dp.

Do not create multiple nested cards each with independent 16–24 dp padding. Prefer fewer, stronger surfaces.

### 4.2 Shape hierarchy

Default-theme target radii:

- Hero / primary expressive surface: 28–32 dp.
- Mode switch container: 24–28 dp.
- Composer: 26–30 dp.
- Main result card: 24–28 dp.
- Secondary result tile: 20–24 dp.
- Suggestion card: 20–24 dp.
- Message surface: 18–24 dp.
- Attachment/assist chip: 12–16 dp.
- Circular icon controls: circular.

Actual radius must remain compatible with the app's surface-corner preference and theme tokens. Use ThemedSurface when the user-configurable surface system should apply.

### 4.3 Color hierarchy

Prefer semantic ColorScheme roles rather than custom colors.

Base surfaces:

- Background: existing app backdrop.
- AI hero: primaryContainer or tertiaryContainer, depending on theme contrast.
- Secondary AI surfaces: surfaceContainerLow / surfaceContainer.
- Elevated result surfaces: surfaceContainerHigh.
- Selected mode: primary.
- Selected mode content: onPrimary.
- Unselected mode: transparent or surfaceContainerHigh.
- User message: primaryContainer or primary depending on required contrast.
- Assistant message: surfaceContainerHigh / surfaceContainer.
- Attachment chip: secondaryContainer.
- Error state: errorContainer.
- Success/applied state: use a theme-supported positive semantic treatment if one exists; otherwise avoid introducing a global success color token in this redesign.

Avoid gradients unless the current theme explicitly provides them. Expressiveness should come primarily from shape, scale, space, motion and tonal contrast.

### 4.4 Typography

Continue using the app's Outfit-based typography.

Header stays shared through _mainTabHeaderAppBar:

- 26 sp.
- FontWeight.w900.
- Centered.
- Same behavior as Exams, Infos and Settings main-tab headers.

AI-specific hierarchy:

- Hero title: 28–30 sp, w900, tight line height.
- Result headline: 22–24 sp, w800/w900.
- Section title: 17–18 sp, w800.
- Message body / result body: 15–16 sp, w500/w600.
- Composer input: 16 sp, w500/w600.
- Assist chip: 12.5–14 sp, w600/w700.
- Metadata: 11.5–13 sp, w600.

Do not use font weight as the only focus indicator.

## 5. Component specification

## 5.1 Shared header

Component: existing _mainTabHeaderAppBar.

Requirements:

- Do not create a special AI-only app bar.
- Centered title.
- AI title uses the same text size, color and weight as the other main tabs.
- Leading menu/history control may remain.
- No AI-specific oversized title treatment inside the app bar.
- If the current chat has a title, use it only where it does not break main-tab header consistency. Preferred default: keep the page header as the localized AI title and show chat title within Chat content/history context.

Reason: the top-level navigation identity should remain stable when conversation content changes.

## 5.2 AI mode switch

New component: AiModeSwitch.

Purpose: replace the current underline TabBar while preserving Analysis and Chat as two equally discoverable modes.

Structure:

    ┌───────────────────────────────┐
    │ [ ◉ Analysis ]   [ ◌ Chat ]  │
    └───────────────────────────────┘

Dimensions:

- Height: 52 dp.
- Horizontal padding around switch: 16 dp.
- Preferred maximum width: 420 dp.
- Internal container radius: 26 dp.
- Selected pill height: 44 dp.
- Selected pill horizontal inset: 4 dp.
- Icon: 18–20 dp.
- Text: 14 sp, selected w800, unselected w650 equivalent.

Visual states:

Idle/unselected:
- Transparent or very subtle surfaceContainerHigh fill.
- onSurfaceVariant content.

Selected:
- primary fill.
- onPrimary content.
- Selected icon can use filled equivalent where available.

Pressed:
- 0.97 scale on active segment.
- Short tonal/ripple response.
- Light haptic.

Disabled:
- Not expected in normal flow. If used during a critical transition, keep both labels readable and suppress interaction.

Motion:

- Selection pill morphs/slides between segments.
- Target duration: 320–420 ms.
- Spring-like curve consistent with _ExpressiveNavBar.
- Icon changes use fade + scale from ~0.82 to 1.0.
- Text should not bounce independently.
- Content below switches using a coordinated fade/scale/shared-axis transition.

Reduced motion:
- No spring overshoot.
- 120–180 ms crossfade.
- No lateral content translation.

Implementation note:
The existing TabController may remain the state coordinator, but the visible control should be custom rather than a standard underline TabBar.

## 5.3 AI hero

New component: AiHeroSurface.

Used in:
- Empty Analysis.
- Empty Chat.
- Optionally initial loading skeleton.

Phone dimensions:
- Full available width.
- Min height around 150 dp.
- 20–24 dp internal padding.
- 28–32 dp radius.

Structure:

- Expressive icon container, approximately 48–56 dp.
- Hero title.
- Supporting copy.
- Optional compact contextual status line, never more than one line by default.

Analysis example hierarchy:
- Icon: auto_awesome_rounded or manage_search_rounded.
- Title: existing aiEmptyPromptTitle.
- Subtitle: existing aiEmptyPromptSubtitle.

Chat example hierarchy:
- Icon: auto_awesome_rounded.
- Title: existing aiChatTitle.
- Subtitle: existing aiChatSubtitle.

Material 3 Expressive detail:

- Use one dominant hero shape, not several stacked cards.
- Icon container can use a contrasting rounded or circular shape.
- Hero may use a slightly asymmetric internal layout but must remain stable at large text scales.
- No looping decorative animation.

Entrance:
- Fade + 0.97 → 1.0 scale, 280–360 ms.
- Optional 8–12 dp vertical rise when motion is enabled.

## 5.4 Contextual suggestions

New component: AiSuggestionCard / AiSuggestionChip.

Analysis:
Use compact contextual prompt chips/cards below the hero. Existing context logic remains unchanged.

Preferred layout:
- Horizontal chip carousel when prompts are short.
- Two-column wrap only when labels remain comfortably readable.
- Never truncate the first/most relevant suggestion below recognition.

Chat:
Use up to three larger suggestion cards.

Chat suggestion card:

- Height: 60–72 dp depending on text.
- Radius: 20–24 dp.
- Leading semantic icon in tonal icon container.
- Prompt text.
- Small trailing arrow/send icon.

Interaction:

Pressed:
- Scale to ~0.975.
- Tonal fill strengthens.
- Light haptic.

Released:
- Spring back.
- If tapped, prompt moves into request flow without unnecessary intermediary screen.

Reduced motion:
- Tonal state only.

## 5.5 Unified composer

New component: AiComposer.

The composer is shared by Analysis and Chat.

### Resting structure

    ┌──────────────────────────────────┐
    │ [attachment chips if any]        │
    │ [＋]  Ask something…       [↑]   │
    └──────────────────────────────────┘

Phone:

- Outer horizontal margin: 16 dp.
- Bottom margin: system inset + 12–16 dp.
- Min collapsed height without attachments: 60–64 dp.
- Radius: 28 dp.
- Internal horizontal padding: 8 dp.
- Input vertical padding: 12–14 dp.

Surface:
- ThemedSurface preferred.
- Base tonal role: surfaceContainerHigh or surfaceContainer.
- Focus state may elevate tonally one step and strengthen outline subtly.
- Blur should respect the same app-level surface behavior used by comparable floating surfaces.

Input:
- No nested visible filled TextField box.
- Transparent input decoration inside the composer surface.
- Max lines: implementation may remain current behavior unless changed deliberately; if expanded, cap to a practical height before scrolling.
- Enter/search semantics remain current behavior.

Leading action:
- Chat: attachment control.
- Analysis: omit attachment control if unsupported.
- Icon touch target: minimum 48 dp.

Trailing primary action:
- Touch target: 48–52 dp.
- Visual shape: circle or rounded 18–22 dp square.
- Enabled with input: primary.
- Empty input: disabled tonal state.
- Analysis icon: search_rounded.
- Chat icon: arrow_upward_rounded or send_rounded; prefer one consistent icon across the app.

### Composer states

Empty/unfocused:
- Low emphasis.
- Hint visible.
- Primary action disabled.

Focused:
- Surface expands visually by 1–2 dp through tonal/elevation/scale treatment, not layout jump.
- Outline may transition toward primary at low alpha.
- Cursor and active icon use primary.
- No font-weight-only focus behavior.

Has text:
- Send/Search action becomes enabled.
- Clear input action may remain available but should not compete with send.

Thinking/sending:
- Composer height remains unchanged.
- Input and attachment mutation disabled as required by current behavior.
- Primary action morphs to loader.
- Loader must occupy the same bounding box as the action icon.

With attachments:
- Attachment chips appear above input row.
- Chips animate in without shifting the whole page abruptly.
- Use one or two lines; overflow should horizontally scroll or wrap predictably.
- Remove control has accessible label.
- Existing 3-file limit remains.

Keyboard open:
- Composer moves above keyboard using current inset logic.
- No duplicate safe-area gap.
- Content should remain scrollable behind/above composer without obscuring the newest chat message.

## 5.6 Attachment chip

New/updated component: AiAttachmentChip.

Structure:
- File-type icon.
- Truncated file name.
- Remove icon.

Targets:
- Height: 32–36 dp.
- Radius: 14–16 dp.
- File icon: 16 dp.
- Remove target should still be accessible; use surrounding chip semantics even if visual icon is small.

Colors:
- secondaryContainer / onSecondaryContainer, or a theme-compatible supporting tonal role.

Motion:
- Insert: fade + width/scale reveal, 180–240 ms.
- Remove: reverse.
- Reduced motion: fade only.

## 5.7 Analysis loading state

New component: AiAnalysisLoadingState.

Do not use a centered page spinner.

Structure:
- Query/context card stays visible.
- One primary skeleton/thinking surface.
- Optional 2–3 skeleton result blocks underneath to reserve approximate layout.

Use:
- manage_search_rounded or auto_awesome_rounded.
- Existing localized thinking/search copy.
- Subtle progress animation.

Expressive loading:
- Prefer controlled shape/tonal pulse or existing app progress primitive.
- Avoid aggressive indeterminate motion.
- No continuous card translation.

Transition to result:
- Loading card morphs/fades into summary card when practical.
- Result sections appear progressively.

## 5.8 Analysis result stack

New component: AiAnalysisResult.

Order:

1. Summary card.
2. Tags/supporting chips.
3. Metric section.
4. Lesson section.
5. Low-priority result actions.

### Summary card

- Full width.
- Radius: 26–28 dp.
- Padding: 20–22 dp.
- Icon container: 40–44 dp.
- Headline: 22–24 sp.
- Body: 15–16 sp, line height around 1.45–1.55.
- surfaceContainerHigh or primaryContainer at restrained emphasis.

Avoid a heavy shadow if blur/tonal separation already provides hierarchy.

### Tags

Use assist chips:
- 30–34 dp high.
- Compact horizontal/Wrap layout.
- Max visible tags can remain limited as today.
- Do not give tags equal visual weight to primary actions.

### Metric section

Section header:
- Semantic icon + localized title.

Metric tile:
- 2 columns on normal phones.
- 3 columns on wide/tablet.
- Radius: 20–22 dp.
- Minimum height: 86–96 dp.
- Primary value larger than label.
- Semantic icon.
- Tone varies subtly, not a rainbow palette.

Suggested type:
- Value: 20–24 sp w850/w900.
- Label: 12.5–14 sp w600.

### Lessons

Continue using the shared LessonCard.

Do not build an AI-specific lesson-card clone.

### Result actions

Examples:
- Search again.
- Clear.

Presentation:
- Text/tonal buttons or compact icon buttons.
- Lower visual priority than result content.
- Available near the result, not only hidden in history/sidebar.

## 5.9 Chat message system

New component: AiChatMessage.

### User message

Purpose:
Clearly show authored prompts without consuming excessive width.

- Align right.
- Max width: 82–85% phone, 70–74% tablet.
- Radius: 20–24 dp with one subtly tighter corner if desired.
- Fill: primary or primaryContainer depending on contrast.
- Body: 15 sp, w550/w600.
- Padding: 14–16 dp horizontal, 11–13 dp vertical.

### Assistant message

Do not style long AI answers as oversized speech bubbles.

- Align left.
- Width: up to available reading column.
- Use surfaceContainer / surfaceContainerHigh.
- Radius: 22–26 dp.
- Padding: 16–18 dp.
- Optional compact AI icon/header only when useful; do not repeat an avatar on every short streaming update.
- Markdown remains selectable.

Markdown spacing:
- Paragraphs: comfortable 1.45–1.55 line height.
- Lists: retain clear indentation.
- Strong text uses increased weight, not a different bright color for every instance.
- Code blocks, if supported by current renderer, must maintain readable contrast.

Vertical rhythm:
- 8 dp between same-speaker logical continuation.
- 12–16 dp between normal messages.
- 20 dp between larger conversational turns if visually needed.

### Streaming

When assistant content is empty:
- Show typing/thinking indicator inside the assistant surface position.

When content begins:
- Keep the same surface.
- Replace typing state with streamed Markdown progressively.
- Do not insert a second assistant card.

Streaming haptics remain governed by current implementation; do not increase haptic frequency.

## 5.10 Typing indicator

New/updated component: AiTypingIndicator.

Recommended:
- Three small dots or a compact expressive loader.
- Dot diameter: 5–7 dp.
- Total visual width around 32–40 dp.
- Located inside assistant message surface.

Motion:
- Offset/opacity sequence, low amplitude.
- 700–1100 ms loop.
- No large bouncing movement.
- Reduced motion: static three-dot state or simple opacity change.

## 5.11 Chat history surface

New component: AiChatHistoryPanel.

Phone behavior:
- Keep current navigation semantics.
- Drawer is acceptable.
- If migrated to a modal sheet later, it must use _showUnifiedSheet / centralized sheet styling.

Header:
- AI icon.
- AI title.
- Supporting line.
- Close affordance.

Primary action:
- New Chat.
- Full-width expressive filled/tonal button.
- Height: 48–52 dp.
- Radius: 18–22 dp.

History item:
- Height: 52–60 dp.
- Radius: 16–18 dp.
- Leading chat icon.
- One-line title.
- Delete/overflow action separated from main tap target.

Selected history item:
- primaryContainer.
- Stronger icon/text contrast.
- Shape/tonal transition when selected.

Destructive actions:
- Do not place delete at the same visual emphasis as opening a conversation.
- Prefer overflow/reveal/low-emphasis trailing action if technically practical.

Bottom utility actions:
- AI prompt editor.
- AI settings.
- Clear current result where contextually valid.

Use separators and grouping to distinguish navigation from configuration/destructive controls.

## 5.12 AI action confirmation

Current explicit confirmation behavior is mandatory.

Redesign goal:
Make AI-proposed changes legible and trustworthy.

Preferred surface:
- Existing Untis dialog system, or centralized sheet if the app's interaction pattern moves there.

Content:
- Title: apply changes.
- Short explanatory text.
- Each proposed action shown as a compact structured row/card, not only a bullet string when practical.
- Semantic icon per action type.
- Destructive actions use error semantic treatment.
- Cancel is always clearly available.
- Apply is explicit and never triggered by dismiss gesture.

States:
- Proposed.
- Applying.
- Applied / failed feedback through existing app feedback patterns.

Never visually imply a proposed action has already happened before confirmation.

## 6. Full state matrix

### A. Initial context loading

Visible:
- Shared header.
- Mode switch may be visible but non-disruptive.
- Tonal skeleton/AI loading content.
- Composer may remain unavailable until required context is loaded.

Do not:
- Blank the entire screen.
- Replace app bar with spinner.

### B. Analysis empty

Visible:
- Mode switch: Analysis selected.
- Analysis hero.
- Contextual prompts.
- Composer with search action.

### C. Analysis input focused

Visible:
- Same content.
- Composer focus state.
- Keyboard.
- Suggestions may remain but should not fight for attention.

### D. Analysis thinking

Visible:
- Submitted query.
- Thinking/loading surface.
- Composer disabled/loading as required.
- No content jump.

### E. Analysis success

Visible:
- Summary.
- Tags.
- Metrics where available.
- Lessons where available.
- Search-again/clear actions.
- Composer ready for next query.

### F. Analysis error

Visible:
- Query remains.
- Error surface in result region.
- Retry/search-again action when possible.
- Composer becomes usable again.

Error card:
- errorContainer.
- error icon.
- Human-readable existing localized error copy.
- Do not show raw technical exception unless current behavior intentionally exposes it.

### G. Chat empty

Visible:
- Chat hero.
- Up to 3 suggestion cards.
- Composer.
- History/new chat accessible.

### H. Chat active

Visible:
- Message list.
- Composer.
- Auto-scroll behavior remains current.
- Hero disappears.

### I. Chat streaming

Visible:
- User message.
- Assistant typing/streaming surface.
- Composer loading state.
- No duplicate typing card once streaming text appears.

### J. Chat error

Visible:
- Error copy belongs to the assistant turn that failed.
- Retry should be close to the failed turn where practical.
- Previous conversation remains visible.

### K. Attachment selected

Visible:
- Attachment chips.
- Composer height increases only by attachment row.
- Remove available before send.

### L. History open

Visible:
- New Chat primary action.
- Chat list.
- Selected session.
- Settings/prompt utilities separated.

### M. AI proposed action

Visible:
- Assistant response without raw untis-action block.
- Explicit confirmation UI.
- Apply/cancel choices.

## 7. Motion specification

Motion must communicate hierarchy and state change.

### 7.1 Motion principles

1. Preserve spatial continuity.
2. Animate the component that changed, not the entire screen.
3. Keep one dominant motion event at a time.
4. Prefer shape/scale/tonal transitions over decorative translation.
5. Respect reduced motion.

### 7.2 Motion table

Mode selection:
- 320–420 ms.
- Spring/morph.
- Selected pill position + width.
- Icon scale/fade.

Mode content:
- 220–320 ms.
- Fade + scale 0.985 → 1.0.
- Optional 8 dp shared-axis shift.

Suggestion press:
- 90–140 ms press-in.
- 220–320 ms spring release.
- Scale ~0.975.

Composer focus:
- 180–260 ms.
- Tonal/outline/very small scale change.
- No height jump.

Send/Search action:
- 180–240 ms icon morph.
- Loading state occupies same size.

Attachment insert/remove:
- 180–240 ms.
- Fade + scale/size reveal.

Analysis result entrance:
- Summary begins first.
- Following sections offset by ~40–70 ms.
- Each section 260–360 ms.
- Maximum total cascade should remain short; do not make users wait for content.

Chat message insert:
- 180–260 ms.
- Fade + small 6–8 dp rise or scale.
- Streaming message does not re-run entrance animation on every chunk.

History selection:
- 220–320 ms.
- Tonal container morph.
- No list-wide animation.

### 7.3 Reduced motion

When MediaQuery.disableAnimations is true or the app equivalent disables animations:

- No spring overshoot.
- No wiggle.
- No positional entrance beyond minimal crossfade.
- No stagger that delays information.
- Loading animation becomes static or low-motion.
- Durations should be approximately 0–160 ms where transition feedback is still needed.

## 8. Material 3 Expressive application rules

Use expressive design selectively.

### Strong expression belongs on:

- Analysis/Chat mode switch.
- Empty-state hero.
- Primary composer action.
- New Chat action.
- Key result summary.
- Meaningful state transitions.

### Quiet expression belongs on:

- Long assistant Markdown.
- Metric labels.
- History list.
- Attachments.
- Error copy.
- Confirmation details.

### Avoid:

- Every card having a different color.
- Oversized icons on every section.
- Constant looping motion.
- Multiple simultaneous spring animations.
- Deep shadow stacks.
- Excessive glass/blur layers.
- Nested rounded rectangles with nearly identical styling.
- Hiding core functions behind gestures.

Material 3 Expressive should increase clarity and personality, not reduce information density or predictability.

## 9. Responsive specification

Breakpoints should rely on existing UntisLayout helpers where possible.

### Compact phone

- 16 dp horizontal margin.
- 2-column metrics only if minimum tile width is respected.
- Suggestion cards full width.
- User chat bubble max 85%.
- Mode switch nearly full width.

### Large phone / foldable narrow pane

- Keep single-column reading flow.
- Allow suggestion cards to wrap into 2 columns only if each remains at least ~160 dp wide.

### Tablet

- Center main content.
- Chat max reading width ~760 dp.
- Analysis max width up to existing ~980 dp.
- Metric tiles 3 columns.
- Composer max width should follow the reading column rather than full device width.
- Mode switch centered.

## 10. Accessibility specification

Required:

- Minimum 48 x 48 dp interaction target for icon-only actions.
- Semantic labels for menu, attachment, remove attachment, send/search, history delete and clear.
- Selected Analysis/Chat state exposed semantically.
- Do not rely only on selected-pill color.
- Text scaling to at least common accessibility sizes without clipping critical controls.
- Composer must remain usable with large text.
- Contrast follows active ColorScheme.
- Error state includes icon/text, not only red.
- Reduced motion honored.
- Markdown remains selectable.
- Focus order follows visual order.
- Keyboard users can reach mode switch, message input and actions predictably on supported platforms.

## 11. Component architecture

Recommended presentation structure:

    lib/screens/ai/
      ai_assistant_page.dart
      ai_ui_tokens.dart
      widgets/
        ai_mode_switch.dart
        ai_hero_surface.dart
        ai_composer.dart
        ai_attachment_chip.dart
        ai_suggestion_card.dart
        ai_analysis_loading_state.dart
        ai_analysis_result.dart
        ai_metric_tile.dart
        ai_chat_message.dart
        ai_typing_indicator.dart
        ai_chat_history_panel.dart
        ai_action_confirmation.dart

Do not force extraction of state/business logic merely to achieve this folder shape.

Preferred split:

- AiAssistantPage owns existing behavioral state.
- Presentation widgets receive explicit state + callbacks.
- Parsing/provider/persistence logic remains where it currently belongs until a separate architecture refactor is justified.
- Shared app primitives stay in shared_ui.dart only if they are genuinely reused outside AI.

## 12. Suggested widget APIs

AiModeSwitch:
- selectedMode.
- onChanged.
- enabled.
- reduceMotion.

AiComposer:
- controller.
- focusNode.
- mode.
- thinking.
- attachments.
- onAttach.
- onRemoveAttachment.
- onSend.
- onClear.
- hintText.

AiHeroSurface:
- mode.
- title.
- subtitle.
- optional leading/status.

AiSuggestionCard:
- text.
- icon.
- onTap.
- emphasis.

AiAnalysisResult:
- result.
- thinking.
- onSearchAgain.
- onClear.

AiChatMessage:
- role.
- content.
- streaming.
- selectable.

AiChatHistoryPanel:
- sessions.
- selectedSessionId.
- onNewChat.
- onOpenSession.
- onDeleteSession.
- onOpenPromptSettings.
- onOpenAiSettings.

This keeps visual components testable without duplicating AI business behavior.

## 13. Implementation order

1. Add AI UI tokens/presentation components without changing behavior.
2. Replace standard TabBar with AiModeSwitch.
3. Implement new empty Analysis/Chat states.
4. Replace _buildSearchBar with AiComposer.
5. Replace chat bubble rendering with AiChatMessage.
6. Redesign analysis loading/result surfaces.
7. Restyle history panel.
8. Update action confirmation presentation if needed.
9. Add reduced-motion behavior.
10. Validate phone/tablet/theme/accessibility states.
11. Add widget/golden tests for critical visual states.

## 14. Required test scenarios

At minimum capture/test:

- Analysis empty — light/dark.
- Chat empty — light/dark.
- Composer focused.
- Composer with 1 and 3 attachments.
- Analysis loading.
- Analysis result with summary only.
- Analysis result with metrics + lessons + tags.
- Chat with short user/assistant exchange.
- Chat with long Markdown.
- Chat streaming.
- Chat error.
- Chat history with selected item.
- AI action confirmation with normal and destructive actions.
- Large text scale.
- Reduced motion.
- Tablet width.
- At least one non-default app theme.

## 15. Definition of done

The UI specification is implemented when:

- The AI screen clearly belongs to the same app as Timetable, Exams, Infos and Settings.
- Analysis and Chat use one coherent component system.
- Existing functionality is unchanged.
- Main-tab header remains consistent.
- Expressive hierarchy is concentrated on hero moments and primary actions.
- Long AI content remains calm and readable.
- Composer is stable across focus/loading/attachment states.
- State transitions are understandable without relying on motion.
- Reduced motion is respected.
- No duplicate one-off surface system is introduced.
- Phone and tablet layouts are both deliberate.
