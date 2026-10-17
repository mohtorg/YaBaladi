// test/location_service_test.dart
//
// اختبارات Wave 1a: DUPLICATE-1 fix
//   - LocationService يستخدم egypt_governorates كمصدر وحيد

import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/core/location/egypt_governorates.dart';
import 'package:yabaladi_rebuild/services/location_service.dart';

void main() {
  group('LocationData — model', () {
    test('toJson يحتوي كل الحقول', () {
      const data = LocationData(
        latitude: 30.04,
        longitude: 31.23,
        governorateAr: 'القاهرة',
        governorateEn: 'Cairo',
      );
      final json = data.toJson();
      expect(json['lat'], 30.04);
      expect(json['lng'], 31.23);
      expect(json['ar'], 'القاهرة');
      expect(json['en'], 'Cairo');
    });

    test('round-trip يحفظ البيانات', () {
      const data = LocationData(
        latitude: 31.26,
        longitude: 32.30,
        governorateAr: 'بورسعيد',
        governorateEn: 'Port Said',
      );
      final restored = LocationData.fromJson(data.toJson());
      expect(restored, isNotNull);
      expect(restored!.latitude, 31.26);
      expect(restored.longitude, 32.30);
      expect(restored.governorateAr, 'بورسعيد');
    });

    test('fromJson بـ بيانات ناقصة → null', () {
      final restored = LocationData.fromJson(<String, dynamic>{
        'lat': 'not-a-number', // ← نص بدل رقم
      });
      expect(restored, isNull);
    });
  });

  group('egypt_governorates — المصدر الوحيد', () {
    test('nearestGovernorate(القاهرة) → القاهرة', () {
      final gov = nearestGovernorate(30.0444, 31.2357);
      expect(gov.nameAr, 'القاهرة');
      expect(gov.nameEn, 'Cairo');
      expect(gov.id, 'cairo');
    });

    test('nearestGovernorate(بورسعيد) → بورسعيد', () {
      final gov = nearestGovernorate(31.2653, 32.3019);
      expect(gov.nameAr, 'بورسعيد');
      expect(gov.id, 'port_said');
    });

    test('nearestGovernorate(الإسكندرية) → الإسكندرية', () {
      final gov = nearestGovernorate(31.2001, 29.9187);
      expect(gov.nameAr, 'الإسكندرية');
      expect(gov.id, 'alexandria');
    });

    test('27 محافظة متوفرة', () {
      expect(kEgyptGovernorates.length, 27);
    });

    test('كل محافظة لها id فريد', () {
      final ids = kEgyptGovernorates.map((g) => g.id).toSet();
      expect(ids.length, kEgyptGovernorates.length);
    });
  });
}
