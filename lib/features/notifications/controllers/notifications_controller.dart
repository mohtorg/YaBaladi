// lib/features/notifications/controllers/notifications_controller.dart
//
// [v1.2 — 2026-11-01] — PER-USER READ STATE FOR BROADCASTS
//   - ADDED: users/{uid}/notification_reads subcollection for per-user read state.
//   - ADDED: users/{uid}/notification_hides subcollection for per-user hidden broadcasts.
//   - FIXED: Broadcast notifications no longer marked as read for ALL users.
//   - KEPT: All previous behavior for user-specific notifications.

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

  // ✅ بيانات خام من Firebase
  List<AppNotification> _rawNotifications = [];
  Set<String> _myReadBroadcastIds = {};
  Set<String> _myHiddenBroadcastIds = {};

  StreamSubscription<QuerySnapshot>? _notifSub;
  StreamSubscription<QuerySnapshot>? _readsSub;
  StreamSubscription<QuerySnapshot>? _hidesSub;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void listen(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _cancelSubscriptions();
    _isLoading = true;
    notifyListeners();

    // ─── 1. الإشعارات (الخاصة بالمستخدم + العامة) ───
    _notifSub = _db
        .collection('notifications')
        .where('userId', whereIn: [userId, 'all'])
        .limit(100)
        .snapshots()
        .listen(
          (snap) {
            _rawNotifications =
                snap.docs.map((d) => AppNotification.fromDoc(d)).toList();
            _recompute();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Notifications listen error: $e');
            _isLoading = false;
            notifyListeners();
          },
        );

    // ─── 2. حالة قراءة المستخدم للإشعارات العامة ───
    _readsSub = _db
        .collection('users')
        .doc(userId)
        .collection('notification_reads')
        .snapshots()
        .listen(
      (snap) {
        _myReadBroadcastIds = snap.docs.map((d) => d.id).toSet();
        _recompute();
        notifyListeners();
      },
      onError: (e) => debugPrint('Reads listen error: $e'),
    );

    // ─── 3. الإشعارات العامة التي أخفاها المستخدم ───
    _hidesSub = _db
        .collection('users')
        .doc(userId)
        .collection('notification_hides')
        .snapshots()
        .listen(
      (snap) {
        _myHiddenBroadcastIds = snap.docs.map((d) => d.id).toSet();
        _recompute();
        notifyListeners();
      },
      onError: (e) => debugPrint('Hides listen error: $e'),
    );
  }

  /// ✅ يدمج الإشعارات مع حالة القراءة الشخصية
  void _recompute() {
    _notifications = _rawNotifications
        .where((n) => !_myHiddenBroadcastIds.contains(n.id))
        .map((n) {
      // الإشعارات العامة: القراءة تعتمد على الـ subcollection
      if (n.userId == 'all') {
        final wasReadByMe = _myReadBroadcastIds.contains(n.id);
        return n.copyWith(isRead: wasReadByMe);
      }
      // الإشعارات الخاصة: القراءة تعتمد على حقل isRead الأصلي
      return n;
    }).toList()
      ..sort((a, b) {
        final da = a.createdAt ?? DateTime(2000);
        final db = b.createdAt ?? DateTime(2000);
        return db.compareTo(da);
      });

    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) return;

    // البحث عن الإشعار لمعرفة نوعه
    AppNotification? notif;
    try {
      notif = _rawNotifications.firstWhere((n) => n.id == notificationId);
    } catch (_) {
      return;
    }

    try {
      if (notif.userId == 'all') {
        // ✅ إشعار عام: نضيف وثيقة في مجموعته الفرعية فقط
        await _db
            .collection('users')
            .doc(_userId)
            .collection('notification_reads')
            .doc(notificationId)
            .set({'readAt': FieldValue.serverTimestamp()});
      } else {
        // ✅ إشعار خاص: نحدّث الوثيقة الأصلية
        await _db
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await markAsRead(n.id);
    }
  }

  Future<void> deleteNotification(String id) async {
    if (_userId == null) return;

    AppNotification? notif;
    try {
      notif = _rawNotifications.firstWhere((n) => n.id == id);
    } catch (_) {
      return;
    }

    try {
      if (notif.userId == 'all') {
        // ✅ إشعار عام: نخفيه للمستخدم الحالي فقط
        await _db
            .collection('users')
            .doc(_userId)
            .collection('notification_hides')
            .doc(id)
            .set({'hiddenAt': FieldValue.serverTimestamp()});
      } else {
        // ✅ إشعار خاص: نحذفه تماماً
        await _db.collection('notifications').doc(id).delete();
      }
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  void stop() {
    _cancelSubscriptions();
    _userId = null;
    _rawNotifications = [];
    _notifications = [];
    _myReadBroadcastIds = {};
    _myHiddenBroadcastIds = {};
    _unreadCount = 0;
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _notifSub?.cancel();
    _notifSub = null;
    _readsSub?.cancel();
    _readsSub = null;
    _hidesSub?.cancel();
    _hidesSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
