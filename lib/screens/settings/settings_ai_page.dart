part of '../../main.dart';

class SettingsAiPage extends StatefulWidget {
  const SettingsAiPage({super.key});

  @override
  State<SettingsAiPage> createState() => _SettingsAiPageState();
}

class _SettingsAiPageState extends State<SettingsAiPage> {
  @override
  void initState() {
    super.initState();
    _reloadFromPrefs();
  }

  Future<void> _reloadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    aiProvider = _normalizeAiProvider(
      prefs.getString('aiProvider') ?? aiProvider,
    );
    aiCustomCompatibility = _normalizeAiCustomCompatibility(
      prefs.getString('aiCustomCompatibility') ?? aiCustomCompatibility,
    );
    aiModel = prefs.getString('aiModel') ?? aiModel;
    aiCustomBaseUrl = prefs.getString('aiCustomBaseUrl') ?? aiCustomBaseUrl;
    aiSystemPromptTemplate =
        prefs.getString('aiSystemPromptTemplate') ?? aiSystemPromptTemplate;
    geminiApiKey = prefs.getString('geminiApiKey') ?? geminiApiKey;
    openAiApiKey = prefs.getString('openAiApiKey') ?? openAiApiKey;
    mistralApiKey = prefs.getString('mistralApiKey') ?? mistralApiKey;
    customAiApiKey = prefs.getString('customAiApiKey') ?? customAiApiKey;

    final validModels = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    if (!validModels.contains(aiModel)) {
      aiModel = _defaultModelForProvider(
        aiProvider,
        customCompatibility: aiCustomCompatibility,
      );
      await prefs.setString('aiModel', aiModel);
    }
    if (mounted) setState(() {});
  }

  String _activeProviderApiKey() {
    switch (_normalizeAiProvider(aiProvider)) {
      case 'openai':
        return openAiApiKey;
      case 'mistral':
        return mistralApiKey;
      case 'custom':
        return customAiApiKey;
      case 'gemini':
      default:
        return geminiApiKey;
    }
  }

  void _showProviderDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiProvider,
      options: kSupportedAiProviders
          .map(
            (provider) => _SheetOption(
              value: provider,
              title: _localizedAiProviderLabel(l, provider),
              icon: provider == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : provider == 'openai'
                  ? Icons.chat_bubble_outline_rounded
                  : provider == 'mistral'
                  ? Icons.cloud_rounded
                  : Icons.settings_ethernet_rounded,
              selected: aiProvider == provider,
            ),
          )
          .toList(),
    ).then((value) async {
      if (value != null) {
        await _settingsSetAiProvider(value);
        await _reloadFromPrefs();
      }
    });
  }

  void _showModelDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final models = _modelsForProvider(
      aiProvider,
      customCompatibility: aiCustomCompatibility,
    );
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiModel,
      options: models
          .map(
            (model) => _SheetOption(
              value: model,
              title: model,
              icon: Icons.memory_rounded,
              selected: aiModel == model,
            ),
          )
          .toList(),
    ).then((value) async {
      if (value != null) {
        await _settingsSetAiModel(value);
        await _reloadFromPrefs();
      }
    });
  }

  void _showCompatibilityDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiCompatibility,
      options: kSupportedAiCustomCompatibilities
          .map(
            (compat) => _SheetOption(
              value: compat,
              title: _settingsAiCompatibilityLabel(l, compat),
              icon: compat == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : Icons.chat_rounded,
              selected: aiCustomCompatibility == compat,
            ),
          )
          .toList(),
    ).then((value) async {
      if (value != null) {
        await _settingsSetAiCustomCompatibility(value);
        await _reloadFromPrefs();
      }
    });
  }

  void _showBaseUrlDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: aiCustomBaseUrl);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsAiCustomBaseUrl,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.settingsAiCustomBaseUrlHint,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.settingsApiKeyCancel),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await _settingsSetAiCustomBaseUrl(ctrl.text.trim());
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _reloadFromPrefs();
                      },
                      child: Text(l.settingsApiKeySave),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPromptDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final defaultTemplate = _buildDefaultAiPromptTemplate(l);
    final ctrl = TextEditingController(
      text: aiSystemPromptTemplate.isEmpty
          ? defaultTemplate
          : aiSystemPromptTemplate,
    );

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsAiPromptEditTitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 280,
                  child: TextField(
                    controller: ctrl,
                    minLines: 10,
                    maxLines: 18,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12.5),
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.settingsApiKeyCancel),
                    ),
                    TextButton(
                      onPressed: () => ctrl.text = defaultTemplate,
                      child: Text(l.settingsAiPromptReset),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await _settingsSetAiSystemPromptTemplate(
                          ctrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _reloadFromPrefs();
                      },
                      child: Text(l.settingsApiKeySave),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPromptVariablesDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsAiPromptVariables,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView(
                    shrinkWrap: true,
                    children: aiPromptVariableDescriptions.entries
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.label_important_outline),
                            title: Text(
                              entry.key,
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              entry.value,
                              style: GoogleFonts.outfit(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.settingsApiKeyCancel),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showApiKeyDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: _activeProviderApiKey());
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsAiApiKey,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiApiKeyDialogDesc,
                  style: GoogleFonts.outfit(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: _settingsApiKeyHintForProvider(aiProvider),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _settingsOpenApiKeyPortal(context),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l.settingsAiApiKeyGet),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.settingsApiKeyCancel),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await _settingsSetProviderApiKey(ctrl.text.trim());
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _reloadFromPrefs();
                      },
                      child: Text(l.settingsApiKeySave),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final isCustom = aiProvider == 'custom';
    final activeKey = _activeProviderApiKey();

    return Scaffold(
      appBar: RoundedBlurAppBar(
        title: Text(
          l.settingsSectionAI,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _AnimatedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.smart_toy_rounded),
                title: Text(
                  l.settingsAiProvider,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _localizedAiProviderLabel(l, aiProvider),
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showProviderDialog,
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.memory_rounded),
                title: Text(
                  l.settingsAiModel,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(aiModel, style: GoogleFonts.outfit()),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showModelDialog,
              ),
            ),
            if (isCustom) ...[
              const SizedBox(height: 12),
              Card.filled(
                color: cs.surfaceContainerHigh,
                child: ListTile(
                  leading: const Icon(Icons.merge_type_rounded),
                  title: Text(
                    l.settingsAiCompatibility,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _settingsAiCompatibilityLabel(l, aiCustomCompatibility),
                    style: GoogleFonts.outfit(),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showCompatibilityDialog,
                ),
              ),
              const SizedBox(height: 12),
              Card.filled(
                color: cs.surfaceContainerHigh,
                child: ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: Text(
                    l.settingsAiCustomBaseUrl,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    aiCustomBaseUrl.isEmpty
                        ? l.settingsAiCustomBaseUrlHint
                        : aiCustomBaseUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showBaseUrlDialog,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.key_rounded),
                title: Text(
                  l.settingsAiApiKey,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  activeKey.isEmpty
                      ? l.settingsAiApiKeyNotSet
                      : _settingsMaskKey(activeKey),
                  style: GoogleFonts.jetBrainsMono(fontSize: 12.2),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showApiKeyDialog,
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: Text(
                  l.settingsAiPrompt,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsAiPromptDesc,
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showPromptDialog,
              ),
            ),
            const SizedBox(height: 12),
            Card.filled(
              color: cs.surfaceContainerHigh,
              child: ListTile(
                leading: const Icon(Icons.data_object_rounded),
                title: Text(
                  l.settingsAiPromptVariables,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.settingsAiPromptVariablesDesc,
                  style: GoogleFonts.outfit(),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showPromptVariablesDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
