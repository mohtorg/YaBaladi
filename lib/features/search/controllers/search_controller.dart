import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesSearchStatus { idle, loading, loaded, error }

/// يدير حالة البحث:
/// - نص البحث (مع debounce)
/// - التصنيف المختار
/// - النتائج
///
/// ملاحظة: الاسم `PlacesSearchController` مقصود — لتجنب التعارض مع
/// `SearchController` الجاهز في Flutter (material/search_anchor.dart).
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
      _run();
    });
  }

  void setCategory(String? id) {
    _categoryId = id;
    _debounce?.cancel();
    _run();
  }

  Future<void> refresh() => _run();

  void clear() {
    _debounce?.cancel();
    _query = '';
    _categoryId = null;
    _results = const [];
    _status = PlacesSearchStatus.idle;
    _error = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // INTERNAL
  // ═══════════════════════════════════════════════════════════════

  Future<void> _run() async {
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
      _results = await _repo.search(
        query: _query,
        categoryId: _categoryId,
      );
      _status = PlacesSearchStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PlacesSearchStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}