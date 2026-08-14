part of '../main.dart';

// --- LOGIN SEITE ---

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  static const int _totalOnboardingSteps = 5;
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
    _pageController.addListener(_onPageChanged);
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _useLoginKey =
            prefs.getString('loginCredentialMode') == _credentialModeLoginKey;
      });
    });
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? _currentPage;
    if (page == 2) {
      _schoolSearchFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _schoolSearchFocusNode.dispose();
    _serverController.dispose();
    _schoolController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    _aiApiKeyController.dispose();
    _aiCustomBaseUrlController.dispose();
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

  Future<void> _openApiKeyPortal() async {
    final l = AppL10n.of(appLocaleNotifier.value);
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
        _syncApiKeyControllerForProvider();
      });
    });
  }

  void _showOnboardingAiModelDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
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
              title: model,
              icon: Icons.memory_rounded,
              selected: _onboardingAiModel == model,
            ),
          )
          .toList(),
    ).then((value) {
      if (value == null) return;
      setState(() => _onboardingAiModel = value);
    });
  }

  void _showOnboardingAiCompatibilityDialog() {
    final l = AppL10n.of(appLocaleNotifier.value);
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiCustomBaseUrlDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
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
                      child: Text(
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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
                        l.settingsApiKeySave,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsAiPromptDesc,
                  style: GoogleFonts.outfit(
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
                        l.settingsApiKeyCancel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ctrl.text = defaultTemplate;
                      },
                      child: Text(
                        l.settingsAiPromptReset,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        aiSystemPromptTemplate = ctrl.text.trim();
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        l.settingsApiKeySave,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.settingsAiPromptVariablesDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
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
                    child: Text(
                      l.settingsApiKeyCancel,
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

  void _nextPage() {
    FocusScope.of(context).unfocus();
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
    setState(() => _isLogginIn = true);
    final l = AppL10n.of(appLocaleNotifier.value);

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
        await prefs.setString('sessionId', sessionID);
        await prefs.setString('schoolUrl', schoolUrl);
        await prefs.setString('schoolName', schoolName);
        await prefs.setString('username', _userController.text);
        await prefs.setString('password', _passwordController.text);
        await prefs.setString(
          'loginCredentialMode',
          _useLoginKey ? _credentialModeLoginKey : _credentialModePassword,
        );
        await prefs.setInt('personType', personType);
        await prefs.setInt('personId', personId);
        await prefs.setBool('demoMode', false);
        demoModeNotifier.value = false;

        updateUntisData().catchError((_) {});

        if (mounted) _nextPage();
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

    if (mounted) _nextPage();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
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

    await prefs.setString('aiProvider', aiProvider);
    await prefs.setString('aiModel', aiModel);
    await prefs.setString('aiCustomCompatibility', aiCustomCompatibility);
    await prefs.setString('aiCustomBaseUrl', aiCustomBaseUrl);
    await prefs.setString('aiSystemPromptTemplate', aiSystemPromptTemplate);
    await prefs.setString('geminiApiKey', geminiApiKey);
    await prefs.setString('openAiApiKey', openAiApiKey);
    await prefs.setString('mistralApiKey', mistralApiKey);
    await prefs.setString('customAiApiKey', customAiApiKey);

    await prefs.setBool('onboardingCompleted', true);
    await prefs.setBool('tutorialCompleted', false);

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
    final l = AppL10n.of(appLocaleNotifier.value);
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
      child: Builder(builder: (sheetContext) {
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
                    style: GoogleFonts.outfit(
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
                            ? baseColor.withValues(alpha: blurOn ? 0.22 : 0.16)
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
                                  style: GoogleFonts.outfit(
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
      }),
    );
  }

  Future<void> _setBlurEnabled(bool enabled) async {
    blurEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blurEnabled', enabled);
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
          ValueListenableBuilder<bool>(
            valueListenable: backgroundAnimationsNotifier,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: backgroundAnimationStyleNotifier,
                builder: (context, style, _) =>
                    _AnimatedBackgroundScene(style: style),
              );
            },
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
                const SizedBox(height: 8),
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildLanguageStep(),
                      _buildThemeStep(),
                      _buildLoginStep(),
                      _buildGeminiStep(),
                      _buildTutorialStep(),
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
              style: GoogleFonts.outfit(
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
    final l = AppL10n.of(appLocaleNotifier.value);
    const langs = [
      ('de', 'Deutsch', '🇩🇪'),
      ('en', 'English', '🇬🇧'),
      ('fr', 'Français', '🇫🇷'),
      ('es', 'Español', '🇪🇸'),
      ('el', 'Ελληνικά', '🇬🇷'),
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
          appLocaleNotifier.value = code;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('appLocale', code);
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
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight:
                        isSel ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSel ? colors.onPrimaryContainer : colors.onSurface,
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
    final l = AppL10n.of(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;

    return _StepWrapper(
      icon: Icons.palette_rounded,
      title: l.onboardingAppearanceTitle,
      subtitle: l.onboardingAppearanceSubtitle,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Theme mode section
            _buildSectionLabel(l.settingsThemeMode, colors),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, val, _) => _buildThemeModeRow(l, val, colors),
            ),
            const SizedBox(height: 18),
            // Background section
            _buildSectionLabel(l.settingsBackgroundAnimations, colors),
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
                      final prefs = await SharedPreferences.getInstance();
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
                            valueListenable: backgroundAnimationStyleNotifier,
                            builder: (context, style, _) =>
                                _buildChevronTile(
                              icon: _backgroundStyleIcon(style),
                              title: l.settingsBackgroundStyle,
                              subtitle: _backgroundStyleLabel(l, style),
                              onTap: () async {
                                final selected =
                                    await _showBackgroundStylePicker(style);
                                if (selected != null) {
                                  await _setBackgroundAnimationStyle(selected);
                                }
                              },
                              colors: colors,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<bool>(
                            valueListenable: backgroundGyroscopeNotifier,
                            builder: (context, val, _) => _buildToggleTile(
                              icon: Icons.screen_rotation_rounded,
                              title: l.settingsBackgroundGyroscope,
                              subtitle: l.settingsBackgroundGyroscopeDesc,
                              value: val,
                              onChanged: _setBackgroundGyroscopeEnabled,
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              ),
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
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: colors.primary.withValues(alpha: 0.75),
      ),
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
            padding: EdgeInsets.only(
              right: mode == ThemeMode.dark ? 0 : 8,
            ),
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
                        style: GoogleFonts.outfit(
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
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
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
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
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
    final l = AppL10n.of(appLocaleNotifier.value);
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
              style: GoogleFonts.outfit(fontSize: 15),
              decoration: InputDecoration(
                hintText: l.loginSearchHint,
                hintStyle: GoogleFonts.outfit(color: colors.onSurfaceVariant),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search_rounded, color: colors.onSurfaceVariant),
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
                                color: colors.surfaceContainerHigh
                                    .withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                size: 36,
                                color: colors.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.loginNoSchoolsFound,
                              style: GoogleFonts.outfit(
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
                                  color: colors.surfaceContainerHigh
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: colors.outlineVariant
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer
                                            .withValues(alpha: 0.7),
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
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            s.address.isNotEmpty
                                                ? s.address
                                                : s.loginName,
                                            style: GoogleFonts.outfit(
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
                                      color: colors.onSurfaceVariant
                                          .withValues(alpha: 0.6),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLogginIn ? null : _activateDemoMode,
                  icon: const Icon(Icons.science_rounded, size: 17),
                  label: Text(l.onboardingUseDemoMode),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.onboardingUseDemoModeDesc,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
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
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            _serverController.text,
                            style: GoogleFonts.outfit(
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
            _buildField(
              _userController,
              l.loginUsername,
              Icons.person_rounded,
            ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                _requiresTwoFactor ? l.loginVerifyButton : l.loginButton,
                style: GoogleFonts.outfit(
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
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeminiStep() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;
    final isCustom = _onboardingAiProvider == 'custom';
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
                          l.settingsAiApiKeyDialogDesc,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            color: colors.onSurface.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                        if (providerPortal.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _openApiKeyPortal,
                            icon: const Icon(Icons.open_in_new_rounded, size: 14),
                            label: Text(
                              l.settingsAiApiKeyGet,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              subtitle: currentModel,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l.onboardingSkip,
                style: GoogleFonts.outfit(
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
                if (_aiApiKeyController.text.trim().isNotEmpty) {
                  _nextPage();
                } else {
                  _showError(l.onboardingGeminiEnterKeyOrSkip);
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l.onboardingNext,
                style: GoogleFonts.outfit(
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
    final l = AppL10n.of(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;

    final features = [
      (Icons.calendar_month_rounded, l.onboardingFeatureTimetableTitle,
          l.onboardingFeatureTimetableDesc, colors.primary),
      (Icons.draw_rounded, l.onboardingFeatureExamsTitle,
          l.onboardingFeatureExamsDesc, colors.secondary),
      (Icons.auto_awesome_rounded, l.onboardingFeatureAiTitle,
          l.onboardingFeatureAiDesc, colors.tertiary),
      (Icons.notifications_active_rounded, l.onboardingFeatureNotifyTitle,
          l.onboardingFeatureNotifyDesc, colors.primary),
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
          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.74),
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
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 14.2,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: GoogleFonts.outfit(
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
    final l = AppL10n.of(appLocaleNotifier.value);

    return FilledButton(
      onPressed: onTap ?? _nextPage,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: Text(
        lbl ?? l.onboardingNext,
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _searchSchool(String query) async {
    if (query.length < 3) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
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
      }
    } catch (_) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = keyboardOpen || constraints.maxHeight < 680;
          final iconSize = compact ? 52.0 : 68.0;
          final iconInner = compact ? 24.0 : 30.0;
          final titleSize = compact ? 22.0 : 28.0;
          final subtitleSize = compact ? 13.0 : 14.5;
          final topSpacing = compact ? 8.0 : 14.0;
          final sectionSpacing = compact ? 10.0 : 16.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primaryContainer,
                      cs.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(iconSize / 3.2),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  icon,
                  size: iconInner,
                  color: cs.onPrimaryContainer,
                ),
              ),
              SizedBox(height: topSpacing),
              Container(
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
                child: Column(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              // Content
              Expanded(child: content),
              if (footer != null) ...[
                SizedBox(height: compact ? 6 : 10),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardOpen ? 4 : 0),
                  child: footer!,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
