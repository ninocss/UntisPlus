part of '../main.dart';

@immutable
class ExpressiveButtonGroupItem<T> {
  const ExpressiveButtonGroupItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final Widget label;
  final Widget? icon;
  final bool enabled;
}

/// A compact selection group backed by Material's keyboard- and
/// semantics-aware segmented button behavior.
class ExpressiveButtonGroup<T> extends StatelessWidget {
  const ExpressiveButtonGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.showSelectedIcon = true,
  });

  final List<ExpressiveButtonGroupItem<T>> items;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final bool multiSelectionEnabled;
  final bool emptySelectionAllowed;
  final bool showSelectedIcon;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [
        for (final item in items)
          ButtonSegment<T>(
            value: item.value,
            label: item.label,
            icon: item.icon,
            enabled: item.enabled,
          ),
      ],
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      emptySelectionAllowed: emptySelectionAllowed,
      showSelectedIcon: showSelectedIcon,
    );
  }
}

/// A direct primary action paired with a related anchored menu.
class ExpressiveSplitButton extends StatefulWidget {
  const ExpressiveSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.menuChildren,
    required this.menuTooltip,
    this.mainTooltip,
    this.icon,
    this.enabled = true,
  });

  final Widget label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final List<Widget> menuChildren;
  final String menuTooltip;
  final String? mainTooltip;
  final bool enabled;

  @override
  State<ExpressiveSplitButton> createState() => _ExpressiveSplitButtonState();
}

class _ExpressiveSplitButtonState extends State<ExpressiveSplitButton> {
  bool _menuOpen = false;

  ButtonStyle _partStyle(BuildContext context, {required bool menu}) {
    final expressive = untisThemeTokensOf(context).expressive;
    if (expressive == null) {
      return FilledButton.styleFrom(minimumSize: const Size(48, 48));
    }
    final rtl = Directionality.of(context).name == 'rtl';
    final outer = Radius.circular(expressive.standardActionSize / 2);
    const inner = Radius.circular(8);
    final left = menu == rtl;
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(expressive.minimumTouchTarget, expressive.standardActionSize),
      ),
      padding: WidgetStatePropertyAll(
        menu ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20),
      ),
      shape: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(
              expressive.pressedControlRadius,
            ),
          );
        }
        return RoundedSuperellipseBorder(
          borderRadius: BorderRadius.horizontal(
            left: left ? inner : outer,
            right: left ? outer : inner,
          ),
        );
      }),
      animationDuration: expressive.quickMotion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = untisThemeTokensOf(context).expressive;
    final duration = motion?.motionDuration(context) ?? Duration.zero;
    Widget mainButton = widget.icon == null
        ? FilledButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: _partStyle(context, menu: false),
            child: widget.label,
          )
        : FilledButton.icon(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: _partStyle(context, menu: false),
            icon: widget.icon!,
            label: widget.label,
          );
    if (widget.mainTooltip case final tooltip?) {
      mainButton = Tooltip(message: tooltip, child: mainButton);
    }
    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mainButton,
          const SizedBox(width: 2),
          MenuAnchor(
            onOpen: () => setState(() => _menuOpen = true),
            onClose: () => setState(() => _menuOpen = false),
            menuChildren: widget.menuChildren,
            builder: (context, controller, child) => Tooltip(
              message: widget.menuTooltip,
              child: FilledButton(
                onPressed: widget.enabled && widget.menuChildren.isNotEmpty
                    ? () => controller.isOpen
                          ? controller.close()
                          : controller.open()
                    : null,
                style: _partStyle(context, menu: true),
                child: AnimatedRotation(
                  turns: _menuOpen ? .5 : 0,
                  duration: duration,
                  curve: motion?.motionCurve ?? Curves.linear,
                  child: const Icon(Icons.arrow_drop_down_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A solid, compact action surface for editors and contextual actions.
class ExpressiveToolbar extends StatelessWidget {
  const ExpressiveToolbar({
    super.key,
    required this.children,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(4),
    this.spacing = 2,
  });

  final List<Widget> children;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expressive = untisThemeTokensOf(context).expressive;
    if (expressive == null) {
      return Semantics(
        container: true,
        label: semanticLabel,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      );
    }
    final shape = expressive.largeSurfaceShape;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

class ExpressiveMenuAction {
  const ExpressiveMenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onSelected;
  final bool destructive;
}

/// The common anchored overflow menu for contextual editor actions.
class ExpressiveOverflowMenu extends StatelessWidget {
  const ExpressiveOverflowMenu({
    super.key,
    required this.tooltip,
    required this.actions,
    this.icon = Icons.more_vert_rounded,
  });

  final String tooltip;
  final List<ExpressiveMenuAction> actions;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MenuAnchor(
      menuChildren: [
        for (final action in actions)
          MenuItemButton(
            leadingIcon: Icon(
              action.icon,
              color: action.destructive ? cs.error : null,
            ),
            onPressed: action.onSelected,
            child: Text(
              action.label,
              style: action.destructive ? TextStyle(color: cs.error) : null,
            ),
          ),
      ],
      builder: (context, controller, child) => IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: actions.isEmpty
            ? null
            : () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// A solid shared outer surface for semantically related cards or list rows.
class ExpressiveCardGroup extends StatelessWidget {
  const ExpressiveCardGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.addDividers = true,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool addDividers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expressive = untisThemeTokensOf(context).expressive;
    final shape =
        expressive?.largeSurfaceShape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            untisThemeTokensOf(context).surfaceRadius,
          ),
        );
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (addDividers && index < children.length - 1)
                const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class ExpressiveLoadingIndicator extends StatefulWidget {
  const ExpressiveLoadingIndicator({
    super.key,
    this.contained = true,
    this.size = 48,
    this.semanticsLabel,
    this.animate = true,
  });

  final bool contained;
  final double size;
  final String? semanticsLabel;
  final bool animate;

  @override
  ExpressiveLoadingIndicatorState createState() =>
      ExpressiveLoadingIndicatorState();
}

class ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @visibleForTesting
  bool get isAnimating => _controller.isAnimating;

  void _syncAnimation() {
    final expressive = untisThemeTokensOf(context).expressive;
    _controller.duration =
        expressive?.loadingCycle ?? const Duration(milliseconds: 1600);
    final shouldAnimate =
        expressive != null &&
        widget.animate &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ExpressiveLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (untisThemeTokensOf(context).expressive == null) {
      return Semantics(
        label: widget.semanticsLabel,
        child: SizedBox.square(
          dimension: widget.size,
          child: CircularProgressIndicator(color: scheme.primary),
        ),
      );
    }
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            key: const ValueKey('expressive-loading-paint'),
            size: Size.square(widget.size),
            painter: _ExpressiveLoaderPainter(
              containerColor: scheme.primaryContainer,
              blobColor: widget.contained
                  ? scheme.onPrimaryContainer
                  : scheme.primary,
              turns: _controller.value,
              contained: widget.contained,
            ),
          ),
        ),
      ),
    );
  }
}

class ExpressiveProgressIndicator extends StatefulWidget {
  const ExpressiveProgressIndicator({
    super.key,
    this.value,
    this.height = 8,
    this.semanticsLabel,
    this.semanticsValue,
  }) : assert(value == null || (value >= 0 && value <= 1));

  final double? value;
  final double height;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  ExpressiveProgressIndicatorState createState() =>
      ExpressiveProgressIndicatorState();
}

class ExpressiveProgressIndicatorState
    extends State<ExpressiveProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @visibleForTesting
  bool get isAnimating => _controller.isAnimating;

  void _syncAnimation() {
    final expressive = untisThemeTokensOf(context).expressive;
    _controller.duration =
        expressive?.progressCycle ?? const Duration(milliseconds: 1400);
    final shouldAnimate =
        expressive != null &&
        widget.value == null &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ExpressiveProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (untisThemeTokensOf(context).expressive == null) {
      return Semantics(
        label: widget.semanticsLabel,
        value: widget.semanticsValue,
        child: LinearProgressIndicator(value: widget.value),
      );
    }
    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _ExpressiveProgressPainter(
              value: widget.value,
              phase: _controller.value,
              color: scheme.primary,
              trackColor: scheme.secondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpressiveProgressPainter extends CustomPainter {
  const _ExpressiveProgressPainter({
    required this.value,
    required this.phase,
    required this.color,
    required this.trackColor,
  });

  final double? value;
  final double phase;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, radius),
      Paint()..color = trackColor,
    );
    final start = value == null ? (phase * 1.35 - .35) * size.width : 0.0;
    final end = value == null
        ? start + size.width * .35
        : size.width * value!.clamp(0.0, 1.0);
    if (end <= 0 || start >= size.width || end <= start) return;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(bounds, radius));
    final path = Path();
    const samples = 36;
    for (var i = 0; i <= samples; i++) {
      final x = lerpDouble(start, end, i / samples)!;
      final y =
          size.height / 2 +
          math.sin((i / samples * math.pi * 4) + phase * math.pi * 2) *
              size.height *
              .16;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = size.height * .7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ExpressiveProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
