// features/places/controllers/places_controller.dart
//
// [v2.7 — 2026-10-17] — Architectural separation: raw vs filtered
//   - NEW: allPlacesRaw getter — unfiltered data for Services
//   - NEW: hasData getter — check if any data exists (regardless of filters)
//   - NEW: isFiltered getter — check if any filter is active
//   - DOC: places getter now clearly documented as UI-only
//   - This fixes Trip Planner showing "no places" when filters are active
//
// [v2.6 — 2026-10-16] — Cleanup
// [v2.5-DEBUG] — تشخيص (مؤقت)
// [v2.4] — clearAll notify parameter
// [v2.3] — clearBeforeLoad

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/search/utils/text_normalizer.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesStatus { idle, loading, loaded, error }

enum PlaceSort { ratingDesc, reviewsDesc, nameAsc, newest }

enum PlacesMode { all, category, search }

class PlacesController extends ChangeNotifier {
  PlacesController({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore {
    try {
      _repo = PlacesRepository(firestore: _injectedFirestore);
      _firebaseAvailable = true;
    } catch (e) {
      _firebaseAvailable = false;
      _status = PlacesStatus.error;
      _error = 'Firebase غير متاح';
      debugPrint('PlacesController: Firebase not available ($e)');
    }
  }

  final FirebaseFirestore? _injectedFirestore;
  PlacesRepository? _repo;

  bool _firebaseAvailable = false;
  PlacesStatus _status = PlacesStatus.idle;
  List<Place> _allPlaces = const [];
  String? _error;
  String? _activeCategoryId;
  PlacesMode _mode = PlacesMode.all;

  String _query = '';
  double? _minRating;
  int? _priceLevel;
  PlaceSort _sort = PlaceSort.ratingDesc;

  final Set<String> _amenities = <String>{};
  final Set<String> _features = <String>{};
  final Set<String> _payments = <String>{};

  // ═══════════════════════════════════════════════════════════════
  // Getters — Basic
  // ═══════════════════════════════════════════════════════════════

  bool get firebaseAvailable => _firebaseAvailable;
  PlacesStatus get status => _status;
  String? get error => _error;
  String? get activeCategoryId => _activeCategoryId;
  bool get isLoading => _status == PlacesStatus.loading;
  PlacesMode get mode => _mode;
  String get query => _query;
  bool get hasQuery => _query.trim().isNotEmpty;
  double? get minRating => _minRating;
  int? get priceLevel => _priceLevel;
  PlaceSort get sort => _sort;
  Set<String> get amenities => Set.unmodifiable(_amenities);
  Set<String> get features => Set.unmodifiable(_features);
  Set<String> get payments => Set.unmodifiable(_payments);

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

  // ═══════════════════════════════════════════════════════════════
  // Getters — Data Access (Architectural)
  // ═══════════════════════════════════════════════════════════════

  /// [v2.7] البيانات الخام — بدون query/filters/sort.
  ///
  /// **الاستخدام:** الخدمات (Services) التي تريد كل البيانات
  /// لتصفيتها بطريقتها الخاصة.
  ///
  /// **مثال:** `TripPlannerService.generateTrip()` —
  /// يفلتر حسب governorate + interests الخاصة بالرحلة،
  /// وليس حسب فلاتر شاشة Explore.
  ///
  /// **🚫 لا تستخدمها في Widgets** — استخدم `places` بدلاً.
  List<Place> get allPlacesRaw => List.unmodifiable(_allPlaces);

  /// [v2.7] هل هناك بيانات محمّلة أصلاً (بغض النظر عن الفلاتر)؟
  ///
  /// **الفرق عن `places.isEmpty`:**
  ///   - `hasData = false` → المشكلة في تحميل البيانات (شبكة، Firestore)
  ///   - `hasData = true` + `places.isEmpty` → الفلاتر تخفي كل النتائج
  bool get hasData => _allPlaces.isNotEmpty;

  /// [v2.7] هل يوجد فلتر نشط الآن (query أو خصائص)؟
  bool get isFiltered => hasQuery || hasActiveFilters;

  // ═══════════════════════════════════════════════════════════════
  // Getters — UI View (filtered)
  // ═══════════════════════════════════════════════════════════════

  /// **القائمة النهائية للعرض في UI** — مطبَّق عليها query + filters + sort.
  ///
  /// **الاستخدام:** شاشات العرض فقط (Home, Explore, Search).
  ///
  /// **🚫 لا تستخدمها في Services** — استخدم `allPlacesRaw` بدلاً
  /// (وإلا فسيعتمد التوليد على فلاتر شاشة العرض).
  List<Place> get places {
    var result = _allPlaces;

    final q = _query.trim();
    if (q.isNotEmpty) {
      result = result.where((p) => _matchesQueryFor(p, q)).toList();
    }

    result = result.where(_matchesFilters).toList();
    result = List<Place>.from(result);

    switch (_sort) {
      case PlaceSort.ratingDesc:
        result.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case PlaceSort.reviewsDesc:
        result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case PlaceSort.nameAsc:
        result.sort((a, b) => a.nameAr.compareTo(b.nameAr));
      case PlaceSort.newest:
        result.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });
    }

    return List.unmodifiable(result);
  }

  bool _matchesQueryFor(Place p, String q) {
    return TextNormalizer.matchesAny(
      [p.nameAr, p.nameEn, p.description, ...p.tags],
      q,
    );
  }

  bool _matchesFilters(Place p) {
    if (_minRating != null && p.averageRating < _minRating!) return false;
    if (_priceLevel != null && p.priceLevel != _priceLevel) return false;

    for (final a in _amenities) {
      switch (a) {
        case 'wifi':
          if (!p.hasWifi) return false;
        case 'parking':
          if (!p.hasParking) return false;
        case 'restroom':
          if (!p.hasRestroom) return false;
        case 'accessibility':
          if (!p.hasAccessibility) return false;
      }
    }

    for (final f in _features) {
      switch (f) {
        case 'family':
          if (!p.isFamilyFriendly) return false;
        case 'halal':
          if (!p.isHalal) return false;
        case 'delivery':
          if (!p.hasDelivery) return false;
        case 'reservation':
          if (!p.hasReservation) return false;
        case 'offers':
          if (!p.hasOffers) return false;
      }
    }

    if (_payments.isNotEmpty) {
      final hasMatch = _payments.any((m) => p.paymentMethods.contains(m));
      if (!hasMatch) return false;
    }

    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  // Search API
  // ═══════════════════════════════════════════════════════════════

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void applyQueryNow() {}

  void clearQuery() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  void clearAll({bool notify = true}) {
    _query = '';
    _minRating = null;
    _priceLevel = null;
    _sort = PlaceSort.ratingDesc;
    _amenities.clear();
    _features.clear();
    _payments.clear();
    if (notify) notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> load() async {
    if (!_firebaseAvailable || _repo == null) return;

    final isModeChange = _mode != PlacesMode.all || _activeCategoryId != null;
    _activeCategoryId = null;
    _mode = PlacesMode.all;

    await _doLoad(
      () => _repo!.loadAll(),
      clearBeforeLoad: isModeChange,
    );
  }

  Future<void> loadCategory(String categoryId) async {
    if (!_firebaseAvailable || _repo == null) return;

    final isCategoryChange = _activeCategoryId != categoryId;
    _activeCategoryId = categoryId;
    _mode = PlacesMode.category;

    await _doLoad(
      () => _repo!.loadByCategory(categoryId),
      clearBeforeLoad: isCategoryChange,
    );
  }

  Future<void> refresh() async {
    switch (_mode) {
      case PlacesMode.all:
        await _doLoad(() => _repo!.loadAll(), clearBeforeLoad: false);
      case PlacesMode.category:
        if (_activeCategoryId != null) {
          await _doLoad(
            () => _repo!.loadByCategory(_activeCategoryId!),
            clearBeforeLoad: false,
          );
        } else {
          await _doLoad(() => _repo!.loadAll(), clearBeforeLoad: false);
        }
      case PlacesMode.search:
        await _doLoad(() => _repo!.loadAll(), clearBeforeLoad: false);
    }
  }

  Future<void> _doLoad(
    Future<List<Place>> Function() fetcher, {
    bool clearBeforeLoad = false,
  }) async {
    if (clearBeforeLoad) {
      _allPlaces = const [];
    }
    _status = PlacesStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await fetcher();
      _allPlaces = result;
      _status = PlacesStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = PlacesStatus.error;
      debugPrint('PlacesController._doLoad error: $e');
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Backward Compatibility
  // ═══════════════════════════════════════════════════════════════

  void watchAll() => load();
  void watchCategory(String categoryId) => loadCategory(categoryId);

  // ═══════════════════════════════════════════════════════════════
  // Filter Setters
  // ═══════════════════════════════════════════════════════════════

  void setMinRating(double? value) {
    _minRating = value;
    notifyListeners();
  }

  void setPriceLevel(int? value) {
    _priceLevel = value;
    notifyListeners();
  }

  void setSort(PlaceSort value) {
    _sort = value;
    notifyListeners();
  }

  void setAmenities(Set<String> value) {
    _amenities
      ..clear()
      ..addAll(value);
    notifyListeners();
  }

  void setFeatures(Set<String> value) {
    _features
      ..clear()
      ..addAll(value);
    notifyListeners();
  }

  void setPayments(Set<String> value) {
    _payments
      ..clear()
      ..addAll(value);
    notifyListeners();
  }

  void clearFilters() {
    _minRating = null;
    _priceLevel = null;
    _sort = PlaceSort.ratingDesc;
    _amenities.clear();
    _features.clear();
    _payments.clear();
    notifyListeners();
  }
}
