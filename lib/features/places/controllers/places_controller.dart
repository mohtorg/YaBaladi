// lib/features/places/controllers/places_controller.dart
//
// [v3.1 — 2026-10-20] — CRITICAL FIXES:
//   - ADD: setAmenities(Set<String>) & setFeatures(Set<String>) — used by filter sheet v2.0.
//   - ADD: _requestGeneration token — prevents race conditions between loads.
//   - FIX: _sort auto-reset to recommended when switching from nearest to all.
//   - CLEANUP: removed redundant assignments in loadPaginated.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesStatus { initial, loading, loaded, error }

enum PlacesMode { all, filtered, nearest }

enum PlaceSort { recommended, ratingDesc, distance, newest }

class PlacesController extends ChangeNotifier {
  final PlacesRepository _repo = PlacesRepository();

  // ─── State ───
  PlacesStatus _status = PlacesStatus.initial;
  PlacesStatus get status => _status;

  PlacesMode _mode = PlacesMode.all;
  PlacesMode get mode => _mode;

  List<Place> _allPlacesRaw = [];
  List<Place> get allPlacesRaw => _allPlacesRaw;

  List<Place> _places = [];
  List<Place> get places => _places;

  // ─── Filters ───
  String _query = '';
  String get query => _query;

  double? _minRating;
  double? get minRating => _minRating;

  int? _priceLevel;
  int? get priceLevel => _priceLevel;

  PlaceSort _sort = PlaceSort.recommended;
  PlaceSort get sort => _sort;

  final Set<String> _amenities = {};
  Set<String> get amenities => _amenities;

  final Set<String> _features = {};
  Set<String> get features => _features;

  String? _error;
  String? get error => _error;

  bool get hasQuery => _query.isNotEmpty;
  bool get hasActiveFilters =>
      _minRating != null ||
      _priceLevel != null ||
      _amenities.isNotEmpty ||
      _features.isNotEmpty;

  int get activeFilterCount =>
      (_minRating != null ? 1 : 0) +
      (_priceLevel != null ? 1 : 0) +
      _amenities.length +
      _features.length;

  // ─── Pagination ───
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  DocumentSnapshot? _lastDocument;
  String? _currentGovernorate;
  String? _currentCategoryId;

  // ─── User location (for distance sort) ───
  double? _userLat;
  double? get userLat => _userLat;

  double? _userLng;
  double? get userLng => _userLng;

  // ✅ [v3.1] حماية من Race Conditions
  int _requestGeneration = 0;

  // ═══════════════════════════════════════════════════════════════
  // ✅ [v3.1] FILTERED PLACES — applies all filters + sort locally
  // ═══════════════════════════════════════════════════════════════
  List<Place> get filteredPlaces {
    var result = [..._places];

    // 1. Rating filter
    if (_minRating != null) {
      result = result.where((p) => p.averageRating >= _minRating!).toList();
    }

    // 2. Price filter (max allowed)
    if (_priceLevel != null) {
      result = result.where((p) => p.priceLevel <= _priceLevel!).toList();
    }

    // 3. Amenities filter
    if (_amenities.contains('wifi')) {
      result = result.where((p) => p.hasWifi).toList();
    }
    if (_amenities.contains('parking')) {
      result = result.where((p) => p.hasParking).toList();
    }
    if (_amenities.contains('restroom')) {
      result = result.where((p) => p.hasRestroom).toList();
    }
    if (_amenities.contains('accessibility')) {
      result = result.where((p) => p.hasAccessibility).toList();
    }

    // 4. Features filter
    if (_features.contains('family')) {
      result = result.where((p) => p.isFamilyFriendly).toList();
    }
    if (_features.contains('halal')) {
      result = result.where((p) => p.isHalal).toList();
    }
    if (_features.contains('delivery')) {
      result = result.where((p) => p.hasDelivery).toList();
    }
    if (_features.contains('reservation')) {
      result = result.where((p) => p.hasReservation).toList();
    }

    // 5. Text search
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((p) =>
              p.nameAr.toLowerCase().contains(q) ||
              p.nameEn.toLowerCase().contains(q))
          .toList();
    }

    // 6. Sort
    if (_sort == PlaceSort.ratingDesc) {
      result.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    } else if (_sort == PlaceSort.distance &&
        _userLat != null &&
        _userLng != null) {
      result.sort((a, b) {
        if (a.location == null) return 1;
        if (b.location == null) return -1;
        final dA = Geolocator.distanceBetween(
            _userLat!, _userLng!, a.location!.latitude, a.location!.longitude);
        final dB = Geolocator.distanceBetween(
            _userLat!, _userLng!, b.location!.latitude, b.location!.longitude);
        return dA.compareTo(dB);
      });
    } else if (_sort == PlaceSort.newest) {
      result.sort((a, b) {
        final da = a.createdAt ?? DateTime(2000);
        final db = b.createdAt ?? DateTime(2000);
        return db.compareTo(da);
      });
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD — Legacy (for home/wizard screens)
  // ═══════════════════════════════════════════════════════════════
  Future<void> load() async {
    final myGen = ++_requestGeneration;
    _status = PlacesStatus.loading;
    notifyListeners();

    try {
      final places = await _repo.getAllPlaces();
      if (myGen != _requestGeneration) return;
      _allPlacesRaw = places;
      _places = places;
      _status = PlacesStatus.loaded;
    } catch (e) {
      if (myGen != _requestGeneration) return;
      _error = e.toString();
      _status = PlacesStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  // ═══════════════════════════════════════════════════════════════
  // CLEAR — reset everything
  // ═══════════════════════════════════════════════════════════════
  void clearAll({bool notify = true}) {
    _query = '';
    _minRating = null;
    _priceLevel = null;
    _amenities.clear();
    _features.clear();
    _mode = PlacesMode.all;
    _sort = PlaceSort.recommended;
    _userLat = null;
    _userLng = null;
    if (notify) notifyListeners();
  }

  void clearFilters() {
    _minRating = null;
    _priceLevel = null;
    _amenities.clear();
    _features.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // SETTERS
  // ═══════════════════════════════════════════════════════════════
  void setQuery(String q) {
    _query = q;
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

  // ✅ [v3.1] Batch setters — required by filter sheet v2.0
  void setAmenities(Set<String> val) {
    _amenities
      ..clear()
      ..addAll(val);
    notifyListeners();
  }

  void setFeatures(Set<String> val) {
    _features
      ..clear()
      ..addAll(val);
    notifyListeners();
  }

  // Legacy per-item toggles (kept for backward compatibility)
  void toggleAmenity(String key) {
    _amenities.contains(key) ? _amenities.remove(key) : _amenities.add(key);
    notifyListeners();
  }

  void toggleFeature(String key) {
    _features.contains(key) ? _features.remove(key) : _features.add(key);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════════
  Future<void> loadPaginated({
    required String governorateNameAr,
    String? categoryId,
    int limit = 20,
  }) async {
    final myGen = ++_requestGeneration;

    _status = PlacesStatus.loading;
    _mode = PlacesMode.all;
    _hasMore = true;
    _lastDocument = null;
    _places = [];
    _currentGovernorate = governorateNameAr;
    _currentCategoryId = categoryId;
    _error = null;
    _userLat = null;
    _userLng = null;
    // ✅ [v3.1] إعادة ترتيب افتراضي
    _sort = PlaceSort.recommended;
    notifyListeners();

    try {
      final result = await _repo.fetchPlaces(
        governorateNameAr: governorateNameAr,
        categoryId: categoryId,
        limit: limit,
      );
      if (myGen != _requestGeneration) return; // ✅ stale
      _places = result.places;
      _lastDocument = result.lastDoc;
      _hasMore = result.places.length == limit;
      _status = PlacesStatus.loaded;
    } catch (e) {
      if (myGen != _requestGeneration) return;
      _status = PlacesStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore ||
        !_hasMore ||
        _lastDocument == null ||
        _mode == PlacesMode.nearest) {
      return;
    }

    final myGen = _requestGeneration; // ← snapshot (لا نزيد هنا)
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repo.fetchPlaces(
        governorateNameAr: _currentGovernorate ?? '',
        categoryId: _currentCategoryId,
        limit: 20,
        lastDocument: _lastDocument,
      );
      if (myGen != _requestGeneration) return; // ✅ stale
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

  // ═══════════════════════════════════════════════════════════════
  // NEAREST
  // ═══════════════════════════════════════════════════════════════
  Future<void> loadNearest({
    required double userLat,
    required double userLng,
  }) async {
    final myGen = ++_requestGeneration;

    _status = PlacesStatus.loading;
    _mode = PlacesMode.nearest;
    _places = [];
    _error = null;
    _userLat = userLat;
    _userLng = userLng;
    _sort = PlaceSort.distance;
    notifyListeners();

    try {
      final places = await _repo.getNearestPlaces(
        userLat: userLat,
        userLng: userLng,
      );
      if (myGen != _requestGeneration) return;
      _places = places;
      _status = PlacesStatus.loaded;
    } catch (e) {
      if (myGen != _requestGeneration) return;
      _status = PlacesStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }
}
