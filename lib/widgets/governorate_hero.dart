// widgets/governorate_hero.dart
//
// بطاقة الغلاف الموحدة للمحافظة.
// الهوية الوطنية ثابتة، والصورة الحقيقية هي الطبقة المحلية المتغيرة.
// إذا لم توجد صورة مصرح بها، نستخدم خلفية الهوية الوطنية بدل عرض صورة مجهولة المصدر.

import 'package:flutter/material.dart';
import '../models/governorate_visual_profile.dart';
import '../theme/app_colors.dart';

class GovernorateHero extends StatelessWidget {
  final String governorateName;
  final String? subtitle;
  final GovernorateVisualProfile? visual;
  final VoidCallback? onTap;

  const GovernorateHero({
    super.key,
    required this.governorateName,
    this.subtitle,
    this.visual,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = visual != null && visual!.heroImageUrl.trim().isNotEmpty;

    return Semantics(
      button: onTap != null,
      label: governorateName,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppColors.primary,
            boxShadow: const [
              BoxShadow(blurRadius: 18, offset: Offset(0, 8), color: Color(0x22000000)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(
                  visual!.heroImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withValues(alpha: .88),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'يا بلدي',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      governorateName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 27,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                    if (visual?.credit.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        'الصورة: ${visual!.credit}',
                        style: const TextStyle(color: Colors.white54, fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
