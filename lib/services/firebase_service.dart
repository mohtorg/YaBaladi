// services/firebase_service.dart
// خدمة مركزية لتهيئة Firebase.

import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  // ملاحظة التعديل:
  // أبقينا تهيئة Firebase في نقطة مركزية واحدة. Android يعتمد حاليًا على
  // google-services.json الموجود بالمشروع، بينما تهيئة Web/iOS الكاملة يجب
  // توليدها بأمر flutterfire configure بدل اختراع مفاتيح أو App IDs يدويًا.
  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();
  }
}
