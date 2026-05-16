import 'dart:ui';
import 'package:flutter/material.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: useBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      // Base surface tint layer
                      Positioned.fill(
                        child: Container(
                            color: cs.surface.withValues(alpha: 0.72), // matches appAlphaValues.sheetAlphaBlur
                        ),
                      ),
                      // Primary accent layer
                      Positioned.fill(
                        child: Container(
                          color: cs.primary.withValues(alpha: 0.05),
                        ),
                      ),
                      // Subtle radial gradient behind title
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.4),
                              radius: 0.6,
                              colors: [
                                cs.primary.withValues(alpha: 0.04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                color: cs.surface,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
