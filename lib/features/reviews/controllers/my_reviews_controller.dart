// lib/features/reviews/controllers/my_reviews_controller.dart
//
// [v1.1 — 2026-10-25] — FIX: Added missing 'break' statements in switch blocks
//   - FIXED: 'case should not complete normally' compilation error
//     in getter `reviews` for both _filter and _sort switches.
//   - KEPT: all logic, race-condition protection, and getters identical.

import 'package:flutter/foundation.dart';

import '../../../models/review.dart';
import '../../../repositories/reviews_repository.dart';

enum MyReviewsStatus { idle, loading, loaded, error }

enum MyReviewsSort { newest, highestRating }

enum MyReviewsFilter { all, fiveStars, fourStars, lowRating }

class MyReviewsController extends ChangeNotifier {
  MyReviewsController({ReviewsRepository? repo})
      : _repo = repo ?? ReviewsRepository();

  final ReviewsRepository _repo;

  MyReviewsStatus _status = MyReviewsStatus.idle;
  List<Review> _all = const [];
  String? _error;
  String? _userId;

  MyReviewsSort _sort = MyReviewsSort.newest;
  MyReviewsFilter _filter = MyReviewsFilter.all;

  int _loadGeneration = 0;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  MyReviewsStatus get status => _status;
  String? get error => _error;
  String? get userId => _userId;
  bool get isLoading => _status == MyReviewsStatus.loading;
  bool get hasError => _status == MyReviewsStatus.error;
  bool get isEmpty => _all.isEmpty;

  MyReviewsSort get sort => _sort;
  MyReviewsFilter get filter => _filter;

  int get totalCount => _all.length;

  double get averageRating {
    if (_all.isEmpty) return 0;
    final sum = _all.fold<double>(0, (acc, r) => acc + r.rating);
    return sum / _all.length;
  }

  List<Review> get reviews {
    var result = _all;

    // [FIX] إضافة break لمنع خطأ التجميع
    switch (_filter) {
      case MyReviewsFilter.all:
        break;
      case MyReviewsFilter.fiveStars:
        result = result.where((r) => r.rating >= 5).toList();
        break;
      case MyReviewsFilter.fourStars:
        result = result.where((r) => r.rating >= 4 && r.rating < 5).toList();
        break;
      case MyReviewsFilter.lowRating:
        result = result.where((r) => r.rating < 4).toList();
        break;
    }

    final copy = List<Review>.from(result);

    // [FIX] إضافة break لمنع خطأ التجميع
    switch (_sort) {
      case MyReviewsSort.newest:
        copy.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });
        break;
      case MyReviewsSort.highestRating:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return List.unmodifiable(copy);
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> load(String userId, {bool force = false}) async {
    if (_userId == userId && !force && _status == MyReviewsStatus.loaded) {
      return;
    }

    final myGen = ++_loadGeneration;
    final isNewUser = _userId != userId;

    _userId = userId;
    if (isNewUser) _all = const [];
    _status = MyReviewsStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final list = await _repo.getByUser(userId);

      if (myGen != _loadGeneration) {
        debugPrint(
          'MyReviewsController.load: stale discarded '
          '(gen $myGen vs $_loadGeneration)',
        );
        return;
      }

      _all = list;
      _status = MyReviewsStatus.loaded;
    } catch (e) {
      if (myGen != _loadGeneration) return;
      _error = e.toString();
      _status = MyReviewsStatus.error;
      debugPrint('MyReviewsController.load error: $e');
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS / SORT
  // ═══════════════════════════════════════════════════════════════

  void setFilter(MyReviewsFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void setSort(MyReviewsSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // REMOVE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> remove(String reviewId, String userId) async {
    Review? target;
    for (final r in _all) {
      if (r.id == reviewId) {
        target = r;
        break;
      }
    }

    if (target == null) {
      _error = 'المراجعة غير موجودة';
      notifyListeners();
      return false;
    }

    if (target.userId != userId) {
      _error = 'لا يمكنك حذف مراجعة ليست لك';
      notifyListeners();
      return false;
    }

    try {
      await _repo.delete(reviewId);
      _all = _all.where((r) => r.id != reviewId).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('MyReviewsController.remove error: $e');
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════════

  void clear() {
    _loadGeneration++;
    _all = const [];
    _userId = null;
    _error = null;
    _status = MyReviewsStatus.idle;
    _filter = MyReviewsFilter.all;
    _sort = MyReviewsSort.newest;
    notifyListeners();
  }
}
