// features/places/controllers/places_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';

enum PlacesStatus { idle, loading, loaded, error }

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
  StreamSubscription<List<Place>>? _sub;

  bool _firebaseAvailable = false;
  PlacesStatus _status = PlacesStatus.idle;
  List<Place> _places = const [];
  String? _error;
  String? _activeCategoryId;

  bool get firebaseAvailable => _firebaseAvailable;
  PlacesStatus get status => _status;
  List<Place> get places => List.unmodifiable(_places);
  String? get error => _error;
  String? get activeCategoryId => _activeCategoryId;
  bool get isLoading => _status == PlacesStatus.loading;

  void watchAll() {
    if (!_firebaseAvailable || _repo == null) return;
    _activeCategoryId = null;
    _start(_repo!.watchApproved());
  }

  void watchCategory(String categoryId) {
    if (!_firebaseAvailable || _repo == null) return;
    _activeCategoryId = categoryId;
    _start(_repo!.watchByCategory(categoryId));
  }

  void _start(Stream<List<Place>> stream) {
    _status = PlacesStatus.loading;
    _error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = stream.listen(
      (list) {
        _places = list;
        _status = PlacesStatus.loaded;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _status = PlacesStatus.error;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}