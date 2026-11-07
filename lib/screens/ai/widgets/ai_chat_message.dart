part of '../../../main.dart';

class _AiChatMessage extends StatefulWidget {
  final String content;
  final bool isUser;
  final bool streaming;
  final List<AiLessonCardData>? lessons;
  final VoidCallback? onRegenerate;
  final VoidCallback? onBackToTimetable;

  const _AiChatMessage({
    super.key,
    required this.content,
    required this.isUser,
    this.streaming = false,
    this.lessons,
    this.onRegenerate,
    this.onBackToTimetable,
  });

  @override
  State<_AiChatMessage> createState() => _AiChatMessageState();
}

class _AiChatMessageState extends State<_AiChatMessage> {
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyContent() {
    if (widget.content.isEmpty) return;
    unawaited(Clipboard.setData(ClipboardData(text: widget.content)));
    unawaited(AppHaptics.confirmation());
    setState(() => _copied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final isUser = widget.isUser;
    final streaming = widget.streaming;
    final tablet = UntisLayout.isTablet(context);
    final maxWidth = isUser
        ? (tablet ? 540.0 : MediaQuery.sizeOf(context).width * 0.82)
        : (tablet ? 740.0 : MediaQuery.sizeOf(context).width - 32);

    final bubbleRadius = isUser ? _aiUserBubbleRadius() : _aiAssistantBubbleRadius();

    if (isUser) {
      return Semantics(
        label: widget.content,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: bubbleRadius,
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Text(
                widget.content,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isThinking = !isUser && widget.content.isEmpty && streaming;

    return Semantics(
      liveRegion: streaming,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.82),
              borderRadius: bubbleRadius,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.22),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(_aiRadius(6)),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Untis+ AI',
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                    if (streaming) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                if (isThinking) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _AiTypingIndicator(),
                      const SizedBox(width: 10),
                      Text(
                        l.aiTyping,
                        style: untisThemeTextStyle(
                          context,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  MarkdownBody(
                    data: widget.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: untisThemeTextStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurface,
                            height: 1.48,
                          ),
                          strong: untisThemeTextStyle(
                            context,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                          code: untisThemeTextStyle(
                            context,
                            fontSize: 13.5,
                            color: cs.onSurfaceVariant,
                          ).copyWith(
                            backgroundColor: cs.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(
                              _aiRadius(12),
                            ),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.25),
                            ),
                          ),
                          listBullet: untisThemeTextStyle(
                            context,
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ],
                if (widget.lessons != null && widget.lessons!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.lessons!
                        .map(
                          (lesson) => _AiSmartLessonChip(
                            lesson: lesson,
                            onTap: widget.onBackToTimetable,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (!streaming && widget.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(30, 30),
                        ),
                        onPressed: _copyContent,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            _copied
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            key: ValueKey(_copied),
                            size: 15,
                            color: _copied ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (widget.onRegenerate != null)
                        IconButton(
                          tooltip: l.aiSearchAgain,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(30, 30),
                          ),
                          onPressed: widget.onRegenerate,
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiSmartLessonChip extends StatelessWidget {
  final AiLessonCardData lesson;
  final VoidCallback? onTap;

  const _AiSmartLessonChip({required this.lesson, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final isCancelled = lesson.isCancelled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_aiRadius(12)),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isCancelled
                ? cs.errorContainer.withValues(alpha: 0.35)
                : cs.surfaceContainerHighest.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(_aiRadius(12)),
            border: Border.all(
              color: isCancelled
                  ? cs.error.withValues(alpha: 0.4)
                  : cs.outlineVariant.withValues(alpha: 0.28),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCancelled ? cs.error : cs.primary,
                  borderRadius: BorderRadius.circular(_aiRadius(6)),
                ),
                child: Text(
                  lesson.subjectShort.isNotEmpty
                      ? lesson.subjectShort
                      : lesson.subject,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCancelled ? cs.onError : cs.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lesson.time,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              if (lesson.room.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '(${lesson.room})',
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (isCancelled) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l.detailCancelled,
                    style: untisThemeTextStyle(
                      context,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: cs.onError,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
