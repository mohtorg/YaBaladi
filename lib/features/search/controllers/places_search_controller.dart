// lib/features/search/controllers/places_search_controller.dart
//
// [v1.2 — 2026-11-11] — RACE CONDITION GUARD: Added generation counter to ignore stale search results.
// [v1.1.2 — 2026-10-26] — Wave 13: unawaited() wrappers to prevent lint warnings.
//   - KEPT: all logic, state management, and public API identical.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesSearchStatus { idle, loading, loaded, error }

class PlacesSearchController extends ChangeNotifier {
  PlacesSearchController({PlacesRepository? repo})
      : _repo = repo ?? PlacesRepository();

  final PlacesRepository _repo;
  Timer? _debounce;

  String _query = '';
  String? _categoryId;
  PlacesSearchStatus _status = PlacesSearchStatus.idle;
  List<Place> _results = const [];
  String? _error;

  // ✅ حماية من سباق البيانات (لتجاهل نتائج الطلبات القديمة)
  int _requestGeneration = 0;

  // ─── Getters ───
  String get query => _query;
  String? get categoryId => _categoryId;
  PlacesSearchStatus get status => _status;
  List<Place> get results => List.unmodifiable(_results);
  String? get error => _error;
  bool get isLoading => _status == PlacesSearchStatus.loading;
  bool get hasQuery => _query.trim().isNotEmpty;
  bool get hasCategory => _categoryId != null && _categoryId!.isNotEmpty;
  bool get isActive => hasQuery || hasCategory;

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void setQuery(String value) {
    _query = value;
    notifyListeners();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_run());
    });
  }

  void setCategory(String? id) {
    _categoryId = id;
    _debounce?.cancel();
    unawaited(_run());
  }

  Future<void> refresh() => _run();

  void clear() {
    _debounce?.cancel();
    _query = '';
    _categoryId = null;
    _results = const [];
    _status = PlacesSearchStatus.idle;
    _error = null;
    _requestGeneration++; // إلغاء أي طلبات معلقة
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // INTERNAL
  // ═══════════════════════════════════════════════════════════════

  Future<void> _run() async {
    final myGen = ++_requestGeneration;

    if (!isActive) {
      _results = const [];
      _status = PlacesSearchStatus.idle;
      notifyListeners();
      return;
    }

    _status = PlacesSearchStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await _repo.search(
        query: _query,
        categoryId: _categoryId,
      );

      // ✅ إذا كان هناك طلب أحدث تم تنفيذه، تجاهل هذا الطلب القديم
      if (myGen != _requestGeneration) {
        return;
      }

      _results = results;
      _status = PlacesSearchStatus.loaded;
    } on Exception catch (e) {
      // ✅ نفس الحماية عند حدوث خطأ
      if (myGen != _requestGeneration) {
        return;
      }
      _error = e.toString();
      _status = PlacesSearchStatus.error;
    }

    if (myGen == _requestGeneration) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
