part of '../../../main.dart';

class _AiChatMessage extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool streaming;

  const _AiChatMessage({
    required this.content,
    required this.isUser,
    this.streaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tablet = UntisLayout.isTablet(context);
    final maxWidth = isUser
        ? (tablet ? 560.0 : MediaQuery.sizeOf(context).width * 0.84)
        : (tablet ? 720.0 : MediaQuery.sizeOf(context).width - 32);
    final radius = BorderRadius.only(
      topLeft: Radius.circular(_aiRadius(isUser ? 22 : 24)),
      topRight: Radius.circular(_aiRadius(isUser ? 22 : 24)),
      bottomLeft: Radius.circular(_aiRadius(isUser ? 22 : 8)),
      bottomRight: Radius.circular(_aiRadius(isUser ? 8 : 24)),
    );

    final message = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: isUser ? 15 : 17,
        vertical: isUser ? 12 : 15,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? cs.primaryContainer
            : cs.surfaceContainerHigh.withValues(alpha: 0.76),
        borderRadius: radius,
        border: Border.all(
          color: isUser
              ? cs.primary.withValues(alpha: 0.16)
              : cs.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: !isUser && content.isEmpty
          ? const _AiTypingIndicator()
          : isUser
          ? Text(
              content,
              style: untisThemeTextStyle(
                context,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: cs.onPrimaryContainer,
              ),
            )
          : MarkdownBody(
              data: content,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: untisThemeTextStyle(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      height: 1.5,
                    ),
                    strong: untisThemeTextStyle(
                      context,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    listBullet: untisThemeTextStyle(
                      context,
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ),
    );

    return Semantics(
      liveRegion: streaming && !isUser,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: message,
        ),
      ),
    );
  }
}
