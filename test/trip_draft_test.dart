// test/models/trip_draft_test.dart
//
// اختبارات TripDraft — القيم الافتراضية + JSON + defensive parsing.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/models/trip_draft.dart';
import 'package:yabaladi_rebuild/models/trip_plan.dart';

void main() {
  group('TripDraft — defaults', () {
    test('empty() يُنشئ مسودة نظيفة', () {
      final d = TripDraft.empty('user1');
      expect(d.userId, 'user1');
      expect(d.currentStep, 0);
      expect(d.governorateId, isNull);
      expect(d.durationType, TripDurationType.fullDay);
      expect(d.transportMode, TripTransportMode.driving);
      expect(d.interests, isEmpty);
      expect(d.title, '');
      expect(d.isEmpty, isTrue);
      expect(d.hasProgress, isFalse);
    });
  });

  group('TripDraft — JSON round-trip', () {
    test('حفظ + قراءة كاملَي البيانات', () {
      final now = DateTime(2026, 10, 20, 14, 30);
      final d = TripDraft(
        userId: 'abc',
        currentStep: 2,
        governorateId: 'cairo',
        durationType: TripDurationType.weekend,
        transportMode: TripTransportMode.transit,
        interests: const ['cafes', 'landmarks'],
        title: 'رحلة القاهرة',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        savedAt: now,
      );
      final back = TripDraft.fromJson(d.toJson());
      expect(back.userId, 'abc');
      expect(back.currentStep, 2);
      expect(back.governorateId, 'cairo');
      expect(back.durationType, TripDurationType.weekend);
      expect(back.transportMode, TripTransportMode.transit);
      expect(back.interests, const ['cafes', 'landmarks']);
      expect(back.title, 'رحلة القاهرة');
      expect(back.startDate, now);
      expect(back.endDate, now.add(const Duration(days: 1)));
    });
  });

  group('TripDraft — defensive parsing', () {
    test('JSON فارغ → القيم الافتراضية', () {
      final d = TripDraft.fromJson(<String, dynamic>{});
      expect(d.userId, 'guest');
      expect(d.currentStep, 0);
      expect(d.durationType, TripDurationType.fullDay);
      expect(d.interests, isEmpty);
    });

    test('تواريخ بصيغة غير صحيحة → null', () {
      final d = TripDraft.fromJson(<String, dynamic>{
        'userId': 'u',
        'startDate': 'not-a-date',
      });
      expect(d.startDate, isNull);
    });

    test('codes غير معروفة → القيم الافتراضية', () {
      final d = TripDraft.fromJson(<String, dynamic>{
        'userId': 'u',
        'durationType': 'weird_code',
        'transportMode': 'unknown',
      });
      expect(d.durationType, TripDurationType.fullDay);
      expect(d.transportMode, TripTransportMode.driving);
    });
  });

  group('TripDraft — generatedPlan decoding', () {
    test('generatedPlanJson غير موجود → null', () {
      final d = TripDraft.empty('u');
      expect(d.generatedPlan, isNull);
    });

    test('JSON غير صالح → null (لا رمي استثناء)', () {
      const d = TripDraft(
        userId: 'u',
        generatedPlanJson: '{not-json',
      );
      expect(d.generatedPlan, isNull);
    });

    test('JSON صالح → TripPlan مستعاد', () {
      // ⚠️ ملاحظة: TripPlan.toMap() يستخدم FieldValue.serverTimestamp()
      // و Timestamp — وهما غير قابلَين لـ JSON.
      // لهذا نستخدم JSON يدوي يماثل شكل TripPlan في Firestore.
      const manualJson = <String, dynamic>{
        'userId': 'u',
        'title': 'test',
        'governorateId': 'cairo',
        'governorateNameAr': 'القاهرة',
        'transportMode': 'driving',
        'durationType': 'full_day',
        'interests': <String>[],
        'status': 'draft',
        'stops': <Map<String, dynamic>>[],
        'totalDistanceKm': 0.0,
        'totalDurationMin': 0,
      };
      final json = jsonEncode(manualJson);
      final d = TripDraft(userId: 'u', generatedPlanJson: json);
      final restored = d.generatedPlan;
      expect(restored, isNotNull);
      expect(restored!.title, 'test');
      expect(restored.governorateId, 'cairo');
      expect(restored.transportMode, TripTransportMode.driving);
      expect(restored.durationType, TripDurationType.fullDay);
    });
  });

  group('TripDraft — copyWith', () {
    test('يُغيّر حقلاً دون تأثير على الباقي', () {
      const d = TripDraft(
        userId: 'u',
        currentStep: 1,
        governorateId: 'cairo',
      );
      final d2 = d.copyWith(currentStep: 2);
      expect(d2.currentStep, 2);
      expect(d2.userId, 'u');
      expect(d2.governorateId, 'cairo');
    });
  });
}
