// lib/features/filters/controllers/filters_controller.dart
// [v2.2.0 — 2026-11-12] — RESTORED LEGACY FIELDS & METHODS:
//   - Re-added `selection`, `currentRole`, `visibleFor`, `replaceSelection`, `clearSelection`.
//   - Kept category-aware helpers (`applicableFiltersFor`, etc.) and `load()`.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/filter_definition.dart';

class FiltersController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FilterDefinition> _all = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<QuerySnapshot>? _subscription;

  // ─── State (Legacy - for UI) ───
  Map<String, FilterSelection> _selection = {};
  String _currentRole = 'user';

  // ─── Getters (Core) ───
  List<FilterDefinition> get all => _all;
  bool get loading => _loading;
  String? get error => _error;
  Map<String, FilterSelection> get selection => _selection;
  String get currentRole => _currentRole;

  // ─── Getters (Category-Aware) ───
  List<FilterDefinition> get generalFilters {
    return _all.where((f) => f.categoryId == null).toList();
  }

  List<FilterDefinition> filtersForCategory(String categoryId) {
    return _all.where((f) => f.categoryId == categoryId).toList();
  }

  List<FilterDefinition> applicableFiltersFor(String categoryId) {
    return _all
        .where((f) => f.categoryId == null || f.categoryId == categoryId)
        .toList();
  }

  // ─── Getters (Role-Aware) ───
  List<FilterDefinition> visibleFor(String role) {
    return _all
        .where((f) => f.isActive && f.rolesAllowed.contains(role))
        .toList();
  }

  // ─── Mutators ───
  void setRole(String role) {
    if (_currentRole != role) {
      _currentRole = role;
      notifyListeners();
    }
  }

  void replaceSelection(Map<String, FilterSelection> newSelection) {
    _selection = Map.from(newSelection);
    notifyListeners();
  }

  void clearSelection() {
    _selection = {};
    notifyListeners();
  }

  // ─── Lifecycle ───
  FiltersController() {
    _init();
  }

  void load() {
    _init();
  }

  void _init() {
    _subscription?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _subscription =
        _firestore.collection('filters').orderBy('order').snapshots().listen(
      (snapshot) {
        _all = snapshot.docs
            .map((doc) => FilterDefinition.fromFirestore(doc))
            .toList();
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ─── CRUD Operations ───
  Future<void> create(FilterDefinition filter) async {
    try {
      await _firestore.collection('filters').doc(filter.id).set(filter.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> update(String id, FilterDefinition filter) async {
    try {
      await _firestore.collection('filters').doc(id).update(filter.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.collection('filters').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _firestore.collection('filters').doc(id).update({
        'isActive': isActive,
      });
    } catch (e) {
      rethrow;
    }
  }
}
