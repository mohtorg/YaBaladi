import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationsController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  String? _userId;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void listen(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    // لا نستخدم orderBy (لتجنب فهرسة Firebase) - نرتب محلياً
    _subscription = _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(100)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) => AppNotification.fromDoc(d)).toList();
      list.sort((a, b) {
        final da = a.createdAt ?? DateTime(2000);
        final db = b.createdAt ?? DateTime(2000);
        return db.compareTo(da);
      });
      _notifications = list;
      _unreadCount = list.where((n) => !n.isRead).length;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Notifications listen error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await markAsRead(n.id);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _db.collection('notifications').doc(id).delete();
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
