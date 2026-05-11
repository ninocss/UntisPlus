import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RoundedBlurAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final bool centerTitle;
  final double borderRadius;
  final bool useBlur;
  final ValueListenable<bool>? blurListenable;
  final double blurSigmaX;
  final double blurSigmaY;
  final Color? scrimColor;
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
    this.blurListenable,
    this.blurSigmaX = 16,
    this.blurSigmaY = 16,
    this.scrimColor,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    if (blurListenable == null) {
      return _buildAppBar(context, useBlur);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: blurListenable!,
      builder: (context, enabled, _) => _buildAppBar(context, enabled),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool blurEnabled) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scrim improves contrast over animated / high-frequency backgrounds.
    final scrimAlpha = blurEnabled
        ? (isDark ? 0.72 : 0.82)
        : (isDark ? 0.92 : 0.96);
    final scrim = (scrimColor ?? cs.surface).withValues(
      alpha: scrimAlpha.clamp(0.0, 1.0),
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      title: title,
      bottom: bottom,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
      ),
      flexibleSpace: ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
        child: blurEnabled
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurSigmaX,
                  sigmaY: blurSigmaY,
                ),
                child: ColoredBox(color: scrim),
              )
            : ColoredBox(color: scrim),
      ),
    );
  }
}
