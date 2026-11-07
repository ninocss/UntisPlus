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
        if (mounted) _showCustomInstructionsDialog();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _reloadFromPrefs() async {
    final prefs = SettingsStore.instance.preferences;
    await loadAiPreferences(prefs);

    if (aiProvider == 'custom') {
      aiModel = aiCustomModel.isNotEmpty
          ? aiCustomModel
          : (prefs.getString('aiModel') ?? '');
    } else {
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
    }
    if (mounted) setState(() {});
  }

  Future<void> _setAiEnabled(bool enabled) async {
    aiEnabledNotifier.value = enabled;
    await SettingsStore.instance.writeRaw('aiEnabled', enabled);
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

  final LocalModelDownloadCoordinator _downloadCoordinator =
      LocalModelDownloadCoordinator.instance;

  /// Get the local file path for a model
  Future<String> _getLocalModelPath(String modelId) async {
    final model = kLocalModels.firstWhere((m) => m.id == modelId);
    return _downloadCoordinator.pathFor(model);
  }

  /// Check if a model is already downloaded and valid
  Future<bool> _isModelDownloaded(String modelId) async {
    final model = kLocalModels.firstWhere((m) => m.id == modelId);
    final path = await _getLocalModelPath(modelId);
    return _isValidModelFile(path, model: model);
  }

  /// Validate that a file is a plausible GGUF model (magic bytes + size close
  /// to the advertised model size). Prevents activating a truncated/corrupt
  /// download that llama.cpp would reject with "Failed to create inference
  /// context". Delegates to the shared validator also used by the downloader,
  /// onboarding and startup.
  Future<bool> _isValidModelFile(String path, {LocalModelInfo? model}) async {
    return _isValidLocalModelFile(path, model: model);
  }

  /// Download a local model
  Future<void> _downloadLocalModel(LocalModelInfo model) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final state = await _downloadCoordinator.start(model);
    if (mounted && state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.aiConnectionError} ${state.error}')),
      );
    }
  }

  /// Cancel a model download
  void _cancelDownload(String modelId) {
    _downloadCoordinator.cancel(modelId);
  }

  /// Delete a downloaded model
  Future<void> _deleteLocalModel(LocalModelInfo model) async {
    final l = appL10nFor(appLocaleNotifier.value);
    final path = await _getLocalModelPath(model.id);
    if (!mounted) return;

    final confirmed = await showUntisDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHigh,
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(
              ctx,
            ).colorScheme.errorContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(ctx).colorScheme.onErrorContainer,
            size: 26,
          ),
        ),
        title: Text(
          l.settingsAiLocalModelDeleteConfirm,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(l.delete),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadCoordinator.delete(model);
      if (!mounted) return;
      unawaited(AppHaptics.destructive());
      // If this was the active model, clear the path and revert provider
      if (aiLocalModelPath == path) {
        final prefs = SettingsStore.instance.preferences;
        await prefs.setString('aiLocalModelPath', '');
        aiLocalModelPath = '';
        aiProvider = 'gemini';
        await prefs.setString('aiProvider', 'gemini');
        aiModel = _defaultModelForProvider('gemini');
        await prefs.setString('aiModel', aiModel);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${model.name} ${l.settingsApiKeyRemove}')),
        );
      }
    }
  }

  /// Show local model selection dialog
  void _showLocalModelDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;
          return ValueListenableBuilder<Map<String, LocalModelDownloadState>>(
            valueListenable: _downloadCoordinator,
            builder: (context, _, _) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy_rounded,
                          color: cs.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.settingsAiLocalModel,
                                style: tt.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l.settingsAiLocalModelDesc,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: kLocalModels.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 320 + index * 70),
                            curve: Curves.easeOutCubic,
                            tween: Tween(begin: 0, end: 1),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 18),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildLocalModelCard(
                              ctx,
                              kLocalModels[index],
                              l,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
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

  /// Build a single local model card with Material You Expressive styling.
  Widget _buildLocalModelCard(
    BuildContext ctx,
    LocalModelInfo model,
    AppL10n l,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    final downloadState = _downloadCoordinator.stateFor(model.id);
    final progress = downloadState.progress;
    final isDownloading = downloadState.isDownloading;
    final hasError = downloadState.hasError;
    final isActive = aiLocalModelPath.endsWith(model.url.split('/').last);

    return FutureBuilder<bool>(
      future: _isModelDownloaded(model.id),
      builder: (context, snapshot) {
        final downloaded = snapshot.data ?? false;

        final Color cardColor;
        final Border cardBorder;
        if (isActive) {
          cardColor = cs.surfaceContainerHigh;
          cardBorder = Border.all(
            color: cs.primary,
            width: 1.5,
          );
        } else if (hasError) {
          cardColor = cs.surfaceContainer;
          cardBorder = Border.all(
            color: cs.error.withValues(alpha: 0.4),
            width: 1,
          );
        } else if (isDownloading) {
          cardColor = cs.surfaceContainer;
          cardBorder = Border.all(
            color: cs.primary.withValues(alpha: 0.5),
            width: 1.2,
          );
        } else {
          cardColor = cs.surfaceContainer;
          cardBorder = Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: cardBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModelIcon(
                      ctx,
                      model,
                      isActive: isActive,
                      downloaded: downloaded,
                      isDownloading: isDownloading,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  model.name,
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (isDownloading)
                                _buildStatusChip(
                                  ctx,
                                  l.settingsAiLocalModelDownloading,
                                  cs.primaryContainer,
                                  cs.onPrimaryContainer,
                                )
                              else if (hasError)
                                _buildStatusChip(
                                  ctx,
                                  l.settingsAiLocalModelError,
                                  cs.errorContainer,
                                  cs.onErrorContainer,
                                )
                              else if (isActive)
                                _buildStatusChip(
                                  ctx,
                                  l.settingsAiLocalModelActive,
                                  cs.primaryContainer,
                                  cs.onPrimaryContainer,
                                )
                              else if (downloaded)
                                _buildStatusChip(
                                  ctx,
                                  l.settingsAiLocalModelInstalled,
                                  cs.secondaryContainer,
                                  cs.onSecondaryContainer,
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _getLocalModelDescription(model, l),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.storage_rounded,
                                size: 13,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${model.sizeGb < 1.0 ? model.sizeGb.toStringAsFixed(2) : model.sizeGb.toStringAsFixed(1)} GB',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildModelActionArea(
                  ctx,
                  model,
                  l,
                  progress: progress,
                  isDownloading: isDownloading,
                  hasError: hasError,
                  downloaded: downloaded,
                  isActive: isActive,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelIcon(
    BuildContext ctx,
    LocalModelInfo model, {
    required bool isActive,
    required bool downloaded,
    required bool isDownloading,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    final Color iconBg;
    final IconData icon;
    final Color iconColor;

    if (isActive) {
      iconBg = cs.primaryContainer;
      icon = Icons.check_circle_rounded;
      iconColor = cs.primary;
    } else if (isDownloading) {
      iconBg = cs.primaryContainer.withValues(alpha: 0.6);
      icon = Icons.downloading_rounded;
      iconColor = cs.primary;
    } else if (downloaded) {
      iconBg = cs.surfaceContainerHighest;
      icon = Icons.check_rounded;
      iconColor = cs.onSurfaceVariant;
    } else {
      iconBg = cs.surfaceContainerHighest;
      icon = Icons.download_rounded;
      iconColor = cs.primary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }

  Widget _buildStatusChip(
    BuildContext ctx,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  /// Action area below each model card: progress, buttons depending on state.
  Widget _buildModelActionArea(
    BuildContext ctx,
    LocalModelInfo model,
    AppL10n l, {
    required double progress,
    required bool isDownloading,
    required bool hasError,
    required bool downloaded,
    required bool isActive,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;

    if (isDownloading) {
      return _buildDownloadProgress(ctx, model, l, progress);
    }

    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: cs.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.settingsAiLocalModelError,
                style: tt.bodySmall?.copyWith(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: () => _downloadLocalModel(model),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.settingsAiLocalModelDownload),
            ),
          ],
        ),
      );
    }

    if (downloaded) {
      return Row(
        children: [
          if (!isActive) ...[
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(l.settingsAiLocalModelActive),
                onPressed: () async {
                  final path = await _getLocalModelPath(model.id);
                  if (!await _isValidModelFile(path, model: model)) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(l.aiLocalModelLoadError)),
                      );
                    }
                    return;
                  }
                  final prefs = SettingsStore.instance.preferences;
                  await prefs.setString('aiLocalModelPath', path);
                  aiLocalModelPath = path;
                  aiProvider = 'local';
                  await prefs.setString('aiProvider', 'local');
                  aiModel = model.id;
                  await prefs.setString('aiModel', model.id);
                  if (ctx.mounted) {
                    _reloadFromPrefs();
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(l.delete),
            onPressed: () => _deleteLocalModel(model),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text(l.settingsAiLocalModelDownload),
        onPressed: () => _downloadLocalModel(model),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  /// Expressive download progress bar with percentage, bytes, speed and remaining time.
  Widget _buildDownloadProgress(
    BuildContext ctx,
    LocalModelInfo model,
    AppL10n l,
    double progress,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    final downloadState = _downloadCoordinator.stateFor(model.id);
    final received = downloadState.received;
    final total = downloadState.total;
    final speed = downloadState.bytesPerSecond;
    final remaining = downloadState.estimatedRemainingTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.settingsAiLocalModelDownloading,
                style: GoogleFonts.outfit(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed_rounded, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${_formatByteSize(speed.round())}/s',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (remaining != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatModelRemainingTime(remaining, l),
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            if (total > 0)
              Text(
                '${_formatByteSize(received)} / ${_formatByteSize(total)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _cancelDownload(model.id),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(l.cancel),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: cs.error,
            ),
          ),
        ),
      ],
    );
  }

  void _showModelDialog() {
    if (aiProvider == 'custom') {
      _showCustomModelDialog();
      return;
    }
    final l = appL10nFor(appLocaleNotifier.value);
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

  void _showCustomModelDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    final ctrl = TextEditingController(
      text: aiCustomModel.isNotEmpty ? aiCustomModel : aiModel,
    );
    final suggestions = _modelsForProvider(
      'custom',
      customCompatibility: aiCustomCompatibility,
    );

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
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
                  l.settingsAiCustomModel,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.settingsAiCustomModelDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.jetBrainsMono(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.settingsAiCustomModelHint,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.settingsAiCustomModelSuggestions,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions.map((sug) {
                    return ActionChip(
                      label: Text(
                        sug,
                        style: GoogleFonts.jetBrainsMono(fontSize: 11),
                      ),
                      onPressed: () {
                        ctrl.text = sug;
                        setDialogState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildAiSheetActions([
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final val = ctrl.text.trim();
                      await _settingsSetAiModel(val);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _reloadFromPrefs();
                    },
                    child: Text(l.save),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCompatibilityDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
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

  /// Keeps every action reachable on narrow phones without adding a horizontal
  /// scrollbar to an AI-settings sheet.  A [Wrap] moves a whole button to the
  /// next line instead of clipping it behind the sheet edge.
  Widget _buildAiSheetActions(List<Widget> children) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: children,
      ),
    );
  }

  void _showBaseUrlDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
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
                _buildAiSheetActions([
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await _settingsSetAiCustomBaseUrl(ctrl.text.trim());
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _reloadFromPrefs();
                    },
                    child: Text(l.save),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCustomInstructionsDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: aiCustomInstructions);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          final tokenCount = estimateLocalTokens(ctrl.text);
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
                  l.settingsAiInstructions,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.settingsAiInstructionsDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => setDialogState(() {}),
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.settingsAiInstructionsHint,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '~ $tokenCount ${l.settingsAiPromptTokens}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    _buildAiSheetActions([
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        onPressed: () async {
                          final value = ctrl.text.trim();
                          await SettingsStore.instance.writeRaw(
                            'aiCustomInstructions',
                            value,
                          );
                          aiCustomInstructions = value;
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _reloadFromPrefs();
                        },
                        child: Text(l.save),
                      ),
                    ]),
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
    final l = appL10nFor(appLocaleNotifier.value);
    final defaultTemplate = _buildDefaultAiPromptTemplate(l);
    final ctrl = TextEditingController(
      text: aiSystemPromptTemplate.isEmpty
          ? defaultTemplate
          : aiSystemPromptTemplate,
    );

    const variables = [
      '[today]',
      '[current_lesson]',
      '[next_lesson]',
      '[timetable]',
      '[exams]',
      '[homework]',
      '[grades_summary]',
      '[next_free_day]',
      '[day_summary_today]',
      '[day_summary_tomorrow]',
    ];

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: DefaultTabController(
        length: 2,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            final cs = Theme.of(ctx).colorScheme;
            final isCustomActive = aiSystemPromptTemplate.trim().isNotEmpty;
            final estimatedTokens = estimateLocalTokens(ctrl.text);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.settingsAiPromptAdvanced,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCustomActive
                              ? cs.tertiaryContainer
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCustomActive
                              ? l.settingsAiPromptCustomActive
                              : l.settingsAiPromptDefaultActive,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCustomActive
                                ? cs.onTertiaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    tabs: [
                      Tab(text: l.settingsAiPromptTabEdit),
                      Tab(text: l.settingsAiPromptTabPreview),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: (MediaQuery.of(ctx).size.height * 0.35).clamp(
                      160.0,
                      300.0,
                    ),
                    child: TabBarView(
                      children: [
                        // Tab 1: Edit
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCustomActive)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: cs.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l.settingsAiPromptOverrideWarning,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: cs.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: TextField(
                                controller: ctrl,
                                minLines: 8,
                                maxLines: 20,
                                onChanged: (_) => setDialogState(() {}),
                                style: GoogleFonts.jetBrainsMono(fontSize: 12),
                                decoration: InputDecoration(
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: variables.map((v) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                        v,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () {
                                        final text = ctrl.text;
                                        final sel = ctrl.selection;
                                        final start = sel.start >= 0
                                            ? sel.start
                                            : text.length;
                                        final end = sel.end >= 0
                                            ? sel.end
                                            : text.length;
                                        ctrl.text = text.replaceRange(
                                          start,
                                          end,
                                          v,
                                        );
                                        ctrl.selection =
                                            TextSelection.collapsed(
                                              offset: start + v.length,
                                            );
                                        setDialogState(() {});
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        // Tab 2: Preview
                        SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ctrl.text,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11.5,
                                  ),
                                ),
                                const Divider(height: 24),
                                Text(
                                  l.settingsAiPromptAppAddsHeader,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _chatPromptSuffix(l),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.data_usage_rounded,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '~ $estimatedTokens Tokens',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ctrl.text = defaultTemplate;
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.restart_alt_rounded, size: 15),
                          label: Text(
                            l.settingsAiPromptReset,
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAiSheetActions([
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final val = ctrl.text.trim();
                        final toSave = val == defaultTemplate.trim()
                            ? ''
                            : val;
                        await _settingsSetAiSystemPromptTemplate(toSave);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _reloadFromPrefs();
                      },
                      child: Text(l.save),
                    ),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPromptVariablesDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsAiPromptVariables,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.settingsAiPromptVariablesDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: l.aiPromptVariableDescriptions.entries
                        .map(
                          (entry) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.2),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                entry.key,
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: cs.primary,
                                ),
                              ),
                              subtitle: Text(
                                entry.value,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      l.cancel,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
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
    final l = appL10nFor(appLocaleNotifier.value);
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
                _buildAiSheetActions([
                  TextButton.icon(
                    onPressed: () => _settingsOpenApiKeyPortal(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      l.settingsAiApiKeyGet,
                      style: GoogleFonts.outfit(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await _settingsSetProviderApiKey(ctrl.text.trim());
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _reloadFromPrefs();
                    },
                    child: Text(l.save),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _settingsSetAiTemperature(double value) async {
    final prefs = SettingsStore.instance.preferences;
    await prefs.setDouble('aiTemperature', value);
    aiTemperature = value;
  }

  Future<void> _settingsSetAiMaxTokens(int value) async {
    final prefs = SettingsStore.instance.preferences;
    await prefs.setInt('aiMaxTokens', value);
    aiMaxTokens = value;
  }

  Future<void> _settingsSetAiTopP(double value) async {
    final prefs = SettingsStore.instance.preferences;
    await prefs.setDouble('aiTopP', value);
    aiTopP = value;
  }

  Future<void> _setAiShareGrades(bool value) async {
    aiShareGrades = value;
    await SettingsStore.instance.writeRaw('aiShareGrades', value);
    if (mounted) setState(() {});
  }

  void _showAdvancedSettingsDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    final isLocal = aiProvider == 'local';
    final maxTokensLimit = isLocal ? 1024 : 8192;
    final minTokens = isLocal ? 64 : 128;
    double temp = aiTemperature;
    int tokens = isLocal
        ? effectiveLocalMaxTokens(aiMaxTokens, kLocalModelDefaultSlotContext)
        : aiMaxTokens.clamp(minTokens, maxTokensLimit);
    double topP = aiTopP;

    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.aiParametersTitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  l.aiParametersDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSlider(
                  label: l.aiParameterTemperature,
                  value: temp,
                  min: 0,
                  max: 2,
                  divisions: 20,
                  suffix: temp.toStringAsFixed(1),
                  desc: l.aiTemperatureDesc,
                  onChanged: (v) => setStateDialog(() => temp = v),
                  cs: cs,
                ),
                const SizedBox(height: 24),
                _buildSlider(
                  label: l.aiParameterMaxTokens,
                  value: tokens.toDouble(),
                  min: minTokens.toDouble(),
                  max: maxTokensLimit.toDouble(),
                  divisions: isLocal ? 15 : 31,
                  suffix: tokens.toString(),
                  desc: isLocal
                      ? '${l.aiTokenDesc} (Empfohlen: 256–512 für schnelle lokale Antworten und mehr Platz für Stundenplandaten)'
                      : l.aiTokenDesc,
                  onChanged: (v) => setStateDialog(() => tokens = v.round()),
                  cs: cs,
                ),
                const SizedBox(height: 24),
                _buildSlider(
                  label: l.aiParameterTopP,
                  value: topP,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  suffix: topP.toStringAsFixed(2),
                  desc: l.aiTopPDesc,
                  onChanged: (v) => setStateDialog(() => topP = v),
                  cs: cs,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.cancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        await _settingsSetAiTemperature(temp);
                        await _settingsSetAiMaxTokens(tokens);
                        await _settingsSetAiTopP(topP);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _reloadFromPrefs();
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        l.save,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
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

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required String desc,
    required ValueChanged<double> onChanged,
    required ColorScheme cs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                suffix,
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        HapticSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _clearChatHistory() async {
    final l = appL10nFor(appLocaleNotifier.value);
    final confirmed = await showUntisDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.aiClearHistoryTitle),
        content: Text(l.aiClearHistoryDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = SettingsStore.instance.preferences;
      await prefs.remove('aiChatHistory');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.aiClearHistorySuccess)));
      }
    }
  }

  (String, Color, Color, IconData) _resolveStatus(AppL10n l, ColorScheme cs) {
    if (!aiEnabledNotifier.value) {
      return (
        l.settingsAiStatusDisabled,
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
        Icons.power_settings_new_rounded,
      );
    }
    if (aiProvider == 'local') {
      if (aiLocalModelPath.isNotEmpty) {
        return (
          l.settingsAiStatusReady,
          Colors.green.withValues(alpha: 0.15),
          Colors.green.shade700,
          Icons.check_circle_rounded,
        );
      }
      return (
        l.settingsAiStatusNeedsModel,
        Colors.orange.withValues(alpha: 0.15),
        Colors.orange.shade800,
        Icons.download_for_offline_rounded,
      );
    }
    if (aiProvider == 'custom') {
      if (aiCustomBaseUrl.trim().isEmpty) {
        return (
          l.settingsAiStatusNeedsUrl,
          Colors.orange.withValues(alpha: 0.15),
          Colors.orange.shade800,
          Icons.link_off_rounded,
        );
      }
      if (aiCustomModel.trim().isEmpty) {
        return (
          l.settingsAiStatusNeedsCustomModel,
          Colors.orange.withValues(alpha: 0.15),
          Colors.orange.shade800,
          Icons.edit_note_rounded,
        );
      }
      return (
        l.settingsAiStatusReady,
        Colors.green.withValues(alpha: 0.15),
        Colors.green.shade700,
        Icons.check_circle_rounded,
      );
    }
    final key = _activeProviderApiKey();
    if (key.trim().isEmpty) {
      return (
        l.settingsAiStatusNeedsKey,
        Colors.orange.withValues(alpha: 0.15),
        Colors.orange.shade800,
        Icons.key_off_rounded,
      );
    }
    return (
      l.settingsAiStatusReady,
      Colors.green.withValues(alpha: 0.15),
      Colors.green.shade700,
      Icons.check_circle_rounded,
    );
  }

  Widget _buildAiHeroCard(BuildContext context, AppL10n l, ColorScheme cs) {
    final enabled = aiEnabledNotifier.value;
    final (statusLabel, statusBg, statusFg, statusIcon) = _resolveStatus(l, cs);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: enabled
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.settingsSectionAI,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(maxWidth: 110),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusFg),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            Switch(
              value: enabled,
              onChanged: _setAiEnabled,
            ),
          ],
        ),
      ),
    );
  }

  void _showProviderDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsAiProvider,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                ...kSupportedAiProviders.map((provider) {
                  final isSelected = aiProvider == provider;
                  final (icon, desc) = switch (provider) {
                    'gemini' => (
                      Icons.auto_awesome_rounded,
                      l.settingsAiProviderGeminiDesc,
                    ),
                    'openai' => (
                      Icons.chat_bubble_outline_rounded,
                      l.settingsAiProviderOpenAiDesc,
                    ),
                    'mistral' => (
                      Icons.cloud_rounded,
                      l.settingsAiProviderMistralDesc,
                    ),
                    'custom' => (
                      Icons.settings_ethernet_rounded,
                      l.settingsAiProviderCustomDesc,
                    ),
                    'local' => (
                      Icons.memory_rounded,
                      l.settingsAiProviderLocalDesc,
                    ),
                    _ => (Icons.smart_toy_rounded, ''),
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? cs.primaryContainer.withValues(alpha: 0.35)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.6)
                              : cs.outlineVariant.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          _localizedAiProviderLabel(l, provider),
                          style: GoogleFonts.outfit(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          desc,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: cs.primary,
                                size: 22,
                              )
                            : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (aiProvider == provider) return;
                          await _settingsSetAiProvider(provider);
                          await _reloadFromPrefs();
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final isCustom = aiProvider == 'custom';
    final isLocal = aiProvider == 'local';
    final activeKey = _activeProviderApiKey();

    return SettingsPageShell(
      title: l.settingsSectionAI,
      children: [
        _buildAiHeroCard(context, l, cs),
        if (aiEnabledNotifier.value) ...[
          // ── CONNECTION ──
          SettingsGroup(
            title: l.settingsAiSectionConnection,
            children: [
              SettingsTile(
                icon: switch (aiProvider) {
                  'gemini' => Icons.auto_awesome_rounded,
                  'openai' => Icons.chat_bubble_outline_rounded,
                  'mistral' => Icons.cloud_rounded,
                  'custom' => Icons.settings_ethernet_rounded,
                  'local' => Icons.memory_rounded,
                  _ => Icons.hub_rounded,
                },
                iconBackgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                iconColor: cs.onPrimaryContainer,
                title: l.settingsAiProvider,
                subtitle: _localizedAiProviderLabel(l, aiProvider),
                onTap: _showProviderDialog,
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
                  subtitle: aiCustomBaseUrl.isEmpty
                      ? l.settingsAiCustomBaseUrlHint
                      : aiCustomBaseUrl,
                  onTap: _showBaseUrlDialog,
                ),
                SettingsTile(
                  icon: Icons.smart_toy_outlined,
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: l.settingsAiCustomModel,
                  subtitle: aiCustomModel.isEmpty
                      ? l.settingsAiCustomModelEmpty
                      : aiCustomModel,
                  onTap: _showCustomModelDialog,
                ),
              ],
              if (isLocal) ...[
                SettingsTile(
                  icon: Icons.download_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: l.settingsAiLocalModel,
                  subtitle:
                      kLocalModels
                          .where((m) => m.id == aiModel)
                          .firstOrNull
                          ?.name ??
                      aiModel,
                  onTap: _showLocalModelDialog,
                ),
                SettingsTile(
                  icon: Icons.data_usage_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: '${l.settingsAiContextWindow} (4096 Tokens)',
                  subtitle: l.settingsAiContextWindowDesc,
                  showSubtitle: true,
                ),
              ],
              if (!isLocal && !isCustom)
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
              if (!isLocal)
                SettingsTile(
                  icon: Icons.key_rounded,
                  iconBackgroundColor: cs.secondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  iconColor: cs.onSecondaryContainer,
                  title: l.settingsAiApiKey,
                  subtitle: activeKey.isEmpty
                      ? l.settingsAiApiKeyNotSet
                      : _settingsMaskKey(activeKey),
                  onTap: _showApiKeyDialog,
                ),
              SettingsTile(
                icon: Icons.tune_rounded,
                iconBackgroundColor: cs.secondaryContainer.withValues(
                  alpha: 0.7,
                ),
                iconColor: cs.onSecondaryContainer,
                title: l.settingsAiParametersTitle,
                subtitle: l.settingsAiParametersDesc,
                onTap: _showAdvancedSettingsDialog,
              ),
            ],
          ),

          // ── BEHAVIOR & PROMPT ──
          SettingsGroup(
            title: l.settingsAiSectionBehavior,
            children: [
              SettingsTile(
                icon: Icons.chat_rounded,
                iconBackgroundColor: cs.tertiaryContainer.withValues(
                  alpha: 0.7,
                ),
                iconColor: cs.onTertiaryContainer,
                title: l.settingsAiInstructions,
                subtitle: aiCustomInstructions.isEmpty
                    ? l.settingsAiInstructionsEmpty
                    : aiCustomInstructions,
                onTap: _showCustomInstructionsDialog,
              ),
              SettingsTile(
                icon: Icons.edit_note_rounded,
                iconBackgroundColor: cs.tertiaryContainer.withValues(
                  alpha: 0.7,
                ),
                iconColor: cs.onTertiaryContainer,
                title: l.settingsAiPromptAdvanced,
                subtitle: aiSystemPromptTemplate.isEmpty
                    ? l.settingsAiPromptDefaultActive
                    : l.settingsAiPromptCustomActive,
                trailing: aiSystemPromptTemplate.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.tertiaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CUSTOM',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right_rounded),
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

          // ── PRIVACY ──
          SettingsGroup(
            title: l.settingsAiPrivacy,
            children: [
              SettingsSwitchTile(
                icon: Icons.shield_rounded,
                iconBackgroundColor: cs.surfaceContainerHighest,
                iconColor: cs.onSurfaceVariant,
                title: l.settingsAiShareGrades,
                subtitle: l.settingsAiShareGradesDesc,
                showSubtitle: true,
                value: aiShareGrades,
                onChanged: _setAiShareGrades,
              ),
            ],
          ),

          // ── DATA ──
          SettingsGroup(
            title: l.settingsAiDataTitle,
            children: [
              SettingsTile(
                icon: Icons.delete_sweep_rounded,
                iconBackgroundColor: cs.errorContainer.withValues(alpha: 0.7),
                iconColor: cs.onErrorContainer,
                destructive: true,
                title: l.aiClearHistoryTileTitle,
                subtitle: l.aiClearHistoryTileDesc,
                onTap: _clearChatHistory,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
