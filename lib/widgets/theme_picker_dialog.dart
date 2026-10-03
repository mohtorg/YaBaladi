import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/theme_controller.dart';
import '../theme/design_tokens.dart';

/// A professional Material 3 dialog for picking the app's theme mode.
///
/// Features:
/// - Three options: System, Light, Dark
/// - Icons for each mode
/// - Shows current mode with a check mark
/// - Applies immediately on selection
class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({
    super.key,
    required this.controller,
  });

  final ThemeController controller;

  /// Show the dialog and return the selected mode (or null if dismissed).
  static Future<ThemeMode?> show(
    BuildContext context, {
    required ThemeController controller,
  }) {
    return showDialog<ThemeMode>(
      context: context,
      builder: (_) => ThemePickerDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.themeSelectTitle),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space2,
        vertical: YaBaladiDesignTokens.space3,
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.themeSelectSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space4),

            // System
            _ThemeOptionTile(
              title: l10n.themeSystem,
              subtitle: l10n.themeSystemSubtitle,
              leading: Icons.brightness_auto,
              isSelected: controller.isSystem,
              onTap: () => _select(context, ThemeMode.system),
            ),

            const SizedBox(height: YaBaladiDesignTokens.space2),

            // Light
            _ThemeOptionTile(
              title: l10n.themeLight,
              subtitle: l10n.themeLightSubtitle,
              leading: Icons.light_mode,
              isSelected: controller.isLight,
              onTap: () => _select(context, ThemeMode.light),
            ),

            const SizedBox(height: YaBaladiDesignTokens.space2),

            // Dark
            _ThemeOptionTile(
              title: l10n.themeDark,
              subtitle: l10n.themeDarkSubtitle,
              leading: Icons.dark_mode,
              isSelected: controller.isDark,
              onTap: () => _select(context, ThemeMode.dark),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _select(BuildContext context, ThemeMode mode) async {
    await controller.setMode(mode);
    if (context.mounted) {
      Navigator.of(context).pop(mode);
    }
  }
}

// ============================================================
// THEME OPTION TILE
// ============================================================

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData leading;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(
        YaBaladiDesignTokens.radiusMedium,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          YaBaladiDesignTokens.radiusMedium,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YaBaladiDesignTokens.space4,
            vertical: YaBaladiDesignTokens.space3,
          ),
          child: Row(
            children: [
              Icon(
                leading,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: YaBaladiDesignTokens.space3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: theme.colorScheme.outline,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}