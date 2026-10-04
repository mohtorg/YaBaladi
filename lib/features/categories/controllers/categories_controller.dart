// features/categories/controllers/categories_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../../../models/category.dart';
import '../../../repositories/categories_repository.dart';

enum CategoriesStatus { idle, loading, loaded, error }

/// يغلّف CategoriesRepository + Stream (defensive ضد Firebase غير المُهيَّأ).
class CategoriesController extends ChangeNotifier {
  CategoriesController({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore {
    try {
      _repo = CategoriesRepository(firestore: _injectedFirestore);
      _firebaseAvailable = true;
    } catch (e) {
      _firebaseAvailable = false;
      _status = CategoriesStatus.error;
      _error = 'Firebase غير متاح';
      debugPrint('CategoriesController: Firebase not available ($e)');
    }
  }

  final FirebaseFirestore? _injectedFirestore;
  CategoriesRepository? _repo;
  StreamSubscription<List<Category>>? _sub;

  bool _firebaseAvailable = false;
  CategoriesStatus _status = CategoriesStatus.idle;
  List<Category> _categories = const [];
  String? _error;

  bool get firebaseAvailable => _firebaseAvailable;
  CategoriesStatus get status => _status;
  List<Category> get categories => List.unmodifiable(_categories);
  String? get error => _error;
  bool get isLoading => _status == CategoriesStatus.loading;

  /// ابدأ الاستماع المباشر. آمن للاستدعاء أكثر من مرة.
  void start() {
    if (!_firebaseAvailable || _repo == null) return;
    _status = CategoriesStatus.loading;
    _error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _repo!.watchActive().listen(
      (list) {
        _categories = list;
        _status = CategoriesStatus.loaded;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _status = CategoriesStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> reload() async {
    if (!_firebaseAvailable || _repo == null) return;
    _status = CategoriesStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _categories = await _repo!.getAllActive();
      _status = CategoriesStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = CategoriesStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}