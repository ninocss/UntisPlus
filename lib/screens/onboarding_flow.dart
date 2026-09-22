part of '../main.dart';

// --- LOGIN SEITE ---

class OnboardingFlow extends StatefulWidget {
  /// Account-only mode is used from settings: it deliberately skips language,
  /// appearance and AI setup so adding a second login is a short flow.
  final bool accountOnly;

  const OnboardingFlow({super.key, this.accountOnly = false});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int get _totalOnboardingSteps => widget.accountOnly ? 1 : 5;
  static const String _credentialModePassword = 'password';
  static const String _credentialModeLoginKey = 'loginKey';
  int _currentPage = 0;

  final _serverController = TextEditingController();
  final _schoolController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorController = TextEditingController();
  final _aiApiKeyController = TextEditingController();
  final _aiCustomBaseUrlController = TextEditingController();
  final _schoolSearchFocusNode = FocusNode();

  late String _onboardingAiProvider;
  late String _onboardingAiModel;
  late String _onboardingAiCustomCompatibility;
  Map<String, String> _onboardingProviderApiKeys = {};

  bool _isLogginIn = false;
  bool _requiresTwoFactor = false;
  bool _manualSchoolEntry = false;
  bool _isSearching = false;
  bool _useLoginKey = false;
  bool _localModelDownloading = false;
  double _localModelDownloadProgress = 0;
  String? _localModelDownloadError;
  CancelToken? _localModelDownloadToken;
  String? _inlineError;
  List<SchoolSearchResult> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _onboardingAiProvider = _normalizeAiProvider(aiProvider);
    _onboardingAiCustomCompatibility = _normalizeAiCustomCompatibility(
      aiCustomCompatibility,
    );
    _onboardingAiModel = aiModel;
    _onboardingProviderApiKeys = {
      'gemini': geminiApiKey,
      'openai': openAiApiKey,
      'mistral': mistralApiKey,
      'custom': customAiApiKey,
    };
    final models = _modelsForProvider(
      _onboardingAiProvider,
      customCompatibility: _onboardingAiCustomCompatibility,
    );
    if (!models.contains(_onboardingAiModel)) {
      _onboardingAiModel = _defaultModelForProvider(
        _onboardingAiProvider,
        customCompatibility: _onboardingAiCustomCompatibility,
      );
    }
    _aiCustomBaseUrlController.text = aiCustomBaseUrl;
    _syncApiKeyControllerForProvider();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _useLoginKey =
            prefs.getString('loginCredentialMode') == _credentialModeLoginKey;
      });
      if (!widget.accountOnly) {
        final saved = (prefs.getInt('onboardingCheckpoint') ?? 0).clamp(
          0,
          _totalOnboardingSteps - 1,
        );
        final canPassLogin =
            activeUntisAccountId != null || demoModeNotifier.value;
        final restored = saved > 2 && !canPassLogin ? 2 : saved;
        if (restored != _currentPage) {
          _currentPage = restored;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(restored);
            }
          });
        }
      }
    });
  }

  void _onPageChanged(int page) {
    if (mounted && (_currentPage != page || _inlineError != null)) {
      setState(() {
        _currentPage = page;
        _inlineError = null;
      });
    }
    if (!widget.accountOnly && page == 2) {
      _schoolSearchFocusNode.requestFocus();
    }
    if (!widget.accountOnly) {
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setInt('onboardingCheckpoint', page),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _schoolSearchFocusNode.dispose();
    _serverController.dispose();
    _schoolController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    _aiApiKeyController.dispose();
    _aiCustomBaseUrlController.dispose();
    _localModelDownloadToken?.cancel('Onboarding closed');
    _debounce?.cancel();
    super.dispose();
  }

  String _providerLabel(AppL10n l, String provider) {
    switch (_normalizeAiProvider(provider)) {
      case 'openai':
        return l.settingsAiProviderOpenAi;
      case 'mistral':
        return l.settingsAiProviderMistral;
      case 'custom':
        return l.settingsAiProviderCustom;
      case 'local':
        return l.settingsAiProviderLocal;
      case 'gemini':
      default:
        return l.settingsAiProviderGemini;
    }
  }

  String _compatibilityLabel(AppL10n l, String value) {
    return _normalizeAiCustomCompatibility(value) == 'gemini'
        ? l.settingsAiCompatibilityGemini
        : l.settingsAiCompatibilityOpenAi;
  }

  String _apiKeyHintForProvider(String provider) {
    switch (_normalizeAiProvider(provider)) {
      case 'openai':
        return 'sk-...';
      case 'mistral':
        return 'mistral-...';
      case 'custom':
        return 'token-...';
      case 'local':
        return '';
      case 'gemini':
      default:
        return 'AIza...';
    }
  }

  String _apiKeyPortalUrlForProvider(String provider) {
    switch (_normalizeAiProvider(provider)) {
      case 'openai':
        return 'https://platform.openai.com/api-keys';
      case 'mistral':
        return 'https://console.mistral.ai/api-keys/';
      case 'gemini':
        return 'https://aistudio.google.com/app/apikey';
      case 'custom':
      default:
        return '';
    }
  }

  void _cacheCurrentProviderApiKey() {
    if (_onboardingAiProvider == 'local') return;
    _onboardingProviderApiKeys[_onboardingAiProvider] = _aiApiKeyController.text
        .trim();
  }

  void _syncApiKeyControllerForProvider() {
    final key = _onboardingProviderApiKeys[_onboardingAiProvider] ?? '';
    _aiApiKeyController.text = key;
    _aiApiKeyController.selection = TextSelection.collapsed(
      offset: _aiApiKeyController.text.length,
    );
  }

  LocalModelInfo get _selectedLocalModel {
    return kLocalModels.firstWhere(
      (model) => model.id == _onboardingAiModel,
      orElse: _defaultLocalModel,
    );
  }

  Future<String> _onboardingLocalModelPath(LocalModelInfo model) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${model.url.split('/').last}';
  }

  Future<bool> _isValidOnboardingLocalModel(
    String path,
    LocalModelInfo model,
  ) async {
    return _isValidLocalModelFile(path, model: model);
  }

  Future<void> _downloadSelectedLocalModel() async {
    if (_localModelDownloading) return;
    final model = _selectedLocalModel;
    final path = await _onboardingLocalModelPath(model);
    final partialPath = '$path.part';

    if (await _isValidOnboardingLocalModel(path, model)) {
      aiLocalModelPath = path;
      if (mounted) setState(() => _localModelDownloadProgress = 1);
      return;
    }

    for (final stalePath in [path]) {
      final stale = File(stalePath);
      if (await stale.exists()) await stale.delete();
    }

    final token = CancelToken();
    _localModelDownloadToken = token;
    setState(() {
      _localModelDownloading = true;
      _localModelDownloadProgress = 0;
      _localModelDownloadError = null;
    });

    try {
      final expectedBytes = (model.sizeGb * 1024 * 1024 * 1024).toInt();
      await _downloadLocalModelFile(
        url: model.url,
        targetPath: partialPath,
        cancelToken: token,
        expectedBytes: expectedBytes,
        onProgress: (received, total) {
          if (!mounted || total <= 0 || token.isCancelled) return;
          setState(() => _localModelDownloadProgress = received / total);
        },
      );
      if (!await _isValidOnboardingLocalModel(partialPath, model) ||
          !await _verifyLocalModelChecksum(partialPath, model)) {
        // Corrupt or tampered file must not be promoted or resumed later.
        await File(partialPath).delete();
        throw Exception('GGUF verification failed');
      }
      await File(partialPath).rename(path);
      aiLocalModelPath = path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aiLocalModelPath', path);
      if (mounted) {
        setState(() {
          _localModelDownloading = false;
          _localModelDownloadProgress = 1;
        });
      }
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        if (await File(partialPath).exists()) {
          await File(partialPath).delete();
        }
      }
      if (!mounted) return;
      setState(() {
        _localModelDownloading = false;
        if (error.type != DioExceptionType.cancel) {
          _localModelDownloadError = error.message;
          _localModelDownloadProgress = -1;
        }
      });
    } catch (error) {
      if (await File(partialPath).exists()) await File(partialPath).delete();
      if (!mounted) return;
      setState(() {
        _localModelDownloading = false;
        _localModelDownloadError = error.toString();
        _localModelDownloadProgress = -1;
      });
    } finally {
      _localModelDownloadToken = null;
    }
  }

  void _cancelLocalModelDownload() {
    _localModelDownloadToken?.cancel('User cancelled');
    if (mounted) {
      setState(() {
        _localModelDownloading = false;
        _localModelDownloadProgress = 0;
        _localModelDownloadError = null;
      });
    }
  }

  Future<void> _openApiKeyPortal() async {
    final l = appL10nFor(appLocaleNotifier.value);
    final url = _apiKeyPortalUrlForProvider(_onboardingAiProvider);
    if (url.isEmpty) return;
    final ok = await url_launcher.launchUrlString(
      url,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsAiApiKeyOpenFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showOnboardingAiProviderDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    if (_localModelDownloading) {
      _showError(l.settingsAiLocalModelDownloading);
      return;
    }
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiProvider,
      options: kSupportedAiProviders
          .map(
            (provider) => _SheetOption(
              value: provider,
              title: _providerLabel(l, provider),
              icon: provider == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : provider == 'openai'
                  ? Icons.chat_bubble_outline_rounded
                  : provider == 'mistral'
                  ? Icons.cloud_rounded
                  : provider == 'local'
                  ? Icons.memory_rounded
                  : Icons.settings_ethernet_rounded,
              selected: _onboardingAiProvider == provider,
            ),
          )
          .toList(),
    ).then((value) {
      if (value == null) return;
      _cacheCurrentProviderApiKey();
      setState(() {
        _onboardingAiProvider = _normalizeAiProvider(value);
        final models = _modelsForProvider(
          _onboardingAiProvider,
          customCompatibility: _onboardingAiCustomCompatibility,
        );
        if (!models.contains(_onboardingAiModel)) {
          _onboardingAiModel = models.first;
        }
        _localModelDownloadProgress = 0;
        _localModelDownloadError = null;
        _syncApiKeyControllerForProvider();
      });
    });
  }

  void _showOnboardingAiModelDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    if (_localModelDownloading) {
      _showError(l.settingsAiLocalModelDownloading);
      return;
    }
    final models = _modelsForProvider(
      _onboardingAiProvider,
      customCompatibility: _onboardingAiCustomCompatibility,
    );
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiModel,
      options: models
          .map(
            (model) => _SheetOption(
              value: model,
              title: _onboardingAiProvider == 'local'
                  ? kLocalModels.firstWhere((entry) => entry.id == model).name
                  : model,
              icon: Icons.memory_rounded,
              selected: _onboardingAiModel == model,
            ),
          )
          .toList(),
    ).then((value) {
      if (value == null) return;
      setState(() {
        _onboardingAiModel = value;
        _localModelDownloadProgress = 0;
        _localModelDownloadError = null;
      });
    });
  }

  void _showOnboardingAiCompatibilityDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUnifiedOptionSheet<String>(
      context: context,
      title: l.settingsAiCompatibility,
      options: kSupportedAiCustomCompatibilities
          .map(
            (compat) => _SheetOption(
              value: compat,
              title: _compatibilityLabel(l, compat),
              icon: compat == 'gemini'
                  ? Icons.auto_awesome_rounded
                  : Icons.chat_rounded,
              selected: _onboardingAiCustomCompatibility == compat,
            ),
          )
          .toList(),
    ).then((value) {
      if (value == null) return;
      setState(() {
        _onboardingAiCustomCompatibility = _normalizeAiCustomCompatibility(
          value,
        );
        final models = _modelsForProvider(
          _onboardingAiProvider,
          customCompatibility: _onboardingAiCustomCompatibility,
        );
        if (!models.contains(_onboardingAiModel)) {
          _onboardingAiModel = models.first;
        }
      });
    });
  }

  void _showOnboardingAiCustomBaseUrlDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    final ctrl = TextEditingController(text: _aiCustomBaseUrlController.text);
    _showUnifiedSheet<void>(
      context: context,
      isScrollControlled: true,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
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
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsAiCustomBaseUrl,
                  style: untisThemeTextStyle(
                    context,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiCustomBaseUrlDesc,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  style: untisThemeTextStyle(context, fontSize: 14),
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
                      child: Text(
                        l.cancel,
                        style: untisThemeTextStyle(
                          context,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _aiCustomBaseUrlController.text = ctrl.text.trim();
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        l.save,
                        style: untisThemeTextStyle(
                          context,
                          fontWeight: FontWeight.w700,
                        ),
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

  void _showOnboardingAiPromptDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
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
          final cs = Theme.of(ctx).colorScheme;
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
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsAiPromptEditTitle,
                  style: untisThemeTextStyle(
                    context,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiPromptDesc,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 260,
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
                      child: Text(
                        l.cancel,
                        style: untisThemeTextStyle(
                          context,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ctrl.text = defaultTemplate;
                      },
                      child: Text(
                        l.settingsAiPromptReset,
                        style: untisThemeTextStyle(
                          context,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        aiSystemPromptTemplate = ctrl.text.trim();
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        l.save,
                        style: untisThemeTextStyle(
                          context,
                          fontWeight: FontWeight.w700,
                        ),
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

  void _showOnboardingAiVariablesDialog() {
    final l = appL10nFor(appLocaleNotifier.value);
    _showUnifiedSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsAiPromptVariables,
                  style: untisThemeTextStyle(
                    context,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.settingsAiPromptVariablesDesc,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
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
                              style: untisThemeTextStyle(
                                context,
                                fontSize: 12.5,
                              ),
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
                    child: Text(
                      l.cancel,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w700,
                      ),
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

  Future<void> _persistOnboardingAiConfiguration() async {
    _cacheCurrentProviderApiKey();
    aiProvider = _normalizeAiProvider(_onboardingAiProvider);
    aiCustomCompatibility = _normalizeAiCustomCompatibility(
      _onboardingAiCustomCompatibility,
    );
    aiModel = _onboardingAiModel;
    aiCustomBaseUrl = _aiCustomBaseUrlController.text.trim();
    geminiApiKey = _onboardingProviderApiKeys['gemini'] ?? '';
    openAiApiKey = _onboardingProviderApiKeys['openai'] ?? '';
    mistralApiKey = _onboardingProviderApiKeys['mistral'] ?? '';
    customAiApiKey = _onboardingProviderApiKeys['custom'] ?? '';

    final prefs = await SharedPreferences.getInstance();
    await saveAiProviderPreferences(prefs);
  }

  Future<void> _nextPage() async {
    FocusScope.of(context).unfocus();
    if (!widget.accountOnly && _currentPage == 3) {
      await _persistOnboardingAiConfiguration();
      if (!mounted) return;
    }
    if (_currentPage < _totalOnboardingSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 560),
        curve: _kSmoothBounce,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 480),
        curve: _kSoftBounce,
      );
    }
  }

  Future<void> _handleLogin() async {
    HapticFeedback.heavyImpact();
    final l = appL10nFor(appLocaleNotifier.value);

    if (_serverController.text.trim().isEmpty ||
        _schoolController.text.trim().isEmpty ||
        _userController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError(l.loginFailed);
      return;
    }
    setState(() {
      _isLogginIn = true;
      _inlineError = null;
    });

    schoolUrl = _serverController.text;
    schoolName = _schoolController.text;

    try {
      final authResult = await _authenticateUntis(
        user: _userController.text,
        password: _passwordController.text,
        client: 'UntisPlus',
        requestId: '1',
        otp: _requiresTwoFactor ? _twoFactorController.text.trim() : null,
        useLoginKey: _useLoginKey,
      );

      if (authResult != null) {
        if (authResult['requires2fa'] == true) {
          if (mounted) setState(() => _requiresTwoFactor = true);
          _showError(l.loginTwoFactorRequired);
          return;
        }

        if (authResult['otpInvalid'] == true) {
          if (mounted) setState(() => _requiresTwoFactor = true);
          _showError(l.loginTwoFactorInvalid);
          return;
        }

        sessionID = authResult['sessionId']?.toString() ?? "";

        var rawId = authResult['personId'];
        var rawType = authResult['personType'];

        if (rawId != null && rawId.toString() != "0") {
          personId = int.tryParse(rawId.toString()) ?? 0;
          personType = int.tryParse(rawType.toString()) ?? 5;
        } else if (authResult['klasseId'] != null) {
          personId = int.tryParse(authResult['klasseId'].toString()) ?? 0;
          personType = 1;
        } else {
          personId = 0;
          personType = 5;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('schoolUrl', schoolUrl);
        await prefs.setString('schoolName', schoolName);
        await prefs.setString('username', _userController.text);
        await prefs.setInt('personType', personType);
        await prefs.setInt('personId', personId);
        await prefs.setBool('demoMode', false);
        demoModeNotifier.value = false;
        await saveOrUpdateUntisAccount(
          username: _userController.text,
          password: _passwordController.text,
          credentialMode: _useLoginKey
              ? _credentialModeLoginKey
              : _credentialModePassword,
        );

        updateUntisData().catchError((_) => false);

        if (!mounted) return;
        if (widget.accountOnly) {
          Navigator.of(context).pushAndRemoveUntil(
            _buildBouncyRoute(const MainNavigationScreen()),
            (route) => false,
          );
        } else {
          await prefs.setInt('onboardingCheckpoint', 3);
          _nextPage();
        }
      } else {
        _showError(l.loginFailed);
      }
    } catch (e) {
      _showError('${l.loginConnectionError}: $e');
    } finally {
      if (mounted) setState(() => _isLogginIn = false);
    }
  }

  Future<void> _activateDemoMode() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    demoModeNotifier.value = true;
    schoolName = 'demo.school';
    schoolUrl = 'demo.school';
    personType = DemoModeService.demoPersonType;
    personId = DemoModeService.demoPersonId;
    sessionID = '';

    await prefs.setBool('demoMode', true);
    await prefs.setString('schoolName', schoolName);
    await prefs.setString('schoolUrl', schoolUrl);
    await prefs.setInt('personType', personType);
    await prefs.setInt('personId', personId);
    await prefs.remove('sessionId');
    await prefs.setInt('onboardingCheckpoint', 3);

    if (mounted) _nextPage();
  }

  void _showError(String msg) {
    if (mounted) setState(() => _inlineError = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            _expressiveRadius(context, 16, expressiveRadius: 24),
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await _persistOnboardingAiConfiguration();

    await prefs.setBool('onboardingCompleted', true);
    await prefs.setBool('tutorialCompleted', false);
    await prefs.setInt('onboardingVersion', kCurrentOnboardingVersion);
    await prefs.setInt('tutorialVersionCompleted', 0);
    await prefs.remove('onboardingCheckpoint');

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _buildBouncyRoute(const MainNavigationScreen(showTutorialOnStart: true)),
    );
  }

  String _backgroundStyleLabel(AppL10n l, int style) {
    switch (style) {
      case 1:
        return l.settingsBackgroundStyleSpace;
      case 2:
        return l.settingsBackgroundStyleBubbles;
      case 3:
        return l.settingsBackgroundStyleLines;
      case 4:
        return l.settingsBackgroundStyleThreeD;
      case 5:
        return l.settingsBackgroundStyleNebula;
      case 6:
        return l.settingsBackgroundStylePrism;
      case 7:
        return l.settingsBackgroundStyleWaves;
      case 8:
        return l.settingsBackgroundStyleGrid;
      case 9:
        return l.settingsBackgroundStyleRings;
      case 10:
        return l.settingsBackgroundStyleCustom;
      default:
        return l.settingsBackgroundStyleOrbs;
    }
  }

  IconData _backgroundStyleIcon(int style) {
    switch (style) {
      case 1:
        return Icons.nightlight_round;
      case 2:
        return Icons.bubble_chart_rounded;
      case 3:
        return Icons.show_chart_rounded;
      case 4:
        return Icons.view_in_ar_rounded;
      case 5:
        return Icons.cloud_rounded;
      case 6:
        return Icons.change_history_rounded;
      case 7:
        return Icons.waves_rounded;
      case 8:
        return Icons.grid_on_rounded;
      case 9:
        return Icons.radio_button_checked_rounded;
      case 10:
        return Icons.wallpaper_rounded;
      default:
        return Icons.blur_circular_rounded;
    }
  }

  Future<void> _setBackgroundAnimationStyle(int style) async {
    final normalized = style.clamp(0, 10);
    backgroundAnimationStyleNotifier.value = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backgroundAnimationStyle', normalized);
  }

  Future<int?> _showBackgroundStylePicker(int currentStyle) {
    final l = appL10nFor(appLocaleNotifier.value);
    final mq = MediaQuery.of(context);
    final safeViewportHeight =
        mq.size.height -
        mq.padding.top -
        mq.padding.bottom -
        mq.viewInsets.bottom;
    final sheetHeight = safeViewportHeight.clamp(340.0, 620.0).toDouble();

    return _showUnifiedSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      child: Builder(
        builder: (sheetContext) {
          final colors = Theme.of(sheetContext).colorScheme;
          final blurOn = blurEnabledNotifier.value;

          return _sheetSurface(
            context: sheetContext,
            blur: blurOn,
            child: SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.settingsBackgroundStyle,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: 11,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final selected = idx == currentStyle;
                          final baseColor = colors.primary;
                          final tileColor = selected
                              ? baseColor.withValues(
                                  alpha: blurOn ? 0.22 : 0.16,
                                )
                              : colors.surfaceContainerHigh.withValues(
                                  alpha: blurOn ? 0.78 : 0.9,
                                );
                          final borderColor = selected
                              ? baseColor.withValues(alpha: 0.55)
                              : colors.outlineVariant.withValues(alpha: 0.5);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(sheetContext, idx);
                              },
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: borderColor,
                                    width: selected ? 1.4 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  minTileHeight: 56,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(
                                        alpha: selected ? 0.24 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      _backgroundStyleIcon(idx),
                                      color: colors.primary.withValues(
                                        alpha: 0.96,
                                      ),
                                      size: 19,
                                    ),
                                  ),
                                  title: Text(
                                    _backgroundStyleLabel(l, idx),
                                    style: untisThemeTextStyle(
                                      context,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 15.2,
                                      color: colors.onSurface.withValues(
                                        alpha: 0.98,
                                      ),
                                    ),
                                  ),
                                  trailing: selected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: colors.primary.withValues(
                                            alpha: 0.98,
                                          ),
                                        )
                                      : Icon(
                                          Icons.chevron_right_rounded,
                                          color: colors.onSurfaceVariant
                                              .withValues(alpha: 0.86),
                                        ),
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _setBlurEnabled(bool enabled) async {
    await _settingsSetBlurEnabled(enabled);
  }

  Future<void> _setBackgroundGyroscopeEnabled(bool enabled) async {
    backgroundGyroscopeNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundGyroscope', enabled);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _currentPage % 2 == 0
                      ? colors.primaryContainer
                      : colors.secondaryContainer,
                  colors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Animated background scene
          ValueListenableBuilder<AppThemeId>(
            valueListenable: visualThemeNotifier,
            builder: (context, theme, _) => ValueListenableBuilder<bool>(
              valueListenable: backgroundAnimationsNotifier,
              builder: (context, enabled, _) {
                if (!enabled ||
                    !appThemeCapabilities(theme).supportsBackgroundMotion) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder<int>(
                  valueListenable: backgroundAnimationStyleNotifier,
                  builder: (context, style, _) =>
                      _AnimatedBackgroundScene(style: style),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Progress header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProgressHeader(colors),
                ),
                if (_inlineError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Material(
                      key: const ValueKey('onboarding-inline-error'),
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: colors.onErrorContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _inlineError!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: untisThemeTextStyle(
                                  context,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onErrorContainer,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _inlineError = null),
                              icon: Icon(
                                Icons.close_rounded,
                                color: colors.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      if (widget.accountOnly)
                        _buildLoginStep()
                      else ...[
                        _buildLanguageStep(),
                        _buildThemeStep(),
                        _buildLoginStep(),
                        _buildGeminiStep(),
                        _buildTutorialStep(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _currentPage > 0 ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                onPressed: _currentPage > 0 ? _previousPage : null,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: List.generate(_totalOnboardingSteps, (index) {
                final isActive = index == _currentPage;
                final isDone = index < _currentPage;
                return Expanded(
                  flex: isActive ? 3 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: _kSmoothBounce,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.primary
                          : isDone
                          ? colors.primary.withValues(alpha: 0.55)
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${_currentPage + 1}/$_totalOnboardingSteps',
              style: untisThemeTextStyle(
                context,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageStep() {
    final l = appL10nFor(appLocaleNotifier.value);
    const langs = [
      ('de', 'Deutsch', '🇩🇪'),
      ('en', 'English', '🇬🇧'),
      ('fr', 'Français', '🇫🇷'),
      ('es', 'Español', '🇪🇸'),
    ];

    return _StepWrapper(
      icon: Icons.language_rounded,
      title: l.onboardingWelcomeTitle,
      subtitle: l.onboardingChooseLanguageSubtitle,
      content: ValueListenableBuilder<String>(
        valueListenable: appLocaleNotifier,
        builder: (context, currentLang, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                for (final (code, name, flag) in langs) ...[
                  _buildLangBtn(code, name, flag, currentLang),
                  if (code != 'el') const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
      footer: _buildNextBtn(),
    );
  }

  Widget _buildLangBtn(String code, String name, String flag, String current) {
    final colors = Theme.of(context).colorScheme;
    final isSel = current == code;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          await ensureDateFormattingForLocale(code);
          if (!mounted) return;
          appLocaleNotifier.value = code;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('appLocale', code);
          unawaited(WidgetService.publishNativeCopy(code));
          unawaited(AlarmService.instance.refreshNativeCopy());
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSel
                ? colors.primaryContainer.withValues(alpha: 0.9)
                : colors.surfaceContainerHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel
                  ? colors.primary.withValues(alpha: 0.8)
                  : colors.outlineVariant.withValues(alpha: 0.5),
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Flag in a subtle rounded container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSel
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(flag, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 16,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? colors.onPrimaryContainer : colors.onSurface,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSel
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('check'),
                        color: colors.primary,
                        size: 22,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('empty'),
                        color: colors.outlineVariant,
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeStep() {
    final l = appL10nFor(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;

    return _StepWrapper(
      icon: Icons.palette_rounded,
      title: l.onboardingAppearanceTitle,
      subtitle: l.onboardingAppearanceSubtitle,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionLabel(l.settingsVisualTheme, colors),
            const SizedBox(height: 8),
            ValueListenableBuilder<AppThemeId>(
              valueListenable: visualThemeNotifier,
              builder: (context, selected, _) => Column(
                children: [
                  _buildThemeLivePreview(l, selected, colors),
                  const SizedBox(height: 10),
                  _buildOnboardingThemePicker(l, selected, colors),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Theme mode section
            _buildSectionLabel(l.settingsThemeMode, colors),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, val, _) => _buildThemeModeRow(l, val, colors),
            ),
            ValueListenableBuilder<AppThemeId>(
              valueListenable: visualThemeNotifier,
              builder: (context, theme, _) {
                final capabilities = appThemeCapabilities(theme);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (capabilities.supportsBackgroundMotion) ...[
                      const SizedBox(height: 18),
                      _buildSectionLabel(
                        l.settingsBackgroundAnimations,
                        colors,
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: backgroundAnimationsNotifier,
                        builder: (context, animEnabled, _) => Column(
                          children: [
                            _buildToggleTile(
                              icon: Icons.animation_rounded,
                              title: l.settingsBackgroundAnimations,
                              subtitle: l.settingsBackgroundAnimationsDesc,
                              value: animEnabled,
                              onChanged: (nv) async {
                                backgroundAnimationsNotifier.value = nv;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('backgroundAnimations', nv);
                              },
                              colors: colors,
                            ),
                            const SizedBox(height: 8),
                            AnimatedOpacity(
                              opacity: animEnabled ? 1.0 : 0.45,
                              duration: const Duration(milliseconds: 250),
                              child: IgnorePointer(
                                ignoring: !animEnabled,
                                child: Column(
                                  children: [
                                    ValueListenableBuilder<int>(
                                      valueListenable:
                                          backgroundAnimationStyleNotifier,
                                      builder: (context, style, _) =>
                                          _buildChevronTile(
                                            icon: _backgroundStyleIcon(style),
                                            title: l.settingsBackgroundStyle,
                                            subtitle: _backgroundStyleLabel(
                                              l,
                                              style,
                                            ),
                                            onTap: () async {
                                              final selected =
                                                  await _showBackgroundStylePicker(
                                                    style,
                                                  );
                                              if (selected != null) {
                                                await _setBackgroundAnimationStyle(
                                                  selected,
                                                );
                                              }
                                            },
                                            colors: colors,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<bool>(
                                      valueListenable:
                                          backgroundGyroscopeNotifier,
                                      builder: (context, val, _) =>
                                          _buildToggleTile(
                                            icon: Icons.screen_rotation_rounded,
                                            title:
                                                l.settingsBackgroundGyroscope,
                                            subtitle: l
                                                .settingsBackgroundGyroscopeDesc,
                                            value: val,
                                            onChanged:
                                                _setBackgroundGyroscopeEnabled,
                                            colors: colors,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (capabilities.supportsBlur) ...[
                      const SizedBox(height: 18),
                      _buildSectionLabel(l.settingsGlassEffect, colors),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: blurEnabledNotifier,
                        builder: (context, val, _) => _buildToggleTile(
                          icon: Icons.blur_on_rounded,
                          title: l.settingsGlassEffect,
                          subtitle: l.settingsGlassEffectDesc,
                          value: val,
                          onChanged: _setBlurEnabled,
                          colors: colors,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      footer: _buildNextBtn(),
    );
  }

  Widget _buildSectionLabel(String text, ColorScheme colors) {
    return Text(
      text.toUpperCase(),
      style: untisThemeTextStyle(
        context,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: colors.primary.withValues(alpha: 0.75),
      ),
    );
  }

  List<Color> _onboardingThemeColors(AppThemeId theme) => switch (theme) {
    AppThemeId.defaultTheme => const [Color(0xFF0F766E), Color(0xFFD5F5EF)],
    AppThemeId.manga => const [Color(0xFFF4ECDD), Color(0xFF17120C)],
    AppThemeId.glass => const [Color(0xFF2A63D5), Color(0xFF8DE2D0)],
    AppThemeId.cyber => const [Color(0xFF071015), Color(0xFF6EEAF2)],
  };

  String _onboardingThemeName(AppL10n l, AppThemeId theme) => switch (theme) {
    AppThemeId.defaultTheme => l.themeDefault,
    AppThemeId.manga => l.themeManga,
    AppThemeId.glass => l.themeGlass,
    AppThemeId.cyber => l.themeCyber,
  };

  Widget _buildThemeLivePreview(
    AppL10n l,
    AppThemeId theme,
    ColorScheme colors,
  ) {
    final preview = _onboardingThemeColors(theme);
    final sharp = theme == AppThemeId.manga || theme == AppThemeId.cyber;
    final radius = sharp ? 4.0 : 22.0;
    return AnimatedContainer(
      key: const ValueKey('onboarding-theme-preview'),
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 280),
      height: 132,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: preview,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.42),
          width: sharp ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _onboardingThemeName(l, theme),
                  style: untisThemeTextStyle(
                    context,
                    display: true,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome_rounded, color: colors.primary),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(sharp ? 2 : 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(sharp ? 2 : 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingThemePicker(
    AppL10n l,
    AppThemeId selected,
    ColorScheme colors,
  ) {
    return ResponsiveFixedGrid(
      itemCount: AppThemeId.values.length,
      mainAxisExtent: 64,
      spacing: 8,
      itemBuilder: (context, index) {
        final theme = AppThemeId.values[index];
        final active = theme == selected;
        final preview = _onboardingThemeColors(theme);
        final sharp = theme == AppThemeId.manga || theme == AppThemeId.cyber;
        return Semantics(
          selected: active,
          button: true,
          label: _onboardingThemeName(l, theme),
          child: InkWell(
            key: ValueKey('onboarding-theme-${theme.storageKey}'),
            onTap: () {
              HapticFeedback.selectionClick();
              unawaited(_settingsSetVisualTheme(theme));
            },
            borderRadius: BorderRadius.circular(sharp ? 3 : 14),
            child: AnimatedContainer(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(sharp ? 3 : 14),
                border: Border.all(
                  color: active ? colors.primary : colors.outlineVariant,
                  width: active ? 2 : 1,
                ),
                boxShadow: active && sharp
                    ? [
                        BoxShadow(
                          color: preview.last.withValues(alpha: 0.72),
                          offset: const Offset(3, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: preview,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(sharp ? 1 : 10),
                      border: sharp
                          ? Border.all(color: preview.last, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      theme == AppThemeId.glass
                          ? Icons.water_drop_rounded
                          : Icons.palette_rounded,
                      color: preview.last.computeLuminance() > 0.55
                          ? Colors.black87
                          : Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _onboardingThemeName(l, theme),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (active)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: colors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeRow(AppL10n l, ThemeMode val, ColorScheme colors) {
    final modes = [
      (ThemeMode.light, Icons.light_mode_rounded, l.settingsThemeLight),
      (ThemeMode.system, Icons.brightness_auto_rounded, l.settingsThemeSystem),
      (ThemeMode.dark, Icons.dark_mode_rounded, l.settingsThemeDark),
    ];
    return Row(
      children: modes.map((m) {
        final (mode, icon, label) = m;
        final selected = val == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: mode == ThemeMode.dark ? 0 : 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  themeModeNotifier.value = mode;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('themeMode', mode.index);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer.withValues(alpha: 0.85)
                        : colors.surfaceContainerHigh.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.7)
                          : colors.outlineVariant.withValues(alpha: 0.4),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: untisThemeTextStyle(
                          context,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevronTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: untisThemeTextStyle(
                        context,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: untisThemeTextStyle(
                        context,
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginStep() {
    final l = appL10nFor(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;

    Widget content;
    Widget footer;
    if (!_manualSchoolEntry && _schoolController.text.isEmpty) {
      // School search view
      content = Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: TextField(
              focusNode: _schoolSearchFocusNode,
              style: untisThemeTextStyle(context, fontSize: 15),
              decoration: InputDecoration(
                hintText: l.loginSearchHint,
                hintStyle: untisThemeTextStyle(
                  context,
                  color: colors.onSurfaceVariant,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 600), () {
                  if (!mounted) return;
                  _searchSchool(val);
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh.withValues(
                              alpha: 0.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            size: 36,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.loginNoSchoolsFound,
                          style: untisThemeTextStyle(
                            context,
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, $2) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final s = _searchResults[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _schoolController.text = s.loginName;
                              _serverController.text = s.serverUrl;
                              _searchResults = [];
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHigh.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer.withValues(
                                      alpha: 0.7,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 18,
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.displayName,
                                        style: untisThemeTextStyle(
                                          context,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        s.address.isNotEmpty
                                            ? s.address
                                            : s.loginName,
                                        style: untisThemeTextStyle(
                                          context,
                                          fontSize: 12,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                  size: 20,
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
      );
      footer = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _manualSchoolEntry = true),
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: Text(l.loginManualEntry),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    shape: _legacyButtonShape(context, 14),
                  ),
                ),
              ),
              if (!widget.accountOnly) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLogginIn ? null : _activateDemoMode,
                    icon: const Icon(Icons.science_rounded, size: 17),
                    label: Text(l.onboardingUseDemoMode),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      shape: _legacyButtonShape(context, 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!widget.accountOnly) ...[
            const SizedBox(height: 6),
            Text(
              l.onboardingUseDemoModeDesc,
              textAlign: TextAlign.center,
              style: untisThemeTextStyle(
                context,
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    } else {
      // Credentials view
      content = SingleChildScrollView(
        child: Column(
          children: [
            if (!_manualSchoolEntry && _schoolController.text.isNotEmpty) ...[
              // Cleaner school card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: colors.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _schoolController.text,
                            style: untisThemeTextStyle(
                              context,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            _serverController.text,
                            style: untisThemeTextStyle(
                              context,
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      tooltip: l.loginChangeSchool,
                      onPressed: () => setState(() {
                        _schoolController.clear();
                        _serverController.clear();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              _buildField(_serverController, l.loginServer, Icons.dns_rounded),
              const SizedBox(height: 10),
              _buildField(
                _schoolController,
                l.loginSchool,
                Icons.location_city_rounded,
              ),
              const SizedBox(height: 10),
            ],
            _buildField(_userController, l.loginUsername, Icons.person_rounded),
            const SizedBox(height: 10),
            // Credential mode toggle
            Row(
              children: [
                Expanded(
                  child: _buildCredentialModeChip(
                    label: l.loginCredentialModePassword,
                    selected: !_useLoginKey,
                    onTap: () => setState(() => _useLoginKey = false),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCredentialModeChip(
                    label: l.loginCredentialModeLoginKey,
                    selected: _useLoginKey,
                    onTap: () => setState(() => _useLoginKey = true),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildField(
              _passwordController,
              _useLoginKey ? l.loginLoginKey : l.loginPassword,
              Icons.key_rounded,
              obscure: true,
              helperText: _useLoginKey ? l.loginLoginKeyHint : null,
            ),
            if (_requiresTwoFactor) ...[
              const SizedBox(height: 10),
              _buildField(
                _twoFactorController,
                l.loginTwoFactorCode,
                Icons.verified_user_rounded,
                keyboardType: TextInputType.number,
                helperText: l.loginTwoFactorHint,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
              ),
            ],
          ],
        ),
      );
      footer = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          if (_isLogginIn)
            const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            FilledButton(
              onPressed: _handleLogin,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: _legacyButtonShape(context, 18),
              ),
              child: Text(
                _requiresTwoFactor ? l.loginVerifyButton : l.loginButton,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (_manualSchoolEntry) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => setState(() {
                _manualSchoolEntry = false;
                _schoolController.clear();
                _serverController.clear();
              }),
              icon: const Icon(Icons.search_rounded, size: 16),
              label: Text(l.loginSwitchToSearch),
            ),
          ],
        ],
      );
    }

    return _StepWrapper(
      icon: Icons.school_rounded,
      title: l.onboardingSchoolLoginTitle,
      subtitle: l.onboardingSchoolLoginSubtitle,
      content: content,
      footer: footer,
    );
  }

  Widget _buildCredentialModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.85)
                : colors.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.65)
                  : colors.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: untisThemeTextStyle(
              context,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueWithLocalModel() async {
    final l = appL10nFor(appLocaleNotifier.value);
    final model = _selectedLocalModel;
    final path = await _onboardingLocalModelPath(model);
    if (!await _isValidOnboardingLocalModel(path, model)) {
      _showError(l.settingsAiLocalModelDownload);
      return;
    }
    aiLocalModelPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiLocalModelPath', path);
    _nextPage();
  }

  Widget _buildOnboardingLocalModelCard(AppL10n l, ColorScheme colors) {
    final model = _selectedLocalModel;
    return FutureBuilder<bool>(
      future: _onboardingLocalModelPath(
        model,
      ).then((path) => _isValidOnboardingLocalModel(path, model)),
      builder: (context, snapshot) {
        final downloaded = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: downloaded
                ? colors.primaryContainer.withValues(alpha: 0.5)
                : colors.surfaceContainerHigh.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: downloaded ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsAiLocalModel,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      color: colors.onTertiaryContainer,
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
                            context,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        Text(
                          l.settingsAiLocalModelSize(model.sizeGb),
                          style: untisThemeTextStyle(
                            context,
                            fontSize: 12.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (downloaded)
                    Icon(Icons.check_circle_rounded, color: colors.primary),
                ],
              ),
              if (_localModelDownloading) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: _localModelDownloadProgress > 0
                      ? _localModelDownloadProgress
                      : null,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 6),
                Text(
                  '${l.settingsAiLocalModelDownloading} ${(_localModelDownloadProgress * 100).clamp(0, 100).round()}%',
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (_localModelDownloadError != null) ...[
                const SizedBox(height: 10),
                Text(
                  l.settingsAiLocalModelError,
                  style: untisThemeTextStyle(
                    context,
                    fontWeight: FontWeight.w700,
                    color: colors.error,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _localModelDownloading
                    ? OutlinedButton.icon(
                        onPressed: _cancelLocalModelDownload,
                        icon: const Icon(Icons.close_rounded),
                        label: Text(l.cancel),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: downloaded
                            ? null
                            : _downloadSelectedLocalModel,
                        icon: Icon(
                          downloaded
                              ? Icons.download_done_rounded
                              : Icons.download_rounded,
                        ),
                        label: Text(
                          downloaded
                              ? l.settingsAiLocalModelInstalled
                              : l.settingsAiLocalModelDownload,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeminiStep() {
    final l = appL10nFor(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;
    final isCustom = _onboardingAiProvider == 'custom';
    final isLocal = _onboardingAiProvider == 'local';
    final providerPortal = _apiKeyPortalUrlForProvider(_onboardingAiProvider);
    final modelOptions = _modelsForProvider(
      _onboardingAiProvider,
      customCompatibility: _onboardingAiCustomCompatibility,
    );
    final currentModel = modelOptions.contains(_onboardingAiModel)
        ? _onboardingAiModel
        : modelOptions.first;

    return _StepWrapper(
      icon: Icons.auto_awesome_rounded,
      title: l.settingsSectionAI,
      subtitle: l.onboardingGeminiSubtitle,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner – gradient accent card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primaryContainer.withValues(alpha: 0.7),
                    colors.secondaryContainer.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLocal
                              ? l.settingsAiLocalModelDesc
                              : l.settingsAiApiKeyDialogDesc,
                          style: untisThemeTextStyle(
                            context,
                            fontSize: 13.5,
                            color: colors.onSurface.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                        if (providerPortal.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _openApiKeyPortal,
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                            ),
                            label: Text(
                              l.settingsAiApiKeyGet,
                              style: untisThemeTextStyle(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildOnboardingAiOptionTile(
              icon: Icons.smart_toy_rounded,
              title: l.settingsAiProvider,
              subtitle: _providerLabel(l, _onboardingAiProvider),
              onTap: _showOnboardingAiProviderDialog,
            ),
            const SizedBox(height: 8),
            _buildOnboardingAiOptionTile(
              icon: Icons.memory_rounded,
              title: l.settingsAiModel,
              subtitle: isLocal ? _selectedLocalModel.name : currentModel,
              onTap: _showOnboardingAiModelDialog,
            ),
            if (isCustom) ...[
              const SizedBox(height: 8),
              _buildOnboardingAiOptionTile(
                icon: Icons.merge_type_rounded,
                title: l.settingsAiCompatibility,
                subtitle: _compatibilityLabel(
                  l,
                  _onboardingAiCustomCompatibility,
                ),
                onTap: _showOnboardingAiCompatibilityDialog,
              ),
              const SizedBox(height: 8),
              _buildOnboardingAiOptionTile(
                icon: Icons.link_rounded,
                title: l.settingsAiCustomBaseUrl,
                subtitle: _aiCustomBaseUrlController.text.isEmpty
                    ? l.settingsAiCustomBaseUrlHint
                    : _aiCustomBaseUrlController.text,
                onTap: _showOnboardingAiCustomBaseUrlDialog,
              ),
            ],
            const SizedBox(height: 8),
            _buildOnboardingAiOptionTile(
              icon: Icons.edit_note_rounded,
              title: l.settingsAiPrompt,
              subtitle: l.settingsAiPromptDesc,
              onTap: _showOnboardingAiPromptDialog,
            ),
            const SizedBox(height: 8),
            _buildOnboardingAiOptionTile(
              icon: Icons.data_object_rounded,
              title: l.settingsAiPromptVariables,
              subtitle: l.settingsAiPromptVariablesDesc,
              onTap: _showOnboardingAiVariablesDialog,
            ),
            const SizedBox(height: 14),
            if (isLocal)
              _buildOnboardingLocalModelCard(l, colors)
            else
              _buildField(
                _aiApiKeyController,
                '${l.settingsAiApiKey} · ${_providerLabel(l, _onboardingAiProvider)}',
                Icons.key_rounded,
                helperText: _apiKeyHintForProvider(_onboardingAiProvider),
              ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _nextPage,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: _legacyButtonShape(context, 16),
              ),
              child: Text(
                l.onboardingSkip,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () {
                if (isLocal) {
                  _continueWithLocalModel();
                } else if (_aiApiKeyController.text.trim().isNotEmpty) {
                  _nextPage();
                } else {
                  _showError(l.onboardingGeminiEnterKeyOrSkip);
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: _legacyButtonShape(context, 16),
              ),
              child: Text(
                l.onboardingNext,
                style: untisThemeTextStyle(
                  context,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep() {
    final l = appL10nFor(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;

    final features = [
      (
        Icons.calendar_month_rounded,
        l.onboardingFeatureTimetableTitle,
        l.onboardingFeatureTimetableDesc,
        colors.primary,
      ),
      (
        Icons.draw_rounded,
        l.onboardingFeatureExamsTitle,
        l.onboardingFeatureExamsDesc,
        colors.secondary,
      ),
      (
        Icons.auto_awesome_rounded,
        l.onboardingFeatureAiTitle,
        l.onboardingFeatureAiDesc,
        colors.tertiary,
      ),
      (
        Icons.notifications_active_rounded,
        l.onboardingFeatureNotifyTitle,
        l.onboardingFeatureNotifyDesc,
        colors.primary,
      ),
      (
        Icons.system_update_alt_rounded,
        l.onboardingFeatureUpdatesTitle,
        l.onboardingFeatureUpdatesDesc,
        colors.secondary,
      ),
      (
        Icons.backup_rounded,
        l.onboardingFeatureBackupTitle,
        l.onboardingFeatureBackupDesc,
        colors.tertiary,
      ),
    ];

    return _StepWrapper(
      icon: Icons.rocket_launch_rounded,
      title: l.onboardingReadyTitle,
      subtitle: l.onboardingReadySubtitle,
      content: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < features.length; i++) ...[
              _buildFeatureCard(
                icon: features[i].$1,
                title: features[i].$2,
                desc: features[i].$3,
                accentColor: features[i].$4,
                colors: colors,
              ),
              if (i < features.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      footer: FilledButton.icon(
        onPressed: _completeOnboarding,
        icon: const Icon(Icons.check_rounded),
        label: Text(
          l.onboardingFinishSetup,
          style: untisThemeTextStyle(
            context,
            display: true,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 58),
          shape: _legacyButtonShape(context, 18),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color accentColor,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: untisThemeTextStyle(
                    context,
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingAiOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface.withValues(alpha: 0.74),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: ListTile(
            dense: true,
            minVerticalPadding: 0,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.onPrimaryContainer),
            ),
            title: Text(
              title,
              style: untisThemeTextStyle(
                context,
                fontWeight: FontWeight.w700,
                fontSize: 14.2,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: untisThemeTextStyle(
                context,
                fontSize: 12.4,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextBtn([String? lbl, VoidCallback? onTap]) {
    final l = appL10nFor(appLocaleNotifier.value);

    return FilledButton(
      onPressed: onTap ?? _nextPage,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 58),
        shape: _legacyButtonShape(context, 18),
        elevation: 0,
      ),
      child: Text(
        lbl ?? l.onboardingNext,
        style: untisThemeTextStyle(
          context,
          display: true,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _searchSchool(String query) async {
    if (query.length < 3) return;
    final l = appL10nFor(appLocaleNotifier.value);
    setState(() {
      _isSearching = true;
      _searchResults = [];
      _inlineError = null;
    });

    try {
      final url = Uri.parse('https://mobile.webuntis.com/ms/schoolquery2');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": "1",
          "method": "searchSchool",
          "params": [
            {"search": query},
          ],
          "jsonrpc": "2.0",
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['schools'] != null) {
          final list = (data['result']['schools'] as List)
              .map((e) => SchoolSearchResult.fromJson(e))
              .toList();
          if (mounted) setState(() => _searchResults = list);
        }
      } else if (mounted) {
        _showError('${l.loginConnectionError} (${response.statusCode})');
      }
    } catch (_) {
      if (mounted) _showError(l.loginConnectionError);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Widget _buildField(
    TextEditingController c,
    String l,
    IconData i, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? helperText,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: l,
        helperText: helperText,
        counterText: '',
        prefixIcon: Icon(i),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StepWrapper extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget content;
  final Widget? footer;

  const _StepWrapper({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = keyboardOpen || constraints.maxHeight < 680;
        final wide = constraints.maxWidth >= 720 && !keyboardOpen;
        final reduceMotion = mq.disableAnimations;

        Widget header({required bool editorial}) {
          final iconSize = editorial ? 82.0 : (compact ? 52.0 : 64.0);
          final titleSize = editorial ? 34.0 : (compact ? 22.0 : 27.0);
          final textColor = editorial ? cs.onPrimaryContainer : cs.onSurface;
          final secondaryText = editorial
              ? cs.onPrimaryContainer.withValues(alpha: 0.74)
              : cs.onSurfaceVariant;

          final text = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: editorial
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: editorial ? cs.surface.withValues(alpha: 0.55) : null,
                  gradient: editorial
                      ? null
                      : LinearGradient(
                          colors: [cs.primaryContainer, cs.secondaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(
                    editorial ? 26 : iconSize / 3.2,
                  ),
                  border: Border.all(
                    color: editorial
                        ? cs.onPrimaryContainer.withValues(alpha: 0.2)
                        : cs.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  icon,
                  size: editorial ? 38 : (compact ? 24 : 29),
                  color: editorial ? cs.primary : cs.onPrimaryContainer,
                ),
              ),
              SizedBox(height: editorial ? 28 : (compact ? 8 : 12)),
              Text(
                title,
                style: untisThemeTextStyle(
                  context,
                  display: true,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: editorial ? -1.1 : -0.5,
                  color: textColor,
                  height: 1.02,
                ),
                textAlign: editorial ? TextAlign.start : TextAlign.center,
              ),
              SizedBox(height: editorial ? 12 : 5),
              Text(
                subtitle,
                style: untisThemeTextStyle(
                  context,
                  fontSize: editorial ? 16 : (compact ? 13 : 14.5),
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                  height: 1.45,
                ),
                textAlign: editorial ? TextAlign.start : TextAlign.center,
              ),
            ],
          );

          if (!editorial) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                compact ? 10 : 13,
                16,
                compact ? 12 : 15,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.18),
                ),
              ),
              child: text,
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -64,
                    top: -52,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.tertiary.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -42,
                    bottom: -70,
                    child: Transform.rotate(
                      angle: -0.18,
                      child: Container(
                        width: 180,
                        height: 130,
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(36),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Align(alignment: Alignment.centerLeft, child: text),
                  ),
                ],
              ),
            ),
          );
        }

        Widget form() => Column(
          children: [
            Expanded(child: content),
            if (footer != null) ...[
              SizedBox(height: compact ? 6 : 12),
              AnimatedPadding(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardOpen ? 4 : 0),
                child: footer!,
              ),
            ],
          ],
        );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 28 : 20,
                8,
                wide ? 28 : 20,
                20,
              ),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) =>
                                Transform.translate(
                                  offset: Offset(-18 * (1 - value), 0),
                                  child: Opacity(opacity: value, child: child),
                                ),
                            child: header(editorial: true),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow.withValues(
                                alpha: 0.82,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: form(),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        header(editorial: false),
                        SizedBox(height: compact ? 10 : 14),
                        Expanded(child: form()),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
