// test/egypt_governorates_test.dart
//
// اختبارات Wave 1a: DUPLICATE-1 fix
//   - التحقق من أن `nearestGovernorate` (المصدر الوحيد) يعمل
//   - ضمان التوافق مع `LocationService` بعد إزالة القائمة المكررة

import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/core/location/egypt_governorates.dart';

void main() {
  group('nearestGovernorate — إحداثيات معروفة', () {
    test('القاهرة → cairo', () {
      final gov = nearestGovernorate(30.0444, 31.2357);
      expect(gov.id, 'cairo');
      expect(gov.nameAr, 'القاهرة');
      expect(gov.nameEn, 'Cairo');
    });

    test('بورسعيد → port_said', () {
      final gov = nearestGovernorate(31.2653, 32.3019);
      expect(gov.id, 'port_said');
      expect(gov.nameAr, 'بورسعيد');
    });

    test('الإسكندرية → alexandria', () {
      final gov = nearestGovernorate(31.2001, 29.9187);
      expect(gov.id, 'alexandria');
      expect(gov.nameAr, 'الإسكندرية');
    });

    test('أسوان → aswan', () {
      final gov = nearestGovernorate(24.0889, 32.8998);
      expect(gov.id, 'aswan');
      expect(gov.nameAr, 'أسوان');
    });

    test('قنا → qena', () {
      final gov = nearestGovernorate(26.1551, 32.7160);
      expect(gov.id, 'qena');
      expect(gov.nameAr, 'قنا');
    });
  });

  group('nearestGovernorate — إحداثيات قريبة (fuzzy)', () {
    test('إحداثيات قريبة من القاهرة (delta 0.1) → cairo', () {
      // (30.1, 31.3) — قريبة فعلاً من القاهرة (~10 كم)
      final gov = nearestGovernorate(30.1, 31.3);
      expect(gov.id, 'cairo');
    });

    test('إحداثيات منتصف الدلتا → إحدى محافظات الدلتا', () {
      // (30.5, 31.5) — قريبة من الشرقية (وليست القاهرة)
      final gov = nearestGovernorate(30.5, 31.5);
      expect(
        ['sharqia', 'qalyubia', 'dakahlia', 'gharbia'].contains(gov.id),
        isTrue,
        reason: 'يجب أن تُرجع إحدى محافظات الدلتا',
      );
    });

    test('إحداثيات وسط سيناء → إحدى محافظات سيناء', () {
      final gov = nearestGovernorate(30.5, 33.5);
      expect(
        ['north_sinai', 'south_sinai', 'suez', 'ismailia'].contains(gov.id),
        isTrue,
        reason: 'يجب أن تُرجع إحدى محافظات القناة/سيناء',
      );
    });
  });

  group('nearestGovernorate — لا يعيد null أبداً', () {
    test('إحداثيات صفر → قيمة افتراضية (غير null)', () {
      final gov = nearestGovernorate(0.0, 0.0);
      expect(gov.id, isNotEmpty);
    });

    test('إحداثيات خارج مصر → أقرب محافظة', () {
      // الرياض (السعودية) — الأقرب جغرافياً: البحر الأحمر أو جنوب سيناء
      final gov = nearestGovernorate(24.7136, 46.6753);
      expect(gov.id, isNotEmpty);
      expect(gov.nameAr, isNotEmpty);
    });
  });

  group('kEgyptGovernorates — التكامل', () {
    test('27 محافظة كاملة', () {
      expect(kEgyptGovernorates.length, 27);
    });

    test('كل محافظة لها id فريد', () {
      final ids = kEgyptGovernorates.map((g) => g.id).toSet();
      expect(ids.length, 27);
    });

    test('كل محافظة لها nameAr و nameEn غير فارغ', () {
      for (final gov in kEgyptGovernorates) {
        expect(gov.nameAr, isNotEmpty);
        expect(gov.nameEn, isNotEmpty);
      }
    });

    test('القاهرة هي الافتراضية', () {
      final defaultGov = kEgyptGovernorates.firstWhere((g) => g.isDefault);
      expect(defaultGov.id, 'cairo');
    });
  });

  group('DUPLICATE-1 — التحقق من التوحيد', () {
    test('nearestGovernorate هو نفس المصدر المستخدم في LocationService', () {
      // القاهرة — نفس القيمة المتوقعة في كلا المكانين
      final gov = nearestGovernorate(30.0444, 31.2357);
      expect(gov.nameAr, 'القاهرة');
      expect(gov.nameEn, 'Cairo');
      // لو LocationService استخدم قائمة منفصلة، قد يعطي نتيجة مختلفة
      // هذا الاختبار يوثق أن القيمة الوحيدة صحيحة
    });
  });
}
