import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/favorite.dart';
import '../../../repositories/favorites_repository.dart';

/// يدير حالة المفضلة محليًا (cache) + يزامن مع Firestore.
class FavoritesController extends ChangeNotifier {
  FavoritesController({FavoritesRepository? repo})
      : _repo = repo ?? FavoritesRepository();

  final FavoritesRepository _repo;

  /// placeId → isFavorite (لكل مكان شافه المستخدم)
  final Map<String, bool> _state = {};

  /// placeId في حالة toggle الآن
  final Set<String> _busy = {};

  /// قائمة المفضلة كاملة (Stream)
  List<Favorite> _favorites = const [];

  StreamSubscription<List<Favorite>>? _sub;
  String? _watchingUid;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool isFavorite(String placeId) => _state[placeId] ?? false;
  bool isBusy(String placeId) => _busy.contains(placeId);

  List<Favorite> get favorites => List.unmodifiable(_favorites);
  int get count => _favorites.length;
  bool get isEmpty => _favorites.isEmpty;
  String? get watchingUid => _watchingUid;

  // ═══════════════════════════════════════════════════════════════
  // STREAM WATCHING
  // ═══════════════════════════════════════════════════════════════

  /// يبدأ مراقبة قائمة المفضلة للمستخدم.
  void startWatching(String userId) {
    if (_watchingUid == userId) return;

    _watchingUid = userId;
    _sub?.cancel();

    _sub = _repo.watchByUser(userId).listen(
      (list) {
        _favorites = list;
        // زامن الـ state المحلي
        for (final f in list) {
          _state[f.placeId] = true;
        }
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('FavoritesController.watch: $e');
      },
    );
  }

  /// يوقف المراقبة (عند logout).
  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    _watchingUid = null;
    _favorites = const [];
    _state.clear();
    _busy.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // SINGLE PLACE
  // ═══════════════════════════════════════════════════════════════

  /// يتحقق إذا كان المكان في المفضلة (لأول مرة).
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

  /// يضيف/يحذف المكان.
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}