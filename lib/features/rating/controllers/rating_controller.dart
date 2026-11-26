// lib/features/rating/controllers/rating_controller.dart
// [v1.4 — 2026-11-15] — Phase 16: exposes `isUpdate` via result.
// (Signature of `submit()` unchanged — internal flags flow through result.)

import 'package:flutter/foundation.dart';
import '../services/rating_service.dart';

class RatingController extends ChangeNotifier {
  final RatingService _service;

  RatingController({RatingService? service})
      : _service = service ?? RatingService();

  bool _isSubmitting = false;
  String? _error;
  RatingSubmitResult? _result;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  RatingSubmitResult? get result => _result;

  void reset() {
    _isSubmitting = false;
    _error = null;
    _result = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String placeId,
    required String categoryId,
    required double placeLat,
    required double placeLng,
    required String pinObfuscated,
    String? zoneId,
    required int overall,
    required Map<String, int> dimensions,
    required Map<String, dynamic> dimensionsMetadata,
    required String body,
    String? userProvidedPin,
    String? userProvidedQr,
  }) async {
    _isSubmitting = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final result = await _service.submitRating(
        placeId: placeId,
        categoryId: categoryId,
        placeLat: placeLat,
        placeLng: placeLng,
        pinObfuscated: pinObfuscated,
        zoneId: zoneId,
        overall: overall,
        dimensions: dimensions,
        dimensionsMetadata: dimensionsMetadata,
        body: body,
        userProvidedPin: userProvidedPin,
        userProvidedQr: userProvidedQr,
      );

      _isSubmitting = false;
      if (result.success) {
        _result = result;
        notifyListeners();
        return true;
      }
      _error = result.failureReason ?? 'فشل التحقق';
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _error = 'حدث خطأ غير متوقع: $e';
      notifyListeners();
      return false;
    }
  }
}
