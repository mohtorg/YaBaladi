// services/rating_service.dart
// خدمة إدارة التقييمات الموثّقة وتحديث متوسط المكان بصورة ذرّية.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating_model.dart';
import '../models/visit_model.dart';

class RatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> submitRating({
    required String visitId,
    required String placeId,
    required String userId,
    required int stars,
    String? comment,
  }) async {
    if (stars < 1 || stars > 5) {
      throw ArgumentError('عدد النجوم يجب أن يكون بين 1 و5');
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != userId) {
      throw StateError('المستخدم الحالي غير مخوّل بإرسال هذا التقييم');
    }

    // مفتاح التقييم هو visitId نفسه: زيارة واحدة = تقييم واحد فقط.
    final ratingRef = _db.collection('ratings').doc(visitId);
    final visitRef = _db.collection('visits').doc(visitId);
    final placeRef = _db.collection('places').doc(placeId);

    // ملاحظة التعديل:
    // أصبح Transaction يتحقق أولًا من أن الزيارة تخص المستخدم والمكان الصحيح
    // وأنها لم تُقيّم من قبل. ثم ينشئ التقييم ويقفل الزيارة ويحدث المتوسط في
    // العملية نفسها. هذا يمنع التقييم المكرر وتعارض تحديثات المتوسط.
    await _db.runTransaction((transaction) async {
      final visitSnapshot = await transaction.get(visitRef);
      final placeSnapshot = await transaction.get(placeRef);

      if (!visitSnapshot.exists || !placeSnapshot.exists) {
        throw StateError('الزيارة أو المكان غير موجود');
      }

      final visitData = visitSnapshot.data()!;
      if (visitData['userId'] != userId ||
          visitData['placeId'] != placeId ||
          visitData['ratingSubmitted'] == true) {
        throw StateError('هذه الزيارة غير صالحة لتقديم تقييم جديد');
      }

      final currentRating =
          (placeSnapshot.data()?['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount =
          (placeSnapshot.data()?['ratingCount'] as num?)?.toInt() ?? 0;
      final newCount = currentCount + 1;
      final newAverage = ((currentRating * currentCount) + stars) / newCount;

      final rating = Rating(
        id: ratingRef.id,
        visitId: visitId,
        placeId: placeId,
        userId: userId,
        stars: stars,
        comment: comment,
        createdAt: DateTime.now(),
      );

      transaction.set(ratingRef, {
        ...rating.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(visitRef, {'ratingSubmitted': true});
      transaction.update(placeRef, {
        'rating': double.parse(newAverage.toStringAsFixed(2)),
        'ratingCount': newCount,
        'lastRatingId': ratingRef.id,
      });
    });

    return ratingRef.id;
  }

  // سجل التقييمات يختلف عن الزيارات المنتظرة للتقييم.
  // هذه الدالة تقرأ فقط التقييمات التي أرسلها المستخدم فعليًا، بينما
  // pendingRatableVisits تبقى مخصصة للزيارات التي لم تُقيّم بعد.
  Stream<List<Rating>> userRatings(String userId) {
    return _db
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final ratings = snapshot.docs
          .map((doc) => Rating.fromMap(doc.id, doc.data()))
          .toList();
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ratings;
    });
  }

  Stream<List<Visit>> pendingRatableVisits(String userId) {
    return _db
        .collection('visits')
        .where('userId', isEqualTo: userId)
        .where('ratingSubmitted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final visits = snapshot.docs
          .map((doc) => Visit.fromMap(doc.id, doc.data()))
          .where((visit) => visit.canStillRate)
          .toList();
      visits.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      return visits;
    });
  }
}
