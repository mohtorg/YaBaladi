// lib/features/reviews/controllers/reviews_controller.dart
//
// [v1.0.1 — 2026-10-14] — Removed unnecessary dispose() override
// [v1.0 — 2026-10-14] — F2.1: Initial ReviewsController

import 'package:flutter/foundation.dart';

import '../../../models/review.dart';
import '../../../repositories/reviews_repository.dart';

enum ReviewsStatus { idle, loading, loaded, error }

/// يدير حالة مراجعات مكان واحد.
class ReviewsController extends ChangeNotifier {
  ReviewsController({ReviewsRepository? repo})
      : _repo = repo ?? ReviewsRepository();

  final ReviewsRepository _repo;

  ReviewsStatus _status = ReviewsStatus.idle;
  List<Review> _reviews = const [];
  String? _error;
  String? _placeId;

  int _loadGeneration = 0;

  ReviewsStatus get status => _status;
  List<Review> get reviews => List.unmodifiable(_reviews);
  String? get error => _error;
  String? get placeId => _placeId;
  bool get isLoading => _status == ReviewsStatus.loading;
  bool get hasReviews => _reviews.isNotEmpty;
  bool get hasError => _status == ReviewsStatus.error;
  int get count => _reviews.length;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }

  bool hasReviewed(String userId) {
    return _reviews.any((r) => r.userId == userId);
  }

  Review? reviewBy(String userId) {
    for (final r in _reviews) {
      if (r.userId == userId) return r;
    }
    return null;
  }

  Future<void> load(String placeId, {bool force = false}) async {
    if (_placeId == placeId && !force && _status == ReviewsStatus.loaded) {
      return;
    }

    final isNewPlace = _placeId != placeId;
    final myGen = ++_loadGeneration;

    _placeId = placeId;
    if (isNewPlace) {
      _reviews = const [];
    }
    _status = ReviewsStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final list = await _repo.getByPlace(placeId);

      if (myGen != _loadGeneration) {
        debugPrint(
          'ReviewsController.load: stale response discarded '
          '(gen $myGen vs current $_loadGeneration)',
        );
        return;
      }

      _reviews = list;
      _status = ReviewsStatus.loaded;
    } catch (e) {
      if (myGen != _loadGeneration) return;
      _error = e.toString();
      _status = ReviewsStatus.error;
      debugPrint('ReviewsController.load error: $e');
    }
    notifyListeners();
  }

  Future<bool> submit(Review review) async {
    if (_placeId == null || _placeId!.isEmpty) {
      _error = 'لم يتم تحديد المكان';
      notifyListeners();
      return false;
    }

    try {
      final newId = await _repo.create(review);
      final saved = review.copyWith(id: newId);

      _reviews = [saved, ..._reviews];
      _status = ReviewsStatus.loaded;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('ReviewsController.submit error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String reviewId, String userId) async {
    Review? target;
    for (final r in _reviews) {
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
      _reviews = _reviews.where((r) => r.id != reviewId).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('ReviewsController.remove error: $e');
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _loadGeneration++;
    _reviews = const [];
    _placeId = null;
    _error = null;
    _status = ReviewsStatus.idle;
    notifyListeners();
  }
}
