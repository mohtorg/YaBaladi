// lib/features/places/controllers/places_controller.dart
// [v5.1 — 2026-11-15] — Phase 12: rankable places sorted first.
//   - In every sort branch, `isRankable == true` places precede `false` ones.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/place.dart';
import '../../../models/filter_definition.dart';
import '../../../repositories/places_repository.dart';
import '../../../core/helpers/location_url_helper.dart';

enum PlacesStatus { initial, loading, loaded, error }

enum PlacesMode { all, filtered, nearest }

enum PlaceSort {
  recommended,
  adjustedScore,
  ratingDesc,
  trustedDesc,
  distance,
  newest,
}

class PlacesController extends ChangeNotifier {
  final PlacesRepository _repo = PlacesRepository();

  PlacesStatus _status = PlacesStatus.initial;
  PlacesStatus get status => _status;

  PlacesMode _mode = PlacesMode.all;
  PlacesMode get mode => _mode;

  List<Place> _allPlacesRaw = [];
  List<Place> get allPlacesRaw => _allPlacesRaw;

  List<Place> _places = [];
  List<Place> get places => _places;

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

  Map<String, FilterSelection> _activeDynamicFilters = {};
  Map<String, FilterDefinition> _filtersMetadata = {};

  Map<String, FilterSelection> get activeDynamicFilters =>
      Map.unmodifiable(_activeDynamicFilters);

  Map<String, FilterDefinition> get filtersMetadata =>
      Map.unmodifiable(_filtersMetadata);

  void setFiltersMetadata(List<FilterDefinition> filters) {
    _filtersMetadata = {for (final f in filters) f.id: f};
    notifyListeners();
  }

  void applyDynamicFilters(Map<String, FilterSelection> filters) {
    _activeDynamicFilters = Map.from(filters);
    notifyListeners();
  }

  List<Place> applyFilters(Map<String, FilterSelection> filters) {
    final previous = _activeDynamicFilters;
    _activeDynamicFilters = Map.from(filters);
    try {
      return List<Place>.from(filteredPlaces);
    } finally {
      _activeDynamicFilters = previous;
    }
  }

  String? _error;
  String? get error => _error;

  bool get hasQuery => _query.isNotEmpty;

  bool get hasActiveFilters {
    final legacy = _minRating != null ||
        _priceLevel != null ||
        _amenities.isNotEmpty ||
        _features.isNotEmpty;
    final dynamic = _activeDynamicFilters.values.any((s) => s.isNotEmpty);
    return legacy || dynamic;
  }

  int get activeFilterCount {
    final legacy = (_minRating != null ? 1 : 0) +
        (_priceLevel != null ? 1 : 0) +
        _amenities.length +
        _features.length;
    final dynamic =
        _activeDynamicFilters.values.where((s) => s.isNotEmpty).length;
    return legacy + dynamic;
  }

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  DocumentSnapshot? _lastDocument;
  String? _currentGovernorate;
  String? _currentCategoryId;
  String? get currentCategoryId => _currentCategoryId;

  double? _userLat;
  double? get userLat => _userLat;

  double? _userLng;
  double? get userLng => _userLng;

  int _requestGeneration = 0;

  PlaceSort get effectiveSort {
    for (final entry in _activeDynamicFilters.entries) {
      final filter = _filtersMetadata[entry.key];
      if (filter?.type == FilterType.sort && entry.value.isNotEmpty) {
        final v = entry.value.values.first;
        switch (v) {
          case 'rating_desc':
            return PlaceSort.adjustedScore;
          case 'newest':
            return PlaceSort.newest;
          case 'distance':
            return PlaceSort.distance;
          case 'trusted':
            return PlaceSort.trustedDesc;
          case 'recommended':
          default:
            return PlaceSort.adjustedScore;
        }
      }
    }
    if (_sort == PlaceSort.recommended) return PlaceSort.adjustedScore;
    return _sort;
  }

  String get sortLabel {
    switch (effectiveSort) {
      case PlaceSort.recommended:
      case PlaceSort.adjustedScore:
        return 'الأعلى جودة';
      case PlaceSort.ratingDesc:
        return 'الأعلى تقييماً';
      case PlaceSort.trustedDesc:
        return 'الأكثر ثقة';
      case PlaceSort.distance:
        return 'الأقرب';
      case PlaceSort.newest:
        return 'الأحدث';
    }
  }

  List<Place> _applyDynamicFilters(List<Place> input) {
    var result = input;

    for (final entry in _activeDynamicFilters.entries) {
      final filter = _filtersMetadata[entry.key];
      if (filter == null) continue;
      final selection = entry.value;
      if (selection.isEmpty) continue;

      switch (filter.type) {
        case FilterType.boolean:
          final wanted = selection.values.first == 'true';
          result = result.where((p) {
            final v = p.toMap()[filter.fieldKey];
            return (v == true) == wanted;
          }).toList();
          break;
        case FilterType.singleChoice:
          final value = selection.values.first;
          result = result.where((p) {
            final v = p.toMap()[filter.fieldKey];
            return v?.toString() == value;
          }).toList();
          break;
        case FilterType.multiChoice:
          result = result.where((p) {
            final raw = p.toMap()[filter.fieldKey];
            final list = (raw is List)
                ? raw.map((e) => e.toString()).toSet()
                : <String>{};
            return selection.values.every((s) => list.contains(s));
          }).toList();
          break;
        case FilterType.range:
          final rawValue = selection.values.first;
          final min = double.tryParse(rawValue) ?? 0;
          result = result.where((p) {
            final v = (p.toMap()[filter.fieldKey] as num?)?.toDouble() ?? 0;
            return v >= min;
          }).toList();
          break;
        case FilterType.sort:
          break;
      }
    }

    return result;
  }

  List<Place> get filteredPlaces {
    var result = [..._places];

    result = _applyDynamicFilters(result);

    if (_minRating != null) {
      result = result.where((p) => p.averageRating >= _minRating!).toList();
    }
    if (_priceLevel != null) {
      result = result.where((p) => p.priceLevel <= _priceLevel!).toList();
    }
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
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((p) =>
              p.nameAr.toLowerCase().contains(q) ||
              p.nameEn.toLowerCase().contains(q))
          .toList();
    }

    final sort = effectiveSort;

    // ✅ Phase 12: قاعدة مشتركة — rankable قبل non-rankable
    int rankableFirst(Place a, Place b) {
      if (a.isRankable == b.isRankable) return 0;
      return a.isRankable ? -1 : 1;
    }

    if (sort == PlaceSort.adjustedScore) {
      result.sort((a, b) {
        final r = rankableFirst(a, b);
        if (r != 0) return r;
        final sa = a.adjustedScore ?? a.averageRating;
        final sb = b.adjustedScore ?? b.averageRating;
        return sb.compareTo(sa);
      });
    } else if (sort == PlaceSort.ratingDesc) {
      result.sort((a, b) {
        final r = rankableFirst(a, b);
        if (r != 0) return r;
        return b.averageRating.compareTo(a.averageRating);
      });
    } else if (sort == PlaceSort.trustedDesc) {
      result.sort((a, b) {
        final r = rankableFirst(a, b);
        if (r != 0) return r;
        final qa = a.sampleQuality ?? 0.0;
        final qb = b.sampleQuality ?? 0.0;
        return qb.compareTo(qa);
      });
    } else if (sort == PlaceSort.distance &&
        _userLat != null &&
        _userLng != null) {
      result.sort((a, b) {
        final r = rankableFirst(a, b);
        if (r != 0) return r;
        if (a.location == null) return 1;
        if (b.location == null) return -1;
        final dA = LocationUrlHelper.calculateDistanceMeters(
            _userLat!, _userLng!, a.location!.latitude, a.location!.longitude);
        final dB = LocationUrlHelper.calculateDistanceMeters(
            _userLat!, _userLng!, b.location!.latitude, b.location!.longitude);
        return dA.compareTo(dB);
      });
    } else if (sort == PlaceSort.newest) {
      result.sort((a, b) {
        final r = rankableFirst(a, b);
        if (r != 0) return r;
        final da = a.createdAt ?? DateTime(2000);
        final db = b.createdAt ?? DateTime(2000);
        return db.compareTo(da);
      });
    }

    return result;
  }

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

  void clearAll({bool notify = true}) {
    _query = '';
    _minRating = null;
    _priceLevel = null;
    _amenities.clear();
    _features.clear();
    _activeDynamicFilters = {};
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
    _activeDynamicFilters = {};
    notifyListeners();
  }

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

  void toggleAmenity(String key) {
    if (_amenities.contains(key)) {
      _amenities.remove(key);
    } else {
      _amenities.add(key);
    }
    notifyListeners();
  }

  void toggleFeature(String key) {
    if (_features.contains(key)) {
      _features.remove(key);
    } else {
      _features.add(key);
    }
    notifyListeners();
  }

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
    _sort = PlaceSort.recommended;
    notifyListeners();

    try {
      final result = await _repo.fetchPlaces(
        governorateNameAr: governorateNameAr,
        categoryId: categoryId,
        limit: limit,
      );
      if (myGen != _requestGeneration) return;
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

    final myGen = _requestGeneration;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repo.fetchPlaces(
        governorateNameAr: _currentGovernorate ?? '',
        categoryId: _currentCategoryId,
        limit: 20,
        lastDocument: _lastDocument,
      );
      if (myGen != _requestGeneration) return;
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
