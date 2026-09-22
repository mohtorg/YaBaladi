// screens/experience_mode_screen.dart
// تغيير مسار الاستخدام للحساب الشخصي بين "مقيم" و"زائر".
// لا يغيّر role ولا يمس صلاحيات مقدم الخدمة/الإدارة.

import 'package:flutter/material.dart';
import '../models/app_experience_mode.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ExperienceModeScreen extends StatelessWidget {
  const ExperienceModeScreen({super.key});

  Future<void> _change(BuildContext context, AppExperienceMode mode) async {
    try {
      await AuthService().setExperienceMode(mode);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تغيير الوضع: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طريقة استخدام يا بلدي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().currentAppUserStream,
        builder: (context, snapshot) {
          final current = snapshot.data?.experienceMode;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'يمكنك تغيير المسار في أي وقت حسب استخدامك الحالي.',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 18),
              _ModeTile(
                icon: Icons.home_work_outlined,
                title: 'مقيم',
                subtitle: 'اكتشاف المدينة والخدمات والعروض اليومية.',
                selected: current == AppExperienceMode.resident,
                onTap: () => _change(context, AppExperienceMode.resident),
              ),
              const SizedBox(height: 12),
              _ModeTile(
                icon: Icons.luggage_outlined,
                title: 'زائر',
                subtitle: 'اكتشاف المكان ورحلة اليوم والأنشطة المناسبة للزيارة.',
                selected: current == AppExperienceMode.visitor,
                onTap: () => _change(context, AppExperienceMode.visitor),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: .10),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.chevron_left),
        onTap: selected ? null : onTap,
      ),
    );
  }
}
