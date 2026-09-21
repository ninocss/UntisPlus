part of '../../../main.dart';

class AiAttachmentChip extends StatelessWidget {
  final AiChatAttachment attachment;
  final VoidCallback? onRemove;

  const AiAttachmentChip({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  IconData _iconForMime() {
    final mime = attachment.mimeType.toLowerCase();
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mime.contains('json') || mime.contains('csv')) {
      return Icons.data_object_rounded;
    }
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: attachment.name,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220, minHeight: 34),
        padding: const EdgeInsets.only(left: 10, right: 4),
        decoration: BoxDecoration(
          color: cs.secondaryContainer.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(_aiRadius(15)),
          border: Border.all(
            color: cs.secondary.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForMime(),
              size: 16,
              color: cs.onSecondaryContainer,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),
            if (onRemove != null)
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).deleteButtonTooltip,
                child: IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
