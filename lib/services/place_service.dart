// services/place_service.dart
//
// مصدر الحقيقة للأماكن هو Firestore فقط.
// مهم: لا يوجد Seed تلقائي عند تشغيل التطبيق؛ البيانات الحقيقية يجب أن تدخل
// من لوحة الإدارة أو من مسار مقدم الخدمة المعتمد. هذا يمنع ظهور بيانات تجريبية
// أو إعادة إدخال بيانات غير مقصودة في بيئة الإنتاج.
//
// Firestore يسمح ببنية موحدة للمستندات، لذلك نستخدم governorateId وcityId معًا
// استعدادًا للتوسع من محافظة واحدة إلى مدن ومناطق متعددة.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';

class PlaceService {
  final CollectionReference<Map<String, dynamic>> _placesRef =
      FirebaseFirestore.instance.collection('places');

  Future<List<Place>> getPlacesByCity(String cityId) async {
    final snapshot = await _placesRef.where('cityId', isEqualTo: cityId).get();

    return snapshot.docs
        .map((doc) => Place.fromMap(doc.id, doc.data()))
        // المستندات القديمة لا تحتوي isPublished؛ Place.fromMap يعتبرها منشورة.
        .where((place) => place.isPublished)
        .toList();
  }

  Future<List<Place>> getPlacesByGovernorate(String governorateId) async {
    final snapshot = await _placesRef
        .where('governorateId', isEqualTo: governorateId)
        .get();

    return snapshot.docs
        .map((doc) => Place.fromMap(doc.id, doc.data()))
        .where((place) => place.isPublished)
        .toList();
  }

  Future<Place?> getPlaceById(String placeId) async {
    final doc = await _placesRef.doc(placeId).get();
    if (!doc.exists || doc.data() == null) return null;
    final place = Place.fromMap(doc.id, doc.data()!);
    return place.isPublished ? place : null;
  }
}
