// lib/models/merchant_request.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum MerchantRequestStatus { pending, approved, rejected, needsInfo }

enum MerchantRequestType { createNew }

extension MerchantRequestStatusX on MerchantRequestStatus {
  String get value {
    switch (this) {
      case MerchantRequestStatus.pending:
        return 'pending';
      case MerchantRequestStatus.approved:
        return 'approved';
      case MerchantRequestStatus.rejected:
        return 'rejected';
      case MerchantRequestStatus.needsInfo:
        return 'needs_info';
    }
  }
}

class MerchantRequest {
  final String id;
  final String userId;
  final MerchantRequestType type;
  final String businessName;
  final String businessPhone;

  // 🆕 بيانات المكان الجديد
  final String? placeNameAr;
  final String? placeNameEn;
  final String? categoryId;
  final String? governorateId;
  final String? address;
  final GeoPoint? location;
  final String? description;

  final MerchantRequestStatus status;
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? createdPlaceId;

  const MerchantRequest({
    required this.id,
    required this.userId,
    this.type = MerchantRequestType.createNew,
    required this.businessName,
    required this.businessPhone,
    this.placeNameAr,
    this.placeNameEn,
    this.categoryId,
    this.governorateId,
    this.address,
    this.location,
    this.description,
    this.status = MerchantRequestStatus.pending,
    this.adminNote,
    this.createdAt,
    this.reviewedAt,
    this.createdPlaceId,
  });

  factory MerchantRequest.fromMap(String id, Map<String, dynamic> map) {
    return MerchantRequest(
      id: id,
      userId: map['userId'] ?? '',
      type: MerchantRequestType.createNew,
      businessName: map['businessName'] ?? '',
      businessPhone: map['businessPhone'] ?? '',
      placeNameAr: map['placeNameAr'],
      placeNameEn: map['placeNameEn'],
      categoryId: map['categoryId'],
      governorateId: map['governorateId'],
      address: map['address'],
      location: map['location'] as GeoPoint?,
      description: map['description'],
      status: _parseStatus(map['status']),
      adminNote: map['adminNote'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      createdPlaceId: map['createdPlaceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': 'create_new',
      'businessName': businessName,
      'businessPhone': businessPhone,
      if (placeNameAr != null) 'placeNameAr': placeNameAr,
      if (placeNameEn != null) 'placeNameEn': placeNameEn,
      if (categoryId != null) 'categoryId': categoryId,
      if (governorateId != null) 'governorateId': governorateId,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      'status': status.value,
      if (adminNote != null) 'adminNote': adminNote,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (createdPlaceId != null) 'createdPlaceId': createdPlaceId,
    };
  }

  static MerchantRequestStatus _parseStatus(String? s) {
    switch (s) {
      case 'approved':
        return MerchantRequestStatus.approved;
      case 'rejected':
        return MerchantRequestStatus.rejected;
      case 'needs_info':
        return MerchantRequestStatus.needsInfo;
      default:
        return MerchantRequestStatus.pending;
    }
  }
}
