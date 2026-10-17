// lib/features/trip/controllers/trip_plans_controller.dart
//
// [v1.0 — 2026-10-15] — G6.7: TripPlansController
//   - يدير حالة رحلات المستخدم.
//   - يستخدم Stream (watchByUser) للتحديث الفوري.
//   - يوفر: load, save, delete, updateStatus.
//   - حماية من Race Conditions عبر _loadGeneration.
//   - Auto-select: آخر رحلة نشطة عند التحميل.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/trip_plan.dart';
import '../../../repositories/trip_repository.dart';

enum TripPlansStatus { idle, loading, loaded, error }

class TripPlansController extends ChangeNotifier {
  TripPlansController({TripRepository? repo})
      : _repo = repo ?? TripRepository();

  final TripRepository _repo;

  TripPlansStatus _status = TripPlansStatus.idle;
  List<TripPlan> _plans = const [];
  String? _error;
  String? _userId;

  /// الرحلة المُختارة حالياً (للعرض).
  TripPlan? _selectedPlan;

  /// حماية من Race Conditions.
  int _loadGeneration = 0;

  /// Stream subscription للإلغاء عند dispose.
  StreamSubscription<List<TripPlan>>? _plansSub;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  TripPlansStatus get status => _status;
  List<TripPlan> get plans => List.unmodifiable(_plans);
  String? get error => _error;
  String? get userId => _userId;
  bool get isLoading => _status == TripPlansStatus.loading;
  bool get hasError => _status == TripPlansStatus.error;
  bool get isEmpty => _plans.isEmpty;
  bool get hasPlans => _plans.isNotEmpty;
  int get count => _plans.length;

  /// الرحلة المُختارة.
  TripPlan? get selectedPlan => _selectedPlan;

  /// رحلات نشطة فقط (status == active).
  List<TripPlan> get activePlans =>
      _plans.where((p) => p.status == TripStatus.active).toList();

  /// رحلات مكتملة (status == completed).
  List<TripPlan> get completedPlans =>
      _plans.where((p) => p.status == TripStatus.completed).toList();

  /// رحلات قادمة (status == draft OR active، startDate > now).
  List<TripPlan> get upcomingPlans {
    final now = DateTime.now();
    return _plans
        .where((p) =>
            (p.status == TripStatus.draft || p.status == TripStatus.active) &&
            (p.startDate == null || p.startDate!.isAfter(now)))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════

  /// يشترك في Stream رحلات المستخدم — التحديثات فورية.
  ///
  /// - [force] = true → يُلغي اشتراكاً قديماً ويعيد.
  Future<void> load(String userId, {bool force = false}) async {
    if (!force && _userId == userId && _status == TripPlansStatus.loaded) {
      return;
    }

    // إلغاء الاشتراك القديم إن وُجد
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
          if (myGen != _loadGeneration) return; // stale
          _plans = list;
          _status = TripPlansStatus.loaded;
          _autoSelectPlan();
          notifyListeners();
        },
        onError: (e) {
          if (myGen != _loadGeneration) return;
          _error = e.toString();
          _status = TripPlansStatus.error;
          debugPrint('TripPlansController stream error: $e');
          notifyListeners();
        },
      );
    } catch (e) {
      if (myGen != _loadGeneration) return;
      _error = e.toString();
      _status = TripPlansStatus.error;
      debugPrint('TripPlansController.load error: $e');
      notifyListeners();
    }
  }

  /// يوقف الاشتراك (يُستخدَم عند signOut).
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
  // SAVE (create or update)
  // ═══════════════════════════════════════════════════════════════

  /// يحفظ رحلة — إنشاء (id فارغ) أو تحديث.
  ///
  /// يُعيد `true` عند النجاح.
  Future<bool> save(TripPlan trip) async {
    try {
      if (trip.id.isEmpty) {
        final newId = await _repo.create(trip);
        _selectedPlan = trip.copyWith(id: newId);
      } else {
        await _repo.update(trip);
        _selectedPlan = trip;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('TripPlansController.save error: $e');
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> delete(String tripId) async {
    try {
      await _repo.delete(tripId);
      _plans = _plans.where((p) => p.id != tripId).toList();
      if (_selectedPlan?.id == tripId) _selectedPlan = null;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('TripPlansController.delete error: $e');
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════════════════════

  /// يُحدِّث حالة رحلة (draft → active → completed).
  Future<bool> updateStatus(String tripId, TripStatus status) async {
    try {
      await _repo.updateStatus(tripId, status);
      // Stream سيُحدِّث القائمة تلقائياً
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('TripPlansController.updateStatus error: $e');
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SELECT
  // ═══════════════════════════════════════════════════════════════

  /// يختار رحلة للعرض.
  void selectPlan(TripPlan? plan) {
    if (_selectedPlan?.id == plan?.id) return;
    _selectedPlan = plan;
    notifyListeners();
  }

  /// يختار رحلة بالـ id.
  void selectPlanById(String? id) {
    if (id == null || id.isEmpty) {
      selectPlan(null);
      return;
    }
    try {
      final plan = _plans.firstWhere((p) => p.id == id);
      selectPlan(plan);
    } catch (_) {
      selectPlan(null);
    }
  }

  /// يُصفِّر الخطأ الحالي.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// يختار تلقائياً رحلة عند التحميل:
  ///   - آخر رحلة نشطة (active)
  ///   - أو آخر رحلة (createdAt DESC)
  void _autoSelectPlan() {
    if (_plans.isEmpty) {
      _selectedPlan = null;
      return;
    }

    // ابحث عن أول رحلة نشطة
    TripPlan? active;
    for (final p in _plans) {
      if (p.status == TripStatus.active) {
        active = p;
        break;
      }
    }

    // إن لم توجد، استخدم الأولى (الأحدث)
    _selectedPlan = active ?? _plans.first;
  }

  @override
  void dispose() {
    _plansSub?.cancel();
    _plansSub = null;
    super.dispose();
  }
}
