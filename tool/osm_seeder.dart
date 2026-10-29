import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

void main() async {
  print('🌍 بدء الاتصال بـ Overpass API لجلب الأماكن في بورسعيد...');

  // استعلام Overpass QL
  final query = '''
    [out:json][timeout:90];
    (
      node["amenity"~"restaurant|cafe|fast_food"](31.20,32.25,31.30,32.40);
      node["tourism"~"attraction|museum"](31.20,32.25,31.30,32.40);
    );
    out body;
  ''';

  // قائمة السيرفرات البديلة (الأكثر استقراراً أولاً)
  final List<String> endpoints = [
    'https://z.overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass-api.de/api/interpreter',
  ];

  // إنشاء عميل HTTP يتجاهل أخطاء الشهادة (لتفادي مشكلة maps.mail.ru)
  final ioClient = IOClient(
    HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true,
  );

  bool success = false;
  List? elements;

  for (String endpoint in endpoints) {
    print('⏳ محاولة الاتصال بـ: $endpoint');
    try {
      // نستخدم http.Client العادي أولاً، وإذا فشل نجرب IOClient
      final response = await http.post(
        Uri.parse(endpoint),
        body: {'data': query},
        headers: {'User-Agent': 'YaBaladi-Seeder/1.0 (contact@yabaladi.com)'},
      ).timeout(const Duration(seconds: 90)); // مهلة 90 ثانية

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        elements = data['elements'] as List;
        success = true;
        print('✅ تم الاتصال بنجاح بالسيرفر!');
        break;
      } else {
        print('⚠️ فشل السيرفر برمز: ${response.statusCode}، جاري تجربة السيرفر التالي...');
      }
    } catch (e) {
      print('⚠️ خطأ في السيرفر ($e)، جاري تجربة السيرفر التالي...');
    }
  }

  // إذا فشلت جميع السيرفرات العادية، نجرب maps.mail.ru مع تجاهل الشهادة
  if (!success) {
    print('⏳ محاولة أخيرة مع سيرفر maps.mail.ru (مع تجاهل الشهادة)...');
    try {
      final response = await ioClient.post(
        Uri.parse('https://maps.mail.ru/osm/tools/overpass/api/interpreter'),
        body: {'data': query},
        headers: {'User-Agent': 'YaBaladi-Seeder/1.0'},
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        elements = data['elements'] as List;
        success = true;
        print('✅ تم الاتصال بنجاح عبر maps.mail.ru!');
      } else {
        print('⚠️ maps.mail.ru فشل أيضاً برمز: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ maps.mail.ru فشل: $e');
    }
  }

  if (!success || elements == null) {
    print('❌ فشل الاتصال بجميع السيرفرات. يرجى المحاولة لاحقاً.');
    print('💡 نصيحة: يمكنك تجربة تشغيل السكريبت عبر VPN أو تغيير شبكة الإنترنت.');
    return;
  }

  print('✅ تم العثور على ${elements.length} مكان. جاري التنظيف...');

  final List<Map<String, dynamic>> cleanedPlaces = [];

  for (var element in elements) {
    final tags = element['tags'] as Map<String, dynamic>?;
    if (tags == null) continue;

    final name = tags['name:ar'] ?? tags['name'];
    if (name == null || name.toString().trim().isEmpty) {
      continue; // تجاهل الأماكن بدون اسم
    }

    final phone = tags['contact:phone'] ?? tags['phone'] ?? '';

    String category = 'other';
    if (tags['amenity'] == 'restaurant' || tags['amenity'] == 'fast_food') category = 'restaurant';
    if (tags['amenity'] == 'cafe') category = 'cafe';
    if (tags['tourism'] == 'attraction' || tags['tourism'] == 'museum') category = 'attraction';

    cleanedPlaces.add({
      'osm_id': element['id'].toString(),
      'name': name.toString(),
      'name_en': tags['name:en']?.toString() ?? '',
      'category': category,
      'phone': phone.toString(),
      'website': tags['website']?.toString() ?? '',
      'latitude': element['lat'],
      'longitude': element['lon'],
      'address': tags['addr:street']?.toString() ?? '',
      'governorate': 'بورسعيد',
      'source': 'OpenStreetMap',
      'is_active': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  print('🧹 تم تنظيف البيانات. الأماكن الصالحة: ${cleanedPlaces.length}');

  final file = File('port_said_osm_data.json');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(cleanedPlaces));

  print('💾 تم حفظ البيانات في ملف: port_said_osm_data.json');
  print('👉 راجع الملف، وإذا كان جاهزاً، سنقوم برفعه إلى Firebase في الخطوة التالية.');
}