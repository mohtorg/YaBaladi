// lib/models/governorate_config.dart
// [v1.0 — 2026-10-29] — جديد كلياً
// يدمج بيانات Firestore (isActive, deliveryEnabled, ...) مع
// البيانات الجغرافية الثابتة (EgyptGovernorate) من
// egypt_governorates.dart — عبر مطابقة nameAr.
//
// ⚠️ ملاحظة: هذا الملف لا يعدّل EgyptGovernorate ولا يعتمد على
//    `id` الخاص به. السبب: الشاشة الحالية تستخدم docIds مختلفة
//    مثل 'portsaid' بدلاً من 'port_said'. المطابقة بـ nameAr
//    هي الأكثر أماناً لأنها فريدة ومستقرة.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/location/egypt_governorates.dart';

class GovernorateConfig {
  /// معرّف الوثيقة في Firestore (مثل 'portsaid' أو 'port_said').
  final String docId;

  /// البيانات القادمة من Firestore (مصدر الحقيقة للعرض والتحكم).
  final String nameAr;
  final String nameEn;
  final int order;
  final bool isActive;
  final bool deliveryEnabled;
  final bool tripsEnabled;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  /// ربط اختياري مع البيانات الجغرافية الثابتة.
  /// يُملأ تلقائياً في fromMap إذا تطابق nameAr.
  /// قد يكون null إذا كانت المحافظة غير موجودة في القائمة الثابتة.
  final EgyptGovernorate? geo;

  const GovernorateConfig({
    required this.docId,
    required this.nameAr,
    required this.nameEn,
    required this.order,
    required this.isActive,
    required this.deliveryEnabled,
    required this.tripsEnabled,
    this.createdAt,
    this.updatedAt,
    this.geo,
  });

  // ─── Firestore → Model ───
  factory GovernorateConfig.fromMap(
    String docId,
    Map<String, dynamic> data,
  ) {
    final nameAr = (data['nameAr'] as String?)?.trim() ?? '';
    return GovernorateConfig(
      docId: docId,
      nameAr: nameAr,
      nameEn: (data['nameEn'] as String?)?.trim() ?? '',
      order: (data['order'] as num?)?.toInt() ?? 999,
      isActive: data['isActive'] == true,
      deliveryEnabled: data['deliveryEnabled'] == true,
      tripsEnabled: data['tripsEnabled'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
      geo: governorateByArName(nameAr),
    );
  }

  // ─── Model → Firestore ───
  Map<String, dynamic> toMap({bool forCreate = false}) {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'order': order,
      'isActive': isActive,
      'deliveryEnabled': deliveryEnabled,
      'tripsEnabled': tripsEnabled,
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ─── Immutable update ───
  GovernorateConfig copyWith({
    String? nameAr,
    String? nameEn,
    int? order,
    bool? isActive,
    bool? deliveryEnabled,
    bool? tripsEnabled,
  }) {
    return GovernorateConfig(
      docId: docId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      tripsEnabled: tripsEnabled ?? this.tripsEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
      geo: geo,
    );
  }

  // ─── Helpers ───
  String get displayName =>
      nameAr.isNotEmpty ? nameAr : (geo?.nameAr ?? nameEn);

  bool get hasCoordinates => geo != null;
  double? get latitude => geo?.lat;
  double? get longitude => geo?.lng;

  // ─── Equality ───
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GovernorateConfig &&
          runtimeType == other.runtimeType &&
          docId == other.docId &&
          isActive == other.isActive &&
          deliveryEnabled == other.deliveryEnabled &&
          tripsEnabled == other.tripsEnabled;

  @override
  int get hashCode => Object.hash(
        docId,
        isActive,
        deliveryEnabled,
        tripsEnabled,
      );

  @override
  String toString() => 'GovernorateConfig($docId, $nameAr, active=$isActive)';
}
