// services/coupon_service.dart
// خدمة توليد واسترداد كوبونات المكافآت.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'YB-$code';
  }

  Future<Coupon> generateRewardCoupon({
    required String userId,
    required String placeId,
    required String ratingId,
  }) async {
    // المبدأ الأمني: التقييم الموثق يمنح كوبونًا واحدًا فقط.
    // نستخدم coupon_claims/{ratingId} كسجل حجز ذري للمكافأة، بينما يظل
    // Document ID للكوبون هو الكود الذي يكتبه التاجر عند الاسترداد.
    final claimRef = _db.collection('coupon_claims').doc(ratingId);
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));
    String? createdCode;
    String discountLabel = 'خصم 10% على زيارتك القادمة';

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      final couponRef = _db.collection('coupons').doc(code);

      final created = await _db.runTransaction<bool>((transaction) async {
        final claimSnapshot = await transaction.get(claimRef);
        if (claimSnapshot.exists) {
          throw StateError('تم إصدار كوبون هذا التقييم بالفعل');
        }

        final couponSnapshot = await transaction.get(couponRef);
        if (couponSnapshot.exists) return false;

        final ratingRef = _db.collection('ratings').doc(ratingId);
        final placeRef = _db.collection('places').doc(placeId);
        final ratingSnapshot = await transaction.get(ratingRef);
        final placeSnapshot = await transaction.get(placeRef);
        if (!ratingSnapshot.exists || !placeSnapshot.exists) {
          throw StateError('التقييم أو المكان غير موجود');
        }

        final rating = ratingSnapshot.data()!;
        if (rating['userId'] != userId || rating['placeId'] != placeId) {
          throw StateError('التقييم لا يخص هذا المستخدم أو المكان');
        }

        final configuredOffer = placeSnapshot.data()?['discountOffer'];
        discountLabel = configuredOffer is String && configuredOffer.trim().isNotEmpty
            ? configuredOffer.trim()
            : 'خصم 10% على زيارتك القادمة';

        // هذا المستند يمنع إصدار مكافأة ثانية لنفس التقييم حتى عند
        // وجود طلبين متزامنين من الهاتف.
        transaction.set(claimRef, {
          'ratingId': ratingId,
          'userId': userId,
          'placeId': placeId,
          'code': code,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.set(couponRef, {
          'code': code,
          'userId': userId,
          'placeId': placeId,
          'ratingId': ratingId,
          'discountLabel': discountLabel,
          'isUsed': false,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
        });
        return true;
      });

      if (created) {
        createdCode = code;
        break;
      }
    }

    if (createdCode == null) {
      throw StateError('تعذر إنشاء كود كوبون فريد، حاول مرة أخرى');
    }

    return Coupon(
      id: createdCode,
      code: createdCode,
      userId: userId,
      placeId: placeId,
      ratingId: ratingId,
      discountLabel: discountLabel,
      createdAt: now,
      expiresAt: expiresAt,
    );
  }

  Future<CouponRedemptionResult> redeemCoupon({
    required String code,
    required String merchantId,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final docRef = _db.collection('coupons').doc(normalizedCode);

    // ملاحظة التعديل:
    // الاسترداد Transaction ذري حتى لا يُستخدم الكوبون مرتين بالتزامن.
    try {
      final result = await _db.runTransaction<String>((transaction) async {
        final couponDoc = await transaction.get(docRef);
        if (!couponDoc.exists) return 'NOT_FOUND';

        final coupon = Coupon.fromMap(couponDoc.id, couponDoc.data()!);
        if (!coupon.isValid) return 'INVALID';

        final placeRef = _db.collection('places').doc(coupon.placeId);
        final placeDoc = await transaction.get(placeRef);
        if (!placeDoc.exists || placeDoc.data()?['ownerId'] != merchantId) {
          return 'WRONG_MERCHANT';
        }

        transaction.update(docRef, {
          'isUsed': true,
          'usedAt': FieldValue.serverTimestamp(),
          'usedBy': merchantId,
        });
        return 'OK:${coupon.discountLabel}';
      });

      if (result == 'NOT_FOUND') {
        return CouponRedemptionResult(success: false, message: 'الكود غير موجود');
      }
      if (result == 'INVALID') {
        return CouponRedemptionResult(
          success: false,
          message: 'الكود مستخدم من قبل أو منتهي الصلاحية',
        );
      }
      if (result == 'WRONG_MERCHANT') {
        return CouponRedemptionResult(success: false, message: 'هذا الكوبون ليس لمكانك');
      }

      return CouponRedemptionResult(
        success: true,
        message: '${result.substring(3)} ✅',
      );
    } on FirebaseException catch (e) {
      return CouponRedemptionResult(
        success: false,
        message: 'تعذر استرداد الكوبون: ${e.message ?? e.code}',
      );
    }
  }
}

class CouponRedemptionResult {
  final bool success;
  final String message;

  CouponRedemptionResult({required this.success, required this.message});
}

