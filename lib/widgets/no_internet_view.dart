// lib/widgets/no_internet_view.dart
//
// [v1.1 — 2026-10-25] — i18n of hard-coded strings
//   - FIX: العنوان والرسالة وزر إعادة المحاولة صارت عبر AppLocalizations
//          (pending_strings.dart: noInternetTitle, noInternetBody, retryNow).
//   - KEPT: التصميم وواجهة الويدجت (onRetry) دون تغيير.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/pending_strings.dart';

class NoInternetView extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة إبداعية تعبر عن الانقطاع
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // الرسالة الإبداعية
            Text(
              l10n.noInternetTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noInternetBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // زر إعادة المحاولة
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                l10n.retryNow,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
