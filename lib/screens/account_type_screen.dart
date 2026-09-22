// screens/account_type_screen.dart
//
// نقطة الدخول بعد أول تسجيل ناجح للحساب العام.
// الفصل مهم هنا: "مقيم" و"زائر" ليسا دورين أمنيّين؛ كلاهما role=user
// لكن لكل واحد تجربة استخدام مختلفة. "مقدم خدمة" هو role=merchant ومساره منفصل.
// لا نضيف Admin إلى هذه الشاشة؛ الصلاحيات الإدارية تأتي من Firebase فقط.

import 'package:flutter/material.dart';
import '../models/app_experience_mode.dart';
import '../services/auth_service.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';
import '../services/quick_auth_service.dart';
import '../services/entry_intent.dart';

class AccountTypeScreen extends StatefulWidget {
  final bool initialMerchant;

  const AccountTypeScreen({super.key, this.initialMerchant = false});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  @override
  void initState() {
    super.initState();
    _showMerchantForm = widget.initialMerchant;
  }

  bool _showMerchantForm = false;
  bool _isLoading = false;
  final QuickAuthService _quickAuth = QuickAuthService();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _offerQuickAuth() async {
    // تفعيل الدخول السريع اختياري. عند الموافقة نطلب مصادقة الجهاز أولًا،
    // ثم نحفظ فقط علم التفعيل؛ لا يتم تخزين نمط/PIN أو بصمة المستخدم.
    try {
      if (!await _quickAuth.isDeviceSupported()) return;
      if (!mounted) return;
      final enable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تفعيل الدخول السريع؟'),
          content: const Text('في المرات القادمة يمكنك فتح يا بلدي ببصمة الإصبع أو نمط/PIN الهاتف بدل إعادة تسجيل الدخول.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لاحقًا')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تفعيل')),
          ],
        ),
      );
      if (enable != true) return;
      final authenticated = await _quickAuth.authenticate();
      if (authenticated) await _quickAuth.setEnabled(true);
    } catch (_) {
      // عدم دعم الجهاز للدخول السريع لا يمنع إنشاء الحساب أو استخدام التطبيق.
    }
  }

  Future<void> _selectPersonalMode(AppExperienceMode mode) async {
    final lang = LocaleController.of(context).locale.languageCode;
    setState(() => _isLoading = true);
    try {
      await _offerQuickAuth();
      // role=user ثابت للحساب الشخصي، وmode فقط هو الذي يحدد تجربة الدخول.
      await AuthService().setAccountType(role: 'user');
      await AuthService().setExperienceMode(mode);
      EntryIntent.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of('account_type_save_error', lang)}: $e')),
      );
    }
  }

  Future<void> _selectMerchant() async {
    final lang = LocaleController.of(context).locale.languageCode;
    if (_businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of('business_name_required', lang))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _offerQuickAuth();
      await AuthService().setAccountType(
        role: 'merchant',
        businessName: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      EntryIntent.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of('merchant_create_error', lang)}: $e')),
      );
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.of('mode_title', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.of('mode_subtitle', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    _ModeCard(
                      icon: Icons.home_work_outlined,
                      title: AppStrings.of('resident_mode', lang),
                      subtitle: AppStrings.of('resident_mode_desc', lang),
                      onTap: () => _selectPersonalMode(AppExperienceMode.resident),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.luggage_outlined,
                      title: AppStrings.of('visitor_mode', lang),
                      subtitle: AppStrings.of('visitor_mode_desc', lang),
                      onTap: () => _selectPersonalMode(AppExperienceMode.visitor),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.storefront_outlined,
                      title: AppStrings.of('provider_mode', lang),
                      subtitle: AppStrings.of('provider_mode_desc', lang),
                      onTap: () => setState(() => _showMerchantForm = true),
                    ),
                    if (_showMerchantForm) ...[
                      const SizedBox(height: 18),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.of('provider_details', lang),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _businessNameController,
                                decoration: InputDecoration(labelText: AppStrings.of('business_name', lang),
                                  prefixIcon: const Icon(Icons.business),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(labelText: AppStrings.of('phone_optional', lang),
                                  prefixIcon: const Icon(Icons.phone),
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _selectMerchant,
                                icon: const Icon(Icons.arrow_forward),
                                label: Text(AppStrings.of('continue_as_provider', lang)),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _showMerchantForm = false),
                                child: Text(AppStrings.of('back_to_choices', lang)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      AppStrings.of('mode_note', lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withValues(alpha: .10),
                child: Icon(icon, color: AppColors.primary, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}



