// ⭐ الهدف: بناء ثقة قابلة للتحقق، لا جمع نجوم.
// نموذج الزيارة — يثبت وجود المستخدم فعليًا في المكان.

import 'package:cloud_firestore/cloud_firestore.dart';

class VisitModel {
  final String id;
  final String userId;
  final String placeId;
  final String verificationMethod;

  final double? latitude;
  final double? longitude;
  final double? distanceMeters;

  final bool pinVerified;
  final bool gpsVerified;
  final bool isMockedLocation;

  final String deviceId;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const VisitModel({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.verificationMethod,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    required this.pinVerified,
    required this.gpsVerified,
    required this.isMockedLocation,
    required this.deviceId,
    this.verifiedAt,
    required this.createdAt,
  });

  factory VisitModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return VisitModel.fromMap(doc.id, data);
  }

  factory VisitModel.fromMap(String id, Map<String, dynamic> data) {
    return VisitModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      placeId: data['placeId'] as String? ?? '',
      verificationMethod:
          data['verificationMethod'] as String? ?? 'SELF_DECLARED',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble(),
      pinVerified: data['pinVerified'] as bool? ?? false,
      gpsVerified: data['gpsVerified'] as bool? ?? false,
      isMockedLocation: data['isMockedLocation'] as bool? ?? false,
      deviceId: data['deviceId'] as String? ?? '',
      verifiedAt: _parseDate(data['verifiedAt']),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'placeId': placeId,
      'verificationMethod': verificationMethod,
      'latitude': latitude,
      'longitude': longitude,
      'distanceMeters': distanceMeters,
      'pinVerified': pinVerified,
      'gpsVerified': gpsVerified,
      'isMockedLocation': isMockedLocation,
      'deviceId': deviceId,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isValid =>
      verifiedAt != null && !isMockedLocation && (gpsVerified || pinVerified);

  bool get isFullyVerified => isValid && gpsVerified && pinVerified;

  String get verificationLabel {
    if (isMockedLocation) return 'موقع مزيّف';
    if (gpsVerified && pinVerified) return 'موثّق بالكامل (GPS + PIN)';
    if (gpsVerified) return 'موثّق بالموقع';
    if (pinVerified) return 'موثّق بالرمز';
    return 'غير موثّق';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
