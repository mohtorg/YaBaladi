// ⭐ الهدف: بناء ثقة قابلة للتحقق، لا جمع نجوم.
// تسجيل زيارة موثقة — شرط أساسي لكتابة تقييم.

import 'package:cloud_firestore/cloud_firestore.dart';

class VisitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ينشئ وثيقة زيارة موثقة. يجب أن يُستدعى **بعد** التحقق من GPS و/أو PIN.
  Future<String> createVisit({
    required String userId,
    required String placeId,
    required bool gpsVerified,
    required bool pinVerified,
    required double? latitude,
    required double? longitude,
    required double? distanceMeters,
    required bool isMockedLocation,
    required String deviceId,
  }) async {
    final isValid = (gpsVerified || pinVerified) && !isMockedLocation;

    final data = <String, dynamic>{
      'userId': userId,
      'placeId': placeId,
      'verificationMethod': _deriveMethod(gpsVerified, pinVerified),
      'latitude': latitude,
      'longitude': longitude,
      'distanceMeters': distanceMeters,
      'pinVerified': pinVerified,
      'gpsVerified': gpsVerified,
      'isMockedLocation': isMockedLocation,
      'deviceId': deviceId,
      'verifiedAt': isValid ? FieldValue.serverTimestamp() : null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final doc = await _firestore.collection('visits').add(data);
    return doc.id;
  }

  /// يعيد آخر زيارة صالحة لمستخدم معين في مكان معين (خلال الـ 24 ساعة الأخيرة).
  Future<Map<String, dynamic>?> getRecentValidVisit({
    required String userId,
    required String placeId,
  }) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final snap = await _firestore
        .collection('visits')
        .where('userId', isEqualTo: userId)
        .where('placeId', isEqualTo: placeId)
        .where('verifiedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('verifiedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return {...data, 'id': snap.docs.first.id};
  }

  /// يحسب عدد تقييمات المستخدم في آخر 24 ساعة (مقاومة التلاعب).
  Future<int> countUserVisitsInLast24h(String userId) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final snap = await _firestore
        .collection('visits')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .count()
        .get();
    return snap.count ?? 0;
  }

  String _deriveMethod(bool gps, bool pin) {
    if (gps && pin) return 'GPS_PIN';
    if (gps) return 'GPS';
    if (pin) return 'PIN';
    return 'SELF_DECLARED';
  }
}
