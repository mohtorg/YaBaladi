// lib/features/admin/widgets/common_widgets.dart
//
// [v2.1 — FIXED] — UI OVERFLOW & INK SPLASH FIXES:
//   - FIXED: Added Flexible/FittedBox in AdminKpiCard to prevent number overflow.
//   - FIXED: Added Flexible in AdminMiniStat for long titles.
//   - FIXED: Used Expanded in AdminDetailRow to balance label/value widths.
//   - FIXED: Converted AdminSection Container to Material with clipBehavior.
//   - KEPT: All vivid gradients, colors, and typography intact.

import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';

// ═══════════════════════════════════════════════════════════════
// KPI CARD — بطاقة إحصائية رئيسية (VIVID + BOLD)
// ═══════════════════════════════════════════════════════════════
class AdminKpiCard extends StatelessWidget {
  final String title;
  final int count;
  final String unit;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AdminKpiCard({
    super.key,
    required this.title,
    required this.count,
    required this.unit,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                Color.lerp(color, Colors.black, 0.28)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.lerp(color, Colors.white, 0.35)!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // ✅ تغليف الرقم بـ Flexible و FittedBox لمنع انهيار الشاشة
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // ✅ تغليف الوحدة بـ Flexible
                  Flexible(
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI STAT — بطاقة إحصائية صغيرة
// ═══════════════════════════════════════════════════════════════
class AdminMiniStat extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const AdminMiniStat({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          // ✅ تغليف النص بـ Flexible لمنع انهيار الشاشة
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DETAIL ROW — سطر تفاصيل (Label + Value)
// ═══════════════════════════════════════════════════════════════
class AdminDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const AdminDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ استخدام Expanded لضمان توزيع المساحة بالتساوي ومنع الانكسار
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SERVICE CHIP — رقاقة خدمة
// ═══════════════════════════════════════════════════════════════
class AdminServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const AdminServiceChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION WRAPPER — قسم موحد
// ═══════════════════════════════════════════════════════════════
class AdminSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const AdminSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ تحويل الـ Container إلى Material مع clipBehavior
    // لضمان بقاء تأثير الموجة (Ink Splash) داخل الحواف الدائرية لأي ListTile بداخل children
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: YaBaladiDesignTokens.primaryBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1.5,
            color: theme.colorScheme.outlineVariant,
          ),
          ...children,
        ],
      ),
    );
  }
}
