// models/favorite.dart
//
// [v1.1 — 2026-10-18] — Defensive Casting + Consistency
//   - FIX: createdAt defensive cast (is Timestamp check بدل as Timestamp?)
//     → لا يرمي TypeError لو كانت البيانات قديمة/خاطئة
//   - FIX: placeId defensive cast (is String check بدل as String?)
//   - NEW: copyWith() — للتوافق مع Place, TripPlan, Review, TripStop
//   - NEW: == and hashCode — للمقارنة في Sets والاختبارات
//   - NOTE: id = placeId (مقصود — backward-compatible)
//
// [v1.0 — الأصل]
//
// المسار في Firestore: users/{uid}/favorites/{placeId}
// - `id` = placeId (الـ Document ID)
// - `userId` = يأتي من الـ path (مش مخزّن في الوثيقة)
//
// مطابق لـ Master Plan v1.0:
//   users/{uid}/favorites/{pid}   ← المفضلة

import 'package:cloud_firestore/cloud_firestore.dart';

/// موديل المفضلة.
class Favorite {
  /// = placeId (الـ Document ID)
  final String id;

  /// يأتي من الـ path — مش مخزّن في الوثيقة
  final String userId;

  final String placeId;
  final DateTime? createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.placeId,
    this.createdAt,
  });

  // ═══════════════════════════════════════════════════════════════
  // PARSING
  // ═══════════════════════════════════════════════════════════════

  /// يحوّل من Firestore — `userId` يوصل من الـ path.
  ///
  /// **defensive casting:** يستخدم `is` بدل `as` لتفادي
  /// `TypeError` على بيانات قديمة/خاطئة (Admin panel، migrations).
  factory Favorite.fromMap(
    String userId,
    String docId,
    Map<String, dynamic> map,
  ) {
    // placeId — defensive cast
    final rawPlaceId = map['placeId'];
    final resolvedPlaceId =
        (rawPlaceId is String && rawPlaceId.isNotEmpty) ? rawPlaceId : docId;

    // createdAt — defensive cast
    final rawCreatedAt = map['createdAt'];
    final resolvedCreatedAt =
        rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null;

    return Favorite(
      id: docId,
      userId: userId,
      placeId: resolvedPlaceId,
      createdAt: resolvedCreatedAt,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SERIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// للكتابة في Firestore — بدون `userId` (موجود في الـ path).
  ///
  /// **مهم:** `placeId` يجب أن يكون موجوداً — الـ rules v3.0
  /// تتحقق من `request.resource.data.placeId == placeId`.
  Map<String, dynamic> toMap() => {
        'placeId': placeId,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  // ═══════════════════════════════════════════════════════════════
  // COPY WITH — consistency
  // ═══════════════════════════════════════════════════════════════

  Favorite copyWith({
    String? id,
    String? userId,
    String? placeId,
    DateTime? createdAt,
  }) =>
      Favorite(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        placeId: placeId ?? this.placeId,
        createdAt: createdAt ?? this.createdAt,
      );

  // ═══════════════════════════════════════════════════════════════
  // EQUALITY — للمقارنة في Sets والاختبارات
  // ═══════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Favorite &&
          other.id == id &&
          other.userId == userId &&
          other.placeId == placeId &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, userId, placeId, createdAt);

  @override
  String toString() => 'Favorite(user=$userId, place=$placeId)';
}
