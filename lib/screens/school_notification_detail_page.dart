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
        messageId: attachment.messageId ?? item.id,
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
    final buffer = StringBuffer()
      ..write(item.title.trim())
      ..writeln();
    if ((item.author ?? '').trim().isNotEmpty) {
      buffer.writeln(item.author!.trim());
    }
    if (dateLabel.isNotEmpty) buffer.writeln(dateLabel);
    if (plainBody.isNotEmpty) buffer.write('\n\n$plainBody');
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.infoMessageCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final isExpressive = _usesExpressiveComponents(context);
    final cardRadius = BorderRadius.circular(isExpressive ? 24 : 18);

    return Scaffold(
      backgroundColor: cs.surface,
      extendBodyBehindAppBar: true,
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
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
              16,
              150,
            ),
            children: [
              ThemedSurface(
                borderRadius: cardRadius,
                color: cs.surfaceContainerLow.withValues(alpha: 0.65),
                border: Border.all(
                  color: cs.outlineVariant.withValues(
                    alpha: isExpressive ? 0.20 : 0.30,
                  ),
                  width: tokens.borderWidth,
                ),
                respectSurfaceCornerPreference: false,
                showShadow: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: isExpressive ? 52 : 44,
                            height: isExpressive ? 52 : 44,
                            decoration: BoxDecoration(
                              color: isInbox
                                  ? cs.secondary.withValues(alpha: 0.16)
                                  : cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                isExpressive ? 16 : 12,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isInbox
                                  ? Icons.mail_rounded
                                  : Icons.campaign_rounded,
                              size: isExpressive ? 26 : 22,
                              color: isInbox ? cs.secondary : cs.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    color: cs.onSurface,
                                  ),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (item.displayBody.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: cs.outlineVariant.withValues(
                            alpha: isExpressive ? 0.18 : 0.25,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SelectionArea(
                          child: _InfoHtmlBody(
                            document: sanitizeSchoolHtml(item.displayBody),
                            onOpenUrl: (url) => _openDetailUrl(context, url),
                          ),
                        ),
                      ],
                      if (item.attachments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: cs.outlineVariant.withValues(
                            alpha: isExpressive ? 0.18 : 0.25,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionHeader(
                          context,
                          l.infoAttachments,
                          Icons.attach_file_rounded,
                          count: item.attachments.length,
                        ),
                        const SizedBox(height: 12),
                        for (final attachment in item.attachments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ThemedSurface(
                              borderRadius: BorderRadius.circular(
                                isExpressive ? 16 : 12,
                              ),
                              color: cs.surfaceContainerHigh.withValues(
                                alpha: 0.50,
                              ),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: isExpressive ? 0.20 : 0.30,
                                ),
                                width: tokens.borderWidth,
                              ),
                              respectSurfaceCornerPreference: false,
                              showShadow: false,
                              child: Material(
                                type: MaterialType.transparency,
                                borderRadius: BorderRadius.circular(
                                  isExpressive ? 16 : 12,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    isExpressive ? 16 : 12,
                                  ),
                                  onTap: () =>
                                      _downloadAttachment(context, attachment),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            _attachmentIcon(
                                              attachment.fileExtension,
                                            ),
                                            size: 20,
                                            color: cs.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                attachment.name.isEmpty
                                                    ? 'Attachment'
                                                    : attachment.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: cs.onSurface,
                                                ),
                                              ),
                                              if (attachment
                                                  .fileExtension.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  attachment.fileExtension,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11.5,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: cs.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.download_rounded,
                                            size: 18,
                                            color: cs.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                      if (item.url != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () => _openDetailUrl(context, item.url),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(
                            l.infoOpenLink,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
    final isExpressive = _usesExpressiveComponents(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(isExpressive ? 12 : 8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
