// lib/features/trip/controllers/trip_plans_controller.dart
//
// [v1.5.1 — 2026-10-19] — FIX: Restored missing getters from v1.1
//   - Restored: isLoading, hasError, isEmpty, hasPlans, activePlans, completedPlans, upcomingPlans, count.
//   - KEPT: save() forcing userId and null dates for serverTimestamp.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../models/trip_plan.dart';
import '../../../repositories/trip_repository.dart';

enum TripPlansStatus { idle, loading, loaded, error }

class TripPlansController extends ChangeNotifier {
  TripPlansController({TripRepository? repo})
      : _repo = repo ?? TripRepository();

  final TripRepository _repo;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TripPlansStatus _status = TripPlansStatus.idle;
  List<TripPlan> _plans = const [];
  String? _error;
  String? _userId;
  TripPlan? _selectedPlan;
  int _loadGeneration = 0;
  StreamSubscription<List<TripPlan>>? _plansSub;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  TripPlansStatus get status => _status;
  List<TripPlan> get plans => List.unmodifiable(_plans);
  String? get error => _error;
  String? get userId => _userId;
  TripPlan? get selectedPlan => _selectedPlan;

  bool get isLoading => _status == TripPlansStatus.loading;
  bool get hasError => _status == TripPlansStatus.error;
  bool get isEmpty => _plans.isEmpty;
  bool get hasPlans => _plans.isNotEmpty;
  int get count => _plans.length;

  List<TripPlan> get activePlans =>
      _plans.where((p) => p.status == TripStatus.active).toList();

  List<TripPlan> get completedPlans =>
      _plans.where((p) => p.status == TripStatus.completed).toList();

  List<TripPlan> get upcomingPlans {
    final now = DateTime.now();
    return _plans
        .where(
          (p) =>
              (p.status == TripStatus.draft || p.status == TripStatus.active) &&
              (p.startDate == null || p.startDate!.isAfter(now)),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> load(String userId, {bool force = false}) async {
    if (!force && _userId == userId && _status == TripPlansStatus.loaded) {
      return;
    }

    await _plansSub?.cancel();
    _plansSub = null;

    final myGen = ++_loadGeneration;
    _userId = userId;
    _status = TripPlansStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _plansSub = _repo.watchByUser(userId).listen(
        (list) {
          if (myGen != _loadGeneration) return;
          _plans = list;
          _status = TripPlansStatus.loaded;
          _autoSelectPlan();
          notifyListeners();
        },
        onError: (Object e) {
          if (myGen != _loadGeneration) return;
          _error = e.toString();
          _status = TripPlansStatus.error;
          debugPrint('TripPlansController stream error: $e');
          notifyListeners();
        },
      );
    } on Exception catch (e) {
      if (myGen != _loadGeneration) return;
      _error = e.toString();
      _status = TripPlansStatus.error;
      debugPrint('TripPlansController.load error: $e');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _plansSub?.cancel();
    _plansSub = null;
    _loadGeneration++;
    _plans = const [];
    _userId = null;
    _selectedPlan = null;
    _status = TripPlansStatus.idle;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE (create or update) — ✅ FIXED FOR RULES v3.4
  // ═══════════════════════════════════════════════════════════════

  Future<bool> save(TripPlan trip) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'يجب تسجيل الدخول أولاً';
      notifyListeners();
      return false;
    }

    // ✅ بناء الكائن يدوياً لتجنب مشكلة copyWith مع القيم الفارغة
    final safeTrip = TripPlan(
      id: trip.id,
      userId: user.uid,
      title: trip.title,
      governorateId: trip.governorateId,
      governorateNameAr: trip.governorateNameAr,
      transportMode: trip.transportMode,
      durationType: trip.durationType,
      interests: trip.interests,
      status: trip.status, // تأكد أن الويزارد يرسلها active
      stops: trip.stops,
      totalDistanceKm: trip.totalDistanceKm,
      totalDurationMin: trip.totalDurationMin,
      startDate: trip.startDate,
      endDate: trip.endDate,
      createdAt: trip.id.isEmpty ? null : trip.createdAt, // ✅ null عند الإنشاء
      updatedAt: trip.id.isEmpty ? null : trip.updatedAt,
    );

    try {
      if (safeTrip.id.isEmpty) {
        final newId = await _repo.create(safeTrip);
        _selectedPlan = safeTrip.copyWith(id: newId);
      } else {
        await _repo.update(safeTrip);
        _selectedPlan = safeTrip;
      }
      _error = null;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      debugPrint('❌ TripPlansController.save error: $e');
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE & STATUS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> delete(String tripId) async {
    try {
      await _repo.delete(tripId);
      _plans = _plans.where((p) => p.id != tripId).toList();
      if (_selectedPlan?.id == tripId) _selectedPlan = null;
      _error = null;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      debugPrint('TripPlansController.delete error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String tripId, TripStatus status) async {
    try {
      await _repo.updateStatus(tripId, status);
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      debugPrint('TripPlansController.updateStatus error: $e');
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SELECT & HELPERS
  // ═══════════════════════════════════════════════════════════════

  void selectPlan(TripPlan? plan) {
    if (_selectedPlan?.id == plan?.id) return;
    _selectedPlan = plan;
    notifyListeners();
  }

  void selectPlanById(String? id) {
    if (id == null || id.isEmpty) {
      selectPlan(null);
      return;
    }
    try {
      final plan = _plans.firstWhere((p) => p.id == id);
      selectPlan(plan);
    } on StateError {
      selectPlan(null);
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _autoSelectPlan() {
    if (_plans.isEmpty) {
      _selectedPlan = null;
      return;
    }
    TripPlan? active;
    for (final p in _plans) {
      if (p.status == TripStatus.active) {
        active = p;
        break;
      }
    }
    _selectedPlan = active ?? _plans.first;
  }

  @override
  void dispose() {
    _plansSub?.cancel();
    _plansSub = null;
    super.dispose();
  }
}
