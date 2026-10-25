// test/location_service_test.dart
//
// اختبارات LocationData و LocationService
// [v1.2 — 2026-10-22] — توافق مع LocationData v5.1
//   - FIX: استخدام nameAr بدلاً من governorateAr
//   - FIX: استخدام accuracyMeters بدلاً من governorateEn
//   - FIX: اختبار toJson يتوقع المفاتيح الفعلية lat/lng/nameAr/accuracy
//   - ADD: اختبار تجاهل الحقول null في toJson
//   - KEPT: اختبارات fromJson الدفاعية و getBySource و egypt_governorates

import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/core/location/egypt_governorates.dart';
import 'package:yabaladi_rebuild/core/location/location_source.dart';
import 'package:yabaladi_rebuild/services/location_service.dart';

void main() {
  group('LocationData — model', () {
    test('toJson يحتوي الحقول غير الفارغة', () {
      const data = LocationData(
        latitude: 30.04,
        longitude: 31.23,
        nameAr: 'القاهرة',
        accuracyMeters: 10.5,
      );
      final json = data.toJson();
      expect(json['lat'], 30.04);
      expect(json['lng'], 31.23);
      expect(json['nameAr'], 'القاهرة');
      expect(json['accuracy'], 10.5);
    });

    test('toJson يتجاهل الحقول null', () {
      const data = LocationData(
        latitude: 30.04,
        longitude: 31.23,
      );
      final json = data.toJson();
      expect(json.containsKey('nameAr'), isFalse);
      expect(json.containsKey('accuracy'), isFalse);
    });

    test('round-trip يحفظ البيانات', () {
      const data = LocationData(
        latitude: 31.26,
        longitude: 32.30,
        nameAr: 'بورسعيد',
        accuracyMeters: 12.0,
      );
      final restored = LocationData.fromJson(data.toJson());
      expect(restored, isNotNull);
      expect(restored!.latitude, 31.26);
      expect(restored.longitude, 32.30);
      expect(restored.nameAr, 'بورسعيد');
      expect(restored.accuracyMeters, 12.0);
    });

    test('fromJson بـ بيانات ناقصة → null (defensive)', () {
      final restored = LocationData.fromJson(<String, dynamic>{
        'lat': 'not-a-number', // نص غير رقمي
      });
      expect(restored, isNull);
    });

    test('fromJson يقبل String رقمي', () {
      final restored = LocationData.fromJson(<String, dynamic>{
        'lat': '30.5',
        'lng': '31.2',
      });
      expect(restored, isNotNull);
      expect(restored!.latitude, 30.5);
      expect(restored.longitude, 31.2);
      expect(restored.nameAr, isNull);
      expect(restored.accuracyMeters, isNull);
    });
  });

  group('egypt_governorates — بيانات المحافظات', () {
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

  // ═══════════════════════════════════════════════════════════════
  // [v1.1] Wave 5.5c: getBySource
  // ═══════════════════════════════════════════════════════════════
  group('LocationService.getBySource', () {
    test('manual يعيد null (UI يتولى)', () async {
      final a = await LocationService.getBySource(LocationSource.manual);
      expect(a, isNull);
    });

    test('onlineSearch يعيد null (UI يتولى)', () async {
      final b = await LocationService.getBySource(LocationSource.onlineSearch);
      expect(b, isNull);
    });
  });
}
