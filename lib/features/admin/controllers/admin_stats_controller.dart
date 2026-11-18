// lib/features/admin/controllers/admin_stats_controller.dart
//
// [v1.2 — FIXED: REVIEWS SUM INTEGRATION]
//   - FIXED: Replaced 'reviews.count()' with 'places.aggregate(sum('reviewCount'))'
//     to ensure the dashboard accurately reflects the reviews attributed to places.
//   - KEPT: Safety flags (_disposed, _requestId) and all other queries.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_stats.dart';

class AdminStatsController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AdminStats _stats = const AdminStats();
  bool _loading = true;
  String? _error;

  // ✅ حماية ضد الانهيار بعد التدمير
  bool _disposed = false;
  // ✅ حماية ضد تضارب الطلبات (Race Condition)
  int _requestId = 0;

  AdminStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_disposed) return;

    // التقاط رقم الطلب الحالي
    final currentRequestId = ++_requestId;

    _loading = true;
    _error = null;
    _safeNotify();

    try {
      final places = _db.collection('places');
      final users = _db.collection('users');

      // ✅ 7 استعلامات تجميعية فقط (بدلاً من 100+ قراءة)
      final results = await Future.wait([
        places.count().get(),
        places.where('isApproved', isEqualTo: true).count().get(),
        places.where('isApproved', isEqualTo: false).count().get(),
        places.where('isActive', isEqualTo: true).count().get(),
        places.where('isActive', isEqualTo: false).count().get(),
        users.count().get(),
        // ✅ استخدام aggregate(sum) لجمع حقل reviewCount من الأماكن
        places.aggregate(sum('reviewCount')).get(),
      ]);

      // ✅ إذا تم إرسال طلب أحدث أو تم تدمير الشاشة، نتجاهل هذه النتيجة
      if (currentRequestId != _requestId || _disposed) return;

      _stats = AdminStats(
        totalPlaces: results[0].count ?? 0,
        approvedPlaces: results[1].count ?? 0,
        unapprovedPlaces: results[2].count ?? 0,
        activePlaces: results[3].count ?? 0,
        inactivePlaces: results[4].count ?? 0,
        totalUsers: results[5].count ?? 0,
        // ✅ قراءة المجموع النهائي
        totalReviews: results[6].getSum('reviewCount')?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error loading admin stats: $e');
      if (currentRequestId != _requestId || _disposed) return;
      _error = e.toString();
    } finally {
      // ✅ نُنهي التحميل فقط إذا كان هذا هو الطلب الأحدث ولم يتم التدمير
      if (currentRequestId == _requestId && !_disposed) {
        _loading = false;
        _safeNotify();
      }
    }
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
