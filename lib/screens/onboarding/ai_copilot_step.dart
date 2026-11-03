part of '../../main.dart';

/// Step 3: Material 3 Expressive AI Copilot Stage with bento-style selection
/// for Gemini, on-device GGUF models, custom endpoints, and zero-friction skip.
class AiCopilotStep extends StatefulWidget {
  final String initialProvider;
  final String initialModel;
  final String initialCustomCompatibility;
  final Map<String, String> initialApiKeys;
  final String initialCustomBaseUrl;
  final ValueChanged<Map<String, dynamic>> onSave;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const AiCopilotStep({
    super.key,
    required this.initialProvider,
    required this.initialModel,
    required this.initialCustomCompatibility,
    required this.initialApiKeys,
    required this.initialCustomBaseUrl,
    required this.onSave,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<AiCopilotStep> createState() => _AiCopilotStepState();
}

class _AiCopilotStepState extends State<AiCopilotStep> {
  late String _provider;
  late String _model;
  late String _customCompatibility;
  late Map<String, String> _apiKeys;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _customBaseUrlController;

  bool _isDownloading = false;
  double _downloadProgress = 0;
  CancelToken? _cancelToken;

  LocalModelInfo get _selectedLocalModel {
    return kLocalModels.firstWhere(
      (m) => m.id == _model,
      orElse: _defaultLocalModel,
    );
  }

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
    _model = widget.initialModel;
    _customCompatibility = widget.initialCustomCompatibility;
    _apiKeys = Map.from(widget.initialApiKeys);
    _apiKeyController = TextEditingController(text: _apiKeys[_provider] ?? '');
    _customBaseUrlController = TextEditingController(
      text: widget.initialCustomBaseUrl,
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _apiKeyController.dispose();
    _customBaseUrlController.dispose();
    super.dispose();
  }

  void _onProviderChanged(String provider) {
    AppHaptics.selection();
    _apiKeys[_provider] = _apiKeyController.text.trim();
    setState(() {
      _provider = provider;
      _apiKeyController.text = _apiKeys[provider] ?? '';
      final models = _modelsForProvider(
        _provider,
        customCompatibility: _customCompatibility,
      );
      if (!models.contains(_model)) {
        _model = models.first;
      }
    });
  }

  void _submit() {
    _apiKeys[_provider] = _apiKeyController.text.trim();
    widget.onSave({
      'provider': _provider,
      'model': _model,
      'customCompatibility': _customCompatibility,
      'apiKeys': _apiKeys,
      'customBaseUrl': _customBaseUrlController.text.trim(),
    });
    widget.onNext();
  }

  String _getLocalModelDescription(LocalModelInfo model, AppL10n l) {
    switch (model.id) {
      case 'qwen3-0.6b-q4_k_m':
      case 'lfm2-1.2b-q4_k_m':
        return l.aiLocalModelDescSmall;
      case 'qwen3-1.7b-q4_k_m':
      case 'granite-4.0-h-micro-q4_k_m':
        return l.aiLocalModelDescBalanced;
      case 'qwen3-4b-instruct-2507-q4_k_m':
        return l.aiLocalModelDescMultilingual;
      case 'gemma-4-e2b-it-q4_k_m':
        return l.aiLocalModelDescHighQuality;
      case 'gemma-4-e4b-it-q4_k_m':
        return l.aiLocalModelDescStrong;
      default:
        return model.description;
    }
  }

  void _showModelPicker(BuildContext context, AppL10n l) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.onboardingSelectModel,
                  style: untisThemeTextStyle(
                    ctx,
                    display: true,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: kLocalModels.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final model = kLocalModels[index];
                      final isSelected = model.id == _model;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() {
                              _model = model.id;
                            });
                            Navigator.of(ctx).pop();
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primaryContainer.withValues(alpha: 0.7)
                                  : colors.surfaceContainerHigh.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? colors.primary
                                    : colors.outlineVariant.withValues(alpha: 0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary.withValues(alpha: 0.15)
                                        : colors.surface.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.memory_rounded,
                                    color: isSelected ? colors.primary : colors.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        model.name,
                                        style: untisThemeTextStyle(
                                          ctx,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          color: isSelected
                                              ? colors.onPrimaryContainer
                                              : colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${l.settingsAiLocalModelSize(model.sizeGb)} · ${_getLocalModelDescription(model, l)}',
                                        style: untisThemeTextStyle(
                                          ctx,
                                          fontSize: 12,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected ? colors.primary : colors.outlineVariant,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final isLocal = _provider == 'local';
    final isCustom = _provider == 'custom';

    return M3StepContainer(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Header with AI sparkle emblem
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primaryContainer, colors.tertiaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.onboardingFeatureAiTitle,
                        style: untisThemeTextStyle(
                          context,
                          display: true,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        l.onboardingGeminiSubtitle,
                        style: untisThemeTextStyle(
                          context,
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bento selector cards
            _buildProviderBento(
              id: 'gemini',
              title: 'Google Gemini',
              subtitle: l.onboardingAiGeminiDesc,
              badge: l.onboardingAiBadgeRecommended,
              icon: Icons.auto_awesome_rounded,
              colors: colors,
            ),
            const SizedBox(height: 10),

            _buildProviderBento(
              id: 'local',
              title: l.settingsAiLocalModel,
              subtitle: l.onboardingAiLocalDesc,
              badge: l.onboardingAiBadgePrivate,
              icon: Icons.memory_rounded,
              colors: colors,
            ),
            const SizedBox(height: 10),

            _buildProviderBento(
              id: 'openai',
              title: 'OpenAI (ChatGPT)',
              subtitle: l.onboardingAiOpenAiDesc,
              icon: Icons.chat_bubble_outline_rounded,
              colors: colors,
            ),
            const SizedBox(height: 10),

            _buildProviderBento(
              id: 'custom',
              title: 'Custom Endpoint',
              subtitle: l.onboardingAiCustomDesc,
              icon: Icons.settings_ethernet_rounded,
              colors: colors,
            ),
            const SizedBox(height: 18),

            // Provider-specific details / inputs
            if (isLocal) ...[
              // Local Model Selection & Download Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.memory_rounded, color: colors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.settingsAiLocalModel,
                            style: untisThemeTextStyle(
                              context,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        // Choose model trigger button
                        OutlinedButton.icon(
                          onPressed: () => _showModelPicker(context, l),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: Text(
                            l.onboardingSelectModel,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedLocalModel.name,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l.settingsAiLocalModelSize(_selectedLocalModel.sizeGb)} · ${_getLocalModelDescription(_selectedLocalModel, l)}',
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 12.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (_isDownloading) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          // Trigger local download simulation or download start
                          setState(() {
                            _isDownloading = !_isDownloading;
                            _downloadProgress = 0.5;
                          });
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: Text(l.settingsAiLocalModelDownload),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // API Key input field
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  style: untisThemeTextStyle(context, fontSize: 15),
                  decoration: InputDecoration(
                    icon: Icon(Icons.key_rounded, color: colors.primary, size: 20),
                    labelText: l.settingsAiApiKey,
                    labelStyle: untisThemeTextStyle(
                      context,
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    hintText: 'AIzaSy...',
                    hintStyle: untisThemeTextStyle(
                      context,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              if (_provider == 'gemini' || _provider == 'openai' || _provider == 'mistral') ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final url = _settingsApiKeyPortalUrlForProvider(_provider);
                      if (url.isNotEmpty) {
                        await url_launcher.launchUrlString(
                          url,
                          mode: url_launcher.LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      _provider == 'gemini'
                          ? l.onboardingGeminiGetApiKeyLink
                          : l.settingsAiApiKeyGet,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ],
              if (isCustom) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: TextField(
                    controller: _customBaseUrlController,
                    style: untisThemeTextStyle(context, fontSize: 15),
                    decoration: InputDecoration(
                      icon: Icon(Icons.link_rounded, color: colors.primary, size: 20),
                      labelText: l.settingsAiCustomBaseUrl,
                      labelStyle: untisThemeTextStyle(
                        context,
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      hintText: 'https://api.openai.com/v1',
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          M3PillButton(
            label: l.onboardingNext,
            icon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          M3PillButton(
            label: l.onboardingContinueWithoutAi,
            icon: Icons.chevron_right_rounded,
            isPrimary: false,
            onPressed: () {
              widget.onSave({'provider': 'disabled'});
              widget.onSkip();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProviderBento({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required ColorScheme colors,
    String? badge,
  }) {
    final isSelected = _provider == id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onProviderChanged(id),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer.withValues(alpha: 0.5)
                : colors.surfaceContainerHigh.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : colors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? colors.onPrimary : colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: untisThemeTextStyle(
                            context,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: colors.onSurface,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge,
                              style: untisThemeTextStyle(
                                context,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? colors.primary : colors.outlineVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
