// lib/models/moderation_log_model.dart
// [v1.0 — 2026-11-12] — GOVERNANCE MODELS:
//   - ReportReason enum: 7 standardized report reasons (UI + audit ready).
//   - ReportStatus enum: pending / reviewed / dismissed / resolved.
//   - ModerationAction enum: 5 actions an admin can take.
//   - ReportModel: backward-compatible with legacy reportRating().
//   - ModerationLogModel: full audit trail entry.

import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════

enum ReportReason {
  spam,
  offensive,
  fake,
  personalInfo,
  offTopic,
  conflictOfInterest,
  other,
}

extension ReportReasonExt on ReportReason {
  String get key => name;

  String get labelAr {
    switch (this) {
      case ReportReason.spam:
        return 'محتوى دعائي';
      case ReportReason.offensive:
        return 'سب أو قذف';
      case ReportReason.fake:
        return 'تقييم مزيف';
      case ReportReason.personalInfo:
        return 'كشف بيانات شخصية';
      case ReportReason.offTopic:
        return 'خارج الموضوع';
      case ReportReason.conflictOfInterest:
        return 'تضارب مصالح';
      case ReportReason.other:
        return 'سبب آخر';
    }
  }

  String get descriptionAr {
    switch (this) {
      case ReportReason.spam:
        return 'المحتوى يروّج لخدمة أو منتج خارج نطاق المكان.';
      case ReportReason.offensive:
        return 'يحتوي على شتائم أو تهديد أو إساءة لشخص أو جهة.';
      case ReportReason.fake:
        return 'يُشتبه بأنه تقييم غير حقيقي أو مكتوب نيابة عن آخر.';
      case ReportReason.personalInfo:
        return 'ينشر معلومات شخصية (أسماء، هواتف، عناوين) دون إذن.';
      case ReportReason.offTopic:
        return 'لا يتعلق بتجربة المكان (نقاش ديني، سياسي، إعلاني).';
      case ReportReason.conflictOfInterest:
        return 'يبدو أنه من منافس أو شخص له مصلحة.';
      case ReportReason.other:
        return 'سبب آخر — يُرجى توضيحه في الملاحظة.';
    }
  }

  static ReportReason fromKey(String key) {
    for (final r in ReportReason.values) {
      if (r.name == key) {
        return r;
      }
    }
    return ReportReason.other;
  }
}

enum ReportStatus { pending, reviewed, dismissed, resolved }

extension ReportStatusExt on ReportStatus {
  String get labelAr {
    switch (this) {
      case ReportStatus.pending:
        return 'قيد الانتظار';
      case ReportStatus.reviewed:
        return 'تمت المراجعة';
      case ReportStatus.dismissed:
        return 'تم التجاهل';
      case ReportStatus.resolved:
        return 'تم الحل';
    }
  }

  static ReportStatus fromKey(String key) {
    final normalized = key.toLowerCase();
    for (final s in ReportStatus.values) {
      if (s.name == normalized) {
        return s;
      }
    }
    return ReportStatus.pending;
  }
}

enum ModerationAction {
  dismissed,
  warned,
  ratingHidden,
  ratingRemoved,
  userBanned,
}

extension ModerationActionExt on ModerationAction {
  String get key => name;

  String get labelAr {
    switch (this) {
      case ModerationAction.dismissed:
        return 'تجاهل البلاغ';
      case ModerationAction.warned:
        return 'تحذير الكاتب';
      case ModerationAction.ratingHidden:
        return 'إخفاء التقييم (قابل للاستعادة)';
      case ModerationAction.ratingRemoved:
        return 'حذف التقييم نهائياً';
      case ModerationAction.userBanned:
        return 'حظر المستخدم';
    }
  }

  String get descriptionAr {
    switch (this) {
      case ModerationAction.dismissed:
        return 'التقييم يبقى منشوراً. يُسجَّل القرار فقط.';
      case ModerationAction.warned:
        return 'يُنبَّه الكاتب رسمياً. التقييم يبقى منشوراً.';
      case ModerationAction.ratingHidden:
        return 'التقييم يختفي من العرض العام. يمكن استعادته لاحقاً.';
      case ModerationAction.ratingRemoved:
        return 'التقييم يُحذف نهائياً من العرض. لا يمكن استعادته.';
      case ModerationAction.userBanned:
        return 'يُحظر المستخدم من التقييم مستقبلاً.';
    }
  }

  static ModerationAction fromKey(String key) {
    for (final a in ModerationAction.values) {
      if (a.name == key) {
        return a;
      }
    }
    return ModerationAction.dismissed;
  }
}

// ═══════════════════════════════════════════════════════════════
// ReportModel — `reports/{reportId}`
// ═══════════════════════════════════════════════════════════════

class ReportModel {
  final String id;
  final String ratingId;
  final String reporterId;
  final String? reporterName;
  final ReportReason reason;
  final String? reasonNote;
  final ReportStatus status;
  final String? resolutionActionKey;
  final String? resolutionNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const ReportModel({
    required this.id,
    required this.ratingId,
    required this.reporterId,
    this.reporterName,
    required this.reason,
    this.reasonNote,
    required this.status,
    this.resolutionActionKey,
    this.resolutionNote,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 1. التعامل مع reason: نُفضّل مطابقة enum keys، وإلا fallback → other
    final rawReason = (data['reason'] ?? '').toString();
    ReportReason reason = ReportReason.other;
    for (final r in ReportReason.values) {
      if (r.name == rawReason) {
        reason = r;
        break;
      }
    }

    // 2. status: legacy قد يكون 'PENDING' uppercase
    final rawStatus = (data['status'] ?? 'pending').toString();
    final status = ReportStatusExt.fromKey(rawStatus);

    // 3. reasonNote: legacy قد يستخدم 'note'
    final note = data['reasonNote']?.toString() ?? data['note']?.toString();

    return ReportModel(
      id: doc.id,
      ratingId: (data['ratingId'] ?? '').toString(),
      reporterId: (data['reporterId'] ?? '').toString(),
      reporterName: data['reporterName']?.toString(),
      reason: reason,
      reasonNote: note,
      status: status,
      resolutionActionKey: data['resolutionActionKey']?.toString(),
      resolutionNote: data['resolutionNote']?.toString(),
      reviewedBy: data['reviewedBy']?.toString(),
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

// ═══════════════════════════════════════════════════════════════
// ModerationLogModel — `moderation_logs/{logId}`
// ═══════════════════════════════════════════════════════════════

class ModerationLogModel {
  final String id;
  final String actionKey;
  final String targetType;
  final String targetId;
  final String? reportId;
  final String? reasonKey;
  final String? reasonNote;
  final String actorId;
  final String actorName;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;
  final DateTime? createdAt;

  const ModerationLogModel({
    required this.id,
    required this.actionKey,
    required this.targetType,
    required this.targetId,
    this.reportId,
    this.reasonKey,
    this.reasonNote,
    required this.actorId,
    required this.actorName,
    this.previousState,
    this.newState,
    this.createdAt,
  });

  factory ModerationLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ModerationLogModel(
      id: doc.id,
      actionKey: (data['actionKey'] ?? '').toString(),
      targetType: (data['targetType'] ?? '').toString(),
      targetId: (data['targetId'] ?? '').toString(),
      reportId: data['reportId']?.toString(),
      reasonKey: data['reasonKey']?.toString(),
      reasonNote: data['reasonNote']?.toString(),
      actorId: (data['actorId'] ?? '').toString(),
      actorName: (data['actorName'] ?? '').toString(),
      previousState: data['previousState'] is Map
          ? Map<String, dynamic>.from(data['previousState'] as Map)
          : null,
      newState: data['newState'] is Map
          ? Map<String, dynamic>.from(data['newState'] as Map)
          : null,
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
