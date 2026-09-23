// مركز إعدادات موحّد للمستخدم ومقدم الخدمة.
// مهم: لا نضع اختيار "أدمن/مشرف" هنا؛ الصلاحيات الإدارية تأتي من Firebase فقط.
// تسجيل الخروج موجود هنا فقط لتجنب تكرار الإجراء في أكثر من شاشة.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'notification_settings_screen.dart';
import 'experience_mode_screen.dart';
import '../services/quick_auth_service.dart';
import 'privacy_security_screen.dart';
import 'support_center_screen.dart';

class SettingsTabScreen extends StatelessWidget {
  const SettingsTabScreen({super.key});

  Future<void> _whatsapp() async {
    final u = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('مرحبًا يا بلدي، أريد التواصل معكم')}');
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<void> _invite(BuildContext context, String lang) async {
    final uid = AuthService().currentUser?.uid ?? '';
    final message = lang == 'en'
        ? 'Join me on Ya Baladi. My invitation code: $uid'
        : 'انضم معي إلى تطبيق يا بلدي. كود الدعوة الخاص بي: $uid';
    final u = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  void _dialog(BuildContext context, String title, String body, String close) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(title), content: SingleChildScrollView(child: Text(body)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(close))]));
  }

  Future<void> _complaint(BuildContext context, String lang) async {
    final title = TextEditingController();
    final body = TextEditingController();
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final sent = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(AppStrings.of('complaints', lang)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: InputDecoration(labelText: AppStrings.of('subject', lang))),
        const SizedBox(height: 8),
        TextField(controller: body, maxLines: 4, decoration: InputDecoration(labelText: AppStrings.of('details', lang))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.of('cancel', lang))),
        FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().isNotEmpty && body.text.trim().isNotEmpty), child: Text(AppStrings.of('send', lang))),
      ],
    ));
    if (sent == true) {
      await FirebaseFirestore.instance.collection('support_tickets').add({'userId': uid, 'subject': title.text.trim(), 'details': body.text.trim(), 'status': 'new', 'createdAt': FieldValue.serverTimestamp()});
      title.dispose(); body.dispose();
      if (context.mounted) _dialog(context, AppStrings.of('sent', lang), AppStrings.of('support_sent_message', lang), AppStrings.of('close', lang));
    } else { title.dispose(); body.dispose(); }
  }

  @override
  Widget build(BuildContext context) {
    final ctl = LocaleController.of(context);
    final lang = ctl.locale.languageCode;
    final ar = lang == 'ar';
    final user = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of('settings', lang)), backgroundColor: const Color(0xFF1454A3), foregroundColor: Colors.white),
      body: ListView(children: [
        FutureBuilder<AppUser?>(
          future: AuthService().getCurrentAppUser(),
          builder: (context, snapshot) {
            final appUser = snapshot.data;
            if (appUser == null || appUser.isMerchant) return const SizedBox.shrink();
            return ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(AppStrings.of('visitor_experience_settings', lang)),
              subtitle: Text(AppStrings.of('visitor_experience_subtitle', lang)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExperienceModeScreen()),
              ),
            );
          },
        ),
        ListTile(leading: const Icon(Icons.language), title: Text(AppStrings.of('language', lang)), subtitle: Text(ar ? 'العربية' : 'English'), trailing: Switch(value: ar, onChanged: (_) => ctl.toggleLocale())),
        const _QuickAuthTile(),
        _Section(AppStrings.of('help_contact', lang)),
        ListTile(leading: const Icon(Icons.support_agent), title: Text(AppStrings.of('support_center', lang)), subtitle: Text(AppStrings.of('support_center_subtitle', lang)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportCenterScreen()))),
        ListTile(leading: const Icon(Icons.chat), title: Text(AppStrings.of('contact_whatsapp', lang)), onTap: _whatsapp),
        ListTile(leading: const Icon(Icons.feedback_outlined), title: Text(AppStrings.of('complaints', lang)), onTap: () => _complaint(context, lang)),
        ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(AppStrings.of('privacy_security', lang)), subtitle: Text(AppStrings.of('privacy_security_subtitle', lang)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()))),
        _Section(AppStrings.of('legal', lang)),
        ListTile(leading: const Icon(Icons.description), title: Text(AppStrings.of('terms_user', lang)), onTap: () => _dialog(context, AppStrings.of('terms_user', lang), ar ? 'الشروط والأحكام الخاصة باستخدام تطبيق يا بلدي للمستخدمين. سيتم استبدال هذه الصيغة بالنص القانوني المعتمد قبل الإطلاق.' : 'Terms and conditions for Ya Baladi users. This placeholder will be replaced by the approved legal text before launch.', AppStrings.of('close', lang))),
        ListTile(leading: const Icon(Icons.store), title: Text(AppStrings.of('terms_merchant', lang)), onTap: () => _dialog(context, AppStrings.of('terms_merchant', lang), ar ? 'الشروط والأحكام الخاصة بمقدمي الخدمات. سيتم استبدال هذه الصيغة بالنص القانوني المعتمد قبل الإطلاق.' : 'Terms and conditions for service providers. This placeholder will be replaced by the approved legal text before launch.', AppStrings.of('close', lang))),
        _Section(AppStrings.of('sharing', lang)),
        ListTile(leading: const Icon(Icons.group_add), title: Text(AppStrings.of('invite_friends', lang)), subtitle: Text(ar ? 'مشاركة كود الدعوة عبر واتساب' : 'Share your invitation code via WhatsApp'), onTap: () => _invite(context, lang)),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.all(16), child: OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(AppStrings.of('logout', lang)),
              content: Text('${ar ? 'هل تريد تسجيل الخروج من' : 'Do you want to sign out from'} ${user?.email ?? (ar ? 'حسابك' : 'your account')}؟'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.of('cancel', lang))),
                FilledButton(onPressed: () async { Navigator.pop(context); await AuthService().signOut(); }, child: Text(AppStrings.of('logout', lang))),
              ],
            ),
          ),
          icon: const Icon(Icons.logout, color: Colors.red), label: Text(AppStrings.of('logout', lang), style: const TextStyle(color: Colors.red)),
        )),
      ]),
    );
  }
}

class _QuickAuthTile extends StatefulWidget {
  const _QuickAuthTile();

  @override
  State<_QuickAuthTile> createState() => _QuickAuthTileState();
}

class _QuickAuthTileState extends State<_QuickAuthTile> {
  final QuickAuthService _service = QuickAuthService();
  bool _supported = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final supported = await _service.isDeviceSupported();
      final enabled = supported ? await _service.isEnabled() : false;
      if (!mounted) return;
      setState(() { _supported = supported; _enabled = enabled; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _supported = false; _loading = false; });
    }
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final ok = await _service.authenticate();
      if (!ok) return;
    }
    await _service.setEnabled(value);
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_supported) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.fingerprint),
      title: Text(AppStrings.of('quick_auth', LocaleController.of(context).locale.languageCode)),
      subtitle: Text(_enabled ? AppStrings.of('quick_auth_enabled', LocaleController.of(context).locale.languageCode) : AppStrings.of('quick_auth_enable', LocaleController.of(context).locale.languageCode)),
      trailing: Switch(value: _enabled, onChanged: _toggle),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 6), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1454A3))));
}
