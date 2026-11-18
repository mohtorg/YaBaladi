// lib/features/about/screens/about_screen.dart
// [v1.1 — 2026-11-15] — VERIFIED: Clean file, no linter issues, no address formatting needed.
// [v1.0 — 2026-11-03] — NEW: About screen with app info.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('عن التطبيق'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.6)
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.location_city,
                  color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'يا بلدي',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'الإصدار 1.0.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Text(
            'تطبيق "يا بلدي" هو دليلك الشامل لاكتشاف أفضل الأماكن، العروض، والخدمات في محافظتك. مهمتنا هي ربط المجتمع بأجمل تجاربه.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 32),
          _linkCard(theme, Icons.star_outline, 'قيم التطبيق',
              'شاركنا رأيك وساعدنا على التحسن', () {}),
          const SizedBox(height: 12),
          _linkCard(theme, Icons.share_outlined, 'شارك التطبيق',
              'شارك التطبيق مع أصدقائك', () {}),
          const SizedBox(height: 12),
          _linkCard(theme, Icons.email_outlined, 'اتصل بنا',
              'hello@yabaladi.app', () => _launch('mailto:hello@yabaladi.app')),
          const SizedBox(height: 12),
          _linkCard(theme, Icons.language, 'الموقع الرسمي', 'yabaladi.app',
              () => _launch('https://yabaladi.app')),
          const SizedBox(height: 32),
          Text(
            'صُنع بحب في مصر 🇪🇬',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 YaBaladi. All rights reserved.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(ThemeData theme, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
