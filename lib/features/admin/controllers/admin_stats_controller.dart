// lib/features/admin/controllers/admin_stats_controller.dart
//
// [v1.0 — 2026-10-21] — Stats via Aggregate Queries (95% quota savings)

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_stats.dart';

class AdminStatsController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AdminStats _stats = const AdminStats();
  bool _loading = true;
  String? _error;

  AdminStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final places = _db.collection('places');
      final users = _db.collection('users');
      final reviews = _db.collection('reviews');

      // ✅ 7 استعلامات تجميعية فقط (بدلاً من 100+ قراءة)
      final results = await Future.wait([
        places.count().get(),
        places.where('isApproved', isEqualTo: true).count().get(),
        places.where('isApproved', isEqualTo: false).count().get(),
        places.where('isActive', isEqualTo: true).count().get(),
        places.where('isActive', isEqualTo: false).count().get(),
        users.count().get(),
        reviews.count().get(),
      ]);

      _stats = AdminStats(
        totalPlaces: results[0].count ?? 0,
        approvedPlaces: results[1].count ?? 0,
        unapprovedPlaces: results[2].count ?? 0,
        activePlaces: results[3].count ?? 0,
        inactivePlaces: results[4].count ?? 0,
        totalUsers: results[5].count ?? 0,
        totalReviews: results[6].count ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error loading admin stats: $e');
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }
}
