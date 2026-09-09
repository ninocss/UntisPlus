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
    final fullExpressive = tokens.usesFullMaterialExpressive;

    return ValueListenableBuilder<bool>(
      valueListenable: blurEnabledNotifier,
      builder: (context, blurEnabled, _) {
        final isBlurActive =
            !fullExpressive && useBlur && tokens.supportsBlur && blurEnabled;

        return AppBar(
          centerTitle: centerTitle,
          leading: leading,
          actions: actions,
          title: title,
          bottom: bottom,
          backgroundColor: fullExpressive
              ? cs.surface
              : isBlurActive
              ? cs.surface.withValues(
                  alpha: tokens.id == AppThemeId.glass ? 0.42 : 0.62,
                )
              : (blurEnabled ? Colors.transparent : cs.surface),
          elevation: 0,
          scrolledUnderElevation: fullExpressive ? 3 : (isBlurActive ? 0 : 4),
          surfaceTintColor: fullExpressive ? cs.surfaceTint : null,
          flexibleSpace: fullExpressive
              ? null
              : _blurEffect(
                  enabled: useBlur,
                  sigma: tokens.blurSigma,
                  child: Container(color: Colors.transparent),
                ),
        );
      },
    );
  }
}
