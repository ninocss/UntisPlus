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
              subtitle: 'Schnell, präzise & kostenloser API-Schlüssel',
              badge: 'Empfohlen',
              icon: Icons.auto_awesome_rounded,
              colors: colors,
            ),
            const SizedBox(height: 10),

            _buildProviderBento(
              id: 'local',
              title: l.settingsAiLocalModel,
              subtitle: '100% offline & auf deinem Gerät ausgeführt',
              badge: 'Privat',
              icon: Icons.memory_rounded,
              colors: colors,
            ),
            const SizedBox(height: 10),

            _buildProviderBento(
              id: 'openai',
              title: 'OpenAI (ChatGPT)',
              subtitle: 'GPT-4o, GPT-4o mini mit eigenem API-Key',
              icon: Icons.chat_bubble_outline_rounded,
              colors: colors,
            ),
            const SizedBox(height: 10),

            _buildProviderBento(
              id: 'custom',
              title: 'Custom Endpoint',
              subtitle: 'Ollama, vLLM oder kompatible Proxies',
              icon: Icons.settings_ethernet_rounded,
              colors: colors,
            ),
            const SizedBox(height: 18),

            // Provider-specific details / inputs
            if (isLocal) ...[
              // Local Model Download Card
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
                        Icon(Icons.download_rounded, color: colors.primary, size: 22),
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
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedLocalModel.name,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      l.settingsAiLocalModelSize(_selectedLocalModel.sizeGb),
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
                    border: InputBorder.none,
                  ),
                ),
              ),
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
                      border: InputBorder.none,
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
            label: 'Ohne KI fortfahren',
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
