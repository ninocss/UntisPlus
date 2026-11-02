import 'package:flutter/material.dart';

@immutable
class PrimaryDestination {
  const PrimaryDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
    this.targetKey,
    this.labelKey,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
  final Key? targetKey;
  final Key? labelKey;
}

/// Always-labelled destinations. Selection changes shape/color, never the width
/// reserved for a label. A larger text scale wraps into two columns.
/// Loading/empty states are N/A: the caller supplies available destinations.
class PrimaryDestinationBar extends StatelessWidget {
  const PrimaryDestinationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.duration = const Duration(milliseconds: 180),
    this.radius = 24,
  });

  final List<PrimaryDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Duration duration;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(12) > 16;
        if (destinations.isEmpty) return const SizedBox.shrink();
        final columns =
            (largeText || constraints.maxWidth < destinations.length * 52) &&
                destinations.length > 2
            ? 2
            : destinations.length;
        final width = (constraints.maxWidth - (columns - 1) * 4) / columns;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var index = 0; index < destinations.length; index++)
              SizedBox(
                width: width,
                child: PrimaryDestinationButton(
                  destination: destinations[index],
                  selected: index == selectedIndex,
                  onPressed: () => onSelected(index),
                  duration: duration,
                  radius: radius,
                ),
              ),
          ],
        );
      },
    );
  }
}

class PrimaryDestinationButton extends StatelessWidget {
  const PrimaryDestinationButton({
    super.key,
    required this.destination,
    required this.selected,
    required this.onPressed,
    required this.duration,
    required this.radius,
  });

  final PrimaryDestination destination;
  final bool selected;
  final VoidCallback onPressed;
  final Duration duration;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final foreground = selected ? cs.onPrimaryContainer : cs.onSurface;
    final borderRadius = BorderRadius.circular(
      selected ? radius : radius * 0.65,
    );
    return Semantics(
      key: destination.targetKey,
      container: true,
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onPressed,
      value: destination.badgeCount > 0 ? '${destination.badgeCount}' : null,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : duration,
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : Colors.transparent,
            borderRadius: borderRadius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onPressed,
              excludeFromSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 8,
                  ),
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          isLabelVisible: destination.badgeCount > 0,
                          label: Text(
                            destination.badgeCount > 99
                                ? '99+'
                                : '${destination.badgeCount}',
                          ),
                          child: Icon(
                            selected
                                ? destination.selectedIcon
                                : destination.icon,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.label,
                          key: destination.labelKey,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: foreground,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
