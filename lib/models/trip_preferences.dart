// lib/models/trip_preferences.dart
//
// [v1.0 — 2026-10-16] — G6.7: TripPreferences model
//   - يحفظ القيم الافتراضية لمستخدم (لتفادي إعادة الإدخال).

import 'trip_plan.dart';

class TripPreferences {
  const TripPreferences({
    this.defaultTransportMode = TripTransportMode.driving,
    this.defaultDurationType = TripDurationType.fullDay,
    this.defaultInterests = const [],
    this.avoidPlaceIds = const [],
    this.preferFamilyFriendly = false,
    this.minRating = 0.0,
  });

  final TripTransportMode defaultTransportMode;
  final TripDurationType defaultDurationType;
  final List<String> defaultInterests;
  final List<String> avoidPlaceIds;
  final bool preferFamilyFriendly;
  final double minRating;

  bool get isValid => minRating >= 0.0 && minRating <= 5.0;

  bool get isDefault =>
      defaultTransportMode == TripTransportMode.driving &&
      defaultDurationType == TripDurationType.fullDay &&
      defaultInterests.isEmpty &&
      avoidPlaceIds.isEmpty &&
      !preferFamilyFriendly &&
      minRating == 0.0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'defaultTransportMode': defaultTransportMode.code,
        'defaultDurationType': defaultDurationType.code,
        'defaultInterests': defaultInterests,
        'avoidPlaceIds': avoidPlaceIds,
        'preferFamilyFriendly': preferFamilyFriendly,
        'minRating': minRating,
      };

  factory TripPreferences.fromJson(Map<String, dynamic> json) {
    final prefs = TripPreferences(
      defaultTransportMode:
          tripTransportFromCode(json['defaultTransportMode'] as String?),
      defaultDurationType:
          tripDurationFromCode(json['defaultDurationType'] as String?),
      defaultInterests: List<String>.from(
        (json['defaultInterests'] as List?) ?? const <String>[],
      ),
      avoidPlaceIds: List<String>.from(
        (json['avoidPlaceIds'] as List?) ?? const <String>[],
      ),
      preferFamilyFriendly: (json['preferFamilyFriendly'] as bool?) ?? false,
      minRating: (json['minRating'] as num?)?.toDouble() ?? 0.0,
    );
    return prefs.isValid ? prefs : const TripPreferences();
  }

  TripPreferences copyWith({
    TripTransportMode? defaultTransportMode,
    TripDurationType? defaultDurationType,
    List<String>? defaultInterests,
    List<String>? avoidPlaceIds,
    bool? preferFamilyFriendly,
    double? minRating,
  }) =>
      TripPreferences(
        defaultTransportMode: defaultTransportMode ?? this.defaultTransportMode,
        defaultDurationType: defaultDurationType ?? this.defaultDurationType,
        defaultInterests: defaultInterests ?? this.defaultInterests,
        avoidPlaceIds: avoidPlaceIds ?? this.avoidPlaceIds,
        preferFamilyFriendly: preferFamilyFriendly ?? this.preferFamilyFriendly,
        minRating: minRating ?? this.minRating,
      );

  @override
  String toString() => 'TripPreferences(mode=${defaultTransportMode.code}, '
      'duration=${defaultDurationType.code})';
}
