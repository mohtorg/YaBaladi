// مركز الخصوصية والأمان: يوضح الصلاحيات الفعلية واستخدامها وحدودها.
// لا نَعِد بأمان مطلق؛ نعرض الضوابط التي يمكن للمستخدم مراجعتها.
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    final ar = lang == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of('privacy_title', lang)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.verified_user_outlined, size: 42, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(AppStrings.of('privacy_intro', lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(AppStrings.of('privacy_denied', lang)),
        ]))),
        const SizedBox(height: 16),
        _section(AppStrings.of('privacy_permissions_title', lang), [
          _item(Icons.location_on_outlined, AppStrings.of('privacy_permission_location', lang)),
          _item(Icons.camera_alt_outlined, AppStrings.of('privacy_permission_camera', lang)),
          _item(Icons.fingerprint, AppStrings.of('privacy_permission_biometric', lang)),
        ]),
        _section(ar ? 'ما لا نطلبه' : 'What we do not request', [
          _item(Icons.contacts_outlined, AppStrings.of('privacy_no_contacts', lang)),
          _item(Icons.sms_outlined, AppStrings.of('privacy_no_sms', lang)),
        ]),
        _section(ar ? 'كيف نستخدم الصلاحيات' : 'How permissions are used', [
          _item(Icons.my_location_outlined, AppStrings.of('privacy_location', lang)),
          _item(Icons.qr_code_scanner_outlined, AppStrings.of('privacy_camera', lang)),
          _item(Icons.fingerprint, AppStrings.of('privacy_biometric', lang)),
        ]),
        Card(child: ListTile(leading: const Icon(Icons.settings_outlined), title: Text(AppStrings.of('privacy_settings', lang)), subtitle: Text(ar ? 'إعدادات الهاتف > التطبيقات > يا بلدي > الأذونات' : 'Phone Settings > Apps > Ya Baladi > Permissions'))),
      ]),
    );
  }
  Widget _section(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)), const SizedBox(height: 6), ...children])));
  Widget _item(IconData icon, String text) => ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: Icon(icon, color: AppColors.primary), title: Text(text));
}
