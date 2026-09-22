import 'package:cloud_firestore/cloud_firestore.dart';

enum GovernorateStatus { draft, preparing, active, suspended, maintenance }

enum FeatureState { inherit, enabled, disabled, visible, hidden, comingSoon, maintenance }

GovernorateStatus governorateStatusFromValue(String? value) {
  return GovernorateStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => GovernorateStatus.draft,
  );
}

FeatureState featureStateFromValue(String? value) {
  return FeatureState.values.firstWhere(
    (e) => e.name == value,
    orElse: () => FeatureState.inherit,
  );
}

class GovernorateControl {
  final String id;
  final String nameAr;
  final String nameEn;
  final GovernorateStatus status;
  final bool enabled;
  final bool visible;
  final int sortOrder;
  final DateTime? launchDate;
  final DateTime? updatedAt;
  final String? updatedBy;

  const GovernorateControl({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.status,
    required this.enabled,
    required this.visible,
    required this.sortOrder,
    this.launchDate,
    this.updatedAt,
    this.updatedBy,
  });

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : nameAr;

  factory GovernorateControl.fromMap(String id, Map<String, dynamic> map) {
    DateTime? date(dynamic value) => value is Timestamp ? value.toDate() : null;
    return GovernorateControl(
      id: id,
      nameAr: (map['name_ar'] ?? '').toString(),
      nameEn: (map['name_en'] ?? '').toString(),
      status: governorateStatusFromValue(map['status']?.toString()),
      enabled: map['enabled'] != false,
      visible: map['visible'] != false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      launchDate: date(map['launchDate']),
      updatedAt: date(map['updatedAt']),
      updatedBy: map['updatedBy']?.toString(),
    );
  }
}

class GovernorateFeatureDefinition {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final bool defaultEnabled;
  final bool defaultVisible;

  const GovernorateFeatureDefinition({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    this.defaultEnabled = true,
    this.defaultVisible = true,
  });

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : nameAr;
  String descriptionFor(String languageCode) => languageCode == 'en' ? descriptionEn : descriptionAr;
}

class GovernorateGroup {
  final String id;
  final String nameAr;
  final String nameEn;
  final List<String> governorateIds;

  const GovernorateGroup({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.governorateIds,
  });

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : nameAr;

  factory GovernorateGroup.fromMap(String id, Map<String, dynamic> map) {
    return GovernorateGroup(
      id: id,
      nameAr: (map['name_ar'] ?? '').toString(),
      nameEn: (map['name_en'] ?? '').toString(),
      governorateIds: List<String>.from(map['governorateIds'] ?? const []),
    );
  }
}
