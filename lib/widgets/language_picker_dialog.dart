import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../theme/design_tokens.dart';

/// A professional Material 3 dialog for picking the app's language.
///
/// Features:
/// - Radio-style selection between Arabic and English
/// - Shows language name in its own script (العربية / English)
/// - Shows RTL/LTR direction hint
/// - Shows current language with a check mark
/// - Applies immediately on selection (no apply button)
class LanguagePickerDialog extends StatelessWidget {
  const LanguagePickerDialog({
    super.key,
    required this.controller,
  });

  final LocaleController controller;

  /// Show the dialog and return the selected locale (or null if dismissed).
  static Future<Locale?> show(
    BuildContext context, {
    required LocaleController controller,
  }) {
    return showDialog<Locale>(
      context: context,
      builder: (_) => LanguagePickerDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.languageSelectTitle),
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
              l10n.languageSelectSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space4),

            // Arabic option
            _LanguageOptionTile(
              title: l10n.languageArabic,
              subtitle: l10n.languageArabicSubtitle,
              leading: Icons.translate,
              isSelected: controller.isArabic,
              onTap: () => _select(context, LocaleController.arabicLocale),
            ),

            const SizedBox(height: YaBaladiDesignTokens.space2),

            // English option
            _LanguageOptionTile(
              title: l10n.languageEnglish,
              subtitle: l10n.languageEnglishSubtitle,
              leading: Icons.language,
              isSelected: controller.isEnglish,
              onTap: () => _select(context, LocaleController.englishLocale),
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

  Future<void> _select(BuildContext context, Locale locale) async {
    await controller.setLocale(locale);
    if (context.mounted) {
      Navigator.of(context).pop(locale);
    }
  }
}

// ============================================================
// LANGUAGE OPTION TILE
// ============================================================

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
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
              // Leading icon
              Icon(
                leading,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: YaBaladiDesignTokens.space3),

              // Title + Subtitle
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

              // Check icon
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