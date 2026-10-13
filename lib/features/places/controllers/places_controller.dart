// features/places/controllers/places_controller.dart
//
// [v2.4 — Single Notification Fix]
//   - FIX: clearAll() أصبحت تقبل `notify` parameter
//          (يُستخدَم `notify: false` قبل loadCategory/load لمنع
//          "notifyListeners during build" — إشعاران متزامنان)
//   - الملف مُراجَع بالكامل ضد Flutter 3.32 / Dart 3.8.1
//
// [v2.3 — No Flash of Stale Content]
//   - FIX: عند تغيير الوضع/الفئة، تُمسح _allPlaces فوراً قبل الانتظار
//   - Pull-to-refresh داخل نفس الفئة لا يمسح (سلوك صحيح)
//   - _doLoad() تقبل clearBeforeLoad للتحكم الدقيق
//
// [v2.2 — Instant Search Fix]
//   - حذف الـ debounce بالكامل (client-side filtering فوري)
//   - تبسيط Search API: setQuery / clearQuery فقط
//   - applyQueryNow() مُبقاة كـ no-op للتوافق الخلفي
//
// [v2.1 — Simple Revolution] يستخدم `.get()` بدل `.snapshots()`
//   - يعمل في كل البيئات (FlutLab Web, Mobile, Desktop)
//   - لا يحتاج Composite Indexes
//   - البحث + الفلاتر + الترتيب كلهم client-side
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

  bool _firebaseAvailable = false;
  PlacesStatus _status = PlacesStatus.idle;
  List<Place> _allPlaces = const [];
  String? _error;
  String? _activeCategoryId;
  PlacesMode _mode = PlacesMode.all;

  // ─── Query (v2.2: فوري، بلا debounce) ───
  String _query = '';

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

  /// القائمة النهائية: بحث + فلاتر + ترتيب — كلهم client-side وفوريين.
  List<Place> get places {
    var result = _allPlaces;

    // فلتر البحث — يُطبَّق فوراً بناءً على _query مباشرة (v2.2)
    final q = _query.trim();
    if (q.isNotEmpty) {
      result = result.where((p) => _matchesQueryFor(p, q)).toList();
    }

    // فلتر السمات
    result = result.where(_matchesFilters).toList();
    result = List<Place>.from(result);

    // الترتيب
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
  // Search API (v2.2 — فوري، بلا debounce)
  // ═══════════════════════════════════════════════════════════════

  /// يُحدّث نص البحث فوراً (بدون debounce).
  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// [v2.2] no-op — البحث فوري الآن. مُبقاة للتوافق الخلفي فقط.
  void applyQueryNow() {
    // لا شيء — setQuery يقوم بكل العمل فوراً.
  }

  /// يمسح نص البحث فقط (يبقي الفلاتر والفئة).
  void clearQuery() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  /// يمسح كل شيء: البحث + الفلاتر + الترتيب (لا يمسح الفئة).
  ///
  /// [v2.4] `notify` parameter:
  ///   - `true` (افتراضي): يُشعِر المستمعين — للاستخدام العادي.
  ///   - `false`: صامت — للاستخدام قبل `loadCategory()`/`load()` مباشرة
  ///     لتجنّب "notifyListeners during build" (إشعاران متزامنان).
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
  // LOAD (One-shot)
  // ═══════════════════════════════════════════════════════════════

  /// يحمّل كل الأماكن مرة واحدة.
  /// [v2.3]: يمسح _allPlaces فوراً لو كنّا في وضع مختلف (تصنيف سابق).
  Future<void> load() async {
    if (!_firebaseAvailable || _repo == null) return;

    // نمسح فقط لو كنّا في وضع مختلف (يسمح بـ pull-to-refresh بدون وميض)
    final isModeChange = _mode != PlacesMode.all || _activeCategoryId != null;

    _activeCategoryId = null;
    _mode = PlacesMode.all;

    await _doLoad(
      () => _repo!.loadAll(),
      clearBeforeLoad: isModeChange,
    );
  }

  /// يحمّل أماكن تصنيف معين.
  /// [v2.3]: يمسح _allPlaces فوراً لو الفئة مختلفة (يسمح بـ pull-to-refresh
  /// داخل نفس الفئة بدون وميض).
  Future<void> loadCategory(String categoryId) async {
    if (!_firebaseAvailable || _repo == null) return;

    // نمسح فقط لو الفئة مختلفة
    final isCategoryChange = _activeCategoryId != categoryId;

    _activeCategoryId = categoryId;
    _mode = PlacesMode.category;

    await _doLoad(
      () => _repo!.loadByCategory(categoryId),
      clearBeforeLoad: isCategoryChange,
    );
  }

  /// إعادة التحميل حسب الوضع الحالي.
  /// [v2.3]: pull-to-refresh لا يمسح القائمة الحالية (تجربة أفضل).
  Future<void> refresh() async {
    switch (_mode) {
      case PlacesMode.all:
        await _doLoad(
          () => _repo!.loadAll(),
          clearBeforeLoad: false,
        );
      case PlacesMode.category:
        if (_activeCategoryId != null) {
          await _doLoad(
            () => _repo!.loadByCategory(_activeCategoryId!),
            clearBeforeLoad: false,
          );
        } else {
          await _doLoad(
            () => _repo!.loadAll(),
            clearBeforeLoad: false,
          );
        }
      case PlacesMode.search:
        await _doLoad(
          () => _repo!.loadAll(),
          clearBeforeLoad: false,
        );
    }
  }

  /// [v2.3] يقبل clearBeforeLoad لمسح _allPlaces فوراً قبل الانتظار.
  ///
  /// - `clearBeforeLoad: true` → يُستخدَم عند **تغيير الوضع/الفئة**
  ///   (يمنع ظهور المحتوى القديم لحظة ثم اختفائه)
  /// - `clearBeforeLoad: false` → يُستخدَم عند **pull-to-refresh**
  ///   (يبقي القائمة الحالية معروضة أثناء التحديث)
  Future<void> _doLoad(
    Future<List<Place>> Function() fetcher, {
    bool clearBeforeLoad = false,
  }) async {
    if (clearBeforeLoad) {
      _allPlaces = const []; // ← امسح فوراً قبل الانتظار
    }
    _status = PlacesStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _allPlaces = await fetcher();
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

  void watchAll() {
    load(); // fire-and-forget
  }

  void watchCategory(String categoryId) {
    loadCategory(categoryId); // fire-and-forget
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
    // [v2.4] لا يوجد timers لإلغائها — البحث فوري
    super.dispose();
  }
}
