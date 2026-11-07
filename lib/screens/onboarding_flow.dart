part of '../main.dart';

// --- ONBOARDING FLOW (MATERIAL 3 EXPRESSIVE) ---

class OnboardingFlow extends StatefulWidget {
  /// Account-only mode is used from settings: it deliberately skips language,
  /// appearance and AI setup so adding a second login is a short flow.
  final bool accountOnly;

  const OnboardingFlow({super.key, this.accountOnly = false});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final WebUntisLoginRepository _loginRepository = WebUntisLoginRepository();
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
  final _aiCustomBaseUrlController = TextEditingController();

  late String _onboardingAiProvider;
  late String _onboardingAiModel;
  late String _onboardingAiCustomCompatibility;
  Map<String, String> _onboardingProviderApiKeys = {};

  bool _isLogginIn = false;
  bool _requiresTwoFactor = false;
  bool _useLoginKey = false;
  String? _inlineError;

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
    if (_onboardingAiProvider != 'custom' && !models.contains(_onboardingAiModel)) {
      _onboardingAiModel = _defaultModelForProvider(
        _onboardingAiProvider,
        customCompatibility: _onboardingAiCustomCompatibility,
      );
    }
    _aiCustomBaseUrlController.text = aiCustomBaseUrl;

    Future.value(SettingsStore.instance.preferences).then((prefs) {
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
    if (!widget.accountOnly) {
      SettingsStore.instance.preferences.setInt('onboardingCheckpoint', page);
    }
  }

  @override
  void dispose() {
    _loginRepository.close();
    _pageController.dispose();
    _serverController.dispose();
    _schoolController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    _aiCustomBaseUrlController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    FocusScope.of(context).unfocus();
    if (_currentPage < _totalOnboardingSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 40),
        curve: _kSmoothBounce,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      final prev =
          (!widget.accountOnly && _currentPage == 3 && demoModeNotifier.value)
              ? 1
              : _currentPage - 1;
      _pageController.animateToPage(
        prev,
        duration: const Duration(milliseconds: 40),
        curve: _kSoftBounce,
      );
    } else if (widget.accountOnly && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleLogin() async {
    AppHaptics.lightImpact();
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

    schoolUrl = _serverController.text.trim();
    schoolName = _schoolController.text.trim();

    try {
      final authResult = await _loginRepository.authenticate(
        schoolUrl: schoolUrl,
        schoolName: schoolName,
        username: _userController.text.trim(),
        credential: _passwordController.text,
        clientName: 'UntisPlus',
        requestId: '1',
        oneTimeCode: _requiresTwoFactor
            ? _twoFactorController.text.trim()
            : null,
        useLoginKey: _useLoginKey,
      );

      if (authResult.isSuccess) {
        sessionID = authResult.sessionId;

        // Guardian/parent accounts have no timetable of their own; redirect
        // them to their first linked student so the account never stores an
        // element that cannot be fetched.
        final element = _resolveTimetableElementFromAuth(
          authResult.linkedPeople,
          authResult.personId,
          authResult.personType,
        );
        personId = element['personId']! as int;
        personType = element['personType']! as int;

        final prefs = SettingsStore.instance.preferences;
        await prefs.setString('schoolUrl', schoolUrl);
        await prefs.setString('schoolName', schoolName);
        await prefs.setString('username', _userController.text.trim());
        await prefs.setInt('personType', personType);
        await prefs.setInt('personId', personId);
        if (demoModeNotifier.value) _clearTransientSchoolData();
        await prefs.setBool('demoMode', false);
        demoModeNotifier.value = false;
        await saveOrUpdateUntisAccount(
          username: _userController.text.trim(),
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
        switch (authResult.status) {
          case WebUntisLoginStatus.requiresTwoFactor:
            if (mounted) setState(() => _requiresTwoFactor = true);
            _showError(l.loginTwoFactorRequired);
            break;
          case WebUntisLoginStatus.invalidOneTimeCode:
            if (mounted) setState(() => _requiresTwoFactor = true);
            _showError(l.loginTwoFactorInvalid);
            break;
          case WebUntisLoginStatus.failed:
            _showError(l.loginFailed);
            break;
          case WebUntisLoginStatus.success:
            break;
        }
      }
    } catch (e) {
      _showError('${l.loginConnectionError}: $e');
    } finally {
      if (mounted) setState(() => _isLogginIn = false);
    }
  }

  Future<void> _activateDemoMode() async {
    AppHaptics.confirmation();
    final prefs = SettingsStore.instance.preferences;
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
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Future<void> _applyAiSettings(Map<String, dynamic> data) async {
    final provider = data['provider'] as String? ?? 'gemini';
    if (provider == 'disabled') {
      aiProvider = 'gemini';
      geminiApiKey = '';
      openAiApiKey = '';
      mistralApiKey = '';
      customAiApiKey = '';
    } else {
      _onboardingAiProvider = _normalizeAiProvider(provider);
      aiProvider = _onboardingAiProvider;
      _onboardingAiModel = data['model'] as String? ?? _onboardingAiModel;
      aiModel = _onboardingAiModel;
      _onboardingAiCustomCompatibility = _normalizeAiCustomCompatibility(
        data['customCompatibility'] as String? ??
            _onboardingAiCustomCompatibility,
      );
      aiCustomCompatibility = _onboardingAiCustomCompatibility;
      _aiCustomBaseUrlController.text = data['customBaseUrl'] as String? ?? '';
      aiCustomBaseUrl = _aiCustomBaseUrlController.text;
      final keys = data['apiKeys'] as Map<String, String>? ?? {};
      _onboardingProviderApiKeys = Map.from(keys);
      geminiApiKey = keys['gemini'] ?? '';
      openAiApiKey = keys['openai'] ?? '';
      mistralApiKey = keys['mistral'] ?? '';
      customAiApiKey = keys['custom'] ?? '';
    }
    final prefs = SettingsStore.instance.preferences;
    await saveAiProviderPreferences(prefs);
  }

  Future<void> _completeOnboarding() async {
    final prefs = SettingsStore.instance.preferences;
    await saveAiProviderPreferences(prefs);

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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTablet = UntisLayout.isTablet(context);

    return ValueListenableBuilder<String>(
      valueListenable: appLocaleNotifier,
      builder: (context, currentLocale, _) {
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
                          ? colors.primaryContainer.withValues(alpha: 0.35)
                          : colors.secondaryContainer.withValues(alpha: 0.35),
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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Progress header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 28,
                      ),
                      child: M3ExpressiveProgressHeader(
                        currentStep: _currentPage,
                        totalSteps: _totalOnboardingSteps,
                        onBack: _currentPage > 0 ||
                                (widget.accountOnly &&
                                    Navigator.of(context).canPop())
                            ? _previousPage
                            : null,
                      ),
                    ),
                    if (_inlineError != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 32 : 28,
                          8,
                          isTablet ? 32 : 28,
                          0,
                        ),
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
                            SchoolLoginStep(
                              serverController: _serverController,
                              schoolController: _schoolController,
                              userController: _userController,
                              passwordController: _passwordController,
                              twoFactorController: _twoFactorController,
                              isLoggingIn: _isLogginIn,
                              requiresTwoFactor: _requiresTwoFactor,
                              useLoginKey: _useLoginKey,
                              onUseLoginKeyChanged: (val) {
                                setState(() => _useLoginKey = val);
                                SettingsStore.instance.preferences.setString(
                                  'loginCredentialMode',
                                  val
                                      ? _credentialModeLoginKey
                                      : _credentialModePassword,
                                );
                              },
                              onLogin: _handleLogin,
                              onDemoModeSelected: _activateDemoMode,
                              accountOnly: true,
                            )
                          else ...[
                            WelcomeHeroStep(
                              onGetStarted: _nextPage,
                            ),
                            AppearanceStep(
                              onNext: () {
                                if (demoModeNotifier.value) {
                                  _pageController.animateToPage(
                                    3,
                                    duration: const Duration(milliseconds: 40),
                                    curve: _kSmoothBounce,
                                  );
                                } else {
                                  _nextPage();
                                }
                              },
                            ),
                            SchoolLoginStep(
                              serverController: _serverController,
                              schoolController: _schoolController,
                              userController: _userController,
                              passwordController: _passwordController,
                              twoFactorController: _twoFactorController,
                              isLoggingIn: _isLogginIn,
                              requiresTwoFactor: _requiresTwoFactor,
                              useLoginKey: _useLoginKey,
                              onUseLoginKeyChanged: (val) {
                                setState(() => _useLoginKey = val);
                                SettingsStore.instance.preferences.setString(
                                  'loginCredentialMode',
                                  val
                                      ? _credentialModeLoginKey
                                      : _credentialModePassword,
                                );
                              },
                              onLogin: _handleLogin,
                              onDemoModeSelected: _activateDemoMode,
                              accountOnly: false,
                            ),
                            AiCopilotStep(
                              initialProvider: _onboardingAiProvider,
                              initialModel: _onboardingAiModel,
                              initialCustomCompatibility:
                                  _onboardingAiCustomCompatibility,
                              initialApiKeys: _onboardingProviderApiKeys,
                              initialCustomBaseUrl: _aiCustomBaseUrlController.text,
                              onSave: (map) => _applyAiSettings(map),
                              onNext: _nextPage,
                              onSkip: _nextPage,
                            ),
                            FeaturesReadyStep(
                              onComplete: _completeOnboarding,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
