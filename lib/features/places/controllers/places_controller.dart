// lib/features/places/controllers/places_controller.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesStatus { initial, loading, loaded, error }

enum PlacesMode { all, filtered }

enum PlaceSort {
  recommended,
  ratingDesc,
  reviewsDesc,
  nameAsc,
  newest,
  distance
}

class PlacesController extends ChangeNotifier {
  final PlacesRepository _repo = PlacesRepository();

  // ─── Legacy State ───
  PlacesStatus _status = PlacesStatus.initial;
  PlacesStatus get status => _status;

  PlacesMode _mode = PlacesMode.all;
  PlacesMode get mode => _mode;

  List<Place> _allPlacesRaw = [];
  List<Place> get allPlacesRaw => _allPlacesRaw;

  String _query = '';
  String get query => _query;

  double? _minRating;
  double? get minRating => _minRating;

  int? _priceLevel;
  int? get priceLevel => _priceLevel;

  PlaceSort _sort = PlaceSort.recommended;
  PlaceSort get sort => _sort;

  Set<String> _amenities = {};
  Set<String> get amenities => _amenities;

  Set<String> _features = {};
  Set<String> get features => _features;

  Set<String> _payments = {};
  Set<String> get payments => _payments;

  String? _error;
  String? get error => _error;

  bool get hasQuery => _query.isNotEmpty;
  bool get hasActiveFilters =>
      _minRating != null ||
      _priceLevel != null ||
      _amenities.isNotEmpty ||
      _features.isNotEmpty ||
      _payments.isNotEmpty;
  int get activeFilterCount =>
      (_minRating != null ? 1 : 0) +
      (_priceLevel != null ? 1 : 0) +
      _amenities.length +
      _features.length +
      _payments.length;

  // ─── Pagination State ───
  List<Place> _places = [];
  List<Place> get places => _places;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  DocumentSnapshot? _lastDocument;
  String? _currentGovernorate;
  String? _currentCategoryId;

  // ═══════════════════════════════════════════════════════════════
  // Legacy Methods (Restored)
  // ═══════════════════════════════════════════════════════════════

  Future<void> load() async {
    _status = PlacesStatus.loading;
    notifyListeners();
    try {
      _allPlacesRaw = await _repo.getAllPlaces();
      _places = _allPlacesRaw;
      _status = PlacesStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PlacesStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  void clearAll({bool notify = true}) {
    _query = '';
    _minRating = null;
    _priceLevel = null;
    _amenities = {};
    _features = {};
    _payments = {};
    _mode = PlacesMode.all;
    if (notify) notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    notifyListeners();
  }

  void setMinRating(double? val) {
    _minRating = val;
    notifyListeners();
  }

  void setPriceLevel(int? val) {
    _priceLevel = val;
    notifyListeners();
  }

  void setSort(PlaceSort val) {
    _sort = val;
    notifyListeners();
  }

  void setAmenities(Set<String> val) {
    _amenities = val;
    notifyListeners();
  }

  void setFeatures(Set<String> val) {
    _features = val;
    notifyListeners();
  }

  void setPayments(Set<String> val) {
    _payments = val;
    notifyListeners();
  }

  void clearFilters() {
    _minRating = null;
    _priceLevel = null;
    _amenities = {};
    _features = {};
    _payments = {};
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Pagination Methods (New)
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadPaginated({
    required String governorateNameAr,
    String? categoryId,
    int limit = 20,
  }) async {
    _status = PlacesStatus.loading;
    _hasMore = true;
    _lastDocument = null;
    _places = [];
    _currentGovernorate = governorateNameAr;
    _currentCategoryId = categoryId;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.fetchPlaces(
        governorateNameAr: governorateNameAr,
        categoryId: categoryId,
        limit: limit,
      );

      _places = result.places;
      _lastDocument = result.lastDoc;
      _hasMore = result.places.length == limit;
      _status = PlacesStatus.loaded;
    } catch (e) {
      _status = PlacesStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repo.fetchPlaces(
        governorateNameAr: _currentGovernorate ?? '',
        categoryId: _currentCategoryId,
        limit: 20,
        lastDocument: _lastDocument,
      );

      _places.addAll(result.places);
      _lastDocument = result.lastDoc;
      _hasMore = result.places.length == 20;
    } catch (e) {
      debugPrint('❌ loadMore error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
