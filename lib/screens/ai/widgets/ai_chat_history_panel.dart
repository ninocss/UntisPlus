part of '../../../main.dart';

class AiChatHistoryPanel extends StatelessWidget {
  final List<_ChatSession> sessions;
  final String? selectedSessionId;
  final bool showResultActions;
  final VoidCallback onNewChat;
  final ValueChanged<_ChatSession> onOpenSession;
  final ValueChanged<_ChatSession> onDeleteSession;
  final VoidCallback onSearchAgain;
  final VoidCallback onClear;
  final VoidCallback onOpenPromptSettings;
  final VoidCallback onOpenAiSettings;

  const AiChatHistoryPanel({
    super.key,
    required this.sessions,
    required this.selectedSessionId,
    required this.showResultActions,
    required this.onNewChat,
    required this.onOpenSession,
    required this.onDeleteSession,
    required this.onSearchAgain,
    required this.onClear,
    required this.onOpenPromptSettings,
    required this.onOpenAiSettings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(appLocaleNotifier.value);

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ThemedSurface(
        blur: true,
        respectSurfaceBlurPreference: false,
        borderRadius: BorderRadius.zero,
        color: cs.surface.withValues(alpha: 0.9),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(_aiRadius(16)),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.aiTitle,
                            style: untisThemeTextStyle(
                              context,
                              display: true,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            l.aiAskAnything,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: untisThemeTextStyle(
                              context,
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.tonalIcon(
                    onPressed: onNewChat,
                    icon: const Icon(Icons.add_comment_rounded),
                    label: Text(
                      l.aiNewChat,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_aiRadius(20)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: cs.outlineVariant.withValues(alpha: 0.42),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      child: Text(
                        l.aiTabChat,
                        style: untisThemeTextStyle(
                          context,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (sessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          l.aiAskAnything,
                          style: untisThemeTextStyle(
                            context,
                            fontSize: 14,
                            height: 1.35,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      for (final session in sessions)
                        _AiHistoryItem(
                          session: session,
                          selected: session.id == selectedSessionId,
                          onTap: () => onOpenSession(session),
                          onDelete: () => onDeleteSession(session),
                        ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.42),
              ),
              if (showResultActions) ...[
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(l.aiSearchAgain),
                  onTap: onSearchAgain,
                ),
                ListTile(
                  leading: Icon(Icons.delete_sweep_outlined, color: cs.error),
                  title: Text(
                    l.aiClearResult,
                    style: TextStyle(color: cs.error),
                  ),
                  onTap: onClear,
                ),
              ],
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: Text(l.settingsAiPrompt),
                onTap: onOpenPromptSettings,
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(l.aiSettingsMenu),
                onTap: onOpenAiSettings,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiHistoryItem extends StatelessWidget {
  final _ChatSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AiHistoryItem({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final duration = _aiMotionDuration(
      context,
      normal: const Duration(milliseconds: 260),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: duration,
        curve: _aiMotionCurve(context),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.82)
              : cs.surfaceContainerHigh.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(_aiRadius(18)),
          border: Border.all(
            color: (selected ? cs.primary : cs.outlineVariant)
                .withValues(alpha: selected ? 0.26 : 0.14),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_aiRadius(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 4, 7),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
