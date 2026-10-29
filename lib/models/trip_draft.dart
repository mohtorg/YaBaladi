// lib/models/trip_draft.dart
//
// [v1.0 — 2026-10-16] — G6.7: TripDraft model
//   - مسودة رحلة أثناء التخطيط — تُحفظ محلياً في SharedPreferences.
//   - لا تُرسل لـ Firestore. الحفظ النهائي هو المسؤول عن المزامنة.

import 'dart:convert';

import 'trip_plan.dart';

class TripDraft {
  const TripDraft({
    required this.userId,
    this.currentStep = 0,
    this.governorateId,
    this.durationType = TripDurationType.fullDay,
    this.transportMode = TripTransportMode.driving,
    this.interests = const [],
    this.title = '',
    this.startDate,
    this.endDate,
    this.generatedPlanJson,
    this.savedAt,
  });

  final String userId;
  final int currentStep;
  final String? governorateId;
  final TripDurationType durationType;
  final TripTransportMode transportMode;
  final List<String> interests;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;

  /// snapshot للـ TripPlan المُولَّد — JSON string.
  ///
  /// **لماذا JSON string وليس Map؟**
  ///   - SharedPreferences يخزّن String فقط.
  ///   - لا نضيف مكتبة serialization جديدة.
  ///
  /// ⚠️ **تحذير مهم:**
  ///   لا تستخدم `TripPlan.toMap()` مباشرة هنا — فهو يُنتج
  ///   `FieldValue.serverTimestamp()` و `Timestamp` وهما غير
  ///   قابلَين للتحويل إلى JSON (سيرمي TypeError).
  ///   استخدم serializer مخصص (يُبنى في Wave 1c مع TripDraftService).
  final String? generatedPlanJson;

  final DateTime? savedAt;

  bool get isEmpty =>
      currentStep == 0 &&
      governorateId == null &&
      title.isEmpty &&
      generatedPlanJson == null;

  bool get hasProgress => currentStep > 0 || governorateId != null;

  TripPlan? get generatedPlan {
    final raw = generatedPlanJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return TripPlan.fromMap('', map);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'currentStep': currentStep,
        if (governorateId != null) 'governorateId': governorateId,
        'durationType': durationType.code,
        'transportMode': transportMode.code,
        'interests': interests,
        'title': title,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (generatedPlanJson != null) 'generatedPlanJson': generatedPlanJson,
        if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
      };

  factory TripDraft.fromJson(Map<String, dynamic> json) {
    return TripDraft(
      userId: (json['userId'] as String?) ?? 'guest',
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
      governorateId: json['governorateId'] as String?,
      durationType: tripDurationFromCode(json['durationType'] as String?),
      transportMode: tripTransportFromCode(json['transportMode'] as String?),
      interests: List<String>.from(
        (json['interests'] as List?) ?? const <String>[],
      ),
      title: (json['title'] as String?) ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      generatedPlanJson: json['generatedPlanJson'] as String?,
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String)
          : null,
    );
  }

  TripDraft copyWith({
    String? userId,
    int? currentStep,
    String? governorateId,
    TripDurationType? durationType,
    TripTransportMode? transportMode,
    List<String>? interests,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? generatedPlanJson,
    DateTime? savedAt,
  }) =>
      TripDraft(
        userId: userId ?? this.userId,
        currentStep: currentStep ?? this.currentStep,
        governorateId: governorateId ?? this.governorateId,
        durationType: durationType ?? this.durationType,
        transportMode: transportMode ?? this.transportMode,
        interests: interests ?? this.interests,
        title: title ?? this.title,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        generatedPlanJson: generatedPlanJson ?? this.generatedPlanJson,
        savedAt: savedAt ?? this.savedAt,
      );

  static TripDraft empty(String userId) => TripDraft(userId: userId);

  @override
  String toString() =>
      'TripDraft(user=$userId, step=$currentStep, gov=$governorateId)';
}
