// lib/features/rating/services/rating_service.dart
// [v8.1 — 2026-11-15] — PHASE 8: BaseScore from criterion weights.
//   - Added `_computeBaseScore`: weighted mean of `dimensions` using weights
//     extracted from `dimensionsMetadata` (the criteria fingerprint captured
//     at rating time). Falls back to uniform weights when no weight is
//     present, and to `overall` when `dimensions` is empty.
//   - Persists `baseScore` + `baseScoreMetadata` in both create and update
//     paths, and archives `baseScore` top-level in `rating_revisions`.
//   - No UX change: `overall` remains the user-facing star rating.
// [v8.0.1 — 2026-11-15] — LINTER FIX (unchanged).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/user_trust_service.dart';
import '../../../models/moderation_log_model.dart';
import '../../../models/rating_model.dart';
import 'aggregate_service.dart';
import 'device_service.dart';
import '../../../services/location_service.dart';
import 'pin_service.dart';
import 'visit_service.dart';

class RatingSubmitResult {
  final bool success;
  final String? ratingId;
  final double? trustWeight;
  final bool? isFullyVerified;
  final String? verificationMethod;
  final String? failureReason;
  final bool isUpdate;

  const RatingSubmitResult({
    required this.success,
    this.ratingId,
    this.trustWeight,
    this.isFullyVerified,
    this.verificationMethod,
    this.failureReason,
    this.isUpdate = false,
  });

  factory RatingSubmitResult.failure(String reason) {
    return RatingSubmitResult(success: false, failureReason: reason);
  }
}

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VisitService _visitService = VisitService();
  final AggregateService _aggregateService = AggregateService();

  Future<RatingSubmitResult> submitRating({
    required String placeId,
    required String categoryId,
    required double placeLat,
    required double placeLng,
    required String pinObfuscated,
    String? zoneId,
    required int overall,
    required Map<String, int> dimensions,
    required Map<String, dynamic> dimensionsMetadata,
    String? title,
    required String body,
    String? userProvidedPin,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return RatingSubmitResult.failure('يجب تسجيل الدخول أولًا');
    }

    // ─── Phase 15: منع التقييم الذاتي ───
    final placeSnap = await _firestore.collection('places').doc(placeId).get();
    if (!placeSnap.exists) {
      return RatingSubmitResult.failure('المكان لم يعد موجوداً');
    }
    final placeData = placeSnap.data() ?? {};
    final placeOwnerId = placeData['ownerId']?.toString() ?? '';
    if (placeOwnerId.isNotEmpty && placeOwnerId == user.uid) {
      return RatingSubmitResult.failure(
        'لا يمكنك تقييم مكان تملكه — التقييمات يجب أن تكون من زوار حقيقيين',
      );
    }

    // ─── 1. التحقق من الموقع ───
    final locationResult = await LocationService.validatePresenceWithGeoZone(
      placeLat: placeLat,
      placeLng: placeLng,
      zoneId: zoneId,
    );
    if (locationResult.isMocked) {
      return RatingSubmitResult.failure(
        locationResult.reason ?? 'تم اكتشاف موقع مزيّف',
      );
    }

    // ─── 2. التحقق من PIN ───
    bool pinVerified = false;
    if (userProvidedPin != null && userProvidedPin.trim().isNotEmpty) {
      pinVerified = PinService.verify(
        placeId: placeId,
        pinObfuscated: pinObfuscated,
        userInput: userProvidedPin,
      );
      if (!pinVerified) {
        return RatingSubmitResult.failure(
          'رمز المكان غير صحيح — راجع الرمز عند الكاشير',
        );
      }
    }

    if (!locationResult.success && !pinVerified) {
      return RatingSubmitResult.failure(
        locationResult.reason ?? 'فشل التحقق من وجودك في المكان',
      );
    }

    // ─── 3. موثوقية المستخدم ───
    final deviceId = await DeviceService.getDeviceId();
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final publishedCount =
        (userData['publishedRatingsCount'] as num?)?.toInt() ?? 0;
    final distinctCategories = await _getUserDistinctCategoriesCount(user.uid);
    final emailVerified = user.emailVerified;

    final userTrustFactor = UserTrustService.computeTrustFactor(
      userData: userData,
      publishedCount: publishedCount,
      distinctCategoriesCount: distinctCategories,
      emailVerified: emailVerified,
    );

    // ─── 4. Phase 16: هل يوجد تقييم سابق منشور من هذا المستخدم؟ ───
    final existingSnap = await _firestore
        .collection('ratings')
        .where('placeId', isEqualTo: placeId)
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'PUBLISHED')
        .limit(1)
        .get();

    final RatingModel? existingRating = existingSnap.docs.isNotEmpty
        ? RatingModel.fromFirestore(existingSnap.docs.first)
        : null;
    final String? existingRatingId =
        existingSnap.docs.isNotEmpty ? existingSnap.docs.first.id : null;

    final bool isUpdate = existingRating != null;

    // ─── 5. حد الاستخدام اليومي (فقط للتقييمات الجديدة) ───
    if (!isUpdate) {
      final recentVisits =
          await _visitService.countUserVisitsInLast24h(user.uid);
      if (recentVisits >= 10) {
        return RatingSubmitResult.failure(
          'لقد قيّمت 10 أماكن اليوم — حاول غدًا للحفاظ على جودة التقييمات',
        );
      }
    }

    // ─── 6. عامل التحقق + الوزن النهائي ───
    final verificationFactor = _computeVerificationFactor(
      polygonVerified: locationResult.isPolygonVerified,
      radiusVerified: locationResult.isRadiusVerified,
      pinVerified: pinVerified,
    );
    final trustWeight = userTrustFactor * verificationFactor;

    final method = _methodFor(
      polygonVerified: locationResult.isPolygonVerified,
      gpsVerified: locationResult.success,
      pinVerified: pinVerified,
    );

    // ─── 7. إنشاء الزيارة ───
    final visitId = await _visitService.createVisit(
      userId: user.uid,
      placeId: placeId,
      gpsVerified: locationResult.success,
      pinVerified: pinVerified,
      latitude: locationResult.latitude,
      longitude: locationResult.longitude,
      distanceMeters: locationResult.distanceMeters,
      isMockedLocation: locationResult.isMocked,
      deviceId: deviceId,
    );

    // ─── 7.b ✅ Phase 8: حساب baseScore من أوزان المعايير ───
    final baseScoreResult = _computeBaseScore(
      overall: overall,
      dimensions: dimensions,
      dimensionsMetadata: dimensionsMetadata,
    );
    final double baseScore = baseScoreResult.baseScore;
    final Map<String, dynamic> baseScoreMetadata = baseScoreResult.metadata;

    final now = DateTime.now();

    // ─── 8. Phase 16: إنشاء أو تحديث ───
    String ratingId;
    RatingModel ratingModel;
    if (existingRating != null && existingRatingId != null) {
      // ─────────── مسار التحديث ───────────

      // (أ) أرشفة التقييم القديم في rating_revisions
      await _firestore.collection('rating_revisions').add({
        'ratingId': existingRatingId,
        'userId': user.uid,
        'placeId': placeId,
        // ✅ Phase 8: top-level للاستعلام السريع
        'baseScore': existingRating.baseScore,
        'snapshot': existingRating.toMap(),
        'replacedAt': FieldValue.serverTimestamp(),
      });

      // (ب) تحديث التقييم الفعلي
      await _firestore.collection('ratings').doc(existingRatingId).update({
        'categoryId': categoryId,
        'userDisplayName': user.displayName ?? existingRating.userDisplayName,
        'userTrustScore': (userData['trustScore'] as num?)?.toDouble() ?? 0,
        'isUserVerified': emailVerified,
        'overall': overall,
        'dimensions': dimensions,
        'dimensionsMetadata': dimensionsMetadata,
        'templateVersion': 1,
        // ✅ Phase 8
        'baseScore': baseScore,
        'baseScoreMetadata': baseScoreMetadata,
        'title': title,
        'body': body,
        'trustWeight': trustWeight,
        'verificationMethod': method,
        'visitId': visitId,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastEditedAt': FieldValue.serverTimestamp(),
      });

      ratingId = existingRatingId;
      ratingModel = RatingModel(
        id: ratingId,
        placeId: placeId,
        userId: user.uid,
        userDisplayName: user.displayName ?? existingRating.userDisplayName,
        userTrustScore: (userData['trustScore'] as num?)?.toDouble() ?? 0,
        isUserVerified: emailVerified,
        overall: overall,
        dimensions: dimensions,
        dimensionsMetadata: dimensionsMetadata,
        templateVersion: 1,
        baseScore: baseScore,
        baseScoreMetadata: baseScoreMetadata,
        title: title,
        body: body,
        status: 'PUBLISHED',
        trustWeight: trustWeight,
        verificationMethod: method,
        visitId: visitId,
        helpfulCount: existingRating.helpfulCount,
        reportCount: existingRating.reportCount,
        merchantReply: existingRating.merchantReply,
        merchantRepliedAt: existingRating.merchantRepliedAt,
        createdAt: existingRating.createdAt,
        updatedAt: now,
      );

      // (ج) تحديث الإحصاءات ذريّاً
      await _aggregateService.onRatingUpdated(
        placeId: placeId,
        oldRating: existingRating,
        newRating: ratingModel,
      );

      // (د) تحديث المستخدم بدون زيادة العداد
      await _firestore.collection('users').doc(user.uid).set(
        {
          'userTrustFactor': userTrustFactor,
          'lastRatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      // ─────────── مسار الإنشاء ───────────
      // [v-R3] معرّف حتمي: تقييم واحد لكل مستخدم لكل مكان، تفرضه القواعد.
      final String newRatingId = '${user.uid}_$placeId';
      await _firestore.collection('ratings').doc(newRatingId).set({
        'placeId': placeId,
        'categoryId': categoryId,
        'userId': user.uid,
        'userDisplayName': user.displayName ?? 'مستخدم',
        'userTrustScore': (userData['trustScore'] as num?)?.toDouble() ?? 0,
        'isUserVerified': emailVerified,
        'overall': overall,
        'dimensions': dimensions,
        'dimensionsMetadata': dimensionsMetadata,
        'templateVersion': 1,
        // ✅ Phase 8
        'baseScore': baseScore,
        'baseScoreMetadata': baseScoreMetadata,
        'title': title,
        'body': body,
        'visitDate': null,
        'status': 'PUBLISHED',
        'trustWeight': trustWeight,
        'verificationMethod': method,
        'visitId': visitId,
        'helpfulCount': 0,
        'reportCount': 0,
        'merchantReply': null,
        'merchantRepliedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ratingId = newRatingId;
      ratingModel = RatingModel(
        id: ratingId,
        placeId: placeId,
        userId: user.uid,
        userDisplayName: user.displayName ?? 'مستخدم',
        userTrustScore: (userData['trustScore'] as num?)?.toDouble() ?? 0,
        isUserVerified: emailVerified,
        overall: overall,
        dimensions: dimensions,
        dimensionsMetadata: dimensionsMetadata,
        templateVersion: 1,
        baseScore: baseScore,
        baseScoreMetadata: baseScoreMetadata,
        title: title,
        body: body,
        status: 'PUBLISHED',
        trustWeight: trustWeight,
        verificationMethod: method,
        visitId: visitId,
        helpfulCount: 0,
        reportCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      await _aggregateService.onNewRating(
        placeId: placeId,
        rating: ratingModel,
      );

      await _firestore.collection('users').doc(user.uid).set(
        {
          'publishedRatingsCount': FieldValue.increment(1),
          'userTrustFactor': userTrustFactor,
          'lastRatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    return RatingSubmitResult(
      success: true,
      ratingId: ratingId,
      trustWeight: trustWeight,
      isFullyVerified: locationResult.success && pinVerified,
      verificationMethod: method,
      isUpdate: isUpdate,
    );
  }

  Future<void> reportRating({
    required String ratingId,
    required ReportReason reason,
    String? note,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول لإرسال بلاغ');
    }

    final ratingDoc =
        await _firestore.collection('ratings').doc(ratingId).get();
    if (!ratingDoc.exists) {
      throw Exception('التقييم لم يعد موجوداً');
    }
    final ratingData = ratingDoc.data() ?? {};
    if (ratingData['userId'] == user.uid) {
      throw Exception('لا يمكنك الإبلاغ عن تقييمك الخاص');
    }
    final ratingStatus = (ratingData['status'] ?? 'PUBLISHED').toString();
    if (ratingStatus == 'REMOVED') {
      throw Exception('هذا التقييم محذوف بالفعل');
    }

    await _firestore.collection('ratings').doc(ratingId).update({
      'reportCount': FieldValue.increment(1),
    });

    await _firestore.collection('reports').add({
      'ratingId': ratingId,
      'reporterId': user.uid,
      'reporterName': user.displayName,
      'reason': reason.key,
      if (note != null && note.isNotEmpty) 'reasonNote': note,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> _getUserDistinctCategoriesCount(String userId) async {
    try {
      final snap = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'PUBLISHED')
          .get();

      final Set<String> categories = {};
      for (final doc in snap.docs) {
        final cat = doc.data()['categoryId']?.toString();
        if (cat != null && cat.isNotEmpty) {
          categories.add(cat);
        }
      }
      return categories.length;
    } catch (_) {
      return 0;
    }
  }

  double _computeVerificationFactor({
    required bool polygonVerified,
    required bool radiusVerified,
    required bool pinVerified,
  }) {
    if (polygonVerified && pinVerified) return 1.7;
    if (polygonVerified) return 1.4;
    if (radiusVerified && pinVerified) return 1.5;
    if (radiusVerified) return 1.2;
    if (pinVerified) return 1.0;
    return 0.6;
  }

  String _methodFor({
    required bool polygonVerified,
    required bool gpsVerified,
    required bool pinVerified,
  }) {
    if (polygonVerified && pinVerified) return 'POLYGON_PIN';
    if (polygonVerified) return 'POLYGON';
    if (gpsVerified && pinVerified) return 'GPS_PIN';
    if (gpsVerified) return 'GPS';
    if (pinVerified) return 'PIN';
    return 'SELF_DECLARED';
  }

  // ═══════════════════════════════════════════════════════════════════
  // ✅ Phase 8: BaseScore computation
  // ═══════════════════════════════════════════════════════════════════

  /// يحسب `baseScore` من `dimensions` + أوزان المعايير.
  ///
  /// الاستراتيجية (تصاعدية):
  /// 1. `dimensions` فارغة → fallback إلى `overall.toDouble()`.
  /// 2. معايير بأوزان صريحة في `dimensionsMetadata` → weighted mean.
  /// 3. معايير بلا أوزان → uniform weights (1.0) → plain mean of dimensions.
  ///
  /// النتيجة دائماً في النطاق [1.0, 5.0].
  ///
  /// ملاحظة: `dimensionsMetadata` هي "بصمة المعايير وقت التقييم"؛
  /// هي المصدر الصحيح للأوزان لأنها تضمن أن `baseScore` قابل لإعادة
  /// الحساب حتى لو تغيرت `review_criteria` لاحقاً.
  ({double baseScore, Map<String, dynamic> metadata}) _computeBaseScore({
    required int overall,
    required Map<String, int> dimensions,
    required Map<String, dynamic> dimensionsMetadata,
  }) {
    // (1) لا dimensions → fallback إلى overall
    if (dimensions.isEmpty) {
      return (
        baseScore: overall.toDouble().clamp(1.0, 5.0),
        metadata: {
          'source': 'overall_fallback',
          'reason': 'empty_dimensions',
          'computedAt': Timestamp.now(),
        },
      );
    }

    // (2) + (3) حساب weighted mean، مع uniform fallback عند غياب الوزن
    final Map<String, double> weights = {};
    double sumWeighted = 0.0;
    double sumWeight = 0.0;
    bool anyExplicitWeight = false;

    for (final entry in dimensions.entries) {
      final rawWeight = _extractWeight(dimensionsMetadata[entry.key]);
      final weight = rawWeight ?? 1.0;
      if (rawWeight != null) {
        anyExplicitWeight = true;
      }
      weights[entry.key] = weight;
      sumWeighted += entry.value * weight;
      sumWeight += weight;
    }

    if (sumWeight <= 0) {
      // حماية رياضية — لا يُفترض الوصول هنا (dimensions غير فارغة)
      return (
        baseScore: overall.toDouble().clamp(1.0, 5.0),
        metadata: {
          'source': 'overall_fallback',
          'reason': 'zero_sum_weight',
          'computedAt': Timestamp.now(),
        },
      );
    }

    final raw = sumWeighted / sumWeight;
    return (
      baseScore: raw.clamp(1.0, 5.0),
      metadata: {
        'source':
            anyExplicitWeight ? 'dimensions_metadata' : 'uniform_fallback',
        'weights': weights,
        'dimensionCount': dimensions.length,
        'computedAt': Timestamp.now(),
      },
    );
  }

  /// يستخرج الوزن من قيمة `dimensionsMetadata[criterionId]`.
  /// يدعم تنسيقين:
  /// - مباشر: `num` (مثال: `1.5`)
  /// - Map: `{'weight': num, ...}`
  double? _extractWeight(dynamic metadata) {
    if (metadata == null) return null;
    if (metadata is num) return metadata.toDouble();
    if (metadata is Map) {
      final w = metadata['weight'];
      if (w is num) return w.toDouble();
    }
    return null;
  }
}
