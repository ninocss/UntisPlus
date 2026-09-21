part of '../../../main.dart';

class _AiComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final _AiMode mode;
  final bool thinking;
  final List<AiChatAttachment> attachments;
  final String hintText;
  final VoidCallback? onAttach;
  final ValueChanged<int> onRemoveAttachment;
  final VoidCallback onSend;
  final VoidCallback onClear;

  const _AiComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.mode,
    required this.thinking,
    required this.attachments,
    required this.hintText,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
    required this.onClear,
  });

  @override
  State<_AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<_AiComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
  }

  @override
  void didUpdateWidget(_AiComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final focused = widget.focusNode.hasFocus;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final canSend = hasText && !widget.thinking;
    final duration = _aiMotionDuration(
      context,
      normal: const Duration(milliseconds: 230),
    );
    final bottom = keyboardOpen
        ? mq.viewInsets.bottom + 12
        : mq.padding.bottom + 14;

    return AnimatedPadding(
      duration: duration,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.mode == _AiMode.chat ? 760 : 900,
          ),
          child: AnimatedScale(
            duration: duration,
            scale: focused && !_aiReduceMotion(context) ? 1.005 : 1,
            child: ThemedSurface(
              borderRadius: BorderRadius.circular(_aiRadius(29)),
              color: (focused
                      ? cs.surfaceContainerHigh
                      : cs.surfaceContainer)
                  .withValues(alpha: focused ? 0.9 : 0.82),
              border: Border.all(
                color: (focused ? cs.primary : cs.outlineVariant)
                    .withValues(alpha: focused ? 0.28 : 0.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.attachments.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final item in widget.attachments.indexed) ...[
                                if (item.$1 > 0) const SizedBox(width: 6),
                                _AiAttachmentChip(
                                  key: ValueKey(
                                    '${item.$2.name}-${item.$1}',
                                  ),
                                  attachment: item.$2,
                                  onRemove: widget.thinking
                                      ? null
                                      : () => widget.onRemoveAttachment(item.$1),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.mode == _AiMode.chat)
                          Semantics(
                            button: true,
                            label: AppL10n.of(
                              appLocaleNotifier.value,
                            ).ui('aiAttachFile'),
                            child: IconButton(
                              onPressed: widget.thinking ? null : widget.onAttach,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            enabled: !widget.thinking,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) {
                              if (canSend) widget.onSend();
                            },
                            style: untisThemeTextStyle(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              hintStyle: untisThemeTextStyle(
                                context,
                                fontSize: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (widget.controller.text.isNotEmpty &&
                            !widget.thinking)
                          Semantics(
                            button: true,
                            label: AppL10n.of(
                              appLocaleNotifier.value,
                            ).aiClearInput,
                            child: IconButton(
                              onPressed: widget.onClear,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 48,
                              ),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Semantics(
                          button: true,
                          enabled: canSend,
                          label: widget.mode == _AiMode.chat
                              ? AppL10n.of(appLocaleNotifier.value).aiTabChat
                              : AppL10n.of(
                                  appLocaleNotifier.value,
                                ).aiTabAnalysis,
                          child: AnimatedContainer(
                            duration: duration,
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: canSend || widget.thinking
                                  ? cs.primary
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                _aiRadius(19),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  _aiRadius(19),
                                ),
                                onTap: canSend ? widget.onSend : null,
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: duration,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                        ),
                                    child: widget.thinking
                                        ? SizedBox(
                                            key: const ValueKey('thinking'),
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: cs.onPrimary,
                                            ),
                                          )
                                        : Icon(
                                            widget.mode == _AiMode.chat
                                                ? Icons.arrow_upward_rounded
                                                : Icons.search_rounded,
                                            key: ValueKey(widget.mode),
                                            color: canSend
                                                ? cs.onPrimary
                                                : cs.onSurfaceVariant,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
