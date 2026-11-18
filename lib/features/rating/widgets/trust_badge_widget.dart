// lib/features/rating/widgets/trust_badge_widget.dart

import 'package:flutter/material.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

class TrustBadgeWidget extends StatelessWidget {
  final String verificationMethod; // GPS_PIN | GPS | PIN | SELF_DECLARED

  const TrustBadgeWidget({
    super.key,
    required this.verificationMethod,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configFor(verificationMethod);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space2,
        vertical: YaBaladiDesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(YaBaladiDesignTokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: YaBaladiDesignTokens.space1),
          Text(
            config.label,
            style: YaBaladiTypography.caption.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _configFor(String method) {
    switch (method) {
      case 'GPS_PIN':
        return _BadgeConfig(
          label: 'موثّق بالكامل',
          color: YaBaladiDesignTokens.success,
          icon: Icons.verified_rounded,
        );
      case 'GPS':
        return _BadgeConfig(
          label: 'موثّق بالموقع',
          color: YaBaladiDesignTokens.primaryBlue,
          icon: Icons.location_on_rounded,
        );
      case 'PIN':
        return _BadgeConfig(
          label: 'موثّق بالرمز',
          color: YaBaladiDesignTokens.info,
          icon: Icons.pin_rounded,
        );
      case 'SELF_DECLARED':
      default:
        return _BadgeConfig(
          label: 'غير موثّق',
          color: YaBaladiDesignTokens.textTertiary,
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;
  final IconData icon;
  const _BadgeConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
