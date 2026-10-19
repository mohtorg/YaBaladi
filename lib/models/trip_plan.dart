// lib/models/trip_plan.dart
//
// [v1.2 — 2026-10-18] — Wave 5.1: Geographic Day Split
//   - NEW: stopsByDay getter (يوزع المحطات جغرافياً على الأيام)
//   - NEW: totalDays getter (عدد الأيام للـ Tabs الديناميكية)
//   - NOTE: backward-compatible — لا تغيير في الواجهة العامة

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

enum TripTransportMode { walking, driving, transit }

extension TripTransportModeX on TripTransportMode {
  String get code => switch (this) {
        TripTransportMode.walking => 'walking',
        TripTransportMode.driving => 'driving',
        TripTransportMode.transit => 'transit',
      };

  String get labelAr => switch (this) {
        TripTransportMode.walking => 'سيراً على الأقدام',
        TripTransportMode.driving => 'بالسيارة',
        TripTransportMode.transit => 'بالمواصلات',
      };

  double get speedKmH => switch (this) {
        TripTransportMode.walking => 4.5,
        TripTransportMode.driving => 35.0,
        TripTransportMode.transit => 22.0,
      };
}

TripTransportMode tripTransportFromCode(String? code) {
  return switch (code) {
    'walking' => TripTransportMode.walking,
    'driving' => TripTransportMode.driving,
    'transit' => TripTransportMode.transit,
    _ => TripTransportMode.driving,
  };
}

enum TripDurationType { halfDay, fullDay, weekend }

extension TripDurationTypeX on TripDurationType {
  String get code => switch (this) {
        TripDurationType.halfDay => 'half_day',
        TripDurationType.fullDay => 'full_day',
        TripDurationType.weekend => 'weekend',
      };

  String get labelAr => switch (this) {
        TripDurationType.halfDay => 'نصف يوم',
        TripDurationType.fullDay => 'يوم كامل',
        TripDurationType.weekend => 'عطلة نهاية أسبوع',
      };

  String get subtitleAr => switch (this) {
        TripDurationType.halfDay => '~4 ساعات',
        TripDurationType.fullDay => '~8 ساعات',
        TripDurationType.weekend => '~16 ساعة (يومان)',
      };

  int get maxDurationMin => switch (this) {
        TripDurationType.halfDay => 4 * 60,
        TripDurationType.fullDay => 8 * 60,
        TripDurationType.weekend => 16 * 60,
      };

  int get maxStops => switch (this) {
        TripDurationType.halfDay => 3,
        TripDurationType.fullDay => 5,
        TripDurationType.weekend => 8,
      };

  int get expectedDays => switch (this) {
        TripDurationType.halfDay => 1,
        TripDurationType.fullDay => 1,
        TripDurationType.weekend => 2,
      };
}

TripDurationType tripDurationFromCode(String? code) {
  return switch (code) {
    'half_day' => TripDurationType.halfDay,
    'full_day' => TripDurationType.fullDay,
    'weekend' => TripDurationType.weekend,
    _ => TripDurationType.fullDay,
  };
}

TripDurationType tripDurationFromDays(int days) {
  if (days <= 1) return TripDurationType.fullDay;
  if (days == 2) return TripDurationType.weekend;
  return TripDurationType.weekend;
}

enum TripStatus { draft, active, completed, cancelled }

extension TripStatusX on TripStatus {
  String get code => switch (this) {
        TripStatus.draft => 'draft',
        TripStatus.active => 'active',
        TripStatus.completed => 'completed',
        TripStatus.cancelled => 'cancelled',
      };

  String get labelAr => switch (this) {
        TripStatus.draft => 'مسودة',
        TripStatus.active => 'نشطة',
        TripStatus.completed => 'مكتملة',
        TripStatus.cancelled => 'ملغاة',
      };
}

TripStatus tripStatusFromCode(String? code) {
  return switch (code) {
    'draft' => TripStatus.draft,
    'active' => TripStatus.active,
    'completed' => TripStatus.completed,
    'cancelled' => TripStatus.cancelled,
    _ => TripStatus.draft,
  };
}

// ═══════════════════════════════════════════════════════════════
// TRIP STOP
// ═══════════════════════════════════════════════════════════════

class TripStop {
  const TripStop({
    required this.placeId,
    required this.placeNameAr,
    required this.placeNameEn,
    this.placeImageUrl,
    required this.lat,
    required this.lng,
    required this.categoryId,
    required this.rating,
    required this.reviewCount,
    this.plannedArrival,
    this.plannedDurationMin,
    this.notes,
    this.isVisited = false,
  });

  final String placeId;
  final String placeNameAr;
  final String placeNameEn;
  final String? placeImageUrl;
  final double lat;
  final double lng;
  final String categoryId;
  final double rating;
  final int reviewCount;
  final DateTime? plannedArrival;
  final int? plannedDurationMin;
  final String? notes;
  final bool isVisited;

  factory TripStop.fromMap(Map<String, dynamic> map) {
    return TripStop(
      placeId: (map['placeId'] as String?) ?? '',
      placeNameAr: (map['placeNameAr'] as String?) ?? '',
      placeNameEn: (map['placeNameEn'] as String?) ?? '',
      placeImageUrl: map['placeImageUrl'] as String?,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      categoryId: (map['categoryId'] as String?) ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      plannedArrival: (map['plannedArrival'] as Timestamp?)?.toDate(),
      plannedDurationMin: (map['plannedDurationMin'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      isVisited: (map['isVisited'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'placeId': placeId,
        'placeNameAr': placeNameAr,
        'placeNameEn': placeNameEn,
        if (placeImageUrl != null) 'placeImageUrl': placeImageUrl,
        'lat': lat,
        'lng': lng,
        'categoryId': categoryId,
        'rating': rating,
        'reviewCount': reviewCount,
        if (plannedArrival != null)
          'plannedArrival': Timestamp.fromDate(plannedArrival!),
        if (plannedDurationMin != null)
          'plannedDurationMin': plannedDurationMin,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'isVisited': isVisited,
      };

  TripStop copyWith({
    String? placeId,
    String? placeNameAr,
    String? placeNameEn,
    String? placeImageUrl,
    double? lat,
    double? lng,
    String? categoryId,
    double? rating,
    int? reviewCount,
    DateTime? plannedArrival,
    int? plannedDurationMin,
    String? notes,
    bool? isVisited,
  }) =>
      TripStop(
        placeId: placeId ?? this.placeId,
        placeNameAr: placeNameAr ?? this.placeNameAr,
        placeNameEn: placeNameEn ?? this.placeNameEn,
        placeImageUrl: placeImageUrl ?? this.placeImageUrl,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        categoryId: categoryId ?? this.categoryId,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        plannedArrival: plannedArrival ?? this.plannedArrival,
        plannedDurationMin: plannedDurationMin ?? this.plannedDurationMin,
        notes: notes ?? this.notes,
        isVisited: isVisited ?? this.isVisited,
      );

  @override
  String toString() => 'TripStop($placeId, $placeNameAr)';
}

// ═══════════════════════════════════════════════════════════════
// TRIP PLAN
// ═══════════════════════════════════════════════════════════════

class TripPlan {
  const TripPlan({
    required this.id,
    required this.userId,
    required this.title,
    required this.governorateId,
    required this.governorateNameAr,
    required this.transportMode,
    required this.durationType,
    required this.interests,
    required this.status,
    required this.stops,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String governorateId;
  final String governorateNameAr;
  final TripTransportMode transportMode;
  final TripDurationType durationType;
  final List<String> interests;
  final TripStatus status;
  final List<TripStop> stops;
  final double totalDistanceKm;
  final int totalDurationMin;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isEmpty => stops.isEmpty;
  bool get isNotEmpty => stops.isNotEmpty;
  int get stopCount => stops.length;

  String get shortSummary {
    final hours = (totalDurationMin / 60).toStringAsFixed(0);
    return '$stopCount محطات · ${totalDistanceKm.toStringAsFixed(0)} كم · $hours ساعات';
  }

  TripStop? get firstStop => stops.isEmpty ? null : stops.first;
  TripStop? get lastStop => stops.isEmpty ? null : stops.last;

  String get durationLabel {
    final h = totalDurationMin ~/ 60;
    final m = totalDurationMin % 60;
    if (m == 0) return '$h ساعات';
    return '$h ساعات $m دقيقة';
  }

  int get durationInDays {
    if (startDate == null || endDate == null) return 1;
    final diff = endDate!.difference(startDate!).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  bool get isMultiDay => durationInDays > 1;

  bool get isValidRange {
    if (startDate == null || endDate == null) return true;
    return !endDate!.isBefore(startDate!);
  }

  DateTime? get effectiveEndDate {
    if (endDate != null) return endDate;
    if (startDate == null) return null;
    return startDate!.add(Duration(days: durationType.expectedDays - 1));
  }

  bool get isUpcoming {
    if (startDate == null) return false;
    final now = DateTime.now();
    final end = effectiveEndDate ?? startDate!;
    return end.isAfter(now);
  }

  bool get isOngoing {
    if (startDate == null) return false;
    final now = DateTime.now();
    final end = effectiveEndDate ?? startDate!;
    return startDate!.isBefore(now) && end.isAfter(now);
  }

  String get dateRangeLabel {
    if (startDate == null) return 'غير مجدولة';
    final s = _formatDate(startDate!);
    if (endDate == null || _sameDay(startDate!, endDate!)) {
      return s;
    }
    return '$s → ${_formatDate(endDate!)}';
  }

  int get totalDays => durationType == TripDurationType.weekend ? 2 : 1;

  List<List<TripStop>> get stopsByDay {
    final days = totalDays;
    if (days <= 1 || stops.isEmpty) return [stops];

    final lats = stops.map((s) => s.lat).toList()..sort();
    final lngs = stops.map((s) => s.lng).toList()..sort();
    final latRange = lats.last - lats.first;
    final lngRange = lngs.last - lngs.first;

    final sorted = List<TripStop>.from(stops);
    if (latRange > lngRange) {
      sorted.sort((a, b) => a.lat.compareTo(b.lat));
    } else {
      sorted.sort((a, b) => a.lng.compareTo(b.lng));
    }

    final perDay = (sorted.length / days).ceil();
    final result = <List<TripStop>>[];
    for (var i = 0; i < days; i++) {
      final start = i * perDay;
      final end = (start + perDay).clamp(0, sorted.length);
      if (start >= sorted.length) break;
      result.add(sorted.sublist(start, end));
    }
    return result;
  }

  factory TripPlan.fromMap(String id, Map<String, dynamic> map) {
    final stopsRaw = (map['stops'] as List<dynamic>?) ?? const [];
    final stops = stopsRaw
        .map((s) => TripStop.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();

    return TripPlan(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      governorateId: (map['governorateId'] as String?) ?? '',
      governorateNameAr: (map['governorateNameAr'] as String?) ?? '',
      transportMode: tripTransportFromCode(map['transportMode'] as String?),
      durationType: tripDurationFromCode(map['durationType'] as String?),
      interests: List<String>.from(map['interests'] as List? ?? const []),
      status: tripStatusFromCode(map['status'] as String?),
      stops: stops,
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalDurationMin: (map['totalDurationMin'] as num?)?.toInt() ?? 0,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'governorateId': governorateId,
        'governorateNameAr': governorateNameAr,
        'transportMode': transportMode.code,
        'durationType': durationType.code,
        'interests': interests,
        'status': status.code,
        'stops': stops.map((s) => s.toMap()).toList(),
        'totalDistanceKm': totalDistanceKm,
        'totalDurationMin': totalDurationMin,
        if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  TripPlan copyWith({
    String? id,
    String? userId,
    String? title,
    String? governorateId,
    String? governorateNameAr,
    TripTransportMode? transportMode,
    TripDurationType? durationType,
    List<String>? interests,
    TripStatus? status,
    List<TripStop>? stops,
    double? totalDistanceKm,
    int? totalDurationMin,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TripPlan(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        governorateId: governorateId ?? this.governorateId,
        governorateNameAr: governorateNameAr ?? this.governorateNameAr,
        transportMode: transportMode ?? this.transportMode,
        durationType: durationType ?? this.durationType,
        interests: interests ?? this.interests,
        status: status ?? this.status,
        stops: stops ?? this.stops,
        totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
        totalDurationMin: totalDurationMin ?? this.totalDurationMin,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() =>
      'TripPlan($id, "$title", $stopCount stops, ${status.code})';
}

String _formatDate(DateTime d) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
