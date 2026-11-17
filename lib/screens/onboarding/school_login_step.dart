part of '../../main.dart';

/// Step 2: Material 3 Expressive School Search & Login Stage.
/// Supports universal directory search, manual WebUntis server/school entry,
/// password vs login key switching, and 2FA OTP verification.
class SchoolLoginStep extends StatefulWidget {
  final TextEditingController serverController;
  final TextEditingController schoolController;
  final TextEditingController userController;
  final TextEditingController passwordController;
  final TextEditingController twoFactorController;
  final bool isLoggingIn;
  final bool requiresTwoFactor;
  final bool useLoginKey;
  final ValueChanged<bool> onUseLoginKeyChanged;
  final Future<void> Function() onLogin;
  final VoidCallback onDemoModeSelected;
  final bool accountOnly;

  const SchoolLoginStep({
    super.key,
    required this.serverController,
    required this.schoolController,
    required this.userController,
    required this.passwordController,
    required this.twoFactorController,
    required this.isLoggingIn,
    required this.requiresTwoFactor,
    required this.useLoginKey,
    required this.onUseLoginKeyChanged,
    required this.onLogin,
    required this.onDemoModeSelected,
    this.accountOnly = false,
  });

  @override
  State<SchoolLoginStep> createState() => _SchoolLoginStepState();
}

class _SchoolLoginStepState extends State<SchoolLoginStep> {
  final SchoolDirectoryRepository _directoryRepo = SchoolDirectoryRepository();
  final FocusNode _searchFocus = FocusNode();
  List<SchoolSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _manualSchoolEntry = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _directoryRepo.close();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      try {
        final results = await _directoryRepo.search(trimmed);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final hasSelectedSchool = widget.schoolController.text.isNotEmpty &&
        widget.serverController.text.isNotEmpty;

    final showSearch = !_manualSchoolEntry && !hasSelectedSchool;

    return M3StepContainer(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Header
            Text(
              l.onboardingSchoolLoginTitle,
              style: untisThemeTextStyle(
                context,
                display: true,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.onboardingSchoolLoginSubtitle,
              style: untisThemeTextStyle(
                context,
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            if (showSearch) ...[
              // Universal M3 SearchBar
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: TextField(
                  focusNode: _searchFocus,
                  style: untisThemeTextStyle(context, fontSize: 15),
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l.loginSearchHint,
                    hintStyle: untisThemeTextStyle(
                      context,
                      color: colors.onSurfaceVariant,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Icon(
                        Icons.search_rounded,
                        color: colors.primary,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Search status or results
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchResults.isNotEmpty)
                Column(
                  children: _searchResults.map((school) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() {
                              widget.schoolController.text = school.loginName;
                              widget.serverController.text = school.serverUrl;
                              _searchResults = [];
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHigh.withValues(
                                alpha: 0.65,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colors.outlineVariant.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        school.displayName,
                                        style: untisThemeTextStyle(
                                          context,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          color: colors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        school.address.isNotEmpty
                                            ? school.address
                                            : school.loginName,
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
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l.loginSearchHint,
                        textAlign: TextAlign.center,
                        style: untisThemeTextStyle(
                          context,
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // Selected School Card (if from search)
              if (hasSelectedSchool && !_manualSchoolEntry) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
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
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.schoolController.text,
                              style: untisThemeTextStyle(
                                context,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              widget.serverController.text,
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
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            widget.schoolController.clear();
                            widget.serverController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Manual Server & School inputs (if manual mode)
              if (_manualSchoolEntry) ...[
                _buildField(
                  context,
                  controller: widget.serverController,
                  label: l.loginServer,
                  hint: 'tipo.webuntis.com',
                  icon: Icons.dns_rounded,
                ),
                const SizedBox(height: 12),
                _buildField(
                  context,
                  controller: widget.schoolController,
                  label: l.loginSchool,
                  hint: 'schulname',
                  icon: Icons.location_city_rounded,
                ),
                const SizedBox(height: 12),
              ],

              // Username input
              _buildField(
                context,
                controller: widget.userController,
                label: l.loginUsername,
                hint: 'Benutzername',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),

              // Password / Login Key segmented switch
              Row(
                children: [
                  Expanded(
                    child: _buildCredentialChip(
                      label: l.loginCredentialModePassword,
                      isSelected: !widget.useLoginKey,
                      onTap: () => widget.onUseLoginKeyChanged(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCredentialChip(
                      label: l.loginCredentialModeLoginKey,
                      isSelected: widget.useLoginKey,
                      onTap: () => widget.onUseLoginKeyChanged(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Password or Login Key input
              _buildField(
                context,
                controller: widget.passwordController,
                label: widget.useLoginKey ? l.loginLoginKey : l.loginPassword,
                hint: '••••••••',
                icon: widget.useLoginKey ? Icons.key_rounded : Icons.lock_rounded,
                obscure: true,
              ),

              // 2FA field if required
              if (widget.requiresTwoFactor) ...[
                const SizedBox(height: 12),
                _buildField(
                  context,
                  controller: widget.twoFactorController,
                  label: l.loginTwoFactorCode,
                  hint: '123456',
                  icon: Icons.security_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSearch) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _manualSchoolEntry = true),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      l.loginManualShort,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      side: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                if (!widget.accountOnly) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.isLoggingIn ? null : widget.onDemoModeSelected,
                      icon: const Icon(Icons.science_rounded, size: 18),
                      label: Text(
                        l.loginDemoShort,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        side: BorderSide(
                          color: colors.outlineVariant.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            M3PillButton(
              label: widget.requiresTwoFactor ? l.loginVerifyButton : l.loginButton,
              icon: Icons.arrow_forward_rounded,
              isLoading: widget.isLoggingIn,
              onPressed: widget.onLogin,
            ),
            if (_manualSchoolEntry) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() {
                  _manualSchoolEntry = false;
                  widget.schoolController.clear();
                  widget.serverController.clear();
                }),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: Text(l.loginSwitchToSearch),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: untisThemeTextStyle(context, fontSize: 15),
        decoration: InputDecoration(
          icon: Icon(icon, color: colors.primary, size: 20),
          labelText: label,
          labelStyle: untisThemeTextStyle(
            context,
            color: colors.onSurfaceVariant,
            fontSize: 13,
          ),
          hintText: hint,
          hintStyle: untisThemeTextStyle(
            context,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 14,
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
    );
  }

  Widget _buildCredentialChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer
                : colors.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: untisThemeTextStyle(
              context,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
