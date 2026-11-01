// lib/features/merchant/controllers/merchant_application_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MerchantApplicationController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;

  Future<bool> submitApplication({
    required String userId,
    required String businessName,
    required String businessPhone,
    required String governorateId,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      // إنشاء طلب تاجر جديد بحالة "قيد الانتظار"
      await _db.collection('merchant_requests').add({
        'userId': userId,
        'businessName': businessName,
        'businessPhone': businessPhone,
        'governorateId': governorateId,
        'address': address,
        'status': 'pending',
        'type': 'create_new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      _isSuccess = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل إرسال الطلب: $e';
      notifyListeners();
      return false;
    }
  }
}
