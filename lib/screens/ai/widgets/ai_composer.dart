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
  final VoidCallback? onStop;
  final VoidCallback onClear;

  const _AiComposer({
    required this.controller,
    required this.focusNode,
    required this.mode,
    required this.thinking,
    required this.attachments,
    required this.hintText,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
    this.onStop,
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
    final duration = _aiFastMotionDuration(context);
    final bottomInset = keyboardOpen
        ? mq.viewInsets.bottom + 8
        : (mq.padding.bottom > 0 ? mq.padding.bottom + 6 : 14.0);

    return AnimatedPadding(
      duration: duration,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(14, 4, 14, bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _aiContentMaxWidth(context, _AiMode.chat),
          ),
          child: ThemedSurface(
            blur: true,
            borderRadius: BorderRadius.circular(_aiRadius(28)),
            color: (focused
                    ? cs.surfaceContainerHigh
                    : cs.surfaceContainer)
                .withValues(alpha: focused ? 0.94 : 0.88),
            border: Border.all(
              color: (focused ? cs.primary : cs.outlineVariant)
                  .withValues(alpha: focused ? 0.38 : 0.22),
              width: focused ? 1.2 : 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.attachments.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (final item in widget.attachments.indexed) ...[
                                if (item.$1 > 0) const SizedBox(width: 8),
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
                    ),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.onAttach != null)
                        Semantics(
                          button: true,
                          label: appL10nFor(
                            appLocaleNotifier.value,
                          ).aiAttachFile,
                          child: IconButton.filledTonal(
                            onPressed: widget.thinking ? null : widget.onAttach,
                            style: IconButton.styleFrom(
                              backgroundColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              foregroundColor: cs.onSurfaceVariant,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(42, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _aiRadius(14),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 22),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          enabled: !widget.thinking,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (canSend) widget.onSend();
                          },
                          style: untisThemeTextStyle(
                            context,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: untisThemeTextStyle(
                              context,
                              fontSize: 15.5,
                              color: cs.onSurfaceVariant,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      if (widget.controller.text.isNotEmpty &&
                          !widget.thinking)
                        Semantics(
                          button: true,
                          label: appL10nFor(
                            appLocaleNotifier.value,
                          ).aiClearInput,
                          child: IconButton(
                            onPressed: widget.onClear,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      widget.thinking
                          ? Semantics(
                              button: true,
                              label: appL10nFor(
                                appLocaleNotifier.value,
                              ).cancel,
                              child: IconButton.filled(
                                onPressed: widget.onStop,
                                style: IconButton.styleFrom(
                                  backgroundColor: cs.errorContainer,
                                  foregroundColor: cs.onErrorContainer,
                                  minimumSize: const Size(42, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      _aiRadius(14),
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.stop_rounded,
                                  size: 22,
                                ),
                              ),
                            )
                          : Semantics(
                              button: true,
                              enabled: canSend,
                              label: appL10nFor(
                                appLocaleNotifier.value,
                              ).aiTabChat,
                              child: IconButton.filled(
                                onPressed: canSend ? widget.onSend : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: canSend
                                      ? cs.primary
                                      : cs.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                                  foregroundColor: canSend
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant.withValues(
                                          alpha: 0.45,
                                        ),
                                  minimumSize: const Size(42, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      _aiRadius(14),
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 20,
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
    );
  }
}
