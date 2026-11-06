import 'package:flutter/material.dart';
import 'package:untisplus/l10n.dart';
import 'package:untisplus/main.dart';
import 'package:untisplus/widgets/untis_account_switcher_sheet.dart';

/// Floating translucent glass sidebar navigation component designed for tablet screens.
///
/// Replaces the default [NavigationRail] on tablets with a floating glass panel
/// featuring an app header, animated squircle destinations with badges, and an
/// account switcher footer avatar.
class TabletGlassSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showAi;
  final Map<int, GlobalKey>? tutorialKeys;
  final Map<int, GlobalKey>? tutorialLabelKeys;
  final VoidCallback? onAccountTap;

  const TabletGlassSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showAi = true,
    this.tutorialKeys,
    this.tutorialLabelKeys,
    this.onAccountTap,
  });

  String _resolveInitials(UntisAccount? account) {
    if (account == null) return '';
    final name = account.displayName.trim().isNotEmpty
        ? account.displayName.trim()
        : account.username.trim();
    if (name.isEmpty || name == '?') return '';
    final parts = name
        .split(RegExp(r'[\s._-]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _resolveAccountTooltip(UntisAccount? account, AppL10n l) {
    if (account == null) {
      try {
        return l.accounts;
      } catch (_) {
        return 'Konten';
      }
    }
    final school = account.schoolName.trim();
    final user = account.username.trim();
    if (school.isNotEmpty && user.isNotEmpty) {
      return '$school ($user)';
    }
    if (school.isNotEmpty) return school;
    if (user.isNotEmpty) return user;
    try {
      return l.accounts;
    } catch (_) {
      return 'Konten';
    }
  }

  Widget _buildDestinationItem({
    required BuildContext context,
    required int index,
    required String title,
    required IconData unselectedIcon,
    required IconData selectedIcon,
    required ColorScheme cs,
    bool showBadgeDot = false,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;
    final iconData = isSelected ? selectedIcon : unselectedIcon;
    final iconColor = isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    final bgColor = isSelected ? cs.primaryContainer : Colors.transparent;

    Widget iconWidget = Icon(
      iconData,
      color: iconColor,
      size: 24,
    );

    if (tutorialLabelKeys != null && tutorialLabelKeys![index] != null) {
      iconWidget = KeyedSubtree(
        key: tutorialLabelKeys![index],
        child: iconWidget,
      );
    }

    Widget itemWidget = Tooltip(
      message: title,
      preferBelow: false,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onDestinationSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  if (showBadgeDot)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        key: const ValueKey('tablet-sidebar-timetable-badge'),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        key: const ValueKey('tablet-sidebar-info-badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: cs.error,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: cs.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: TextStyle(
                            color: cs.onError,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (tutorialKeys != null && tutorialKeys![index] != null) {
      itemWidget = KeyedSubtree(
        key: tutorialKeys![index],
        child: itemWidget,
      );
    }

    return itemWidget;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        appLocaleNotifier,
        unreadTimetableChangesNotifier,
        unreadInboxMessagesNotifier,
        untisAccountsNotifier,
      ]),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final l = appL10nFor(appLocaleNotifier.value);
        final account = activeUntisAccount;
        final initials = _resolveInitials(account);
        final accountTooltip = _resolveAccountTooltip(account, l);

        final destinations = [
          _buildDestinationItem(
            context: context,
            index: 0,
            title: l.timetableTitle,
            unselectedIcon: Icons.watch_later_outlined,
            selectedIcon: Icons.watch_later_rounded,
            cs: cs,
            showBadgeDot: unreadTimetableChangesNotifier.value > 0,
          ),
          _buildDestinationItem(
            context: context,
            index: 1,
            title: l.examsTitle,
            unselectedIcon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
            cs: cs,
          ),
          _buildDestinationItem(
            context: context,
            index: 2,
            title: l.navInfo,
            unselectedIcon: Icons.campaign_outlined,
            selectedIcon: Icons.campaign_rounded,
            cs: cs,
            badgeCount: unreadInboxMessagesNotifier.value,
          ),
          _buildDestinationItem(
            context: context,
            index: 3,
            title: l.navMenu,
            unselectedIcon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            cs: cs,
          ),
          if (showAi)
            _buildDestinationItem(
              context: context,
              index: 4,
              title: l.navAi,
              unselectedIcon: Icons.auto_awesome_outlined,
              selectedIcon: Icons.auto_awesome_rounded,
              cs: cs,
            ),
        ];

        return SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: SizedBox(
              width: 78,
              child: ThemedSurface(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Header: Stylized app logo
                      Container(
                        key: const ValueKey('tablet-sidebar-header'),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.school_rounded,
                          size: 24,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Navigation Items
                      for (int i = 0; i < destinations.length; i++) ...[
                        destinations[i],
                        if (i < destinations.length - 1)
                          const SizedBox(height: 8),
                      ],

                      const Spacer(),

                      // Footer: Account switcher avatar
                      Tooltip(
                        message: accountTooltip,
                        preferBelow: false,
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            key: const ValueKey(
                              'tablet-sidebar-account-avatar',
                            ),
                            customBorder: const CircleBorder(),
                            onTap: () {
                              if (onAccountTap != null) {
                                onAccountTap!();
                              } else {
                                UntisAccountSwitcherSheet.show(context);
                              }
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primaryContainer,
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: initials.isNotEmpty
                                  ? Text(
                                      initials,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 20,
                                      color: cs.onPrimaryContainer,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
