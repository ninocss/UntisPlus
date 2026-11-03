part of '../main.dart';

class RoundedBlurAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final bool centerTitle;
  final double borderRadius;
  final bool useBlur;
  final PreferredSizeWidget? bottom;

  const RoundedBlurAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.height = kToolbarHeight,
    this.centerTitle = true,
    this.borderRadius = 12.0,
    this.useBlur = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);

    return ValueListenableBuilder<int>(
      valueListenable: headerStyleNotifier,
      builder: (context, headerStyle, _) => ValueListenableBuilder<bool>(
        valueListenable: blurEnabledNotifier,
        builder: (context, blurEnabled, _) {
          final isBlurActive = useBlur && tokens.supportsBlur && blurEnabled;
          final useFade = headerStyle == 1;
          final useBubbles = headerStyle == 2;
          final solid = !isBlurActive && (!useBubbles || bottom != null);
          final headerTitle = useBubbles && title != null
              ? _headerBubble(
                  context,
                  title!,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                )
              : title;
          final headerLeading = useBubbles && leading != null
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: _headerBubble(context, leading!, circular: true),
                )
              : leading;
          final headerActions = useBubbles && actions != null
              ? actions!
                    .map((action) {
                      final content = _unwrapHeaderActionPadding(action);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _headerBubble(
                          context,
                          Center(child: content),
                          circular: _isIconHeaderAction(content),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      );
                    })
                    .toList(growable: false)
              : actions;

          final bar = AppBar(
            centerTitle: centerTitle,
            leading: headerLeading,
            leadingWidth: useBubbles && leading != null ? 64 : null,
            actions: headerActions,
            title: headerTitle,
            bottom: bottom,
            toolbarHeight: height,
            systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            backgroundColor: solid ? cs.surface : Colors.transparent,
            shape: solid
                ? Border(bottom: BorderSide(color: cs.outlineVariant))
                : null,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          );
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              if (isBlurActive)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: -32,
                  child: _ChromeEdge(
                    strongAtTop: true,
                    tint: cs.surface.withValues(
                      alpha: useBubbles
                          ? 0.10
                          : useFade
                          ? 0.54
                          : tokens.navigationOpacity,
                    ),
                  ),
                ),
              bar,
            ],
          );
        },
      ),
    );
  }
}

Widget _unwrapHeaderActionPadding(Widget action) {
  var content = action;
  while (content is Padding && content.child != null) {
    final padding = content.padding;
    if (padding is! EdgeInsets) break;
    final inset = padding;
    if (inset.left != 0 || inset.top != 0 || inset.bottom != 0) break;
    content = content.child!;
  }
  return content;
}

bool _isIconHeaderAction(Widget action) =>
    action is IconButton || action is PopupMenuButton<dynamic>;

Widget _headerBubble(
  BuildContext context,
  Widget child, {
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 4),
  bool circular = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(circular ? 999 : 28),
    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
  );
  return Material(
    color: cs.surfaceContainerHigh,
    shape: shape,
    clipBehavior: Clip.antiAlias,
    child: IconTheme.merge(
      data: IconThemeData(color: cs.onSurface),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: cs.onSurface),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: circular
              ? SizedBox.square(dimension: 48, child: Center(child: child))
              : Padding(
                  padding: padding,
                  child: Center(child: child),
                ),
        ),
      ),
    ),
  );
}
