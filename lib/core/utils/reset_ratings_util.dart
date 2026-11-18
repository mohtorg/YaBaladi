// lib/core/utils/reset_ratings_util.dart
// [v1.1 — 2026-11-15] — LINTER FIX: Replaced `print` with `debugPrint` to
//   satisfy `avoid_print` rule. No behavioral change.
// [v1.0 — 2026-11-15] — ONE-TIME UTILITY: Reset all ratings.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ResetRatingsUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> resetAllRatings() async {
    debugPrint('🚀 بدء تصفير جميع التقييمات...');

    // 1. مسح ratings
    await _deleteCollection('ratings');
    debugPrint('✅ تم مسح ratings');

    // 2. مسح place_aggregates
    await _deleteCollection('place_aggregates');
    debugPrint('✅ تم مسح place_aggregates');

    // 3. مسح rating_revisions
    await _deleteCollection('rating_revisions');
    debugPrint('✅ تم مسح rating_revisions');

    // 4. إعادة ضبط places
    final places = await _firestore.collection('places').get();
    var batch = _firestore.batch();
    var count = 0;

    for (final doc in places.docs) {
      batch.update(doc.reference, {
        'averageRating': 0.0,
        'reviewCount': 0,
        'adjustedScore': 0.0,
        'sampleQuality': 0.0,
        'isRankable': false,
        'confidenceLabel': null,
      });
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
    debugPrint('✅ تم تصفير بيانات places (${places.docs.length} مكان)');

    debugPrint('🎉 اكتمل التصفير بنجاح!');
  }

  static Future<void> _deleteCollection(String collectionName) async {
    final snapshots = await _firestore.collection(collectionName).get();
    var batch = _firestore.batch();
    var count = 0;

    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }
}
