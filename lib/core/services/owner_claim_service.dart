// lib/core/services/owner_claim_service.dart
// [v1.1 — 2026-11-12] — EVIDENCE SUPPORT:
//   - submitClaim() now accepts evidenceType, evidenceReference, imageUrls.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/owner_claim_request_model.dart';

class OwnerClaimService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> submitClaim({
    required String placeId,
    required String placeName,
    required String userId,
    required String userDisplayName,
    required String userEmail,
    String? businessPhone,
    EvidenceType evidenceType = EvidenceType.other,
    String? evidenceReference,
    List<String> evidenceImageUrls = const [],
    String? notes,
  }) async {
    final doc = await _firestore.collection('owner_claim_requests').add({
      'placeId': placeId,
      'placeName': placeName,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
      if (businessPhone != null && businessPhone.isNotEmpty)
        'businessPhone': businessPhone,
      'evidenceType': evidenceType.key,
      if (evidenceReference != null && evidenceReference.trim().isNotEmpty)
        'evidenceReference': evidenceReference.trim(),
      'evidenceImageUrls': evidenceImageUrls
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'status': ClaimStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<OwnerClaimRequestModel>> watchClaims({ClaimStatus? status}) {
    Query query;
    if (status != null) {
      query = _firestore
          .collection('owner_claim_requests')
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(100);
    } else {
      query = _firestore
          .collection('owner_claim_requests')
          .orderBy('createdAt', descending: true)
          .limit(100);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => OwnerClaimRequestModel.fromFirestore(d))
          .toList();
    });
  }

  Future<void> approveClaim({
    required String claimId,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.runTransaction((tx) async {
      final claimRef =
          _firestore.collection('owner_claim_requests').doc(claimId);
      final claimSnap = await tx.get(claimRef);
      if (!claimSnap.exists) {
        throw 'الطلب غير موجود';
      }
      final claim = OwnerClaimRequestModel.fromFirestore(claimSnap);

      final placeRef = _firestore.collection('places').doc(claim.placeId);
      final placeSnap = await tx.get(placeRef);
      if (!placeSnap.exists) {
        throw 'المكان غير موجود';
      }

      tx.update(placeRef, {
        'ownerId': claim.userId,
        'ownerName': claim.userDisplayName,
        'isApproved': true,
        'claimedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        _firestore.collection('users').doc(claim.userId),
        {
          'role': 'merchant',
          'merchantVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.update(claimRef, {
        'status': ClaimStatus.approved.name,
        'reviewedBy': adminId,
        'reviewerName': adminName,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final logRef = _firestore.collection('moderation_logs').doc();
      tx.set(logRef, {
        'actionKey': 'claim_approved',
        'targetType': 'place',
        'targetId': claim.placeId,
        'reportId': null,
        'reasonKey': 'owner_claim',
        'reasonNote': 'تمت الموافقة على طلب استلام المكان',
        'actorId': adminId,
        'actorName': adminName,
        'previousState': {'placeOwnerId': placeSnap.data()?['ownerId']},
        'newState': {'placeOwnerId': claim.userId},
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectClaim({
    required String claimId,
    required String adminId,
    required String adminName,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw 'يجب ذكر سبب الرفض';
    }

    await _firestore.runTransaction((tx) async {
      final claimRef =
          _firestore.collection('owner_claim_requests').doc(claimId);
      final claimSnap = await tx.get(claimRef);
      if (!claimSnap.exists) {
        throw 'الطلب غير موجود';
      }

      tx.update(claimRef, {
        'status': ClaimStatus.rejected.name,
        'reviewedBy': adminId,
        'reviewerName': adminName,
        'reviewNote': reason.trim(),
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final logRef = _firestore.collection('moderation_logs').doc();
      tx.set(logRef, {
        'actionKey': 'claim_rejected',
        'targetType': 'place',
        'targetId': (claimSnap.data()?['placeId'] ?? '').toString(),
        'reasonKey': 'owner_claim',
        'reasonNote': reason.trim(),
        'actorId': adminId,
        'actorName': adminName,
        'previousState': null,
        'newState': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
