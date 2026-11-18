// lib/core/services/offer_cleanup_service.dart
// [v1.1 — CLIENT-SIDE FILTER FIX]
//   - REMOVED: Compound where() query that caused 'failed-precondition' (missing index) error.
//   - ADDED: Fetches active offers first, then checks expiry date locally in Dart.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OfferCleanupService {
  static Future<void> cleanExpiredOffers() async {
    try {
      final now = Timestamp.now();

      // ✅ جلب الأماكن التي لديها عرض نشط فقط (استعلام بحقل واحد لا يحتاج فهرس مركب)
      final activeOffersSnap = await FirebaseFirestore.instance
          .collection('places')
          .where('hasActiveOffer', isEqualTo: true)
          .get();

      if (activeOffersSnap.docs.isEmpty) return;

      // ✅ الفلترة محلياً للتأكد من أن تاريخ الانتهاء قد مضى
      final expiredDocs = activeOffersSnap.docs.where((doc) {
        final data = doc.data();
        final expiry = data['offerExpiryDate'];
        if (expiry is Timestamp) {
          return expiry.compareTo(now) < 0;
        }
        return false;
      }).toList();

      if (expiredDocs.isEmpty) return; // لا توجد عروض منتهية

      // استخدام Batch لتحديثها كلها دفعة واحدة (كفاءة وسرعة)
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in expiredDocs) {
        batch.update(doc.reference, {
          'hasActiveOffer': false,
          'offerTitle': FieldValue.delete(),
          'offerDetails': FieldValue.delete(),
          'offerExpiryDate': FieldValue.delete(),
          'offerCreatedAt': FieldValue.delete(),
        });
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('🧹 Cleaned up ${expiredDocs.length} expired offers.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error cleaning expired offers: $e');
      }
    }
  }
}
