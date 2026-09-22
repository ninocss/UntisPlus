part of '../main.dart';

String _notificationDateLabel(DateTime? date) {
  if (date == null) return '';
  return DateFormat(
    'dd.MM.yyyy, HH:mm',
    _icuLocale(appLocaleNotifier.value),
  ).format(date);
}

IconData _attachmentIcon(String ext) {
  switch (ext) {
    case 'PDF':
      return Icons.picture_as_pdf_rounded;
    case 'PNG':
    case 'JPG':
    case 'JPEG':
    case 'GIF':
    case 'BMP':
    case 'WEBP':
      return Icons.image_rounded;
    case 'DOC':
    case 'DOCX':
      return Icons.description_rounded;
    case 'XLS':
    case 'XLSX':
    case 'CSV':
      return Icons.table_chart_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

class _SchoolNotificationDetailPage extends StatelessWidget {
  const _SchoolNotificationDetailPage({
    required this.item,
    required this.isInbox,
  });

  final _SchoolNotificationItem item;
  final bool isInbox;

  /// The full detail surface is intentionally reusable inside the tablet
  /// master-detail pane. On phones the ordinary route still owns the Scaffold.
  Widget buildEmbedded(BuildContext context) => build(context);

  String _copyLabel() {
    return appL10nFor(appLocaleNotifier.value).copyMessage;
  }

  Future<void> _openDetailUrl(BuildContext context, String? url) async {
    if (!isSafeSchoolExternalUrl(url)) return;
    final ok = await url_launcher.launchUrlString(
      url!,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      context.showUntisSnackBar(
        appL10nFor(appLocaleNotifier.value).settingsGithubOpenFailed,
      );
    }
  }

  Future<void> _downloadAttachment(
    BuildContext context,
    _MessageAttachment attachment,
  ) async {
    final l = appL10nFor(appLocaleNotifier.value);
    if (attachment.isDemo) {
      context.showUntisSnackBar(l.attachmentDemoUnavailable);
      return;
    }

    final name = attachment.name.isEmpty
        ? 'untisplus-attachment'
        : attachment.name;
    try {
      final bytes = await SchoolInfoRepository().downloadAttachment(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionID,
        attachmentId: attachment.id,
        reauthenticate: () async => await _reAuthenticate() ? sessionID : null,
      );
      final result = await FilePicker.saveFile(
        dialogTitle: l.attachmentSave,
        fileName: name,
        bytes: bytes,
      );
      if (result != null && context.mounted) {
        context.showUntisSnackBar(l.attachmentSaved);
      }
    } catch (_) {
      if (context.mounted) {
        context.showUntisSnackBar(l.attachmentDownloadFailed);
      }
    }
  }

  Future<void> _copyMessage(BuildContext context) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final plainBody = schoolHtmlToPlainText(
      sanitizeSchoolHtml(item.displayBody),
    );
    final dateLabel = _notificationDateLabel(item.date);
    final buffer = StringBuffer(item.title.trim());
    if ((item.author ?? '').trim().isNotEmpty) {
      buffer.writeln(item.author!.trim());
    }
    if (dateLabel.isNotEmpty) buffer.writeln(dateLabel);
    if (plainBody.isNotEmpty) buffer.write('\n\n$plainBody');
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.infoMessageCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: RoundedBlurAppBar(
        title: Text(
          item.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (isInbox)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: _copyLabel(),
                onPressed: () => _copyMessage(context),
                icon: const Icon(Icons.content_copy_rounded),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _AnimatedBackground(child: const SizedBox.expand()),
          ),
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
            children: [
              _glassContainer(
                context: context,
                borderRadius: BorderRadius.circular(24),
                color: cs.surfaceContainerLow.withValues(alpha: 0.62),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isInbox
                                ? Icons.mail_outline_rounded
                                : Icons.campaign_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (item.date != null)
                            _detailInfoChip(
                              context,
                              _notificationDateLabel(item.date),
                              Icons.schedule_rounded,
                            ),
                          if ((item.author ?? '').isNotEmpty)
                            _detailInfoChip(
                              context,
                              item.author!,
                              Icons.person_outline_rounded,
                            ),
                        ],
                      ),
                      if (item.displayBody.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        SelectionArea(
                          child: _InfoHtmlBody(
                            document: sanitizeSchoolHtml(item.displayBody),
                            onOpenUrl: (url) => _openDetailUrl(context, url),
                          ),
                        ),
                      ],
                      if (item.attachments.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text(
                          l.infoAttachments,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final attachment in item.attachments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _glassContainer(
                              context: context,
                              borderRadius: BorderRadius.circular(14),
                              color: cs.surfaceContainerHigh.withValues(
                                alpha: 0.45,
                              ),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () =>
                                    _downloadAttachment(context, attachment),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _attachmentIcon(
                                          attachment.fileExtension,
                                        ),
                                        size: 20,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          attachment.name.isEmpty
                                              ? 'Attachment'
                                              : attachment.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.download_rounded,
                                        size: 20,
                                        color: cs.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                      if (item.url != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _openDetailUrl(context, item.url),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(l.infoOpenLink),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailInfoChip(BuildContext context, String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(999),
      color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
