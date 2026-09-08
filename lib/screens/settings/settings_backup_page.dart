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

  Future<String?> _getValidatedExportContent() async {
    final passphrase = _includeApiKeys
        ? await _requestPassphrase(confirm: true)
        : null;
    if (_includeApiKeys && passphrase == null) return null;
    final content = await _backupService.exportAllToJsonText(
      includeApiKeys: _includeApiKeys,
      passphrase: passphrase,
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
        if (content == null) return;
        final bytes = utf8.encode(content);

        final result = await FilePicker.saveFile(
          dialogTitle: l.settingsBackupExportDialogTitle,
          fileName: _defaultFileName(),
          bytes: bytes,
        );
        if (result == null) return;
        _showSnack(l.settingsBackupExportSuccess);
      });
    } catch (e) {
      _showSnack(
        '${l.settingsBackupImportFailed} (${e.toString()})',
        isError: true,
      );
    }
  }

  Future<void> _exportToClipboard() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    await _setBusyWhile(() async {
      final content = await _getValidatedExportContent();
      if (content == null) return;
      await Clipboard.setData(ClipboardData(text: content));
      _showSnack(l.settingsBackupExportClipboardSuccess);
    });
  }

  Future<void> _importFromFile() async {
    final l = AppL10n.of(appLocaleNotifier.value);
    try {
      await _setBusyWhile(() async {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
        if (file == null) return;

        final content = utf8.decode(await file.readAsBytes());
        if (content.trim().isEmpty) {
          throw const FormatException('Empty file');
        }
        if (!_isValidJson(content)) {
          throw const FormatException('Invalid JSON format');
        }

        final confirmed = await _confirmImport();
        if (!confirmed) return;
        final passphrase = _backupService.requiresPassphrase(content)
            ? await _requestPassphrase()
            : null;
        if (_backupService.requiresPassphrase(content) && passphrase == null) {
          return;
        }
        await _backupService.importAllFromJsonText(
          content,
          passphrase: passphrase,
        );
        await _settingsSyncFromPrefs();
        _showSnack(l.settingsBackupImportSuccess);
      });
    } catch (e) {
      _showSnack(
        '${l.settingsBackupImportFailed} (${e.toString()})',
        isError: true,
      );
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
          _showSnack(l.settingsBackupImportFailed, isError: true);
          return;
        }
        final confirmed = await _confirmImport();
        if (!confirmed) return;
        final passphrase = _backupService.requiresPassphrase(text)
            ? await _requestPassphrase()
            : null;
        if (_backupService.requiresPassphrase(text) && passphrase == null) {
          return;
        }
        await _backupService.importAllFromJsonText(
          text,
          passphrase: passphrase,
        );
        await _settingsSyncFromPrefs();
        _showSnack(l.settingsBackupImportSuccess);
      });
    } catch (e) {
      _showSnack(
        '${l.settingsBackupImportFailed} (${e.toString()})',
        isError: true,
      );
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

  Future<String?> _requestPassphrase({bool confirm = false}) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? validationError;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            confirm
                ? _studentCopy(
                    de: 'Backup verschlüsseln',
                    en: 'Encrypt backup',
                    fr: 'Chiffrer la sauvegarde',
                    es: 'Cifrar copia de seguridad',
                  )
                : _studentCopy(
                    de: 'Backup entschlüsseln',
                    en: 'Decrypt backup',
                    fr: 'Déchiffrer la sauvegarde',
                    es: 'Descifrar copia de seguridad',
                  ),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                confirm
                    ? _studentCopy(
                        de: 'API-Schlüssel werden ausschließlich AES-256-GCM-verschlüsselt exportiert. Das Passwort kann nicht wiederhergestellt werden.',
                        en: 'API keys are exported only with AES-256-GCM encryption. The password cannot be recovered.',
                        fr: 'Les clés API sont exportées uniquement avec un chiffrement AES-256-GCM. Le mot de passe ne peut pas être récupéré.',
                        es: 'Las claves API solo se exportan cifradas con AES-256-GCM. La contraseña no se puede recuperar.',
                      )
                    : _studentCopy(
                        de: 'Dieses Backup enthält verschlüsselte API-Schlüssel.',
                        en: 'This backup contains encrypted API keys.',
                        fr: 'Cette sauvegarde contient des clés API chiffrées.',
                        es: 'Esta copia contiene claves API cifradas.',
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _studentCopy(
                    de: 'Backup-Passwort',
                    en: 'Backup password',
                    fr: 'Mot de passe de sauvegarde',
                    es: 'Contraseña de la copia',
                  ),
                  errorText: validationError,
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _studentCopy(
                      de: 'Passwort wiederholen',
                      en: 'Repeat password',
                      fr: 'Répéter le mot de passe',
                      es: 'Repetir contraseña',
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppL10n.of(appLocaleNotifier.value).settingsApiKeyCancel,
              ),
            ),
            FilledButton(
              onPressed: () {
                final value = password.text;
                final invalid =
                    value.length < 8 || (confirm && value != confirmation.text);
                if (invalid) {
                  setDialogState(() {
                    validationError = value.length < 8
                        ? _studentCopy(
                            de: 'Mindestens 8 Zeichen erforderlich',
                            en: 'At least 8 characters required',
                            fr: 'Au moins 8 caractères requis',
                            es: 'Se requieren al menos 8 caracteres',
                          )
                        : _studentCopy(
                            de: 'Die Passwörter stimmen nicht überein',
                            en: 'The passwords do not match',
                            fr: 'Les mots de passe ne correspondent pas',
                            es: 'Las contraseñas no coinciden',
                          );
                  });
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: Text(
                confirm
                    ? _studentCopy(
                        de: 'Verschlüsseln',
                        en: 'Encrypt',
                        fr: 'Chiffrer',
                        es: 'Cifrar',
                      )
                    : _studentCopy(
                        de: 'Entschlüsseln',
                        en: 'Decrypt',
                        fr: 'Déchiffrer',
                        es: 'Descifrar',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    confirmation.dispose();
    return result;
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
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            // ── GROUP 1: EXPORT ──
            SettingsGroup(
              title: l.settingsHubDataBackup,
              children: [
                SettingsSwitchTile(
                  icon: Icons.key_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsBackupIncludeApiKeys,
                  subtitle: l.settingsBackupIncludeApiKeysDesc,
                  value: _includeApiKeys,
                  onChanged: (value) => setState(() => _includeApiKeys = value),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _busy ? null : _exportToFile,
                          icon: const Icon(Icons.save_alt_rounded, size: 18),
                          label: Text(
                            l.settingsBackupExportAllFile,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _exportToClipboard,
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            size: 18,
                          ),
                          label: Text(
                            l.settingsBackupExportAllClipboard,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── GROUP 2: IMPORT ──
            SettingsGroup(
              title: l.settingsBackupImportAllTitle,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _busy ? null : _importFromFile,
                          icon: const Icon(Icons.file_upload_rounded, size: 18),
                          label: Text(
                            l.settingsBackupImportAllFile,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            backgroundColor: cs.secondaryContainer,
                            foregroundColor: cs.onSecondaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _importFromClipboard,
                          icon: const Icon(
                            Icons.assignment_return_rounded,
                            size: 18,
                          ),
                          label: Text(
                            l.settingsBackupImportAllClipboard,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
