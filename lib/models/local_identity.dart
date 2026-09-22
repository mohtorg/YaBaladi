// models/local_identity.dart
//
// الهوية المحلية طبقة فوق الهوية الوطنية، وليست بديلًا لها.
// هذا يمنع ربط App Icon أو Brand Core ببورسعيد عند التوسع لمحافظة أخرى.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LocalIdentity {
  final String governorateId;
  final String labelAr;
  final String labelEn;
  final Color accent;

  const LocalIdentity({
    required this.governorateId,
    required this.labelAr,
    required this.labelEn,
    required this.accent,
  });

  String labelFor(String lang) => lang == 'en' ? labelEn : labelAr;

  static const portSaid = LocalIdentity(
    governorateId: 'port_said',
    labelAr: 'بورسعيد',
    labelEn: 'Port Said',
    accent: AppColors.portSaidAccent,
  );

  static const national = LocalIdentity(
    governorateId: 'national',
    labelAr: 'مصر',
    labelEn: 'Egypt',
    accent: AppColors.secondary,
  );

  static LocalIdentity forGovernorate(String id) {
    if (id == portSaid.governorateId) return portSaid;
    // لا نخترع لونًا لمحافظة لم نصمم طبقتها المحلية بعد.
    // نستخدم accent الوطني مؤقتًا حتى تُعتمد هوية المحافظة رسميًا.
    return national.copyWith(governorateId: id);
  }

  LocalIdentity copyWith({String? governorateId}) => LocalIdentity(
        governorateId: governorateId ?? this.governorateId,
        labelAr: labelAr,
        labelEn: labelEn,
        accent: accent,
      );
}
