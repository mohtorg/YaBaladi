// test/trip_repository_test.dart
//
// اختبارات Wave 1a: R1 fix
//   - buildUpdateMap لا يحتوي createdAt (لا يُستبدل عند التحديث)
//   - buildUpdateMap يحتوي updatedAt = FieldValue
//   - بقية الحقول محفوظة

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/models/trip_plan.dart';
import 'package:yabaladi_rebuild/repositories/trip_repository.dart';

void main() {
  // ─── مساعد: يبني TripPlan كامل ───
  TripPlan buildPlan({
    String id = 'trip1',
    DateTime? createdAt,
  }) {
    return TripPlan(
      id: id,
      userId: 'u1',
      title: 'رحلة القاهرة',
      governorateId: 'cairo',
      governorateNameAr: 'القاهرة',
      transportMode: TripTransportMode.walking,
      durationType: TripDurationType.weekend,
      interests: const ['cafes', 'landmarks'],
      status: TripStatus.active,
      stops: const [],
      totalDistanceKm: 5.5,
      totalDurationMin: 120,
      createdAt: createdAt,
    );
  }

  group('TripRepository.buildUpdateMap — R1 fix', () {
    test('لا يحتوي createdAt — يبقى كما هو في Firestore', () {
      final trip = buildPlan(createdAt: DateTime(2026, 10, 15));
      final data = TripRepository.buildUpdateMap(trip);
      expect(data.containsKey('createdAt'), isFalse);
    });

    test('لا يحتوي createdAt حتى لو كان null', () {
      final trip = buildPlan(); // createdAt = null
      final data = TripRepository.buildUpdateMap(trip);
      expect(data.containsKey('createdAt'), isFalse);
    });

    test('يحتوي updatedAt = FieldValue (serverTimestamp)', () {
      final trip = buildPlan();
      final data = TripRepository.buildUpdateMap(trip);
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('بقية الحقول محفوظة كما هي', () {
      final trip = buildPlan();
      final data = TripRepository.buildUpdateMap(trip);
      expect(data['userId'], 'u1');
      expect(data['title'], 'رحلة القاهرة');
      expect(data['governorateId'], 'cairo');
      expect(data['governorateNameAr'], 'القاهرة');
      expect(data['status'], 'active');
      expect(data['transportMode'], 'walking');
      expect(data['durationType'], 'weekend');
      expect(data['interests'], const ['cafes', 'landmarks']);
      expect(data['totalDistanceKm'], 5.5);
      expect(data['totalDurationMin'], 120);
    });

    test('toMap() الأصلي لا يزال يحتوي createdAt (لا تغيير في النموذج)', () {
      final trip = buildPlan(createdAt: DateTime(2026, 10, 15));
      final data = trip.toMap();
      expect(data.containsKey('createdAt'), isTrue);
    });
  });
}
