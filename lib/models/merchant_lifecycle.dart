// lib/core/merchant/merchant_lifecycle.dart
//
// [v1.1 — 2026-10-18] — Consistency + i18n + helper getters
//   - NEW: labelAr — Arabic labels للعرض في UI
//   - NEW: code alias — للتوافق مع باقي enums (TripStatus, TripDurationType)
//   - NEW: helper getters (isTerminal, needsAction, isPositive)
//   - NEW: top-level merchantLifecycleFromValue() — نمط المشروع
//   - FIX: fromValue parameter renamed (كان يُظلّل الـ value getter)
//   - DOC: state transitions موثقة
//   - COMPATIBLE: backward-compatible — static fromValue باقٍ
//
// [v1.0 — الأصل] — merchant lifecycle vocabulary

/// Merchant lifecycle vocabulary defined by Ya Baladi project documents.
///
/// This layer is intentionally independent from Firestore, Authentication,
/// permissions, and database schema. It does not perform any state transition.
///
/// **States (8):**
/// - `pending`        → طلب جديد، ينتظر المراجعة
/// - `approved`       → تمت الموافقة عليه من الإدارة
/// - `needsRevision`  → يحتاج تعديلاً من التاجر
/// - `rejected`       → مرفوض نهائياً
/// - `unverified`     → لم يتم التحقق من المستندات
/// - `underReview`    → قيد المراجعة (مستندات)
/// - `verified`       → تم التحقق من المستندات
/// - `published`      → منشور ومتاح للجمهور
///
/// **Typical flow:**
/// ```
/// pending → approved → unverified → underReview → verified → published
///    ↓                       ↓
/// needsRevision         rejected
/// ```
enum MerchantLifecycleStatus {
  pending,
  approved,
  needsRevision,
  rejected,
  unverified,
  underReview,
  verified,
  published,
}

extension MerchantLifecycleStatusX on MerchantLifecycleStatus {
  // ═══════════════════════════════════════════════════════════════
  // PERSISTED VALUE (Firestore)
  // ═══════════════════════════════════════════════════════════════

  /// Canonical persisted/document terminology from the project documents.
  ///
  /// ⚠️ **لا تغيّر هذه القيم** — موجودة في Firestore بالفعل.
  String get value => switch (this) {
        MerchantLifecycleStatus.pending => 'Pending',
        MerchantLifecycleStatus.approved => 'Approved',
        MerchantLifecycleStatus.needsRevision => 'Needs Revision',
        MerchantLifecycleStatus.rejected => 'Rejected',
        MerchantLifecycleStatus.unverified => 'Unverified',
        MerchantLifecycleStatus.underReview => 'Under Review',
        MerchantLifecycleStatus.verified => 'Verified',
        MerchantLifecycleStatus.published => 'Published',
      };

  /// Alias متوافق مع باقي enums في المشروع (TripStatus.code, etc.)
  String get code => value;

  // ═══════════════════════════════════════════════════════════════
  // DISPLAY (i18n)
  // ═══════════════════════════════════════════════════════════════

  /// Arabic label للعرض في الواجهة.
  String get labelAr => switch (this) {
        MerchantLifecycleStatus.pending => 'قيد الانتظار',
        MerchantLifecycleStatus.approved => 'معتمد',
        MerchantLifecycleStatus.needsRevision => 'يحتاج تعديلاً',
        MerchantLifecycleStatus.rejected => 'مرفوض',
        MerchantLifecycleStatus.unverified => 'غير مُتحقق',
        MerchantLifecycleStatus.underReview => 'تحت المراجعة',
        MerchantLifecycleStatus.verified => 'مُتحقق',
        MerchantLifecycleStatus.published => 'منشور',
      };

  /// English label (Title Case, بدون فاصل).
  String get labelEn => value;

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC GETTERS (للاستخدام في الـ admin panel)
  // ═══════════════════════════════════════════════════════════════

  /// هل الحالة نهائية (لا انتقال بعدها)؟
  bool get isTerminal =>
      this == MerchantLifecycleStatus.rejected ||
      this == MerchantLifecycleStatus.published;

  /// هل الحالة موجبة (تاجر مؤهّل/منشور)؟
  bool get isPositive =>
      this == MerchantLifecycleStatus.approved ||
      this == MerchantLifecycleStatus.verified ||
      this == MerchantLifecycleStatus.published;

  /// هل الحالة تحتاج إجراء من التاجر؟
  bool get needsMerchantAction => this == MerchantLifecycleStatus.needsRevision;

  /// هل الحالة قيد المعالجة من الإدارة؟
  bool get isBeingProcessed =>
      this == MerchantLifecycleStatus.pending ||
      this == MerchantLifecycleStatus.underReview;

  // ═══════════════════════════════════════════════════════════════
  // PARSING (static — للتوافق مع v1.0)
  // ═══════════════════════════════════════════════════════════════

  /// يُحوّل قيمة Firestore نصية إلى `MerchantLifecycleStatus`.
  ///
  /// - يعيد `null` إذا كانت القيمة فارغة أو غير معروفة.
  /// - لا يعيد قيمة افتراضية (fail-fast) — لتمييز البيانات غير المعروفة.
  ///
  /// **الاستخدام المفضل:** `merchantLifecycleFromValue(raw)` (top-level).
  static MerchantLifecycleStatus? fromValue(String raw) {
    if (raw.isEmpty) return null;
    for (final status in MerchantLifecycleStatus.values) {
      if (status.value == raw) return status;
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP-LEVEL PARSER (نمط المشروع — مثل tripStatusFromCode)
// ═══════════════════════════════════════════════════════════════

/// يُحوّل قيمة Firestore نصية إلى `MerchantLifecycleStatus`.
///
/// يُعيد `null` إذا كانت `null` أو فارغة أو غير معروفة.
///
/// **مقارنة بالـ static:** هذه الـ top-level function تُطابق نمط
/// `tripStatusFromCode` و `tripDurationFromCode` في المشروع.
MerchantLifecycleStatus? merchantLifecycleFromValue(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return MerchantLifecycleStatusX.fromValue(raw);
}
