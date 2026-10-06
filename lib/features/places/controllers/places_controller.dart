// features/places/controllers/places_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesStatus { idle, loading, loaded, error }

enum PlaceSort {
  ratingDesc,
  reviewsDesc,
  nameAsc,
  newest,
}

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

  // ─── Filters: Basic ───
  double? _minRating;
  int? _priceLevel;
  PlaceSort _sort = PlaceSort.ratingDesc;

  // ─── Filters: Multi-select ───
  final Set<String> _amenities = <String>{};
  final Set<String> _features = <String>{};
  final Set<String> _payments = <String>{};

  // ─── Getters ───
  bool get firebaseAvailable => _firebaseAvailable;
  PlacesStatus get status => _status;
  String? get error => _error;
  String? get activeCategoryId => _activeCategoryId;
  bool get isLoading => _status == PlacesStatus.loading;

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

  /// عدد الفلاتر النشطة (للبادج)
  int get activeFilterCount =>
      (_minRating != null ? 1 : 0) +
      (_priceLevel != null ? 1 : 0) +
      _amenities.length +
      _features.length +
      _payments.length;

  /// يعيد القائمة بعد تطبيق الفلاتر والترتيب
  List<Place> get places {
    final filtered = _allPlaces.where(_matches).toList();

    switch (_sort) {
      case PlaceSort.ratingDesc:
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case PlaceSort.reviewsDesc:
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case PlaceSort.nameAsc:
        filtered.sort((a, b) => a.nameAr.compareTo(b.nameAr));
      case PlaceSort.newest:
        filtered.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });
    }
    return List.unmodifiable(filtered);
  }

  /// فلتر واحد بيجمع كل الشروط
  bool _matches(Place p) {
    // Rating
    if (_minRating != null && p.averageRating < _minRating!) return false;

    // Price
    if (_priceLevel != null && p.priceLevel != _priceLevel) return false;

    // Amenities (AND - لازم كل المحدد موجود)
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

    // Features (AND)
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

    // Payments (OR - أي طريقة من المحدد)
    if (_payments.isNotEmpty) {
      final hasMatch = _payments.any((m) => p.paymentMethods.contains(m));
      if (!hasMatch) return false;
    }

    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  // WATCHERS
  // ═══════════════════════════════════════════════════════════════

  void watchAll() {
    if (!_firebaseAvailable || _repo == null) return;
    _activeCategoryId = null;
    _start(_repo!.watchApproved());
  }

  void watchCategory(String categoryId) {
    if (!_firebaseAvailable || _repo == null) return;
    _activeCategoryId = categoryId;
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
  // FILTERS: Setters
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
    _sub?.cancel();
    super.dispose();
  }
}