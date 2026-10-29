import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket.dart';

class SupportTicketsController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  // نجلب كل البلاغات مرة واحدة ونفلترها برمجياً (أكثر كفاءة وأقل استهلاكاً)
  List<SupportTicket> _allTickets = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'open';

  StreamSubscription<QuerySnapshot>? _subscription;

  // ─── Getters ───
  // إرجاع القائمة مفلترة حسب الاختيار الحالي
  List<SupportTicket> get tickets {
    if (_filter == 'all') return _allTickets;
    return _allTickets.where((t) => t.status == _filter).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;

  // حساب عدد البلاغات الجديدة (للشارة الحمراء)
  int get openCount => _allTickets.where((t) => t.status == 'open').length;

  void setFilter(String f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners(); // لا نحتاج جلب بيانات جديدة، فقط نغير الفلتر محلياً
  }

  Future<void> loadTickets() async {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ الاستماع المباشر لكل البلاغات
      _subscription =
          _db.collection('support_tickets').snapshots().listen((snap) {
        _allTickets = snap.docs.map((d) => SupportTicket.fromDoc(d)).toList();

        // ترتيب البلاغات من الأحدث للأقدم
        _allTickets.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });

        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String ticketId, String newStatus) async {
    try {
      await _db.collection('support_tickets').doc(ticketId).update({
        'status': newStatus,
        'resolvedAt':
            newStatus == 'resolved' ? FieldValue.serverTimestamp() : null,
      });
      // ✅ لسنا بحاجة لتعديل القائمة يدوياً، الـ Stream سيقوم بتحديث الواجهة تلقائياً
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ✅ دالة حذف بلاغ واحد (تستخدمها شاشة الأدمن عند الضغط على زر الحذف)
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _db.collection('support_tickets').doc(ticketId).delete();
      // ✅ التحديث الفوري: الـ Stream سيعيد بناء القائمة بدون الحاجة لأي كود إضافي
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ✅ دالة حذف كل البلاغات المحلولة (لزر "مسح الكل" في الشريط العلوي)
  Future<void> deleteAllResolved() async {
    try {
      final resolvedTickets =
          _allTickets.where((t) => t.status == 'resolved').toList();

      // حذف كل بلاغ محلول واحداً تلو الآخر
      for (final ticket in resolvedTickets) {
        await _db.collection('support_tickets').doc(ticket.id).delete();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
