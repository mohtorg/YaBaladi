import 'package:flutter/foundation.dart';

import '../../../repositories/favorites_repository.dart';

/// يدير حالة المفضلة محليًا (cache) + يزامن مع Firestore.
class FavoritesController extends ChangeNotifier {
  FavoritesController({FavoritesRepository? repo})
      : _repo = repo ?? FavoritesRepository();

  final FavoritesRepository _repo;

  /// placeId → isFavorite
  final Map<String, bool> _state = {};

  /// placeId في حالة toggle الآن
  final Set<String> _busy = {};

  bool isFavorite(String placeId) => _state[placeId] ?? false;
  bool isBusy(String placeId) => _busy.contains(placeId);

  Future<void> load(String userId, String placeId) async {
    if (_state.containsKey(placeId)) return;
    try {
      final fav = await _repo.isFavorite(userId, placeId);
      _state[placeId] = fav;
      notifyListeners();
    } catch (e) {
      debugPrint('FavoritesController.load: $e');
    }
  }

  Future<bool> toggle(String userId, String placeId) async {
    if (_busy.contains(placeId)) return isFavorite(placeId);

    _busy.add(placeId);
    notifyListeners();

    try {
      final newState = await _repo.toggle(userId, placeId);
      _state[placeId] = newState;
      return newState;
    } finally {
      _busy.remove(placeId);
      notifyListeners();
    }
  }

  void clear() {
    _state.clear();
    _busy.clear();
    notifyListeners();
  }
}