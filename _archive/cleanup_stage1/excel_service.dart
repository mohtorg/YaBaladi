import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart'; // ✅ الحزمة الجديدة
import '../models/place_model.dart';

class ExcelParseResult {
  final List<PlaceModel> validPlaces;
  final List<String> errors;

  ExcelParseResult({required this.validPlaces, required this.errors});
}

class ExcelService {
  // ─────────────────────────────────────────────────────────────
  // 1. توليد وتحميل القالب (Template Generator & Downloader)
  // ─────────────────────────────────────────────────────────────
  Future<void> generateAndDownloadTemplate() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Places'];

      sheet.appendRow([
        TextCellValue('name_ar'),
        TextCellValue('name_en'),
        TextCellValue('description'),
        TextCellValue('category'),
        TextCellValue('governorate'),
        TextCellValue('district'),
        TextCellValue('address'),
        TextCellValue('latitude'),
        TextCellValue('longitude'),
        TextCellValue('map_url'),
      ]);

      sheet.appendRow([
        TextCellValue('فنار بورسعيد القديم'),
        TextCellValue('Port Said Lighthouse'),
        TextCellValue('أول فنار في العالم يبنى بالخرسانة المسلحة...'),
        TextCellValue('تاريخي'),
        TextCellValue('بورسعيد'),
        TextCellValue('حي الشرق'),
        TextCellValue('شارع فلسطين، عند مدخل القناة'),
        DoubleCellValue(31.263889),
        DoubleCellValue(32.311667),
        TextCellValue('https://maps.google.com/?q=31.263889,32.311667'),
      ]);

      final bytes = excel.save();
      if (bytes == null) throw Exception('فشل في إنشاء ملف الإكسل');

      await FileSaver.instance.saveFile(
        name: 'Y_Baladi_Places_Template',
        bytes: Uint8List.fromList(bytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      throw Exception('حدث خطأ أثناء توليد القالب: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. اختيار الملف وقراءته والتحقق منه (File Parser)
  // ─────────────────────────────────────────────────────────────
  Future<ExcelParseResult?> pickAndParseExcel() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return null;

      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);

      final List<PlaceModel> validPlaces = [];
      final List<String> errors = [];

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.maxRows < 2) continue;

        final firstRow = sheet.rows[0];
        if (firstRow.isEmpty || firstRow[0]?.value?.toString() != 'name_ar') {
          errors.add(
              'تنبيه: الملف المرفوع لا يطابق قالب "يا بلدي". تأكد من استخدام القالب الصحيح.');
          continue;
        }

        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];

          if (row.isEmpty ||
              row.every((cell) => cell == null || cell.value == null)) {
            continue;
          }

          final place = PlaceModel.fromExcelRow(row);

          if (place.isValid) {
            validPlaces.add(place);
          } else {
            errors.add('السطر ${i + 1}: ${place.validationError}');
          }
        }
      }

      return ExcelParseResult(validPlaces: validPlaces, errors: errors);
    } catch (e) {
      throw Exception(
          'حدث خطأ أثناء قراءة الملف. تأكد من أن الملف بصيغة xlsx صحيحة وغير تالف. ($e)');
    }
  }
}
