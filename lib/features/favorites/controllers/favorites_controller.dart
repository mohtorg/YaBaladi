import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/favorite.dart';
import '../../../repositories/favorites_repository.dart';

/// v1.2 — [2026-10-22] Guest guard (fixes `permission-denied`):
///   - AuthController.uid returns 'guest' for visitors, which was passed to
///     Firestore and rejected by the security rules. startWatching/load/toggle
///     now ignore empty or 'guest' ids, and a switch to a guest stops watching.
///
/// v1.1 — [2026-10-13] State consistency fixes:
///   - Stream emit now flips previously-true entries that leave the list
///   - startWatching resets state on user switch (prevents cross-user leak)
///   - load() respects in-flight toggles
///   - clear() also resets `_favorites`
///
/// يدير حالة المفضلة محليًا (cache) + يزامن مع Firestore.
class FavoritesController extends ChangeNotifier {
  FavoritesController({FavoritesRepository? repo})
      : _repo = repo ?? FavoritesRepository();

  final FavoritesRepository _repo;

  /// معرّف الزائر كما يُرجعه AuthController.uid
  static const String _guestUid = 'guest';

  /// placeId → isFavorite (لكل مكان شافه المستخدم)
  final Map<String, bool> _state = {};

  /// placeId في حالة toggle الآن
  final Set<String> _busy = {};

  /// قائمة المفضلة كاملة (Stream)
  List<Favorite> _favorites = const [];

  StreamSubscription<List<Favorite>>? _sub;
  String? _watchingUid;

  /// هل المعرّف لمستخدم حقيقي مسجّل (وليس زائراً)؟
  static bool _isRealUser(String userId) =>
      userId.isNotEmpty && userId != _guestUid;

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
  /// يتجاهل الزائر: القواعد ترفض قراءة مفضلة بلا حساب (permission-denied).
  void startWatching(String userId) {
    if (!_isRealUser(userId)) {
      // انتقال إلى زائر → أوقف أي مراقبة سابقة ونظّف الحالة
      if (_watchingUid != null) stopWatching();
      return;
    }
    if (_watchingUid == userId) return;

    _sub?.cancel();
    _sub = null;

    // FIX: reset state on user switch — stale data must not leak between users
    _watchingUid = userId;
    _favorites = const [];
    _state.clear();
    _busy.clear();

    _sub = _repo.watchByUser(userId).listen(
      (list) {
        final currentIds = <String>{for (final f in list) f.placeId};

        // FIX: flip previously-true entries that are no longer in the list
        for (final placeId in _state.keys.toList()) {
          if (_state[placeId] == true && !currentIds.contains(placeId)) {
            _state[placeId] = false;
          }
        }

        // mark all favorites as true
        for (final id in currentIds) {
          _state[id] = true;
        }

        _favorites = list;
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
    if (!_isRealUser(userId)) return; // الزائر: لا قراءة من Firestore
    if (_state.containsKey(placeId)) return;
    // FIX: skip if a toggle is in-flight — server value would be stale
    if (_busy.contains(placeId)) return;
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
    if (!_isRealUser(userId)) return false; // الزائر: يحتاج تسجيل دخول
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
    _favorites = const []; // FIX: also reset the list
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null; // FIX: nullify for hygiene
    super.dispose();
  }
}
