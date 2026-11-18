// lib/features/rating/widgets/variance_badge_widget.dart

import 'package:flutter/material.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

class VarianceBadgeWidget extends StatelessWidget {
  final double variance;
  final int totalRatings;

  const VarianceBadgeWidget({
    super.key,
    required this.variance,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    if (totalRatings < 3) {
      return const SizedBox.shrink();
    }

    final config = _configFor();

    return Container(
      padding: const EdgeInsets.all(YaBaladiDesignTokens.space2),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(YaBaladiDesignTokens.radiusSmall),
        border: Border.all(color: config.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 16),
          const SizedBox(width: YaBaladiDesignTokens.space2),
          Expanded(
            child: Text(
              config.label,
              style: YaBaladiTypography.caption.copyWith(
                color: config.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _VarianceConfig _configFor() {
    if (variance > 1.5) {
      return _VarianceConfig(
        label: 'الآراء متباينة — اقرأ التقييمات لتفهم لماذا',
        color: YaBaladiDesignTokens.warning,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (variance < 0.5 && totalRatings > 10) {
      return _VarianceConfig(
        label: 'إجماع مريب — كن حذرًا',
        color: YaBaladiDesignTokens.error,
        icon: Icons.info_outline_rounded,
      );
    }
    return _VarianceConfig(
      label: 'تباين طبيعي وصحي',
      color: YaBaladiDesignTokens.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }
}

class _VarianceConfig {
  final String label;
  final Color color;
  final IconData icon;
  const _VarianceConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
