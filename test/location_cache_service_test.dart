import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yabaladi_rebuild/services/location_cache_service.dart';
import 'package:yabaladi_rebuild/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationCacheService', () {
    test('يحفظ ويقرأ LocationData بشكل صحيح', () async {
      const data = LocationData(
        latitude: 31.258,
        longitude: 32.262,
        nameAr: 'الشرق، بورسعيد',
        accuracyMeters: 5.0,
      );

      await LocationCacheService.save(data);
      final loaded = await LocationCacheService.load();

      expect(loaded, isNotNull);
      expect(loaded!.latitude, 31.258);
      expect(loaded.longitude, 32.262);
      expect(loaded.nameAr, 'الشرق، بورسعيد');
      expect(loaded.accuracyMeters, 5.0);
    });

    test('يرفض cache التالف (0,0)', () async {
      SharedPreferences.setMockInitialValues({
        'loc_cache_lat': 0.0,
        'loc_cache_lng': 0.0,
        'loc_cache_timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final loaded = await LocationCacheService.load();
      expect(loaded, isNull);
    });

    test('clear() يمسح كل البيانات', () async {
      const data = LocationData(latitude: 30.0, longitude: 31.0);
      await LocationCacheService.save(data);

      await LocationCacheService.clear();
      final loaded = await LocationCacheService.load();
      expect(loaded, isNull);
    });
  });
}
