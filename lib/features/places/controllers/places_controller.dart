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

  // ─── Filters ───
  double? _minRating;
  int? _priceLevel;
  PlaceSort _sort = PlaceSort.ratingDesc;

  // ─── Getters ───
  bool get firebaseAvailable => _firebaseAvailable;
  PlacesStatus get status => _status;
  String? get error => _error;
  String? get activeCategoryId => _activeCategoryId;
  bool get isLoading => _status == PlacesStatus.loading;

  double? get minRating => _minRating;
  int? get priceLevel => _priceLevel;
  PlaceSort get sort => _sort;
  bool get hasActiveFilters => _minRating != null || _priceLevel != null;

  /// يعيد القائمة بعد تطبيق الفلاتر والترتيب
  List<Place> get places {
    final filtered = _allPlaces.where((p) {
      if (_minRating != null && p.averageRating < _minRating!) return false;
      if (_priceLevel != null && p.priceLevel != _priceLevel) return false;
      return true;
    }).toList();

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
  // FILTERS
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

  void clearFilters() {
    _minRating = null;
    _priceLevel = null;
    _sort = PlaceSort.ratingDesc;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}