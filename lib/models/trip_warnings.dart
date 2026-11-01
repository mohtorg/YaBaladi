// lib/models/trip_warnings.dart
//
// [v1.0 — 2026-10-16] — G6.7: TripWarnings model
//   - نتيجة تحليل TripPlan قبل الحفظ (Step 3.5 / Review).
//   - النموذج في الذاكرة فقط — لا يُخزَّن في Firestore.

enum TripWarningSeverity { info, warning, critical }

class TripWarning {
  const TripWarning({
    required this.code,
    required this.messageAr,
    this.messageEn,
    this.severity = TripWarningSeverity.warning,
  });

  final String code;
  final String messageAr;
  final String? messageEn;
  final TripWarningSeverity severity;

  @override
  String toString() => 'TripWarning($code, ${severity.name})';
}

class TripWarnings {
  const TripWarnings({this.warnings = const []});

  final List<TripWarning> warnings;

  bool get hasCritical =>
      warnings.any((w) => w.severity == TripWarningSeverity.critical);

  bool get hasAny => warnings.isNotEmpty;

  int countBySeverity(TripWarningSeverity severity) =>
      warnings.where((w) => w.severity == severity).length;

  List<TripWarning> filterBy(TripWarningSeverity severity) =>
      warnings.where((w) => w.severity == severity).toList();

  TripWarnings copyWith({List<TripWarning>? warnings}) =>
      TripWarnings(warnings: warnings ?? this.warnings);

  static const TripWarnings empty = TripWarnings();

  @override
  String toString() => 'TripWarnings(${warnings.length} warnings)';
}
