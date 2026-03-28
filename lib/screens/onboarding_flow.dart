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
  int _currentPage = 0;

  final _serverController = TextEditingController();
  final _schoolController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _geminiController = TextEditingController();

  bool _isLogginIn = false;
  bool _manualSchoolEntry = false;
  bool _isSearching = false;
  List<SchoolSearchResult> _searchResults = [];
  Timer? _debounce;

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage < _totalOnboardingSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleLogin() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLogginIn = true);

    schoolUrl = _serverController.text;
    schoolName = _schoolController.text;

    try {
      final authResult = await _authenticateUntis(
        user: _userController.text,
        password: _passwordController.text,
        client: 'UntisPlus',
        requestId: '1',
      );

      if (authResult != null) {
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
        await prefs.setInt('personType', personType);
        await prefs.setInt('personId', personId);

        updateUntisData().catchError((_) {});

        if (mounted) _nextPage();
      } else {
        _showError(AppL10n.of(appLocaleNotifier.value).loginFailed);
      }
    } catch (e) {
      final l = AppL10n.of(appLocaleNotifier.value);
      _showError('${l.loginConnectionError}: $e');
    } finally {
      if (mounted) setState(() => _isLogginIn = false);
    }
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
    if (_geminiController.text.isNotEmpty) {
      geminiApiKey = _geminiController.text;
      await prefs.setString('geminiApiKey', geminiApiKey);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const MainNavigationScreen(),
        transitionsBuilder: (context, anim1, anim2, child) =>
            FadeTransition(opacity: anim1, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
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
        return l.settingsBackgroundStyleAurora;
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
        return Icons.water_drop_rounded;
      default:
        return Icons.blur_circular_rounded;
    }
  }

  Future<void> _setBackgroundAnimationStyle(int style) async {
    final normalized = style.clamp(0, 5);
    backgroundAnimationStyleNotifier.value = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backgroundAnimationStyle', normalized);
  }

  Future<void> _setBlurEnabled(bool enabled) async {
    blurEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blurEnabled', enabled);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 1),
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
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.84),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.outlineVariant.withOpacity(0.65),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _currentPage > 0
                                  ? _previousPage
                                  : null,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                            ),
                            Expanded(
                              child: Text(
                                '${_currentPage + 1}/$_totalOnboardingSteps',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(_totalOnboardingSteps, (
                            index,
                          ) {
                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentPage >= index
                                      ? colors.primary
                                      : colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
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

  Widget _buildLanguageStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    return _StepWrapper(
      icon: Icons.language,
      title: l.onboardingWelcomeTitle,
      subtitle: l.onboardingChooseLanguageSubtitle,
      content: ValueListenableBuilder<String>(
        valueListenable: appLocaleNotifier,
        builder: (context, currentLang, _) {
          return Column(
            children: [
              _buildLangBtn('de', 'Deutsch', '🇩🇪', currentLang),
              const SizedBox(height: 12),
              _buildLangBtn('en', 'English', '🇬🇧', currentLang),
              const SizedBox(height: 12),
              _buildLangBtn('fr', 'Français', '🇫🇷', currentLang),
              const SizedBox(height: 12),
              _buildLangBtn('es', 'Español', '🇪🇸', currentLang),
              const Spacer(),
              _buildNextBtn(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLangBtn(String code, String name, String flag, String current) {
    final colors = Theme.of(context).colorScheme;
    final isSel = current == code;
    return InkWell(
      onTap: () async {
        appLocaleNotifier.value = code;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appLocale', code);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSel ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? colors.primary : colors.outlineVariant,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? colors.onPrimaryContainer : colors.onSurface,
              ),
            ),
            const Spacer(),
            if (isSel) Icon(Icons.check_circle, color: colors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeStep() {
    final l = AppL10n.of(appLocaleNotifier.value);
    final colors = Theme.of(context).colorScheme;

    return _StepWrapper(
      icon: Icons.palette,
      title: l.onboardingAppearanceTitle,
      subtitle: l.onboardingAppearanceSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outlineVariant.withOpacity(0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsThemeMode,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, val, _) => SegmentedButton<ThemeMode>(
                    style: SegmentedButton.styleFrom(
                      textStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_rounded, size: 17),
                        label: Text(l.settingsThemeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(
                          Icons.brightness_auto_rounded,
                          size: 17,
                        ),
                        label: Text(l.settingsThemeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_rounded, size: 17),
                        label: Text(l.settingsThemeDark),
                      ),
                    ],
                    selected: {val},
                    onSelectionChanged: (set) async {
                      final mode = set.first;
                      themeModeNotifier.value = mode;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('themeMode', mode.index);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: backgroundAnimationsNotifier,
            builder: (context, val, _) => SwitchListTile(
              title: Text(
                l.settingsBackgroundAnimations,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l.settingsBackgroundAnimationsDesc),
              value: val,
              onChanged: (nv) async {
                backgroundAnimationsNotifier.value = nv;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('backgroundAnimations', nv);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              tileColor: colors.surface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: backgroundAnimationsNotifier,
            builder: (context, animationsEnabled, _) {
              return Opacity(
                opacity: animationsEnabled ? 1 : 0.55,
                child: AbsorbPointer(
                  absorbing: !animationsEnabled,
                  child: ValueListenableBuilder<int>(
                    valueListenable: backgroundAnimationStyleNotifier,
                    builder: (context, style, _) => Container(
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.outlineVariant.withOpacity(0.7),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: Icon(_backgroundStyleIcon(style)),
                        title: Text(
                          l.settingsBackgroundStyle,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(_backgroundStyleLabel(l, style)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final selected = await _showUnifiedOptionSheet<int>(
                            context: context,
                            title: l.settingsBackgroundStyle,
                            options: List<int>.generate(6, (idx) => idx)
                                .map(
                                  (styleOption) => _SheetOption(
                                    value: styleOption,
                                    title: _backgroundStyleLabel(
                                      l,
                                      styleOption,
                                    ),
                                    icon: _backgroundStyleIcon(styleOption),
                                    selected: style == styleOption,
                                  ),
                                )
                                .toList(),
                          );
                          if (selected != null) {
                            await _setBackgroundAnimationStyle(selected);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: blurEnabledNotifier,
            builder: (context, val, _) => SwitchListTile(
              title: Text(
                l.settingsGlassEffect,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l.settingsGlassEffectDesc),
              value: val,
              onChanged: (nv) async {
                await _setBlurEnabled(nv);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              tileColor: colors.surface.withOpacity(0.75),
            ),
          ),
          const Spacer(),
          _buildNextBtn(),
        ],
      ),
    );
  }

  Widget _buildLoginStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    Widget content;
    if (!_manualSchoolEntry && _schoolController.text.isEmpty) {
      content = Column(
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: l.loginSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (val) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 800), () {
                if (!mounted) return;
                _searchSchool(val);
              });
            },
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
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        Text(l.loginNoSchoolsFound),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final s = _searchResults[index];
                      return ListTile(
                        title: Text(s.displayName),
                        subtitle: Text(
                          s.address.isNotEmpty
                              ? '${s.address}\n${s.loginName} • ${s.serverUrl}'
                              : '${s.loginName} • ${s.serverUrl}',
                        ),
                        isThreeLine: s.address.isNotEmpty,
                        onTap: () {
                          setState(() {
                            _schoolController.text = s.loginName;
                            _serverController.text = s.serverUrl;
                            _searchResults = [];
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _manualSchoolEntry = true),
            child: Text(l.loginManualEntry),
          ),
        ],
      );
    } else {
      content = SingleChildScrollView(
        child: Column(
          children: [
            if (!_manualSchoolEntry && _schoolController.text.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.school),
                  title: Text(_schoolController.text),
                  subtitle: Text(_serverController.text),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: l.loginChangeSchool,
                    onPressed: () {
                      setState(() {
                        _schoolController.clear();
                        _serverController.clear();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              _buildField(_serverController, l.loginServer, Icons.dns),
              const SizedBox(height: 12),
              _buildField(
                _schoolController,
                l.loginSchool,
                Icons.location_city,
              ),
              const SizedBox(height: 12),
            ],
            _buildField(_userController, l.loginUsername, Icons.person),
            const SizedBox(height: 12),
            _buildField(
              _passwordController,
              l.loginPassword,
              Icons.key,
              obscure: true,
            ),
            const SizedBox(height: 32),
            _isLogginIn
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: _handleLogin,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      l.loginButton,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            if (_manualSchoolEntry) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  _manualSchoolEntry = false;
                  _schoolController.clear();
                  _serverController.clear();
                }),
                child: Text(l.loginSwitchToSearch),
              ),
            ],
          ],
        ),
      );
    }

    return _StepWrapper(
      icon: Icons.school_rounded,
      title: l.onboardingSchoolLoginTitle,
      subtitle: l.onboardingSchoolLoginSubtitle,
      content: content,
    );
  }

  Widget _buildGeminiStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    return _StepWrapper(
      icon: Icons.auto_awesome,
      title: l.onboardingGeminiTitle,
      subtitle: l.onboardingGeminiSubtitle,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, size: 32),
                const SizedBox(height: 12),
                Text(
                  l.onboardingGeminiInfo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.onboardingGeminiGetApiKey),
                  onPressed: () => url_launcher.launchUrlString(
                    'https://aistudio.google.com/app/apikey',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildField(_geminiController, l.settingsApiKey, Icons.key),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _nextPage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    l.onboardingSkip,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_geminiController.text.isNotEmpty) {
                      _nextPage();
                    } else {
                      _showError(l.onboardingGeminiEnterKeyOrSkip);
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    l.onboardingNext,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep() {
    final l = AppL10n.of(appLocaleNotifier.value);

    return _StepWrapper(
      icon: Icons.rocket_launch,
      title: l.onboardingReadyTitle,
      subtitle: l.onboardingReadySubtitle,
      content: Column(
        children: [
          _buildFeatureRow(
            Icons.calendar_month,
            l.onboardingFeatureTimetableTitle,
            l.onboardingFeatureTimetableDesc,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.draw,
            l.onboardingFeatureExamsTitle,
            l.onboardingFeatureExamsDesc,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.auto_awesome,
            l.onboardingFeatureAiTitle,
            l.onboardingFeatureAiDesc,
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.notifications_active,
            l.onboardingFeatureNotifyTitle,
            l.onboardingFeatureNotifyDesc,
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _completeOnboarding,
            icon: const Icon(Icons.check),
            label: Text(
              l.onboardingFinishSetup,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.7),
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

  const _StepWrapper({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            child: Icon(icon, size: 36, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.78),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: content),
        ],
      ),
    );
  }
}

