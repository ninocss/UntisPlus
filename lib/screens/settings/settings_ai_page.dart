// settings_ai_page.dart
part of '../../main.dart';

class SettingsAiPage extends StatefulWidget {
  final bool openPromptEditor;

  const SettingsAiPage({super.key, this.openPromptEditor = false});

  @override
  State<SettingsAiPage> createState() => _SettingsAiPageState();
}

class _SettingsAiPageState extends State<SettingsAiPage> {
  @override
  void initState() {
    super.initState();
    _reloadFromPrefs();
    if (widget.openPromptEditor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPromptDialog();
      });
    }
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
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                const SizedBox(height: 10),
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.settingsApiKeyCancel),
                    ),
                    const SizedBox(width: 8),
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
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: TextField(
                    controller: ctrl,
                    minLines: 8,
                    maxLines: 16,
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.settingsApiKeyCancel),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => ctrl.text = defaultTemplate,
                      child: Text(l.settingsAiPromptReset),
                    ),
                    const SizedBox(width: 8),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    children: l.aiPromptVariableDescriptions.entries
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
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _settingsOpenApiKeyPortal(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(
                        l.settingsAiApiKeyGet,
                        style: GoogleFonts.outfit(fontSize: 13),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.settingsApiKeyCancel),
                    ),
                    const SizedBox(width: 8),
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
    final mq = MediaQuery.of(context);
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
          padding: EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 120),
          children: [
            // ── GROUP 1: AI MODEL & PROVIDER ──
            SettingsGroup(
              title: l.settingsSectionAI,
              children: [
                SettingsTile(
                  icon: Icons.smart_toy_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsAiProvider,
                  subtitle: _localizedAiProviderLabel(l, aiProvider),
                  onTap: _showProviderDialog,
                ),
                SettingsTile(
                  icon: Icons.memory_rounded,
                  iconBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onPrimaryContainer,
                  title: l.settingsAiModel,
                  subtitle: aiModel,
                  onTap: _showModelDialog,
                ),
                if (isCustom) ...[
                  SettingsTile(
                    icon: Icons.merge_type_rounded,
                    iconBackgroundColor: cs.secondaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    iconColor: cs.onSecondaryContainer,
                    title: l.settingsAiCompatibility,
                    subtitle: _settingsAiCompatibilityLabel(
                      l,
                      aiCustomCompatibility,
                    ),
                    onTap: _showCompatibilityDialog,
                  ),
                  SettingsTile(
                    icon: Icons.link_rounded,
                    iconBackgroundColor: cs.secondaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    iconColor: cs.onSecondaryContainer,
                    title: l.settingsAiCustomBaseUrl,
                    subtitle:
                        aiCustomBaseUrl.isEmpty
                            ? l.settingsAiCustomBaseUrlHint
                            : aiCustomBaseUrl,
                    onTap: _showBaseUrlDialog,
                  ),
                ],
                SettingsTile(
                  icon: Icons.key_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: l.settingsAiApiKey,
                  subtitle:
                      activeKey.isEmpty
                          ? l.settingsAiApiKeyNotSet
                          : _settingsMaskKey(activeKey),
                  onTap: _showApiKeyDialog,
                ),
              ],
            ),

            // ── GROUP 2: PROMPT CONFIGURATION ──
            SettingsGroup(
              title: l.settingsAiPrompt,
              children: [
                SettingsTile(
                  icon: Icons.edit_note_rounded,
                  iconBackgroundColor: cs.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onTertiaryContainer,
                  title: l.settingsAiPrompt,
                  subtitle: l.settingsAiPromptDesc,
                  onTap: _showPromptDialog,
                ),
                SettingsTile(
                  icon: Icons.data_object_rounded,
                  iconBackgroundColor: cs.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onTertiaryContainer,
                  title: l.settingsAiPromptVariables,
                  subtitle: l.settingsAiPromptVariablesDesc,
                  onTap: _showPromptVariablesDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
