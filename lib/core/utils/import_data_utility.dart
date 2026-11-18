// lib/core/utils/import_data_utility.dart
// [v1.3] — CONTROL CENTER SUPPORT: Added parentId to allow auto-linking during import from UI.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ImportDataUtility {
  /// دالة لاختيار ملف CSV ورفعه إلى Firestore
  static Future<void> importCsvToFirestore({
    required String collectionName,
    required bool isDistrictCollection, // true للأحياء، false للمناطق
    String? parentId, // ✅ المعرف الأب (المحافظة أو الحي) للربط التلقائي
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // ضروري للويب
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('لم يتم اختيار ملف');
        return;
      }

      final file = result.files.single;
      String csvString = '';

      // دعم الويب (bytes) والموبايل (path)
      if (kIsWeb && file.bytes != null) {
        csvString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        if (file.bytes != null) {
          csvString = utf8.decode(file.bytes!);
        }
      }

      if (csvString.isEmpty) {
        debugPrint('الملف فارغ أو غير مدعوم');
        return;
      }

      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvString);
      final dataRows = rows.skip(1); // تجاهل العناوين

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      int totalImported = 0;

      for (var row in dataRows) {
        if (row.isEmpty) continue;

        // ✅ نستخدم الـ parentId إذا تم تمريره من الواجهة (شاشة التحكم)
        // وإلا نعتمد على العمود الرابع في ملف الـ CSV
        final String resolvedParentId = parentId ?? row[3].toString();

        final Map<String, dynamic> data = {
          'nameAr': row[1].toString(),
          'nameEn': row[2].toString(),
          isDistrictCollection ? 'governorateId' : 'districtId':
              resolvedParentId,
          'isActive': row[4].toString().toLowerCase() == 'true',
        };

        final docRef = FirebaseFirestore.instance
            .collection(collectionName)
            .doc(row[0].toString());

        batch.set(docRef, data);
        count++;
        totalImported++;

        if (count == 500) {
          await batch.commit();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      debugPrint('✅ تم رفع $totalImported وثيقة بنجاح إلى $collectionName');
    } catch (e) {
      debugPrint('❌ خطأ أثناء رفع البيانات: $e');
    }
  }
}
