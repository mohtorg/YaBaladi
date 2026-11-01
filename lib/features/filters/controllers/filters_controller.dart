// lib/features/filters/controllers/filters_controller.dart
//
// [Wave 11 — Filters System] — 2026-10-25
// [v11.1 — 2026-10-25] — FIX: add load() + dispose() for main.dart wiring
//   - NEW: load() subscribes to Firestore stream + auto-calls bindStream
//   - NEW: dispose() cancels subscription (prevents memory leak)
//   - KEPT: full existing API (bindStream, visibleFor, selection, CRUD)

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../models/filter_definition.dart';
import '../../../repositories/filters_repository.dart';

class FiltersController extends ChangeNotifier {
  final FiltersRepository _repo;

  FiltersController({FiltersRepository? repository})
      : _repo = repository ?? FiltersRepository();

  List<FilterDefinition> _all = const [];
  List<FilterDefinition> _active = const [];
  bool _loading = true;
  String? _error;

  Map<String, FilterSelection> _selection = {};
  String _currentRole = 'user';

  StreamSubscription<List<FilterDefinition>>? _subscription;

  // ─── Getters ───
  List<FilterDefinition> get all => _all;
  List<FilterDefinition> get active => _active;
  bool get loading => _loading;
  String? get error => _error;
  String get currentRole => _currentRole;
  Map<String, FilterSelection> get selection => Map.unmodifiable(_selection);
  int get activeCount => _selection.values.where((s) => s.isNotEmpty).length;

  // ─── Stream ───
  Stream<List<FilterDefinition>> get stream => _repo.watchAll();

  /// [v11.1] Subscribe to Firestore stream — called from main.dart:
  ///   ChangeNotifierProvider(create: (_) => FiltersController()..load())
  void load() {
    _subscription?.cancel();
    _loading = true;
    notifyListeners();

    _subscription = _repo.watchAll().listen(
      (filters) => bindStream(filters),
      onError: (Object e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void bindStream(List<FilterDefinition> filters) {
    _all = filters;
    _active = filters.where((f) => f.isActive).toList();
    _loading = false;
    _error = null;
    notifyListeners();
  }

  void setRole(String role) {
    if (_currentRole == role) return;
    _currentRole = role;
    notifyListeners();
  }

  // ─── Visibility (RBAC) ───
  List<FilterDefinition> visibleFor(String role) {
    return _active.where((f) {
      if (f.rolesAllowed.isEmpty) return true;
      return f.rolesAllowed.contains(role);
    }).toList();
  }

  // ─── Selection ───
  FilterSelection selectionFor(String filterId) =>
      _selection[filterId] ?? FilterSelection.empty;

  void toggle(String filterId, String value) {
    final current = _selection[filterId] ?? FilterSelection.empty;
    final next = Set<String>.from(current.values);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    _selection = {..._selection, filterId: FilterSelection(next)};
    notifyListeners();
  }

  void setSingle(String filterId, String? value) {
    if (value == null) {
      _selection.remove(filterId);
    } else {
      _selection = {
        ..._selection,
        filterId: FilterSelection({value})
      };
    }
    notifyListeners();
  }

  void clearFilter(String filterId) {
    _selection.remove(filterId);
    notifyListeners();
  }

  void clearAll() {
    _selection = {};
    notifyListeners();
  }

  void replaceSelection(Map<String, FilterSelection> next) {
    _selection = Map.from(next);
    notifyListeners();
  }

  Map<String, FilterSelection> toPlaceFilters() => Map.from(_selection);

  // ─── CRUD (Admin) ───
  Future<void> create(FilterDefinition filter) async {
    await _repo.create(filter.id, filter);
    notifyListeners();
  }

  Future<void> update(String id, FilterDefinition filter) async {
    await _repo.update(id, filter.toMap());
    notifyListeners();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _repo.update(id, {'isActive': isActive});
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
