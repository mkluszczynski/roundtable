import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Assembles the single dark `ThemeData` per `docs/UI-DESIGN.md` §1. This app
/// only builds a dark theme — no light-mode counterpart.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: AppColors.accentInk,
    secondary: AppColors.live,
    onSecondary: AppColors.liveInk,
    error: AppColors.red,
    onError: Colors.white,
    surface: AppColors.bg1,
    onSurface: AppColors.text0,
    surfaceContainerHighest: AppColors.bg2,
    outline: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg0,
    canvasColor: AppColors.bg0,
    textTheme: AppTypography.textTheme,
    dividerColor: AppColors.border,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg0,
      foregroundColor: AppColors.text0,
      elevation: 0,
      titleTextStyle: AppTypography.screenTitle,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.bg1,
      selectedIconTheme: const IconThemeData(color: AppColors.accent),
      unselectedIconTheme: const IconThemeData(color: AppColors.text1),
      selectedLabelTextStyle: AppTypography.bodyStrong.copyWith(
        color: AppColors.accent,
      ),
      unselectedLabelTextStyle: AppTypography.body.copyWith(
        color: AppColors.text1,
      ),
      indicatorColor: AppColors.accent.withValues(alpha: 0.14),
      useIndicator: true,
    ),
    listTileTheme: ListTileThemeData(
      textColor: AppColors.text0,
      iconColor: AppColors.text1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
        side: BorderSide(color: AppColors.borderStrong),
      ),
      titleTextStyle: AppTypography.cardTitle,
      contentTextStyle: AppTypography.body,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentInk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.text1),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text0,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      labelStyle: AppTypography.body.copyWith(color: AppColors.text1),
      hintStyle: AppTypography.body.copyWith(color: AppColors.text2),
    ),
  );
}
