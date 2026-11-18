// lib/core/services/moderation_service.dart
// [v1.0 — 2026-11-12] — GOVERNANCE SERVICE:
//   - submitReport()  — create report (used by RatingService.reportRating).
//   - watchReports()  — stream filtered reports for admin screen.
//   - watchLogs()     — stream audit trail.
//   - reviewReport()  — atomic transaction: report + rating + user + log.
//   - restoreRating() — restore a hidden rating (also audited).

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/moderation_log_model.dart';

class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Report Submission ───

  Future<String> submitReport({
    required String ratingId,
    required String reporterId,
    String? reporterName,
    required ReportReason reason,
    String? reasonNote,
  }) async {
    final doc = await _firestore.collection('reports').add({
      'ratingId': ratingId,
      'reporterId': reporterId,
      if (reporterName != null && reporterName.isNotEmpty)
        'reporterName': reporterName,
      'reason': reason.key,
      if (reasonNote != null && reasonNote.isNotEmpty) 'reasonNote': reasonNote,
      'status': ReportStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // ─── Reading ───

  Stream<List<ReportModel>> watchReports({ReportStatus? status}) {
    Query query;
    if (status != null) {
      query = _firestore
          .collection('reports')
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(100);
    } else {
      query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(100);
    }

    return query.snapshots().map((snap) {
      return snap.docs.map((d) => ReportModel.fromFirestore(d)).toList();
    });
  }

  Stream<List<ModerationLogModel>> watchLogs({int limit = 100}) {
    return _firestore
        .collection('moderation_logs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => ModerationLogModel.fromFirestore(d)).toList();
    });
  }

  // ─── Review & Actions ───

  Future<void> reviewReport({
    required String reportId,
    required String adminId,
    required String adminName,
    required ModerationAction action,
    required String resolutionNote,
  }) async {
    if (resolutionNote.trim().isEmpty) {
      throw 'يجب كتابة ملاحظة توضح سبب القرار';
    }

    await _firestore.runTransaction((tx) async {
      // 1. اقرأ التقرير
      final reportRef = _firestore.collection('reports').doc(reportId);
      final reportSnap = await tx.get(reportRef);
      if (!reportSnap.exists) {
        throw 'التقرير غير موجود';
      }
      final report = ReportModel.fromFirestore(reportSnap);

      // 2. اقرأ التقييم
      final ratingRef = _firestore.collection('ratings').doc(report.ratingId);
      final ratingSnap = await tx.get(ratingRef);
      if (!ratingSnap.exists) {
        throw 'التقييم لم يعد موجوداً';
      }
      final ratingData = ratingSnap.data() ?? {};
      final previousRatingStatus =
          (ratingData['status'] ?? 'PUBLISHED').toString();
      final ratingUserId = (ratingData['userId'] ?? '').toString();

      // 3. جهّز الحالات الجديدة
      String? newRatingStatus;
      Map<String, dynamic>? newUserState;

      switch (action) {
        case ModerationAction.dismissed:
          newRatingStatus = null;
          break;
        case ModerationAction.warned:
          newRatingStatus = null;
          break;
        case ModerationAction.ratingHidden:
          newRatingStatus = 'HIDDEN';
          break;
        case ModerationAction.ratingRemoved:
          newRatingStatus = 'REMOVED';
          break;
        case ModerationAction.userBanned:
          newRatingStatus = 'REMOVED';
          newUserState = {
            'isBanned': true,
            'banReason': 'تم الحظر بسبب تقييم مخالف: ${report.reason.labelAr}',
            'bannedAt': FieldValue.serverTimestamp(),
            'bannedBy': adminId,
          };
          break;
      }

      // 4. حدّد حالة التقرير
      final ReportStatus newStatus = (action == ModerationAction.dismissed)
          ? ReportStatus.dismissed
          : ReportStatus.resolved;

      // 5. حدّث التقرير
      tx.update(reportRef, {
        'status': newStatus.name,
        'resolutionActionKey': action.key,
        'resolutionNote': resolutionNote.trim(),
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // 6. حدّث التقييم (إن لزم)
      if (newRatingStatus != null) {
        tx.update(ratingRef, {
          'status': newRatingStatus,
          'moderatedAt': FieldValue.serverTimestamp(),
          'moderatedBy': adminId,
        });
      }

      // 7. حدّث المستخدم (حظر)
      if (newUserState != null && ratingUserId.isNotEmpty) {
        tx.set(
          _firestore.collection('users').doc(ratingUserId),
          newUserState,
          SetOptions(merge: true),
        );
      }

      // 8. اكتب السجل
      final logRef = _firestore.collection('moderation_logs').doc();
      tx.set(logRef, {
        'actionKey': action.key,
        'targetType': 'rating',
        'targetId': report.ratingId,
        'reportId': reportId,
        'reasonKey': report.reason.key,
        'reasonNote': report.reasonNote,
        'actorId': adminId,
        'actorName': adminName,
        'previousState': {
          'ratingStatus': previousRatingStatus,
          'reportStatus': ReportStatus.pending.name,
        },
        'newState': {
          'ratingStatus': newRatingStatus ?? previousRatingStatus,
          'reportStatus': newStatus.name,
          'action': action.key,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> restoreRating({
    required String ratingId,
    required String adminId,
    required String adminName,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw 'يجب ذكر سبب الاستعادة';
    }

    await _firestore.runTransaction((tx) async {
      final ratingRef = _firestore.collection('ratings').doc(ratingId);
      final ratingSnap = await tx.get(ratingRef);
      if (!ratingSnap.exists) {
        throw 'التقييم غير موجود';
      }

      final previousStatus =
          (ratingSnap.data()?['status'] ?? 'PUBLISHED').toString();

      tx.update(ratingRef, {
        'status': 'PUBLISHED',
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': adminId,
      });

      final logRef = _firestore.collection('moderation_logs').doc();
      tx.set(logRef, {
        'actionKey': 'restored',
        'targetType': 'rating',
        'targetId': ratingId,
        'actorId': adminId,
        'actorName': adminName,
        'reasonNote': reason.trim(),
        'previousState': {'ratingStatus': previousStatus},
        'newState': {'ratingStatus': 'PUBLISHED'},
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
