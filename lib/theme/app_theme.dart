// lib/theme/app_theme.dart
//
// [v3.0 — 2026-10-20] — Uses YaBaladiTypography (not AppTypography).
//   - Compatible with `app_typography.dart` v3.1 (separate file).
//   - All Material 3 components configured.
//   - light + dark themes.
//   - Depends on: YaBaladiDesignTokens (existing file).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_typography.dart';
import 'design_tokens.dart';

abstract final class AppTheme {
  AppTheme._();

  // ============================================================
  // LIGHT THEME
  // ============================================================
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: YaBaladiDesignTokens.primaryBlue,
      onPrimary: YaBaladiDesignTokens.white,
      primaryContainer: YaBaladiDesignTokens.primaryBlue,
      onPrimaryContainer: YaBaladiDesignTokens.white,
      secondary: YaBaladiDesignTokens.accentOrange,
      onSecondary: YaBaladiDesignTokens.white,
      tertiary: YaBaladiDesignTokens.navy,
      onTertiary: YaBaladiDesignTokens.white,
      error: YaBaladiDesignTokens.error,
      onError: YaBaladiDesignTokens.white,
      surface: YaBaladiDesignTokens.surface,
      onSurface: YaBaladiDesignTokens.textPrimary,
      surfaceContainerHighest: YaBaladiDesignTokens.surfaceVariant,
      outline: YaBaladiDesignTokens.border,
      outlineVariant: YaBaladiDesignTokens.divider,
      shadow: YaBaladiDesignTokens.grey900,
      scrim: YaBaladiDesignTokens.grey900,
      inverseSurface: YaBaladiDesignTokens.navy,
      onInverseSurface: YaBaladiDesignTokens.white,
      inversePrimary: YaBaladiDesignTokens.accentOrange,
    );

    return _buildTheme(colorScheme: colorScheme, isLight: true);
  }

  // ============================================================
  // DARK THEME
  // ============================================================
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: YaBaladiDesignTokens.primaryBlue,
      onPrimary: YaBaladiDesignTokens.white,
      primaryContainer: YaBaladiDesignTokens.navy,
      onPrimaryContainer: YaBaladiDesignTokens.white,
      secondary: YaBaladiDesignTokens.accentOrange,
      onSecondary: YaBaladiDesignTokens.white,
      tertiary: YaBaladiDesignTokens.gold,
      onTertiary: YaBaladiDesignTokens.grey900,
      error: YaBaladiDesignTokens.error,
      onError: YaBaladiDesignTokens.white,
      surface: YaBaladiDesignTokens.surfaceDark,
      onSurface: YaBaladiDesignTokens.textPrimaryDark,
      surfaceContainerHighest: YaBaladiDesignTokens.surfaceVariantDark,
      outline: YaBaladiDesignTokens.borderDark,
      outlineVariant: YaBaladiDesignTokens.dividerDark,
      shadow: YaBaladiDesignTokens.grey900,
      scrim: YaBaladiDesignTokens.grey900,
      inverseSurface: YaBaladiDesignTokens.white,
      onInverseSurface: YaBaladiDesignTokens.grey900,
      inversePrimary: YaBaladiDesignTokens.navy,
    );

    return _buildTheme(colorScheme: colorScheme, isLight: false);
  }

  // ============================================================
  // SHARED THEME BUILDER
  // ============================================================
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required bool isLight,
  }) {
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: YaBaladiTypography.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: YaBaladiDesignTokens.elevation0,
        centerTitle: false,
        titleTextStyle: YaBaladiTypography.headingSection.copyWith(
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      scaffoldBackgroundColor: isLight
          ? YaBaladiDesignTokens.background
          : YaBaladiDesignTokens.backgroundDark,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: YaBaladiDesignTokens.elevation1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(YaBaladiDesignTokens.radiusMedium),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.15),
        elevation: YaBaladiDesignTokens.elevation2,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return YaBaladiTypography.labelMedium.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return YaBaladiTypography.labelMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 26);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(
            YaBaladiDesignTokens.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: YaBaladiDesignTokens.space5,
            vertical: YaBaladiDesignTokens.space3,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(YaBaladiDesignTokens.radiusSmall),
            ),
          ),
          textStyle: YaBaladiTypography.labelLarge,
          elevation: YaBaladiDesignTokens.elevation0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(
            YaBaladiDesignTokens.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: YaBaladiDesignTokens.space5,
            vertical: YaBaladiDesignTokens.space3,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(YaBaladiDesignTokens.radiusSmall),
            ),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: YaBaladiTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(
            YaBaladiDesignTokens.minTouchTarget,
            YaBaladiDesignTokens.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: YaBaladiDesignTokens.space3,
            vertical: YaBaladiDesignTokens.space2,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(YaBaladiDesignTokens.radiusSmall),
            ),
          ),
          textStyle: YaBaladiTypography.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            YaBaladiDesignTokens.minTouchTarget,
            YaBaladiDesignTokens.minTouchTarget,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YaBaladiDesignTokens.space4,
          vertical: YaBaladiDesignTokens.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            YaBaladiDesignTokens.radiusSmall,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            YaBaladiDesignTokens.radiusSmall,
          ),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            YaBaladiDesignTokens.radiusSmall,
          ),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            YaBaladiDesignTokens.radiusSmall,
          ),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: YaBaladiTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: YaBaladiTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: YaBaladiTypography.caption.copyWith(
          color: colorScheme.error,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: YaBaladiTypography.labelMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: YaBaladiDesignTokens.space2,
          vertical: YaBaladiDesignTokens.space1,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: YaBaladiDesignTokens.elevation4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(YaBaladiDesignTokens.radiusLarge),
          ),
        ),
        titleTextStyle: YaBaladiTypography.headingSection.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: YaBaladiTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: YaBaladiDesignTokens.elevation4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(YaBaladiDesignTokens.radiusLarge),
          ),
        ),
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YaBaladiDesignTokens.space4,
          vertical: YaBaladiDesignTokens.space1,
        ),
        minVerticalPadding: YaBaladiDesignTokens.space2,
        titleTextStyle: YaBaladiTypography.bodyLarge.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: YaBaladiTypography.bodySmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        iconColor: colorScheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(YaBaladiDesignTokens.radiusSmall),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: YaBaladiTypography.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(YaBaladiDesignTokens.radiusSmall),
          ),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ============================================================
  // TEXT THEME
  // ============================================================
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: YaBaladiTypography.display.copyWith(
        color: colorScheme.onSurface,
      ),
      displayMedium: YaBaladiTypography.display.copyWith(
        color: colorScheme.onSurface,
      ),
      displaySmall: YaBaladiTypography.display.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineLarge: YaBaladiTypography.headingScreen.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineMedium: YaBaladiTypography.headingScreen.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineSmall: YaBaladiTypography.headingSection.copyWith(
        color: colorScheme.onSurface,
      ),
      titleLarge: YaBaladiTypography.headingSection.copyWith(
        color: colorScheme.onSurface,
      ),
      titleMedium: YaBaladiTypography.headingSubsection.copyWith(
        color: colorScheme.onSurface,
      ),
      titleSmall: YaBaladiTypography.headingLabel.copyWith(
        color: colorScheme.onSurface,
      ),
      bodyLarge: YaBaladiTypography.bodyLarge.copyWith(
        color: colorScheme.onSurface,
      ),
      bodyMedium: YaBaladiTypography.bodyMedium.copyWith(
        color: colorScheme.onSurface,
      ),
      bodySmall: YaBaladiTypography.bodySmall.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: YaBaladiTypography.labelLarge.copyWith(
        color: colorScheme.onSurface,
      ),
      labelMedium: YaBaladiTypography.labelMedium.copyWith(
        color: colorScheme.onSurface,
      ),
      labelSmall: YaBaladiTypography.labelSmall.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
