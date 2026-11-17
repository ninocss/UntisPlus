import 'package:flutter/material.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';

extension UntisAccountSwitcherSheetAccountX on UntisAccount {
  /// Stable display name fallback for WebUntis profiles.
  String get displayName => label;
}

extension UntisAccountSwitcherSheetL10nX on AppL10n {
  /// Localized label for managing accounts button.
  String get accountManage => switch (locale) {
    'en' => 'Manage accounts',
    'fr' => 'Gérer les comptes',
    'es' => 'Gestionar cuentas',
    _ => 'Konten verwalten',
  };
}

/// A modal sheet (or popover) that allows instant switching between WebUntis
/// accounts and direct navigation to account management.
class UntisAccountSwitcherSheet extends StatelessWidget {
  final List<UntisAccount>? accounts;
  final String? activeId;
  final Future<void> Function(UntisAccount)? onSelectAccount;
  final VoidCallback? onManageAccounts;
  final bool isPopover;

  const UntisAccountSwitcherSheet({
    super.key,
    this.accounts,
    this.activeId,
    this.onSelectAccount,
    this.onManageAccounts,
    this.isPopover = false,
  });

  /// Displays the account switcher modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    List<UntisAccount>? accounts,
    String? activeId,
    Future<void> Function(UntisAccount)? onSelectAccount,
    VoidCallback? onManageAccounts,
  }) {
    return showUntisModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => UntisAccountSwitcherSheet(
        accounts: accounts,
        activeId: activeId,
        onSelectAccount: onSelectAccount,
        onManageAccounts: onManageAccounts,
      ),
    );
  }

  /// Displays the account switcher as an anchored popover menu originating from [anchorKey].
  static Future<void> showPopover(
    BuildContext context, {
    required GlobalKey anchorKey,
    List<UntisAccount>? accounts,
    String? activeId,
    Future<void> Function(UntisAccount)? onSelectAccount,
    VoidCallback? onManageAccounts,
  }) {
    final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? const Offset(20, 600);
    final size = renderBox?.size ?? const Size(48, 48);
    final screenSize = MediaQuery.sizeOf(context);

    // Position next to sidebar (to the right of the button) and aligned with the button
    final left = (offset.dx + size.width + 12).clamp(12.0, (screenSize.width - 340.0).clamp(12.0, double.infinity));
    final bottom = (screenSize.height - offset.dy - size.height).clamp(16.0, (screenSize.height - 240.0).clamp(16.0, double.infinity));

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss account menu',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: left,
              bottom: bottom,
              child: Material(
                type: MaterialType.transparency,
                child: UntisAccountSwitcherSheet(
                  accounts: accounts,
                  activeId: activeId,
                  onSelectAccount: onSelectAccount,
                  onManageAccounts: onManageAccounts,
                  isPopover: true,
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            alignment: const Alignment(-0.85, 0.9), // Anchor origin: bottom-left
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _handleAccountTap(
    BuildContext context,
    UntisAccount account,
    bool isActive,
  ) async {
    if (isActive) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (onSelectAccount != null) {
      await onSelectAccount!(account);
    } else {
      await switchUntisAccount(account.id);
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  void _handleManageAccounts(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (onManageAccounts != null) {
      onManageAccounts!();
    } else {
      nav.push(
        MaterialPageRoute(builder: (_) => const SettingsAccountPage()),
      );
    }
  }

  String _resolveTitle(AppL10n l) {
    try {
      return l.accounts;
    } catch (_) {
      return 'Konten';
    }
  }

  String _resolveManageAccountsLabel(AppL10n l) {
    try {
      return l.accountManage;
    } catch (_) {
      return 'Konten verwalten';
    }
  }

  String _resolveNoAccountsLabel(AppL10n l) {
    try {
      return l.widgetNoAccount;
    } catch (_) {
      return 'Kein Konto verfügbar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        untisAccountsNotifier,
        blurEnabledNotifier,
        appLocaleNotifier,
      ]),
      builder: (context, _) {
        final l = appL10nFor(appLocaleNotifier.value);
        final effectiveAccounts = accounts ?? untisAccountsNotifier.value;
        final effectiveActiveId = activeId ?? activeUntisAccountId;
        final title = _resolveTitle(l);
        final manageLabel = _resolveManageAccountsLabel(l);
        final noAccountsLabel = _resolveNoAccountsLabel(l);

        final surface = ThemedSurface(
          borderRadius: isPopover
              ? BorderRadius.circular(22)
              : const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
          sigma: 45,
          blur: blurEnabledNotifier.value,
          respectSurfaceBlurPreference: false,
          respectSurfaceCornerPreference: false,
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            width: 1.0,
          ),
          child: SafeArea(
            top: false,
            bottom: !isPopover,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isPopover ? 14 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isPopover) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: isPopover ? 10 : 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isPopover ? 34 : 40,
                          height: isPopover ? 34 : 40,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: BorderRadius.circular(isPopover ? 10 : 12),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: cs.primary,
                            size: isPopover ? 18 : 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: (isPopover
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.titleLarge)
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (effectiveAccounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          noAccountsLabel,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: isPopover
                            ? 280
                            : MediaQuery.sizeOf(context).height * 0.55,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              int i = 0;
                              i < effectiveAccounts.length;
                              i++
                            ) ...[
                              if (i > 0) const SizedBox(height: 8),
                              _AccountTile(
                                account: effectiveAccounts[i],
                                isActive:
                                    effectiveAccounts[i].id ==
                                    effectiveActiveId,
                                onTap: () => _handleAccountTap(
                                  context,
                                  effectiveAccounts[i],
                                  effectiveAccounts[i].id ==
                                      effectiveActiveId,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleManageAccounts(context),
                      icon: const Icon(
                        Icons.manage_accounts_rounded,
                        size: 20,
                      ),
                      label: Text(manageLabel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );

        if (isPopover) {
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
            child: surface,
          );
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: surface,
          ),
        );
      },
    );
  }
}

class _AccountTile extends StatelessWidget {
  final UntisAccount account;
  final bool isActive;
  final VoidCallback onTap;

  const _AccountTile({
    required this.account,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = account.displayName.isNotEmpty
        ? account.displayName
        : (account.username.isNotEmpty ? account.username : account.label);
    final schoolName = account.schoolName.isNotEmpty
        ? account.schoolName
        : account.schoolUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? cs.primaryContainer.withValues(alpha: 0.32)
                : cs.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.25),
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? cs.primary.withValues(alpha: 0.18)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.55),
                ),
                child: Icon(
                  isActive
                      ? Icons.account_circle_rounded
                      : Icons.account_circle_outlined,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schoolName,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.check_circle_rounded,
                  color: cs.primary,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
