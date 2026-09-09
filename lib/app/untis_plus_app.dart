part of '../main.dart';

class UntisPlusApp extends StatelessWidget {
  final Widget startScreen;
  const UntisPlusApp({super.key, required this.startScreen});

  ThemeData _themeFrom(
    ColorScheme scheme,
    bool isAmoled,
    bool blurEnabled,
    bool glowEffectsEnabled,
    AppThemeId visualTheme,
  ) {
    final tokens = UntisThemeTokens.forTheme(
      visualTheme,
      scheme.brightness,
      scheme,
    ).copyWith(glowEffectsEnabled: glowEffectsEnabled);
    final expressive = appThemeCapabilities(
      visualTheme,
    ).supportsExpressiveComponents;
    final fullExpressive = tokens.usesFullMaterialExpressive;
    final useBlur = blurEnabled && tokens.supportsBlur;
    final baseText = untisThemeTextTheme(visualTheme, scheme.brightness);
    final controlShape = expressive
        ? WidgetStateProperty.resolveWith<OutlinedBorder>((states) {
            if (states.contains(WidgetState.pressed)) {
              return fullExpressive
                  ? RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(
                        tokens.expressive!.pressedControlRadius,
                      ),
                    )
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    );
            }
            return const StadiumBorder();
          })
        : WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.controlRadius),
            ),
          );
    final iconControlShape = expressive
        ? WidgetStateProperty.resolveWith<OutlinedBorder>((states) {
            if (states.contains(WidgetState.pressed)) {
              return fullExpressive
                  ? RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(
                        tokens.expressive!.pressedControlRadius,
                      ),
                    )
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    );
            }
            return const CircleBorder();
          })
        : controlShape;
    final commonButtonStyle = ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      minimumSize: expressive
          ? const WidgetStatePropertyAll(Size(48, 48))
          : null,
      shape: controlShape,
      overlayColor: fullExpressive
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return scheme.onSurface.withValues(
                  alpha: tokens.expressive!.pressedStateLayerOpacity,
                );
              }
              if (states.contains(WidgetState.focused)) {
                return scheme.onSurface.withValues(
                  alpha: tokens.expressive!.focusedStateLayerOpacity,
                );
              }
              if (states.contains(WidgetState.hovered)) {
                return scheme.onSurface.withValues(
                  alpha: tokens.expressive!.hoveredStateLayerOpacity,
                );
              }
              return null;
            })
          : null,
      animationDuration: fullExpressive
          ? null
          : expressive
          ? const Duration(milliseconds: 200)
          : null,
    );
    TextStyle displayFont({
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
    }) {
      final base = tokens.usesFullMaterialExpressive
          ? baseText.titleLarge!
          : TextStyle(fontFamily: appFontFamilyNotifier.value.family);
      return base.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      );
    }

    return ThemeData(
      useMaterial3: true,
      fontFamily: appFontFamilyNotifier.value.family,
      colorScheme: scheme,
      extensions: [tokens],
      scaffoldBackgroundColor:
          (isAmoled && scheme.brightness == Brightness.dark)
          ? Colors.black
          : scheme.surfaceContainerLowest,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: fullExpressive ? scheme.surface : Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: fullExpressive ? 3 : 4,
        surfaceTintColor: fullExpressive
            ? scheme.surfaceTint.withValues(alpha: 0.10)
            : scheme.primary,
        centerTitle: true,
        titleTextStyle: displayFont(
          color: fullExpressive ? scheme.onSurface : scheme.primary,
          fontSize: 22,
          fontWeight: fullExpressive ? FontWeight.w600 : FontWeight.w900,
          letterSpacing: fullExpressive ? 0 : -0.5,
        ),
        iconTheme: IconThemeData(
          color: fullExpressive ? scheme.onSurface : scheme.primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: useBlur
            ? scheme.surfaceContainer.withValues(alpha: 0.68)
            : scheme.surfaceContainer,
        height: expressive ? 76 : null,
        indicatorShape: expressive ? const StadiumBorder() : null,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onSecondaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return displayFont(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            );
          }
          return displayFont(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: fullExpressive ? scheme.surfaceContainerLow : null,
        elevation: fullExpressive ? 0 : null,
        useIndicator: fullExpressive ? true : null,
        indicatorColor: fullExpressive ? scheme.secondaryContainer : null,
        indicatorShape: fullExpressive ? const StadiumBorder() : null,
        selectedIconTheme: fullExpressive
            ? IconThemeData(color: scheme.onSecondaryContainer)
            : null,
        unselectedIconTheme: fullExpressive
            ? IconThemeData(color: scheme.onSurfaceVariant)
            : null,
        selectedLabelTextStyle: fullExpressive
            ? displayFont(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSecondaryContainer,
              )
            : null,
        unselectedLabelTextStyle: fullExpressive
            ? displayFont(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
      cardTheme: CardThemeData(
        shape: fullExpressive
            ? tokens.expressive!.largeSurfaceShape
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  expressive ? 28 : tokens.surfaceRadius,
                ),
              ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: fullExpressive
            ? scheme.surfaceContainerLow
            : useBlur
            ? scheme.surfaceContainerLow.withValues(alpha: 0.8)
            : scheme.surfaceContainerLow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: fullExpressive
            ? scheme.surfaceContainerHigh
            : useBlur
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.85)
            : scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.primary,
        shape: fullExpressive
            ? tokens.expressive!.largeSurfaceShape
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  expressive ? 32 : tokens.surfaceRadius + 6,
                ),
              ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: useBlur
            ? scheme.surfaceContainerLow.withValues(alpha: 0.85)
            : scheme.surfaceContainerLow,
        surfaceTintColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(expressive ? 32 : tokens.surfaceRadius + 6),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: commonButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: commonButtonStyle.copyWith(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: commonButtonStyle),
      textButtonTheme: TextButtonThemeData(style: commonButtonStyle),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: expressive
              ? const WidgetStatePropertyAll(Size(48, 48))
              : null,
          shape: iconControlShape,
          foregroundColor: fullExpressive
              ? WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return scheme.onSurface.withValues(alpha: 0.38);
                  }
                  if (states.contains(WidgetState.selected)) {
                    return scheme.onPrimary;
                  }
                  return scheme.onSurfaceVariant;
                })
              : null,
          backgroundColor: fullExpressive
              ? WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return scheme.onSurface.withValues(alpha: 0.10);
                  }
                  if (states.contains(WidgetState.selected)) {
                    return scheme.primary;
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return scheme.primaryContainer;
                  }
                  if (states.contains(WidgetState.focused)) {
                    return scheme.secondaryContainer.withValues(alpha: 0.88);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return scheme.surfaceContainerHighest;
                  }
                  return scheme.surfaceContainerHigh;
                })
              : null,
          overlayColor: fullExpressive
              ? WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return scheme.onSurface.withValues(
                      alpha: tokens.expressive!.pressedStateLayerOpacity,
                    );
                  }
                  if (states.contains(WidgetState.focused)) {
                    return scheme.onSurface.withValues(
                      alpha: tokens.expressive!.focusedStateLayerOpacity,
                    );
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return scheme.onSurface.withValues(
                      alpha: tokens.expressive!.hoveredStateLayerOpacity,
                    );
                  }
                  return null;
                })
              : null,
          animationDuration: fullExpressive
              ? null
              : expressive
              ? const Duration(milliseconds: 200)
              : null,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: expressive ? 0 : null,
        focusElevation: expressive ? 0 : null,
        hoverElevation: expressive ? 1 : null,
        highlightElevation: expressive ? 0 : null,
        shape: expressive ? const CircleBorder() : null,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: fullExpressive
            ? ButtonStyle(
                minimumSize: WidgetStatePropertyAll(
                  Size.square(tokens.expressive!.minimumTouchTarget),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? scheme.secondaryContainer
                      : scheme.surfaceContainerLow;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return scheme.onSurface.withValues(alpha: 0.38);
                  }
                  return states.contains(WidgetState.selected)
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant;
                }),
                shape: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(
                        tokens.expressive!.pressedControlRadius,
                      ),
                    );
                  }
                  return const StadiumBorder();
                }),
              )
            : SegmentedButton.styleFrom(
                selectedBackgroundColor: scheme.secondaryContainer,
                selectedForegroundColor: scheme.onSecondaryContainer,
                shape: expressive
                    ? const StadiumBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          tokens.controlRadius,
                        ),
                      ),
              ),
      ),
      chipTheme: ChipThemeData(
        shape: expressive
            ? const StadiumBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.controlRadius),
              ),
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: fullExpressive ? scheme.secondaryContainer : null,
        disabledColor: fullExpressive
            ? scheme.onSurface.withValues(alpha: 0.10)
            : null,
        checkmarkColor: fullExpressive ? scheme.onSecondaryContainer : null,
        labelStyle: fullExpressive ? baseText.labelLarge : null,
        padding: EdgeInsets.symmetric(
          horizontal: expressive ? 12 : 8,
          vertical: expressive ? 8 : 4,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (fullExpressive && states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (fullExpressive && states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return scheme.outline.withValues(alpha: 0.5);
        }),
        overlayColor: fullExpressive
            ? WidgetStatePropertyAll(
                scheme.primary.withValues(
                  alpha: tokens.expressive!.pressedStateLayerOpacity,
                ),
              )
            : null,
      ),
      checkboxTheme: fullExpressive
          ? CheckboxThemeData(
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.onSurface.withValues(alpha: 0.12);
                }
                return states.contains(WidgetState.selected)
                    ? scheme.primary
                    : Colors.transparent;
              }),
              checkColor: WidgetStatePropertyAll(scheme.onPrimary),
              overlayColor: WidgetStatePropertyAll(
                scheme.primary.withValues(
                  alpha: tokens.expressive!.pressedStateLayerOpacity,
                ),
              ),
            )
          : null,
      radioTheme: fullExpressive
          ? RadioThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.onSurface.withValues(alpha: 0.38);
                }
                return states.contains(WidgetState.selected)
                    ? scheme.primary
                    : scheme.onSurfaceVariant;
              }),
              overlayColor: WidgetStatePropertyAll(
                scheme.primary.withValues(
                  alpha: tokens.expressive!.pressedStateLayerOpacity,
                ),
              ),
            )
          : null,
      sliderTheme: SliderThemeData(
        trackHeight: fullExpressive ? 6 : null,
        activeTrackColor: fullExpressive
            ? scheme.primary
            : expressive
            ? null
            : scheme.primary,
        inactiveTrackColor: fullExpressive
            ? scheme.secondaryContainer
            : expressive
            ? null
            : scheme.surfaceContainerHighest,
        thumbColor: fullExpressive
            ? scheme.primary
            : expressive
            ? null
            : scheme.primary,
        overlayColor: fullExpressive
            ? scheme.primary.withValues(
                alpha: tokens.expressive!.pressedStateLayerOpacity,
              )
            : expressive
            ? null
            : scheme.primary.withValues(alpha: 0.12),
        // ignore: deprecated_member_use
        year2023: expressive ? false : true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.secondaryContainer,
        refreshBackgroundColor: scheme.surfaceContainerHigh,
        // Flutter 3.47 still requires this transitional flag for the latest
        // native Material progress indicator geometry.
        // ignore: deprecated_member_use
        year2023: expressive ? false : true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: expressive,
        fillColor: expressive ? scheme.surfaceContainerHighest : null,
        border: fullExpressive
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  tokens.expressive!.smallContainerRadius,
                ),
                borderSide: BorderSide.none,
              )
            : expressive
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              )
            : null,
        focusedBorder: fullExpressive
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  tokens.expressive!.smallContainerRadius,
                ),
                borderSide: BorderSide(color: scheme.primary, width: 2),
              )
            : null,
      ),
      searchBarTheme: fullExpressive
          ? SearchBarThemeData(
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                scheme.surfaceContainerHigh,
              ),
              shape: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(
                      tokens.expressive!.pressedControlRadius,
                    ),
                  );
                }
                return const StadiumBorder();
              }),
              constraints: const BoxConstraints(minHeight: 56),
            )
          : null,
      tabBarTheme: fullExpressive
          ? TabBarThemeData(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: ShapeDecoration(
                color: scheme.secondaryContainer,
                shape: const StadiumBorder(),
              ),
              labelColor: scheme.onSecondaryContainer,
              unselectedLabelColor: scheme.onSurfaceVariant,
              labelStyle: baseText.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overlayColor: WidgetStatePropertyAll(
                scheme.onSurface.withValues(
                  alpha: tokens.expressive!.hoveredStateLayerOpacity,
                ),
              ),
              splashBorderRadius: BorderRadius.circular(999),
            )
          : null,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: fullExpressive ? scheme.inverseSurface : null,
        contentTextStyle: fullExpressive
            ? baseText.bodyMedium?.copyWith(color: scheme.onInverseSurface)
            : null,
        actionTextColor: fullExpressive ? scheme.inversePrimary : null,
        shape: fullExpressive
            ? RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(24))
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  expressive ? 24 : tokens.controlRadius,
                ),
              ),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: fullExpressive
          ? TooltipThemeData(
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: ShapeDecoration(
                color: scheme.inverseSurface,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textStyle: baseText.bodySmall?.copyWith(
                color: scheme.onInverseSurface,
              ),
              waitDuration: const Duration(milliseconds: 500),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appFontFamilyNotifier,
      builder: (context, _) => _buildWithFont(context),
    );
  }

  Widget _buildWithFont(BuildContext context) {
    return ValueListenableBuilder<AppThemeId>(
      valueListenable: visualThemeNotifier,
      builder: (context, visualTheme, _) {
        return ValueListenableBuilder<String>(
          valueListenable: appLocaleNotifier,
          builder: (context, locale, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, themeMode, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: useMaterialYouNotifier,
                  builder: (context, useMaterialYou, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: isAmoledNotifier,
                      builder: (context, isAmoled, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: blurEnabledNotifier,
                          builder: (context, blurEnabled, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable: customColorSeedNotifier,
                              builder: (context, seed, _) {
                                return DynamicColorBuilder(
                                  builder: (lightDynamic, darkDynamic) {
                                    final canUseDynamic =
                                        visualTheme == AppThemeId.defaultTheme;
                                    final lightScheme =
                                        (canUseDynamic &&
                                            useMaterialYou &&
                                            lightDynamic != null)
                                        ? lightDynamic.harmonized()
                                        : (canUseDynamic &&
                                              useMaterialYou &&
                                              darkDynamic != null)
                                        ? ColorScheme.fromSeed(
                                            seedColor: darkDynamic.primary,
                                            brightness: Brightness.light,
                                            dynamicSchemeVariant:
                                                DynamicSchemeVariant.vibrant,
                                          )
                                        : untisThemeScheme(
                                            visualTheme,
                                            Brightness.light,
                                            seed,
                                          );

                                    var darkScheme =
                                        (canUseDynamic &&
                                            useMaterialYou &&
                                            darkDynamic != null)
                                        ? darkDynamic.harmonized()
                                        : (canUseDynamic &&
                                              useMaterialYou &&
                                              lightDynamic != null)
                                        ? ColorScheme.fromSeed(
                                            seedColor: lightDynamic.primary,
                                            brightness: Brightness.dark,
                                            dynamicSchemeVariant:
                                                DynamicSchemeVariant.vibrant,
                                          )
                                        : untisThemeScheme(
                                            visualTheme,
                                            Brightness.dark,
                                            seed,
                                          );

                                    if (isAmoled &&
                                        visualTheme ==
                                            AppThemeId.defaultTheme) {
                                      darkScheme = darkScheme.copyWith(
                                        surface: Colors.black,
                                        surfaceContainerLowest: Colors.black,
                                        surfaceContainerLow: Color.alphaBlend(
                                          darkScheme.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                          const Color(0xFF0A0A0A),
                                        ),
                                        surfaceContainer: Color.alphaBlend(
                                          darkScheme.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          const Color(0xFF111111),
                                        ),
                                        surfaceContainerHigh: Color.alphaBlend(
                                          darkScheme.primary.withValues(
                                            alpha: 0.16,
                                          ),
                                          const Color(0xFF1A1A1A),
                                        ),
                                        surfaceContainerHighest:
                                            Color.alphaBlend(
                                              darkScheme.primary.withValues(
                                                alpha: 0.20,
                                              ),
                                              const Color(0xFF222222),
                                            ),
                                      );
                                    }

                                    final l = AppL10n.of(locale);

                                    return ValueListenableBuilder<bool>(
                                      valueListenable:
                                          glowEffectsEnabledNotifier,
                                      builder: (context, glowEnabled, _) {
                                        return MaterialApp(
                                          debugShowCheckedModeBanner: false,
                                          title: l.appName,
                                          scrollBehavior:
                                              const _UntisScrollBehavior(),
                                          theme: _themeFrom(
                                            lightScheme,
                                            isAmoled,
                                            blurEnabled,
                                            glowEnabled,
                                            visualTheme,
                                          ),
                                          darkTheme: _themeFrom(
                                            darkScheme,
                                            isAmoled,
                                            blurEnabled,
                                            glowEnabled,
                                            visualTheme,
                                          ),
                                          themeMode: themeMode,
                                          themeAnimationDuration: Duration.zero,
                                          builder: (context, child) {
                                            final isDark =
                                                Theme.of(context).brightness ==
                                                Brightness.dark;
                                            final overlayStyle =
                                                SystemUiOverlayStyle(
                                                  statusBarColor:
                                                      Colors.transparent,
                                                  statusBarIconBrightness:
                                                      isDark
                                                      ? Brightness.light
                                                      : Brightness.dark,
                                                  statusBarBrightness: isDark
                                                      ? Brightness.dark
                                                      : Brightness.light,
                                                  systemNavigationBarColor:
                                                      Colors.transparent,
                                                  systemNavigationBarIconBrightness:
                                                      isDark
                                                      ? Brightness.light
                                                      : Brightness.dark,
                                                );
                                            return AnnotatedRegion<
                                              SystemUiOverlayStyle
                                            >(
                                              value: overlayStyle,
                                              child:
                                                  child ??
                                                  const SizedBox.shrink(),
                                            );
                                          },
                                          home: startScreen,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Keeps the platform scroll physics but suppresses Android's overscroll
/// glow/stretch, which otherwise flashes behind text at the end of a page.
class _UntisScrollBehavior extends MaterialScrollBehavior {
  const _UntisScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
