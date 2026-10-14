import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../l10n/theme_controller.dart';
import '../theme/design_tokens.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/language_picker_dialog.dart';
import '../widgets/theme_picker_dialog.dart';
import '../widgets/ya_app_bar.dart';

/// شاشة الإعدادات.
///
/// [v1.6 — StatefulWidget Migration for Analyzer]
///   - CHANGE: تحويل من StatelessWidget → StatefulWidget
///   - FIX: استخدام `mounted` (من State) بدل `context.mounted` (parameter)
///          لأن Analyzer لا يعترف بـ `context.mounted` على parameter
///   - FIX: الآن لا تحذيرات "BuildContext across async gaps"
///
/// [v1.5 — BuildContext Analyzer Fix Attempt]
///
/// [v1.4 — D4 full: provider-aware re-auth]
///   - NEW: password dialog عند الحساب Email/Password
///   - NEW: التعامل الذكي حسب auth.hasGoogleProvider / hasPasswordProvider
///
/// [v1.3 — BuildContext Guard Fix]
///
/// [v1.2 — D4 Re-auth Preparation]
///
/// [v1.1 — 2026-10-13]
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = context.watch<LocaleController>();
    final themeController = context.watch<ThemeController>();
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: YaAppBar(title: l10n.settings),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: YaBaladiDesignTokens.space2,
        ),
        children: [
          // ═══════ المظهر ═══════
          _SectionHeader(title: l10n.settingsAppearance),
          _LanguageTile(localeController: localeController),
          _ThemeTile(themeController: themeController),
          const SizedBox(height: YaBaladiDesignTokens.space4),

          // ═══════ الخصوصية والأذونات ═══════
          _SectionHeader(title: l10n.settingsPrivacySection),
          _SettingTile(
            icon: Icons.location_on_outlined,
            title: l10n.locationLabel,
            subtitle: l10n.locationOnDemand,
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.cleaning_services_outlined,
            title: l10n.clearCacheLabel,
            subtitle: l10n.clearCacheSubtitle,
            onTap: _confirmClearCache,
          ),
          const SizedBox(height: YaBaladiDesignTokens.space4),

          // ═══════ القانوني والسياسات ═══════
          _SectionHeader(title: l10n.settingsLegal),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicyLabel,
            subtitle: l10n.privacyPolicySubtitle,
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.description_outlined,
            title: l10n.termsLabel,
            subtitle: l10n.termsSubtitle,
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.info_outline,
            title: l10n.aboutLabel,
            subtitle: l10n.aboutSubtitle,
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.numbers,
            title: l10n.versionLabel,
            subtitle: l10n.versionValue,
            onTap: null,
          ),

          // ═══════ منطقة الخطر ═══════
          if (auth.isLoggedIn) ...[
            const SizedBox(height: YaBaladiDesignTokens.space4),
            _SectionHeader(title: l10n.settingsDangerSection),
            _SettingTile(
              icon: Icons.delete_forever,
              title: l10n.deleteAccountLabel,
              subtitle: l10n.deleteAccountSubtitle,
              isDestructive: true,
              onTap: _confirmDeleteAccount,
            ),
          ],

          const SizedBox(height: YaBaladiDesignTokens.space6),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONFIRMATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _confirmClearCache() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showYaConfirmDialog(
      context: context,
      title: l10n.clearCacheLabel,
      message: l10n.clearCacheConfirm,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await FirebaseFirestore.instance.clearPersistence();
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.enableNetwork();

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.clearCacheSuccess)),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء المسح')),
        );
    }
  }

  /// [v1.6] حذف الحساب — 3 مراحل:
  ///   1) تحذير عام
  ///   2) تأكيد نهائي (نصه يعتمد على نوع الحساب)
  ///   3) التنفيذ حسب المزود (Google / Email+Password)
  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthController>();

    final isPasswordAccount = auth.hasPasswordProvider;
    final isGoogleAccount = auth.hasGoogleProvider;

    // ── 1) تحذير عام ──
    final confirmed = await showYaConfirmDialog(
      context: context,
      title: l10n.deleteAccountLabel,
      message: l10n.deleteAccountWarning,
      confirmLabel: l10n.deleteAccountButton,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // ── 2) تأكيد نهائي — نص مخصص حسب المزود ──
    final String secondMessage;
    if (isPasswordAccount) {
      secondMessage = 'للتأكيد النهائي، سيُطلب منك إدخال كلمة المرور.\n\n'
          'هذه خطوة أمان إضافية لمنع الحذف العرضي.\n\n'
          'هل أنت متأكد من المتابعة؟';
    } else if (isGoogleAccount) {
      secondMessage =
          'للتأكيد النهائي، سيتم فتح نافذة Google لإعادة التحقق من هويتك.\n\n'
          'هذه خطوة أمان إضافية لمنع الحذف العرضي.\n\n'
          'هل أنت متأكد من المتابعة؟';
    } else {
      secondMessage = 'هذه العملية نهائية ولا يمكن التراجع عنها.\n\n'
          'هل أنت متأكد من المتابعة؟';
    }

    final doubleConfirmed = await showYaConfirmDialog(
      context: context,
      title: l10n.deleteAccountLabel,
      message: secondMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );

    if (doubleConfirmed != true) return;
    if (!mounted) return;

    // ── 3) تحديد كلمة المرور (إن كانت مطلوبة) ──
    String? password;
    if (isPasswordAccount) {
      password = await _showPasswordDialog();
      if (password == null || password.isEmpty) return;
      if (!mounted) return;
    }

    // ── 4) التنفيذ ──
    final result = await auth.deleteAccount(password: password);

    if (!mounted) return;

    if (result.isCancelled) return;

    if (!result.isSuccess) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'حدث خطأ أثناء حذف الحساب'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('تم حذف الحساب بنجاح')),
      );
  }

  /// [v1.6] Dialog لكلمة المرور — لحسابات Email/Password.
  Future<String?> _showPasswordDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _PasswordConfirmDialog(
        onConfirm: (password) => Navigator.of(dialogContext).pop(password),
        onCancel: () => Navigator.of(dialogContext).pop(null),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PASSWORD CONFIRM DIALOG
// ═══════════════════════════════════════════════════════════════

class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final ValueChanged<String> onConfirm;
  final VoidCallback onCancel;

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    if (value.isEmpty) return;
    widget.onConfirm(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.lock_outline,
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: const Text('تأكيد كلمة المرور'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'لأسباب أمنية، أدخل كلمة المرور لإتمام حذف الحساب.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            focusNode: _focus,
            obscureText: _obscure,
            autofocus: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.password),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: _submit,
          child: const Text('تأكيد الحذف'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        YaBaladiDesignTokens.space5,
        YaBaladiDesignTokens.space4,
        YaBaladiDesignTokens.space4,
        YaBaladiDesignTokens.space2,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LANGUAGE TILE
// ═══════════════════════════════════════════════════════════════

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        final current = localeController.isArabic
            ? l10n.languageArabic
            : l10n.languageEnglish;

        return _SettingTile(
          icon: Icons.language,
          title: l10n.languageLabel,
          subtitle: current,
          onTap: () => LanguagePickerDialog.show(
            context,
            controller: localeController,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// THEME TILE
// ═══════════════════════════════════════════════════════════════

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final current = themeController.isSystem
            ? l10n.themeSystem
            : themeController.isLight
                ? l10n.themeLight
                : l10n.themeDark;

        return _SettingTile(
          icon: Icons.palette_outlined,
          title: l10n.themeLabel,
          subtitle: current,
          onTap: () => ThemePickerDialog.show(
            context,
            controller: themeController,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SETTING TILE
// ═══════════════════════════════════════════════════════════════

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_left,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
    );
  }
}
