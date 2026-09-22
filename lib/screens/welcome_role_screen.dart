// screens/welcome_role_screen.dart
// الغرض: جعل اختيار مسار الاستخدام هو أول قرار بصري في تجربة التسجيل.
// المقيم والزائر حساب شخصي واحد، ومقدم الخدمة مسار تجاري مستقل.
// لا يوجد Admin هنا؛ صلاحيات الإدارة تأتي من Firebase ولا يختارها المستخدم.

import 'package:flutter/material.dart';
import '../models/app_experience_mode.dart';
import '../theme/app_colors.dart';
import '../services/entry_intent.dart';
import 'login_screen.dart';

class WelcomeRoleScreen extends StatelessWidget {
  const WelcomeRoleScreen({super.key});

  void _openLogin(BuildContext context, {AppExperienceMode? mode, bool merchant = false}) {
    if (merchant) {
      EntryIntent.setMerchant();
    } else if (mode != null) {
      EntryIntent.setPersonal(mode);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(initialMode: mode, initialMerchant: merchant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/branding/ya_baladi_icon.png',
                  width: 86,
                  height: 86,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'يا بلدي',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'اكتشف .. استمتع .. ادعم بلدك',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 34),
              const Text(
                'كيف ستستخدم يا بلدي؟',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر المسار الذي يناسبك الآن، ويمكن تغييره لاحقًا للمستخدم الشخصي.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.45),
              ),
              const SizedBox(height: 24),
              _PathCard(
                icon: Icons.home_work_outlined,
                title: 'أنا مقيم',
                subtitle: 'اكتشف مدينتك وكل ما حولك.',
                iconColor: const Color(0xFF1B70C9),
                onTap: () => _openLogin(context, mode: AppExperienceMode.resident),
              ),
              const SizedBox(height: 12),
              _PathCard(
                icon: Icons.luggage_outlined,
                title: 'أنا زائر',
                subtitle: 'خطط ليومك واكتشف أفضل التجارب.',
                iconColor: const Color(0xFF2D9A78),
                onTap: () => _openLogin(context, mode: AppExperienceMode.visitor),
              ),
              const SizedBox(height: 12),
              _PathCard(
                icon: Icons.storefront_outlined,
                title: 'أنا مقدم خدمة',
                subtitle: 'اعرض نشاطك ووصل إلى عملاء جدد.',
                iconColor: const Color(0xFFE38A2E),
                onTap: () => _openLogin(context, merchant: true),
              ),
              const SizedBox(height: 24),
              const Text(
                'اختيارك لا يمنح أي صلاحيات إدارية. الإدارة لها نظام صلاحيات منفصل وآمن.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _PathCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: iconColor.withValues(alpha: .12),
                child: Icon(icon, color: iconColor, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
