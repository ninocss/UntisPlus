part of '../main.dart';

class _MessageComposePage extends StatefulWidget {
  const _MessageComposePage();

  @override
  State<_MessageComposePage> createState() => _MessageComposePageState();
}

class _MessageComposePageState extends State<_MessageComposePage>
    with WidgetsBindingObserver {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final WebUntisMessageService _service = WebUntisMessageService();

  List<WebUntisMessageRecipient> _recipients = const [];
  final Map<int, WebUntisMessageRecipient> _selectedRecipients = {};
  final List<WebUntisOutgoingAttachment> _attachments = [];
  WebUntisMessagePermissions _permissions = const WebUntisMessagePermissions();
  bool _loading = true;
  bool _sending = false;
  bool _messageCompleted = false;
  String? _error;
  Timer? _draftTimer;

  String get _draftKey => _accountDataKey('messageComposeDraftV1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subjectController.addListener(_queueDraftSave);
    _bodyController.addListener(_queueDraftSave);
    _load();
  }

  Future<void> _load({bool retryAuth = true}) async {
    await _restoreDraft();
    if (demoModeNotifier.value) {
      if (!mounted) return;
      setState(() {
        _recipients = const [
          WebUntisMessageRecipient(
            id: 1,
            type: 'TEACHER',
            name: 'Frau Beispiel',
            role: 'Demo',
          ),
        ];
        _loading = false;
      });
      return;
    }

    try {
      final data = await _service.loadComposeData(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        sessionId: sessionID,
      );
      if (!mounted) return;
      setState(() {
        _recipients = data.recipients;
        _permissions = data.permissions;
        _loading = false;
        _error = null;
      });
    } on WebUntisMessageFailure catch (error) {
      if (retryAuth &&
          (error.statusCode == 401 || error.statusCode == 403) &&
          await _reAuthenticate()) {
        return _load(retryAuth: false);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppL10n.of(appLocaleNotifier.value).messageRecipientsFailed;
      });
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _subjectController.text = decoded['subject']?.toString() ?? '';
      _bodyController.text = decoded['body']?.toString() ?? '';
      final rawRecipients = decoded['recipients'];
      if (rawRecipients is List) {
        for (final item in rawRecipients.whereType<Map>()) {
          final recipient = WebUntisMessageRecipient.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (recipient.id > 0 && recipient.name.isNotEmpty) {
            _selectedRecipients[recipient.id] = recipient;
          }
        }
      }
    } catch (_) {}
  }

  void _queueDraftSave() {
    if (_messageCompleted) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_saveDraftSnapshot()),
    );
  }

  Future<void> _saveDraftSnapshot() async {
    final subject = _subjectController.text;
    final body = _bodyController.text;
    final recipients = _selectedRecipients.values
        .map((recipient) => recipient.toJson())
        .toList(growable: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (subject.trim().isEmpty && body.trim().isEmpty && recipients.isEmpty) {
        await prefs.remove(_draftKey);
        return;
      }
      await prefs.setString(
        _draftKey,
        jsonEncode({
          'subject': subject,
          'body': body,
          'recipients': recipients,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(_saveDraftSnapshot());
    }
  }

  Future<void> _chooseRecipients() async {
    if (_loading) return;
    final l = AppL10n.of(appLocaleNotifier.value);
    if (_recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.messageNoRecipients)),
      );
      return;
    }

    final queryController = TextEditingController();
    final selected = _selectedRecipients.keys.toSet();
    final result = await showUntisAdaptiveSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final query = queryController.text.trim().toLowerCase();
          final filtered = _recipients.where((recipient) {
            if (query.isEmpty) return true;
            return recipient.name.toLowerCase().contains(query) ||
                (recipient.role ?? '').toLowerCase().contains(query);
          }).toList(growable: false);
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: TextField(
                      controller: queryController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l.messageRecipients,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final recipient = filtered[index];
                        return CheckboxListTile(
                          value: selected.contains(recipient.id),
                          title: Text(recipient.name),
                          subtitle: (recipient.role ?? '').isEmpty
                              ? null
                              : Text(recipient.role!),
                          secondary: CircleAvatar(
                            child: Text(
                              recipient.name
                                  .split(RegExp(r'\s+'))
                                  .where((part) => part.isNotEmpty)
                                  .take(2)
                                  .map((part) => part[0].toUpperCase())
                                  .join(),
                            ),
                          ),
                          onChanged: (value) => setSheetState(() {
                            if (value == true) {
                              selected.add(recipient.id);
                            } else {
                              selected.remove(recipient.id);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, selected),
                      child: Text(l.messageRecipientsApply),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    queryController.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _selectedRecipients
        ..clear()
        ..addEntries(
          _recipients
              .where((recipient) => result.contains(recipient.id))
              .map((recipient) => MapEntry(recipient.id, recipient)),
        );
    });
    _queueDraftSave();
  }

  Future<void> _pickAttachments() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final remaining = _permissions.maxFileCount - _attachments.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.messageAttachmentLimit.replaceAll(
              '{count}',
              '${_permissions.maxFileCount}',
            ),
          ),
        ),
      );
      return;
    }

    final picked = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || !mounted) return;

    final added = <WebUntisOutgoingAttachment>[];
    for (final file in picked.files.take(remaining)) {
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
        } catch (_) {}
      }
      if (bytes == null) continue;
      if (bytes.length > _permissions.maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l.messageAttachmentTooLarge.replaceAll('{name}', file.name),
              ),
            ),
          );
        }
        continue;
      }
      added.add(
        WebUntisOutgoingAttachment(name: file.name, bytes: bytes),
      );
    }
    if (added.isNotEmpty && mounted) {
      setState(() => _attachments.addAll(added));
    }
  }

  Future<void> _send() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    if (_selectedRecipients.isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.messageRequiredFields)),
      );
      return;
    }
    if (demoModeNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.messageDemoUnavailable)),
      );
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _sendOnce();
      await _clearDraft();
      _messageCompleted = true;
      if (!mounted) return;
      Navigator.pop(context, true);
    } on WebUntisMessageFailure catch (error) {
      if ((error.statusCode == 401 || error.statusCode == 403) &&
          await _reAuthenticate()) {
        try {
          await _sendOnce();
          await _clearDraft();
          _messageCompleted = true;
          if (!mounted) return;
          Navigator.pop(context, true);
          return;
        } catch (retryError) {
          if (!mounted) return;
          setState(() => _error = retryError.toString());
        }
      } else if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = l.messageSendFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendOnce() => _service.sendMessage(
    schoolUrl: schoolUrl,
    schoolName: schoolName,
    sessionId: sessionID,
    subject: _subjectController.text,
    content: _bodyController.text,
    recipients: _selectedRecipients.values.toList(growable: false),
    attachments: List.unmodifiable(_attachments),
  );

  Future<void> _discardDraft() async {
    await _clearDraft();
    if (!mounted) return;
    setState(() {
      _subjectController.clear();
      _bodyController.clear();
      _selectedRecipients.clear();
      _attachments.clear();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    if (!_messageCompleted) {
      unawaited(_saveDraftSnapshot());
    }
    _subjectController.dispose();
    _bodyController.dispose();
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.messageComposeTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: l.messageDiscardDraft,
            onPressed: _sending ? null : _discardDraft,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.paddingOf(context).bottom + 120,
          ),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _error!,
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),
                ),
              ),
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.group_rounded,
                  title: l.messageRecipients,
                  subtitle: _loading
                      ? l.messageRecipientsLoading
                      : _selectedRecipients.isEmpty
                      ? l.messageRecipientSelect
                      : _selectedRecipients.values
                            .map((recipient) => recipient.name)
                            .join(', '),
                  trailing: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _loading ? null : _chooseRecipients,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              enabled: !_sending,
              textInputAction: TextInputAction.next,
              maxLength: 255,
              decoration: InputDecoration(
                labelText: l.messageSubject,
                prefixIcon: const Icon(Icons.subject_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              enabled: !_sending,
              minLines: 8,
              maxLines: 18,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: l.messageBody,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Icon(Icons.edit_note_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _sending ? null : _pickAttachments,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(l.messageAttach),
                ),
                const Spacer(),
                Text(
                  l.messageDraftAutosave,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_attachments.length, (index) {
                  final attachment = _attachments[index];
                  return InputChip(
                    avatar: const Icon(Icons.insert_drive_file_rounded, size: 18),
                    label: Text(attachment.name),
                    onDeleted: _sending
                        ? null
                        : () => setState(() => _attachments.removeAt(index)),
                  );
                }),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? l.messageSending : l.messageSend),
            ),
          ],
        ),
      ),
    );
  }
}
