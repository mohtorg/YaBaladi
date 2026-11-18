// lib/models/rating_model.dart
// [v2.2 — 2026-11-15] — PHASE 8: added `baseScore` + `baseScoreMetadata`.
//   - `baseScore`: weighted mean of dimensions, computed from criterion
//     weights captured in `dimensionsMetadata` at rating time.
//   - `baseScoreMetadata`: audit trail of the weights used (weights map,
//     source, dimension count, timestamp). Persisted for reproducibility.
//   - `effectiveScore` getter: aggregation-safe accessor — falls back to
//     `overall` for legacy ratings written before Phase 8.
//   - No breaking change: both fields nullable, default null.
// [v2.1 — 2026-11-12] — ADDED METADATA SNAPSHOT.

import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String placeId;
  final String userId;
  final String userDisplayName;
  final double userTrustScore;
  final bool isUserVerified;

  final int overall;

  // الحقول القديمة (Legacy)
  final int? cleanliness;
  final int? service;
  final int? price;
  final int? access;

  // الحقول الجديدة (Dynamic Dimensions)
  final Map<String, int> dimensions;
  final Map<String, dynamic> dimensionsMetadata; // بصمة المعايير وقت التقييم
  final int templateVersion;

  // ✅ Phase 8: BaseScore المحسوب من أوزان المعايير
  final double? baseScore;
  final Map<String, dynamic>? baseScoreMetadata;

  final String? title;
  final String body;
  final DateTime? visitDate;

  final String status;
  final double trustWeight;
  final String verificationMethod;
  final String? visitId;

  final int helpfulCount;
  final int reportCount;
  final String? merchantReply;
  final DateTime? merchantRepliedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RatingModel({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.userDisplayName,
    required this.userTrustScore,
    required this.isUserVerified,
    required this.overall,
    this.cleanliness,
    this.service,
    this.price,
    this.access,
    required this.dimensions,
    required this.dimensionsMetadata,
    required this.templateVersion,
    this.baseScore,
    this.baseScoreMetadata,
    this.title,
    required this.body,
    this.visitDate,
    required this.status,
    required this.trustWeight,
    required this.verificationMethod,
    this.visitId,
    required this.helpfulCount,
    required this.reportCount,
    this.merchantReply,
    this.merchantRepliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RatingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return RatingModel.fromMap(doc.id, data);
  }

  factory RatingModel.fromMap(String id, Map<String, dynamic> data) {
    final Map<String, int> parsedDimensions = {};
    if (data['dimensions'] != null && data['dimensions'] is Map) {
      (data['dimensions'] as Map).forEach((key, value) {
        if (value is num) {
          parsedDimensions[key.toString()] = value.toInt();
        }
      });
    } else {
      if (data['cleanliness'] != null) {
        parsedDimensions['cleanliness'] = (data['cleanliness'] as num).toInt();
      }
      if (data['service'] != null) {
        parsedDimensions['service'] = (data['service'] as num).toInt();
      }
      if (data['price'] != null) {
        parsedDimensions['price'] = (data['price'] as num).toInt();
      }
      if (data['access'] != null) {
        parsedDimensions['access'] = (data['access'] as num).toInt();
      }
    }

    final Map<String, dynamic> metadata = {};
    if (data['dimensionsMetadata'] != null &&
        data['dimensionsMetadata'] is Map) {
      metadata.addAll(data['dimensionsMetadata'] as Map<String, dynamic>);
    }

    Map<String, dynamic>? baseScoreMeta;
    if (data['baseScoreMetadata'] != null && data['baseScoreMetadata'] is Map) {
      baseScoreMeta =
          Map<String, dynamic>.from(data['baseScoreMetadata'] as Map);
    }

    return RatingModel(
      id: id,
      placeId: data['placeId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userDisplayName: data['userDisplayName'] as String? ?? 'مستخدم',
      userTrustScore: (data['userTrustScore'] as num?)?.toDouble() ?? 0.0,
      isUserVerified: data['isUserVerified'] as bool? ?? false,
      overall: (data['overall'] as num?)?.toInt() ?? 0,
      cleanliness: (data['cleanliness'] as num?)?.toInt(),
      service: (data['service'] as num?)?.toInt(),
      price: (data['price'] as num?)?.toInt(),
      access: (data['access'] as num?)?.toInt(),
      dimensions: parsedDimensions,
      dimensionsMetadata: metadata,
      templateVersion: (data['templateVersion'] as num?)?.toInt() ?? 1,
      baseScore: (data['baseScore'] as num?)?.toDouble(),
      baseScoreMetadata: baseScoreMeta,
      title: data['title'] as String?,
      body: data['body'] as String? ?? '',
      visitDate: _parseDate(data['visitDate']),
      status: data['status'] as String? ?? 'PUBLISHED',
      trustWeight: (data['trustWeight'] as num?)?.toDouble() ?? 1.0,
      verificationMethod:
          data['verificationMethod'] as String? ?? 'SELF_DECLARED',
      visitId: data['visitId'] as String?,
      helpfulCount: (data['helpfulCount'] as num?)?.toInt() ?? 0,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      merchantReply: data['merchantReply'] as String?,
      merchantRepliedAt: _parseDate(data['merchantRepliedAt']),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userTrustScore': userTrustScore,
      'isUserVerified': isUserVerified,
      'overall': overall,
      'cleanliness': cleanliness,
      'service': service,
      'price': price,
      'access': access,
      'dimensions': dimensions,
      'dimensionsMetadata': dimensionsMetadata,
      'templateVersion': templateVersion,
      if (baseScore != null) 'baseScore': baseScore,
      if (baseScoreMetadata != null) 'baseScoreMetadata': baseScoreMetadata,
      'title': title,
      'body': body,
      'visitDate': visitDate != null ? Timestamp.fromDate(visitDate!) : null,
      'status': status,
      'trustWeight': trustWeight,
      'verificationMethod': verificationMethod,
      'visitId': visitId,
      'helpfulCount': helpfulCount,
      'reportCount': reportCount,
      'merchantReply': merchantReply,
      'merchantRepliedAt': merchantRepliedAt != null
          ? Timestamp.fromDate(merchantRepliedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RatingModel copyWith({
    String? id,
    String? placeId,
    String? userId,
    String? userDisplayName,
    double? userTrustScore,
    bool? isUserVerified,
    int? overall,
    int? cleanliness,
    int? service,
    int? price,
    int? access,
    Map<String, int>? dimensions,
    Map<String, dynamic>? dimensionsMetadata,
    int? templateVersion,
    double? baseScore,
    Map<String, dynamic>? baseScoreMetadata,
    String? title,
    String? body,
    DateTime? visitDate,
    String? status,
    double? trustWeight,
    String? verificationMethod,
    String? visitId,
    int? helpfulCount,
    int? reportCount,
    String? merchantReply,
    DateTime? merchantRepliedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userTrustScore: userTrustScore ?? this.userTrustScore,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      overall: overall ?? this.overall,
      cleanliness: cleanliness ?? this.cleanliness,
      service: service ?? this.service,
      price: price ?? this.price,
      access: access ?? this.access,
      dimensions: dimensions ?? this.dimensions,
      dimensionsMetadata: dimensionsMetadata ?? this.dimensionsMetadata,
      templateVersion: templateVersion ?? this.templateVersion,
      baseScore: baseScore ?? this.baseScore,
      baseScoreMetadata: baseScoreMetadata ?? this.baseScoreMetadata,
      title: title ?? this.title,
      body: body ?? this.body,
      visitDate: visitDate ?? this.visitDate,
      status: status ?? this.status,
      trustWeight: trustWeight ?? this.trustWeight,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      visitId: visitId ?? this.visitId,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reportCount: reportCount ?? this.reportCount,
      merchantReply: merchantReply ?? this.merchantReply,
      merchantRepliedAt: merchantRepliedAt ?? this.merchantRepliedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isVerified => trustWeight >= 1.2;
  bool get isPending => status == 'PENDING';
  bool get isPublished => status == 'PUBLISHED';
  bool get isHidden => status == 'HIDDEN';
  bool get hasMerchantReply =>
      merchantReply != null && merchantReply!.isNotEmpty;

  /// Phase 8: هل هذا التقييم يحمل baseScore محسوباً؟
  bool get hasBaseScore => baseScore != null;

  /// Phase 8: الدرجة المستخدمة في التجميع.
  /// - تقييمات Phase 8+: `baseScore` (محسوب من dimensions + weights).
  /// - تقييمات Legacy (قبل Phase 8): `overall` كـ fallback.
  ///
  /// هذا الـ getter هو مصدر واحد للحقيقة، يمنع الأخطاء في `AggregateService`.
  double get effectiveScore => baseScore ?? overall.toDouble();

  Map<String, int> get availableDimensions => dimensions;

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
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
