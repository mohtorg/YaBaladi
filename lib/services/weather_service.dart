// services/weather_service.dart
// الغرض: جلب الطقس الفعلي للمحافظة المختارة بدل وضع رقم ثابت داخل التصميم.
// المصدر الحالي Open-Meteo لا يحتاج مفتاح API، ونرسل إحداثيات مركز المحافظة.
// مهم: الرقم المعروض هو قراءة لحظية تقريبية لمركز المحافظة، وليس قياسًا من حساس الهاتف.
// عند فشل الشبكة نعرض "غير متاح" ولا نخترع درجة حرارة.

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  final double temperatureC;
  final int weatherCode;

  const WeatherSnapshot({required this.temperatureC, required this.weatherCode});

  String get conditionAr {
    switch (weatherCode) {
      case 0:
        return 'صافي';
      case 1:
      case 2:
      case 3:
        return 'غائم جزئيًا';
      case 45:
      case 48:
        return 'ضباب';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'رذاذ';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return 'أمطار';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'ثلوج';
      case 80:
      case 81:
      case 82:
        return 'زخات مطر';
      case 95:
      case 96:
      case 99:
        return 'عواصف رعدية';
      default:
        return 'الطقس الآن';
    }
  }
}

class WeatherService {
  static const Map<String, ({double lat, double lng})> _centers = {
    'cairo': (lat: 30.0444, lng: 31.2357),
    'alexandria': (lat: 31.2001, lng: 29.9187),
    'port_said': (lat: 31.2653, lng: 32.3019),
    'suez': (lat: 29.9668, lng: 32.5498),
    'dakahlia': (lat: 31.0409, lng: 31.3785),
    'sharqia': (lat: 30.7327, lng: 31.7195),
    'qalyubia': (lat: 30.1790, lng: 31.2143),
    'kafr_el_sheikh': (lat: 31.1107, lng: 30.9388),
    'gharbia': (lat: 30.7865, lng: 31.0004),
    'monufia': (lat: 30.5972, lng: 30.9876),
    'beheira': (lat: 30.8481, lng: 30.3436),
    'ismailia': (lat: 30.5965, lng: 32.2715),
    'damietta': (lat: 31.4175, lng: 31.8144),
    'giza': (lat: 30.0131, lng: 31.2089),
    'faiyum': (lat: 29.3084, lng: 30.8428),
    'beni_suef': (lat: 29.0661, lng: 31.0994),
    'minya': (lat: 28.1099, lng: 30.7503),
    'asyut': (lat: 27.1809, lng: 31.1837),
    'sohag': (lat: 26.5591, lng: 31.6957),
    'qena': (lat: 26.1551, lng: 32.7160),
    'luxor': (lat: 25.6872, lng: 32.6396),
    'aswan': (lat: 24.0889, lng: 32.8998),
    'red_sea': (lat: 27.2579, lng: 33.8116),
    'new_valley': (lat: 25.4416, lng: 30.5586),
    'matrouh': (lat: 31.3543, lng: 27.2373),
    'north_sinai': (lat: 31.0409, lng: 33.0116),
    'south_sinai': (lat: 27.2579, lng: 33.8116),
  };

  Future<WeatherSnapshot?> getCurrent(String governorateId) async {
    final center = _centers[governorateId];
    if (center == null) return null;
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': center.lat.toString(),
      'longitude': center.lng.toString(),
      'current': 'temperature_2m,weather_code',
      'temperature_unit': 'celsius',
      'timezone': 'Africa/Cairo',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      if (current == null) return null;
      final temp = (current['temperature_2m'] as num?)?.toDouble();
      final code = (current['weather_code'] as num?)?.toInt();
      if (temp == null || code == null) return null;
      return WeatherSnapshot(temperatureC: temp, weatherCode: code);
    } catch (_) {
      return null;
    }
  }
}
