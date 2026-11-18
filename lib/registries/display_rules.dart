// lib/core/config/display_rules.dart
//
// [v1.2 — 2026-11-05] — POLISH: Shortened long variable name, added compile-time
//                         documentation, grouped sections, added usage example.
// [v1.1 — CLEANED] — Cleaned, Documented, and Protected from instantiation.
//   - ADDED: Private constructor to prevent instantiation.
//   - ADDED: Explicit 'bool' types.
//   - ADDED: Doc comments explaining each flag.
//   - KEPT: All values (true) and logic intact.

/// قواعد العرض (Feature Flags / Display Rules) للتطبيق.
///
/// هذا الكلاس يحدد من أين تجلب الشاشات بياناتها، وكيف تتصرف.
/// جميع القيم مضبوطة على `true` لتفعيل الميزات الجديدة.
///
/// ⚠️ **ملاحظة هامة للمطورين:**
/// هذه القيم هي `static const`، أي أنها **تُحسم وقت التجميع (Compile-time)**.
/// لتغيير أي قيمة، يجب تعديل هذا الملف **وإعادة بناء التطبيق بالكامل**.
/// إذا كنت ترغب في "أعلام ميزات ديناميكية" يمكن تغييرها من لوحة التحكم
/// أو من Firebase Remote Config، يجب تحويلها إلى `static bool` وتحميلها
/// من قاعدة البيانات عند بدء تشغيل التطبيق.
///
/// **مثال للاستخدام في الشاشات:**
/// ```dart
/// if (DisplayRules.homeUsesCategoryRegistry) {
///   return HomeScreenWithRegistry();
/// } else {
///   return HomeScreenLegacy();
/// }
/// ```
class DisplayRules {
  // منع إنشاء كائنات من هذا الكلاس (لأنه يحتوي على ثوابت فقط)
  DisplayRules._();

  // ═══════════════════════════════════════════════════════════════
  // 1. الشاشات العامة (Screens)
  // ═══════════════════════════════════════════════════════════════

  /// هل الشاشة الرئيسية تستخدم سجل التصنيفات (Category Registry)؟
  static const bool homeUsesCategoryRegistry = true;

  /// هل شاشة البحث تستخدم سجل التصنيفات؟
  static const bool searchUsesCategoryRegistry = true;

  /// هل شاشة التصنيفات تستخدم سجل التصنيفات؟
  static const bool categoryScreenUsesCategoryRegistry = true;

  /// هل شاشة البحث تستخدم سجل الفلاتر (Filter Registry)؟
  static const bool searchUsesFilterRegistry = true;

  /// هل نتائج البحث تستخدم نفس حالة الفلاتر المحفوظة (Filter State)؟
  static const bool resultsUseSameFilterState = true;

  // ═══════════════════════════════════════════════════════════════
  // 2. صفحات التفاصيل (Details)
  // ═══════════════════════════════════════════════════════════════

  /// هل صفحة التفاصيل تستخدم خصائص المكان (Place Attributes) مباشرة؟
  static const bool detailsUsePlaceAttributes = true;

  // ═══════════════════════════════════════════════════════════════
  // 3. لوحة التحكم (Admin)
  // ═══════════════════════════════════════════════════════════════

  /// هل لوحة التحكم (الأدمن) تستخدم نفس تعريفات التصنيفات والفلاتر؟
  static const bool adminUsesSameDefinitions = true;

  // ═══════════════════════════════════════════════════════════════
  // 4. الموقع (Location)
  // ═══════════════════════════════════════════════════════════════

  /// هل نظام تحديد الموقع (GPS) معطّل في البحث في هذه المرحلة؟
  /// (تم تقصير الاسم من الطويل السابق لسهولة الاستخدام)
  static const bool gpsDisabledInSearch = true;
}
