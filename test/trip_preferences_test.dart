// test/models/trip_preferences_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/models/trip_plan.dart';
import 'package:yabaladi_rebuild/models/trip_preferences.dart';

void main() {
  group('TripPreferences — defaults', () {
    test('القيم الافتراضية صحيحة', () {
      const p = TripPreferences();
      expect(p.defaultTransportMode, TripTransportMode.driving);
      expect(p.defaultDurationType, TripDurationType.fullDay);
      expect(p.defaultInterests, isEmpty);
      expect(p.avoidPlaceIds, isEmpty);
      expect(p.preferFamilyFriendly, isFalse);
      expect(p.minRating, 0.0);
      expect(p.isDefault, isTrue);
    });
  });

  group('TripPreferences — validation', () {
    test('minRating > 5 → غير صالح', () {
      const p = TripPreferences(minRating: 6.0);
      expect(p.isValid, isFalse);
    });

    test('minRating سالب → غير صالح', () {
      const p = TripPreferences(minRating: -1.0);
      expect(p.isValid, isFalse);
    });

    test('minRating في النطاق → صالح', () {
      const p = TripPreferences(minRating: 4.5);
      expect(p.isValid, isTrue);
    });
  });

  group('TripPreferences — JSON round-trip', () {
    test('حفظ + قراءة', () {
      const original = TripPreferences(
        defaultTransportMode: TripTransportMode.walking,
        defaultDurationType: TripDurationType.weekend,
        defaultInterests: ['cafes'],
        avoidPlaceIds: ['place1'],
        preferFamilyFriendly: true,
        minRating: 4.0,
      );
      final back = TripPreferences.fromJson(original.toJson());
      expect(back.defaultTransportMode, TripTransportMode.walking);
      expect(back.defaultDurationType, TripDurationType.weekend);
      expect(back.defaultInterests, const ['cafes']);
      expect(back.avoidPlaceIds, const ['place1']);
      expect(back.preferFamilyFriendly, isTrue);
      expect(back.minRating, 4.0);
    });

    test('JSON به minRating غير صالح → القيم الافتراضية', () {
      final back =
          TripPreferences.fromJson(<String, dynamic>{'minRating': 10.0});
      expect(back.isDefault, isTrue);
    });

    test('JSON فارغ → القيم الافتراضية', () {
      final back = TripPreferences.fromJson(<String, dynamic>{});
      expect(back.isDefault, isTrue);
    });
  });

  group('TripPreferences — copyWith', () {
    test('تعديل minRating فقط', () {
      const p = TripPreferences();
      final p2 = p.copyWith(minRating: 4.5);
      expect(p2.minRating, 4.5);
      expect(p2.defaultTransportMode, TripTransportMode.driving);
    });
  });
}
