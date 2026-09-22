// services/visit_service.dart
// خدمة إدارة دورة حياة الزيارة الموثّقة.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visit_request_model.dart';
import '../models/visit_model.dart';

class VisitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createVisitRequest(String placeId, String userId) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 10));
    final docRef = _db.collection('visit_requests').doc();

    // ملاحظة التعديل:
    // createdAt أصبح وقت خادم Firestore بدل الاعتماد على ساعة جهاز المستخدم.
    // expiresAt يظل Timestamp ثابتًا محسوبًا من الوقت الحالي حتى يمكن التحقق
    // منه بسهولة في التطبيق وقواعد Firestore.
    await docRef.set({
      'placeId': placeId,
      'userId': userId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });

    return docRef.id;
  }

  Future<VisitConfirmationResult> confirmVisitRequest({
    required String requestId,
    required String merchantId,
  }) async {
    // ملاحظة التعديل:
    // تم تحويل تأكيد الزيارة من قراءة ثم Batch منفصل إلى Transaction واحدة.
    // بذلك لا يمكن لمسح QR مرتين في نفس اللحظة أن ينشئ زيارتين لنفس الطلب.
    final requestRef = _db.collection('visit_requests').doc(requestId);
    final visitRef = _db.collection('visits').doc();

    try {
      await _db.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) {
          throw const _VisitConfirmationException('الكود غير صحيح أو غير موجود');
        }

        final request = VisitRequest.fromMap(
          requestSnapshot.id,
          requestSnapshot.data()!,
        );

        if (!request.isValid) {
          throw const _VisitConfirmationException(
            'الكود منتهي الصلاحية، اطلب كود جديد',
          );
        }

        final placeRef = _db.collection('places').doc(request.placeId);
        final placeSnapshot = await transaction.get(placeRef);
        if (!placeSnapshot.exists ||
            placeSnapshot.data()?['ownerId'] != merchantId) {
          throw const _VisitConfirmationException('هذا الكود ليس لمكانك');
        }

        final now = DateTime.now();
        final visit = Visit(
          id: visitRef.id,
          placeId: request.placeId,
          userId: request.userId,
          merchantId: merchantId,
          visitRequestId: requestId,
          scannedAt: now,
          ratingWindowExpiresAt: now.add(const Duration(hours: 24)),
        );

        transaction.set(visitRef, {
          ...visit.toMap(),
          'scannedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(requestRef, {
          'status': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
          'confirmedBy': merchantId,
        });
      });

      return VisitConfirmationResult(
        success: true,
        message: 'تم تسجيل الزيارة بنجاح ✅',
      );
    } on _VisitConfirmationException catch (e) {
      return VisitConfirmationResult(success: false, message: e.message);
    }
  }
}

class _VisitConfirmationException implements Exception {
  final String message;
  const _VisitConfirmationException(this.message);
}

class VisitConfirmationResult {
  final bool success;
  final String message;

  VisitConfirmationResult({required this.success, required this.message});
}
