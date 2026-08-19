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

  @override
  void dispose() {
    _downloadRevision.dispose();
    super.dispose();
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
    aiLocalModelPath = prefs.getString('aiLocalModelPath') ?? aiLocalModelPath;
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

  /// State for local model downloads
  final Map<String, double> _downloadProgress = {};
  final Map<String, CancelToken> _downloadTokens = {};
  final Set<String> _downloadingModels = {};
  final Map<String, DateTime> _lastProgressUpdate = {};
  final Map<String, int> _downloadReceived = {};
  final Map<String, int> _downloadTotal = {};
  final Map<String, int> _lastReceived = {};
  final Map<String, double> _downloadSpeed = {};

  /// Bumped whenever download state changes so the open bottom sheet rebuilds.
  final ValueNotifier<int> _downloadRevision = ValueNotifier<int>(0);

  void _markDownloadStateChanged() {
    _downloadRevision.value++;
  }

  /// Get the local file path for a model
  Future<String> _getLocalModelPath(String modelId) async {
    final dir = await getApplicationDocumentsDirectory();
    final model = kLocalModels.firstWhere((m) => m.id == modelId);
    final fileName = model.url.split('/').last;
    return '${dir.path}/$fileName';
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
  /// context".
  Future<bool> _isValidModelFile(String path,
      {LocalModelInfo? model}) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length < 1024 * 1024) return false;
      if (model != null) {
        final expectedBytes = (model.sizeGb * 1024 * 1024 * 1024).toInt();
        if (length < expectedBytes * 0.6) return false;
      }
      final raf = await file.open();
      try {
        final header = await raf.read(4);
        if (header.length < 4) return false;
        return String.fromCharCodes(header) == 'GGUF';
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// Download a local model
  Future<void> _downloadLocalModel(LocalModelInfo model) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final path = await _getLocalModelPath(model.id);
    
    // Check if already downloading
    if (_downloadingModels.contains(model.id)) return;
    
    // Check if already downloaded and valid
    if (await _isValidModelFile(path, model: model)) {
      setState(() {
        _downloadProgress[model.id] = 1.0;
      });
      _markDownloadStateChanged();
      return;
    }

    // A stale/corrupt file exists — delete it so the fresh download doesn't
    // append to a broken GGUF.
    if (await File(path).exists()) {
      await File(path).delete();
    }

    setState(() {
      _downloadingModels.add(model.id);
      _downloadProgress[model.id] = 0.0;
    });
    _markDownloadStateChanged();

    final cancelToken = CancelToken();
    _downloadTokens[model.id] = cancelToken;

    try {
      final dio = Dio();
      final tempPath = '$path.part';
      await dio.download(
        model.url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (cancelToken.isCancelled) return;
          if (total > 0) {
            final now = DateTime.now();
            final last = _lastProgressUpdate[model.id];
            if (last == null || now.difference(last).inMilliseconds > 200) {
              final lastReceived = _lastReceived[model.id] ?? received;
              final deltaMs = now.difference(last ?? now).inMilliseconds;
              _downloadSpeed[model.id] =
                  deltaMs > 0 ? (received - lastReceived) * 1000 / deltaMs : 0;
              _lastReceived[model.id] = received;
              _lastProgressUpdate[model.id] = now;
              setState(() {
                _downloadProgress[model.id] = received / total;
                _downloadReceived[model.id] = received;
                _downloadTotal[model.id] = total;
              });
              _markDownloadStateChanged();
            }
          }
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {'User-Agent': 'UntisPlus/1.0'},
        ),
      );

      // Verify the downloaded file is a valid GGUF model before promoting it
      // to the final path. A truncated/corrupt download never becomes visible
      // as an "installed" model.
      if (await _isValidModelFile(tempPath, model: model)) {
        if (await File(path).exists()) {
          await File(path).delete();
        }
        await File(tempPath).rename(path);
        final fileLength = await File(path).length();
        setState(() {
          _downloadProgress[model.id] = 1.0;
          _downloadReceived[model.id] = fileLength;
          _downloadTotal[model.id] = fileLength;
          _downloadSpeed.remove(model.id);
          _downloadingModels.remove(model.id);
          _lastProgressUpdate.remove(model.id);
        });
        _markDownloadStateChanged();
      } else {
        await File(tempPath).delete();
        throw Exception('Download verification failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Download was cancelled, clean up partial file
        await File(path).delete();
        await File('$path.part').delete();
      } else {
        await File('$path.part').delete();
        setState(() {
          _downloadProgress[model.id] = -1.0; // Error state
          _downloadSpeed.remove(model.id);
          _downloadingModels.remove(model.id);
          _lastProgressUpdate.remove(model.id);
        });
        _markDownloadStateChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.aiConnectionError} ${e.message}')),
          );
        }
      }
    } catch (e) {
      await File('$path.part').delete();
      setState(() {
        _downloadProgress[model.id] = -1.0;
        _downloadSpeed.remove(model.id);
        _downloadingModels.remove(model.id);
        _lastProgressUpdate.remove(model.id);
      });
      _markDownloadStateChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.aiConnectionError} $e')),
        );
      }
    } finally {
      _downloadTokens.remove(model.id);
      _lastProgressUpdate.remove(model.id);
      _downloadSpeed.remove(model.id);
    }
  }

  /// Cancel a model download
  void _cancelDownload(String modelId) {
    final token = _downloadTokens[modelId];
    if (token != null && !token.isCancelled) {
      token.cancel('User cancelled');
    }
    _downloadingModels.remove(modelId);
    _downloadProgress.remove(modelId);
    _downloadSpeed.remove(modelId);
    _lastReceived.remove(modelId);
    _lastProgressUpdate.remove(modelId);
    _downloadReceived.remove(modelId);
    _downloadTotal.remove(modelId);
    _markDownloadStateChanged();
  }

  /// Delete a downloaded model
  Future<void> _deleteLocalModel(LocalModelInfo model) async {
    final l = AppL10n.of(appLocaleNotifier.value);
    final path = await _getLocalModelPath(model.id);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.errorContainer.withValues(alpha: 0.6),
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
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.settingsApiKeyCancel),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(l.settingsAiLocalModelDelete),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await File(path).delete();
      setState(() {
        _downloadProgress.remove(model.id);
        _downloadReceived.remove(model.id);
        _downloadTotal.remove(model.id);
        _downloadSpeed.remove(model.id);
      });
      _markDownloadStateChanged();
      // If this was the active model, clear the path and revert provider
      if (aiLocalModelPath == path) {
        final prefs = await SharedPreferences.getInstance();
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
    final l = AppL10n.of(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;
          return ValueListenableBuilder<int>(
            valueListenable: _downloadRevision,
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
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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

  /// Build a single local model card with Material You Expressive styling.
  Widget _buildLocalModelCard(
    BuildContext ctx,
    LocalModelInfo model,
    AppL10n l,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    final progress = _downloadProgress[model.id] ?? 0.0;
    final isDownloading = _downloadingModels.contains(model.id);
    final hasError = progress < 0;
    final isActive = aiLocalModelPath.endsWith(model.url.split('/').last);

    return FutureBuilder<bool>(
      future: _isModelDownloaded(model.id),
      builder: (context, snapshot) {
        final downloaded = snapshot.data ?? false;

        final Color cardColor;
        final Border cardBorder;
        if (isActive) {
          cardColor = cs.primaryContainer.withValues(alpha: 0.5);
          cardBorder = Border.all(color: cs.primary.withValues(alpha: 0.55), width: 1.4);
        } else if (hasError) {
          cardColor = cs.errorContainer.withValues(alpha: 0.35);
          cardBorder = Border.all(color: cs.error.withValues(alpha: 0.3), width: 1);
        } else if (isDownloading) {
          cardColor = cs.primaryContainer.withValues(alpha: 0.28);
          cardBorder = Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1);
        } else if (downloaded) {
          cardColor = cs.secondaryContainer.withValues(alpha: 0.32);
          cardBorder = Border.all(color: cs.outlineVariant.withValues(alpha: 0.35), width: 1);
        } else {
          cardColor = cs.surfaceContainerHigh.withValues(alpha: 0.55);
          cardBorder = Border.all(color: cs.outlineVariant.withValues(alpha: 0.35), width: 1);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: cardBorder,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
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
                            model.description,
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
                                '${model.sizeGb.toStringAsFixed(1)} GB',
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
    final BoxDecoration iconDecoration;
    final IconData icon;
    final Color iconColor;

    if (isActive) {
      iconDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
      icon = Icons.check_rounded;
      iconColor = cs.onPrimary;
    } else if (isDownloading) {
      iconDecoration = BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(15),
      );
      icon = Icons.download_rounded;
      iconColor = cs.onPrimaryContainer;
    } else if (downloaded) {
      iconDecoration = BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(15),
      );
      icon = Icons.check_circle_rounded;
      iconColor = cs.onSecondaryContainer;
    } else {
      iconDecoration = BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      );
      icon = Icons.download_rounded;
      iconColor = cs.primary;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: iconDecoration,
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
            Icon(Icons.error_outline_rounded, size: 20, color: cs.onErrorContainer),
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
                        SnackBar(
                          content: Text(l.aiLocalModelLoadError),
                        ),
                      );
                    }
                    return;
                  }
                  final prefs = await SharedPreferences.getInstance();
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
            label: Text(l.settingsAiLocalModelDelete),
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

  /// Expressive download progress bar with percentage, bytes and speed.
  Widget _buildDownloadProgress(
    BuildContext ctx,
    LocalModelInfo model,
    AppL10n l,
    double progress,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    final received = _downloadReceived[model.id] ?? 0;
    final total = _downloadTotal[model.id] ?? 0;
    final speed = _downloadSpeed[model.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.settingsAiLocalModelDownloading,
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    color: cs.surfaceContainerHighest,
                  ),
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.tertiary],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.speed_rounded, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${_formatBytes(speed.round())}/s',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            if (total > 0)
              Text(
                '${_formatBytes(received)} / ${_formatBytes(total)}',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: () => _cancelDownload(model.id),
              tooltip: l.settingsApiKeyCancel,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
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
                          : provider == 'local'
                              ? Icons.memory_rounded
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
    final isLocal = aiProvider == 'local';
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
                if (!isLocal)
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

            // ── GROUP: LOCAL MODEL SETTINGS (only for local provider) ──
            if (isLocal) ...[
              SettingsGroup(
                title: l.settingsAiLocalModel,
                children: [
                  SettingsTile(
                    icon: Icons.download_rounded,
                    iconBackgroundColor: cs.tertiaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    iconColor: cs.onTertiaryContainer,
                    title: l.settingsAiLocalModel,
                    subtitle: l.settingsAiLocalModelDesc,
                    onTap: _showLocalModelDialog,
                  ),
                ],
              ),
            ],

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
