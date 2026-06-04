// settings_backup_page.dart
part of '../../main.dart';

class SettingsBackupPage extends StatefulWidget {
  const SettingsBackupPage({super.key});

  @override
  State<SettingsBackupPage> createState() => _SettingsBackupPageState();
}

class _SettingsBackupPageState extends State<SettingsBackupPage> {
  final BackupService _backupService = BackupService();
  bool _includeApiKeys = false;
  bool _busy = false;

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _setBusyWhile(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _defaultFileName() {
    final stamp = DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    return 'untisplus-settings-$stamp.json';
  }

  bool _isValidJson(String text) {
    try {
      jsonDecode(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _getValidatedExportContent() async {
    final content = await _backupService.exportAllToJsonText(
      includeApiKeys: _includeApiKeys,
    );
    if (content.trim().isEmpty) {
      throw Exception('Exported content is empty');
    }
    if (!_isValidJson(content)) {
      throw Exception('Generated JSON is invalid');
    }
    return content;
  }

  Future<void> _exportToFile() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    try {
      await _setBusyWhile(() async {
        final content = await _getValidatedExportContent();
        final bytes = utf8.encode(content);

        final result = await FilePicker.saveFile(
          dialogTitle: l.settingsBackupExportDialogTitle,
          fileName: _defaultFileName(),
          bytes: bytes,
        );
        if (result == null || result.isEmpty) return;
        _showSnack(l.settingsBackupExportSuccess);
      });
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('JSON is invalid') || errorMsg.contains('empty')) {
        _showSnack("l.settingsBackupInvalidJson", isError: true);
      } else {
        _showSnack('${"l.settingsBackupExportFailed"} (${e.toString()})', isError: true);
      }
    }
  }

  Future<void> _exportToClipboard() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    await _setBusyWhile(() async {
      final content = await _getValidatedExportContent();
      await Clipboard.setData(ClipboardData(text: content));
      _showSnack(l.settingsBackupExportClipboardSuccess);
    });
  }

  Future<void> _importFromFile() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    try {
      await _setBusyWhile(() async {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['json'],
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.single;

        String? content;
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else if (file.path != null && file.path!.isNotEmpty) {
          content = await File(file.path!).readAsString();
        }
        if (content == null || content.trim().isEmpty) {
          throw const FormatException('Empty file');
        }
        if (!_isValidJson(content)) {
          throw const FormatException('Invalid JSON format');
        }

        final confirmed = await _confirmImport();
        if (!confirmed) return;
        await _backupService.importAllFromJsonText(content);
        await _settingsSyncFromPrefs();
        _showSnack(l.settingsBackupImportSuccess);
      });
    } catch (e) {
      _showSnack('${l.settingsBackupImportFailed} (${e.toString()})', isError: true);
    }
  }

  Future<void> _importFromClipboard() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    try {
      await _setBusyWhile(() async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text?.trim() ?? '';
        if (text.isEmpty) {
          _showSnack(l.settingsBackupClipboardEmpty, isError: true);
          return;
        }
        if (!_isValidJson(text)) {
          _showSnack("l.settingsBackupInvalidJson", isError: true);
          return;
        }
        final confirmed = await _confirmImport();
        if (!confirmed) return;
        await _backupService.importAllFromJsonText(text);
        await _settingsSyncFromPrefs();
        _showSnack(l.settingsBackupImportSuccess);
      });
    } catch (e) {
      _showSnack('${l.settingsBackupImportFailed} (${e.toString()})', isError: true);
    }
  }

  Future<bool> _confirmImport() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l.settingsBackupConfirmTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        content: Text(l.settingsBackupConfirmDesc, style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.settingsApiKeyCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.settingsBackupConfirmAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsHubDataBackup,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, mq.padding.bottom + 120),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _includeApiKeys,
                      onChanged: (value) =>
                          setState(() => _includeApiKeys = value),
                      title: Text(
                        l.settingsBackupIncludeApiKeys,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        l.settingsBackupIncludeApiKeysDesc,
                        style: GoogleFonts.outfit(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _busy ? null : _exportToFile,
                      icon: const Icon(Icons.save_alt_rounded, size: 20),
                      label: Text(
                        l.settingsBackupExportAllFile,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _exportToClipboard,
                      icon: const Icon(Icons.content_paste_rounded),
                      label: Text(
                        l.settingsBackupExportAllClipboard,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cs.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsBackupImportAllTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _busy ? null : _importFromFile,
                      icon: const Icon(Icons.file_upload_rounded, size: 20),
                      label: Text(
                        l.settingsBackupImportAllFile,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: cs.tertiaryContainer,
                        foregroundColor: cs.onTertiaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _importFromClipboard,
                      icon: const Icon(Icons.assignment_return_rounded),
                      label: Text(
                        l.settingsBackupImportAllClipboard,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}