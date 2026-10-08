// features/places/controllers/places_controller.dart
//
// [v2.0 — Unified] يدمج:
//   - الفلاتر المتقدمة (rating + price + amenities + features + payments)
//   - البحث النصي (مع TextNormalizer و debounce 350ms)
//   - الترتيب (ratingDesc / reviewsDesc / nameAsc / newest)
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/search/utils/text_normalizer.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesStatus { idle, loading, loaded, error }

enum PlaceSort { ratingDesc, reviewsDesc, nameAsc, newest }

/// وضع الـ Controller:
/// - all: كل الأماكن (Home)
/// - category: تصنيف محدد
/// - search: بحث نصي حر
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
  StreamSubscription<List<Place>>? _sub;

  bool _firebaseAvailable = false;
  PlacesStatus _status = PlacesStatus.idle;
  List<Place> _allPlaces = const [];
  String? _error;
  String? _activeCategoryId;
  PlacesMode _mode = PlacesMode.all;

  // ─── Query ───
  String _query = '';
  String _appliedQuery = '';
  Timer? _queryDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 350);

  // ─── Filters: Basic ───
  double? _minRating;
  int? _priceLevel;
  PlaceSort _sort = PlaceSort.ratingDesc;

  // ─── Filters: Multi-select ───
  final Set<String> _amenities = <String>{};
  final Set<String> _features = <String>{};
  final Set<String> _payments = <String>{};


  // ═══════════════════════════════════════════════════════════════
  // Getters
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

  /// القائمة النهائية: بحث + فلاتر + ترتيب.
  List<Place> get places {
    var result = _allPlaces;

    if (_appliedQuery.isNotEmpty) {
      result = result.where(_matchesQuery).toList();
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

  bool _matchesQuery(Place p) {
    return TextNormalizer.matchesAny(
      [p.nameAr, p.nameEn, p.description, ...p.tags],
      _appliedQuery,
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

    _queryDebounce?.cancel();
    _queryDebounce = Timer(_debounceDuration, () {
      _appliedQuery = value.trim();
      notifyListeners();
    });
  }

  void applyQueryNow() {
    _queryDebounce?.cancel();
    _appliedQuery = _query.trim();
    notifyListeners();
  }

  void clearQuery() {
    _queryDebounce?.cancel();
    _query = '';
    _appliedQuery = '';
    notifyListeners();
  }

  void clearAll() {
    _queryDebounce?.cancel();
    _query = '';
    _appliedQuery = '';
    _minRating = null;
    _priceLevel = null;
    _sort = PlaceSort.ratingDesc;
    _amenities.clear();
    _features.clear();
    _payments.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Watchers
  // ═══════════════════════════════════════════════════════════════

  void watchAll() {
    if (!_firebaseAvailable || _repo == null) return;
    _activeCategoryId = null;
    _mode = PlacesMode.all;
    _start(_repo!.watchApproved());
  }

  void watchCategory(String categoryId) {
    if (!_firebaseAvailable || _repo == null) return;
    _activeCategoryId = categoryId;
    _mode = PlacesMode.category;
    _start(_repo!.watchByCategory(categoryId));
  }

  void _start(Stream<List<Place>> stream) {
    _status = PlacesStatus.loading;
    _error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = stream.listen(
      (list) {
        _allPlaces = list;
        _status = PlacesStatus.loaded;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _status = PlacesStatus.error;
        notifyListeners();
      },
    );
  }


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

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
