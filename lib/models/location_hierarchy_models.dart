// lib/models/location_hierarchy_models.dart
// [v1.2] — ADDED: notes field to ZoneModel.

import 'package:cloud_firestore/cloud_firestore.dart';

class DistrictModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String governorateId;
  final bool isActive;
  final String? geoZoneId;

  const DistrictModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.governorateId,
    this.isActive = true,
    this.geoZoneId,
  });

  factory DistrictModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DistrictModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      governorateId: data['governorateId'] ?? '',
      isActive: data['isActive'] != false,
      geoZoneId: data['geoZoneId'],
    );
  }
}

class ZoneModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String districtId;
  final bool isActive;
  final String? geoZoneId;
  final String? notes; // ✅ حقل الملاحظات الجديد

  const ZoneModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.districtId,
    this.isActive = true,
    this.geoZoneId,
    this.notes,
  });

  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ZoneModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      districtId: data['districtId'] ?? '',
      isActive: data['isActive'] != false,
      geoZoneId: data['geoZoneId'],
      notes: data['notes'],
    );
  }
}
