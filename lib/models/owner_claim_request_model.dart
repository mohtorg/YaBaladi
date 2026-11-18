// lib/models/owner_claim_request_model.dart
// [v1.1 — 2026-11-12] — EVIDENCE SUPPORT:
//   - Added `EvidenceType` enum (5 types).
//   - Extended `OwnerClaimRequestModel` with:
//       * evidenceType, evidenceReference, evidenceImageUrls.
//   - Kept all backward-compatible fields (v1.0).

import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════

enum ClaimStatus { pending, approved, rejected }

extension ClaimStatusExt on ClaimStatus {
  String get labelAr {
    switch (this) {
      case ClaimStatus.pending:
        return 'قيد الانتظار';
      case ClaimStatus.approved:
        return 'تمت الموافقة';
      case ClaimStatus.rejected:
        return 'مرفوض';
    }
  }

  static ClaimStatus fromKey(String key) {
    for (final s in ClaimStatus.values) {
      if (s.name == key) {
        return s;
      }
    }
    return ClaimStatus.pending;
  }
}

enum EvidenceType {
  commercialRegistration,
  leaseContract,
  utilityBill,
  photoOfPremises,
  other,
}

extension EvidenceTypeExt on EvidenceType {
  String get key => name;

  String get labelAr {
    switch (this) {
      case EvidenceType.commercialRegistration:
        return 'السجل التجاري';
      case EvidenceType.leaseContract:
        return 'عقد الإيجار';
      case EvidenceType.utilityBill:
        return 'فاتورة مرافق (كهرباء/مياه/غاز)';
      case EvidenceType.photoOfPremises:
        return 'صورة للمكان مع لوحة الاسم';
      case EvidenceType.other:
        return 'مستند آخر';
    }
  }

  static EvidenceType fromKey(String key) {
    for (final e in EvidenceType.values) {
      if (e.name == key) {
        return e;
      }
    }
    return EvidenceType.other;
  }
}

// ═══════════════════════════════════════════════════════════════
// OwnerClaimRequestModel
// ═══════════════════════════════════════════════════════════════

class OwnerClaimRequestModel {
  final String id;
  final String placeId;
  final String placeName;
  final String userId;
  final String userDisplayName;
  final String userEmail;
  final String? businessPhone;
  final EvidenceType evidenceType;
  final String? evidenceReference;
  final List<String> evidenceImageUrls;
  final String? notes;
  final ClaimStatus status;
  final String? reviewedBy;
  final String? reviewerName;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const OwnerClaimRequestModel({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.userId,
    required this.userDisplayName,
    required this.userEmail,
    this.businessPhone,
    this.evidenceType = EvidenceType.other,
    this.evidenceReference,
    this.evidenceImageUrls = const [],
    this.notes,
    required this.status,
    this.reviewedBy,
    this.reviewerName,
    this.reviewNote,
    this.reviewedAt,
    this.createdAt,
  });

  factory OwnerClaimRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawImages = data['evidenceImageUrls'];
    final images = (rawImages is List)
        ? rawImages.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return OwnerClaimRequestModel(
      id: doc.id,
      placeId: (data['placeId'] ?? '').toString(),
      placeName: (data['placeName'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      userDisplayName: (data['userDisplayName'] ?? '').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
      businessPhone: data['businessPhone']?.toString(),
      evidenceType: EvidenceTypeExt.fromKey(
        (data['evidenceType'] ?? 'other').toString(),
      ),
      evidenceReference: data['evidenceReference']?.toString(),
      evidenceImageUrls: images,
      notes: data['notes']?.toString(),
      status: ClaimStatusExt.fromKey(
        (data['status'] ?? 'pending').toString(),
      ),
      reviewedBy: data['reviewedBy']?.toString(),
      reviewerName: data['reviewerName']?.toString(),
      reviewNote: data['reviewNote']?.toString(),
      reviewedAt: _parseDate(data['reviewedAt']),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
