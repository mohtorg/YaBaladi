// lib/features/admin/services/excel_import_service.dart
// [v3.3.0 — 2026-11-08] — FIXED: Default priceLevel to 1 to prevent UI Dropdown crashes.

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

// ✅ كلاس جديد لإرجاع نتيجة الفرز بالتفصيل
class ParseResult {
  final List<Map<String, dynamic>> validPlaces;
  final List<String> errors;
  ParseResult({required this.validPlaces, required this.errors});
}

class ExcelImportResult {
  final int successCount;
  final int failCount;
  final List<String> errors;

  const ExcelImportResult({
    required this.successCount,
    required this.failCount,
    required this.errors,
  });
}

class ExcelImportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> generateAndDownloadTemplate() async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['معالم بورسعيد'];
    excel.setDefaultSheet('معالم بورسعيد');

    final List<String> headers = [
      'name',
      'name_en',
      'description',
      'categoryId',
      'governorate',
      'geoZoneName',
      'address',
      'map_url',
      'longitude',
      'latitude',
      'phone',
      'website',
      'email',
      'facebook',
      'priceLevel',
      'hasWifi',
      'hasParking',
      'hasRestroom',
      'hasAccessibility',
      'isFamilyFriendly',
      'hasShade',
      'hasDelivery',
      'hasReservation',
      'tags',
      'is_active'
    ];

    for (int i = 0; i < headers.length; i++) {
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // ✅ تم تغيير السعر إلى 1 في المثال
    final List<CellValue?> exampleRow = [
      TextCellValue('فنار بورسعيد القديم'),
      TextCellValue('Port Said Lighthouse'),
      TextCellValue('منارة مثمنة...'),
      TextCellValue('landmarks'),
      TextCellValue('بورسعيد'),
      TextCellValue('حي الشرق'),
      TextCellValue('شارع فلسطين'),
      TextCellValue('https://maps.google.com/?q=31.263889,32.311667'),
      DoubleCellValue(32.311667),
      DoubleCellValue(31.263889),
      TextCellValue('01000000000'),
      TextCellValue('https://example.com'),
      TextCellValue('info@example.com'),
      TextCellValue('https://facebook.com/example'),
      IntCellValue(1), // ✅ السعر 1
      BoolCellValue(false),
      BoolCellValue(false),
      BoolCellValue(false),
      BoolCellValue(false),
      BoolCellValue(true),
      BoolCellValue(false),
      BoolCellValue(false),
      BoolCellValue(false),
      TextCellValue('تاريخي, فنار'),
      BoolCellValue(true)
    ];

    for (int i = 0; i < exampleRow.length; i++) {
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          .value = exampleRow[i];
    }

    final List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.instance.saveFile(
        name: 'yabaladi_places_template',
        bytes: Uint8List.fromList(fileBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }
  }

  Future<ParseResult> parseExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, dynamic>> validPlaces = [];
    final List<String> errors = [];

    if (excel.tables.isEmpty) {
      errors.add('الملف فارغ أو غير صالح.');
      return ParseResult(validPlaces: validPlaces, errors: errors);
    }

    final table = excel.tables[excel.tables.keys.first];
    if (table == null || table.rows.isEmpty) {
      errors.add('الورقة الأولى فارغة.');
      return ParseResult(validPlaces: validPlaces, errors: errors);
    }

    final rows = table.rows;
    final headers = rows[0]
        .map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
        .toList();
    int getIndex(String name) => headers.indexOf(name.toLowerCase());

    if (getIndex('name') == -1) {
      errors.add('العمود "name" (اسم المكان) غير موجود في الملف.');
      return ParseResult(validPlaces: validPlaces, errors: errors);
    }

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String getCell(String name) {
        final int idx = getIndex(name);
        if (idx == -1 || row.length <= idx) return '';
        return row[idx]?.value?.toString().trim() ?? '';
      }

      bool getBool(String name) {
        final v = getCell(name).toLowerCase();
        return v == 'true' || v == '1' || v == 'نعم';
      }

      double? getDouble(String name) {
        final val = getCell(name);
        if (val.isEmpty) return null;
        return double.tryParse(val.replaceAll(',', '.'));
      }

      // ✅ التعديل هنا: القيمة الافتراضية 1، وإذا كانت 0 أو أقل نرجع 1
      int getInt(String name, {int defaultValue = 1}) {
        final val = getCell(name);
        if (val.isEmpty) return defaultValue;
        final parsed = int.tryParse(val);
        if (parsed == null || parsed < 1) return defaultValue;
        return parsed;
      }

      final name = getCell('name');
      final lat = getDouble('latitude');
      final lng = getDouble('longitude');

      if (name.isEmpty) {
        errors.add('السطر ${i + 1}: اسم المكان مفقود.');
        continue;
      }
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
        errors.add(
            '"$name" (السطر ${i + 1}): إحداثيات خط الطول أو العرض مفقودة.');
        continue;
      }

      // نطاق مصر التقريبي: يكشف تبديل خط الطول والعرض أو الأخطاء الكبيرة.
      if (lat < 21.5 || lat > 32.0 || lng < 24.5 || lng > 37.0) {
        errors.add(
            '"$name" (السطر ${i + 1}): الإحداثيات خارج نطاق مصر (تحقق من تبديل الطول والعرض).');
        continue;
      }

      validPlaces.add({
        'name': name,
        'name_en': getCell('name_en'),
        'description': getCell('description'),
        'category': getCell('category'),
        'categoryId':
            getCell('categoryid').isEmpty ? 'other' : getCell('categoryid'),
        'governorate': getCell('governorate'),
        'geoZoneName': getCell('geozonename'),
        'address': getCell('address'),
        'map_url': getCell('map_url'),
        'phone': getCell('phone'),
        'website': getCell('website'),
        'email': getCell('email'),
        'facebook': getCell('facebook'),
        'priceLevel': getInt('pricelevel'), // ✅ سيتم قراءتها بأمان
        'hasWifi': getBool('haswifi'),
        'hasParking': getBool('hasparking'),
        'hasRestroom': getBool('hasrestroom'),
        'hasAccessibility': getBool('hasaccessibility'),
        'isFamilyFriendly': getBool('isfamilyfriendly'),
        'hasShade': getBool('hasshade'),
        'hasDelivery': getBool('hasdelivery'),
        'hasReservation': getBool('hasreservation'),
        'tags': getCell('tags')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'latitude': lat,
        'longitude': lng,
        'is_active': getBool('is_active'),
        'isApproved': true,
        'addedBy': 'admin',
      });
    }
    return ParseResult(validPlaces: validPlaces, errors: errors);
  }

  Future<ExcelImportResult> uploadToFirestore(
    List<Map<String, dynamic>> rows, {
    void Function(int current, int total)? onProgress,
  }) async {
    int success = 0;
    int fail = 0;
    final errors = <String>[];
    const int batchSize = 450;

    for (int start = 0; start < rows.length; start += batchSize) {
      final end =
          (start + batchSize < rows.length) ? start + batchSize : rows.length;
      final chunk = rows.sublist(start, end);
      final batch = _db.batch();

      int chunkSuccess = 0;

      for (final row in chunk) {
        try {
          final lat = row['latitude'] as double? ?? 0.0;
          final lng = row['longitude'] as double? ?? 0.0;

          final docRef = _db.collection('places').doc();

          final docData = Map<String, dynamic>.from(row)
            ..remove('latitude')
            ..remove('longitude')
            ..['location'] = GeoPoint(lat, lng)
            ..['latitude'] = lat
            ..['longitude'] = lng
            ..['geohash'] = _encodeGeohash(lat, lng)
            ..['averageRating'] = 0.0
            ..['reviewCount'] = 0
            ..['imageUrls'] = <String>[]
            // الحقول التي يقرؤها التطبيق فعلاً (Place.fromMap والاستعلامات)،
            // وتُترك الأسماء القديمة للتوافق مع بقية الشاشات.
            ..['nameAr'] = row['name']
            ..['nameEn'] = row['name_en'] ?? ''
            ..['isActive'] = row['is_active'] ?? false
            ..['googleMapsUrl'] = row['map_url'] ?? ''
            ..['createdAt'] = FieldValue.serverTimestamp()
            ..['created_at'] = FieldValue.serverTimestamp()
            ..['updatedAt'] = FieldValue.serverTimestamp();

          batch.set(docRef, docData);
          chunkSuccess++;
        } catch (e) {
          errors.add('${row['name']}: $e');
          fail++;
        }
      }

      if (chunkSuccess > 0) {
        try {
          await batch.commit();
          success += chunkSuccess;
        } catch (e) {
          fail += chunkSuccess;
          errors.add('فشل حفظ الدفعة: $e');
        }
      }
      onProgress?.call(end, rows.length);
    }
    return ExcelImportResult(
        successCount: success, failCount: fail, errors: errors);
  }

  String _encodeGeohash(double latitude, double longitude,
      {int precision = 7}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var isEven = true;
    var bit = 0;
    var ch = 0;
    final sb = StringBuffer();
    var latMin = -90.0, latMax = 90.0, lonMin = -180.0, lonMax = 180.0;
    while (sb.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude > mid) {
          ch |= 1 << (4 - bit);
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude > mid) {
          ch |= 1 << (4 - bit);
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        sb.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return sb.toString();
  }
}
