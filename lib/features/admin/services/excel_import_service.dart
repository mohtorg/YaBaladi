// lib/features/admin/services/excel_import_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart'; // ✅ مكتبة csv

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

  /// قراءة ملف CSV وإرجاع قائمة صفوف
  Future<List<Map<String, dynamic>>> parseCsv(Uint8List bytes) async {
    // فك ترميز UTF-8 (يدعم العربية)
    final content = utf8.decode(bytes, allowMalformed: true);
    final csvData = const CsvToListConverter(
      fieldDelimiter: ',',
      eol: '\n',
    ).convert(content);

    if (csvData.isEmpty) return [];

    final List<Map<String, dynamic>> rows = [];

    // تخطي الصف الأول (العناوين)
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      String _cell(int idx) =>
          row.length > idx ? row[idx]?.toString().trim() ?? '' : '';
      bool _bool(int idx) {
        final v = _cell(idx).toLowerCase();
        return v == 'true' || v == '1' || v == 'نعم';
      }

      double? _double(int idx) => double.tryParse(_cell(idx));

      final nameAr = _cell(0);
      if (nameAr.isEmpty) continue;

      rows.add({
        'nameAr': nameAr,
        'nameEn': _cell(1),
        'categoryId': _cell(2).isEmpty ? 'other' : _cell(2),
        'governorate': _cell(3),
        'city': _cell(4),
        'address': _cell(5),
        'latitude': _double(6),
        'longitude': _double(7),
        'phone': _cell(8),
        'website': _cell(9),
        'description': _cell(10),
        'tags': _cell(11)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'hasWifi': _bool(12),
        'hasParking': _bool(13),
        'hasRestroom': _bool(14),
        'hasAccessibility': _bool(15),
        'isFamilyFriendly': _bool(16),
        'isHalal': _bool(17),
        'hasDelivery': _bool(18),
        'hasReservation': _bool(19),
        'isApproved': _bool(20),
        'isActive': _bool(21),
        'addedBy': _cell(22).isEmpty ? 'admin' : _cell(22),
      });
    }
    return rows;
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

      for (final row in chunk) {
        try {
          final lat = row['latitude'] as double?;
          final lng = row['longitude'] as double?;
          if (lat == null || lng == null) {
            errors.add('${row['nameAr']}: إحداثيات مفقودة');
            fail++;
            continue;
          }

          final docRef = _db.collection('places').doc();
          final docData = Map<String, dynamic>.from(row)
            ..remove('latitude')
            ..remove('longitude')
            ..['location'] = GeoPoint(lat, lng)
            ..['geohash'] = _encodeGeohash(lat, lng)
            ..['averageRating'] = 0.0
            ..['reviewCount'] = 0
            ..['imageUrls'] = <String>[]
            ..['createdAt'] = FieldValue.serverTimestamp()
            ..['updatedAt'] = FieldValue.serverTimestamp();

          batch.set(docRef, docData);
          success++;
        } catch (e) {
          errors.add('${row['nameAr']}: $e');
          fail++;
        }
      }
      await batch.commit();
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
