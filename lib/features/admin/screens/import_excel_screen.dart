// lib/features/admin/screens/import_excel_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/design_tokens.dart';
import '../services/excel_import_service.dart';

class ImportExcelScreen extends StatefulWidget {
  const ImportExcelScreen({super.key});

  @override
  State<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends State<ImportExcelScreen> {
  final _service = ExcelImportService();
  bool _loading = false;
  int _current = 0;
  int _total = 0;
  ExcelImportResult? _result;

  Future<void> _pickAndUpload() async {
    setState(() {
      _loading = true;
      _result = null;
      _current = 0;
      _total = 0;
    });

    try {
      // 1. اختيار ملف CSV
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (picked == null || picked.files.first.bytes == null) {
        setState(() => _loading = false);
        return;
      }

      // 2. قراءة الملف
      final bytes = picked.files.first.bytes!;
      final rows = await _service.parseCsv(bytes);

      if (rows.isEmpty) {
        _showSnack('الملف فارغ أو غير صالح', Colors.red);
        setState(() => _loading = false);
        return;
      }

      setState(() => _total = rows.length);

      // 3. الرفع مع متابعة التقدم
      final result = await _service.uploadToFirestore(
        rows,
        onProgress: (current, total) => setState(() => _current = current),
      );

      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      _showSnack('خطأ: $e', Colors.red);
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('استيراد الأماكن (CSV)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── بطاقة التعليمات ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'كيفية تحضير الملف',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. أنشئ الملف في Excel',
                  style: TextStyle(fontSize: 13),
                ),
                const Text(
                  '2. الصف الأول = أسماء الأعمدة (nameAr, nameEn, ...)',
                  style: TextStyle(fontSize: 13),
                ),
                const Text(
                  '3. احفظ الملف بصيغة CSV (Comma delimited)',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحقول الإلزامية:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'nameAr, categoryId, governorate, latitude, longitude',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── زر الرفع ───
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _loading ? null : _pickAndUpload,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _loading ? 'جاري الرفع...' : 'اختر ملف CSV للرفع',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: YaBaladiDesignTokens.primaryBlue,
              ),
            ),
          ),

          // ─── مؤشر التقدم ───
          if (_loading && _total > 0) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _current / _total,
              backgroundColor: Colors.grey.shade200,
              color: YaBaladiDesignTokens.primaryBlue,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$_current / $_total صف',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],

          // ─── النتيجة ───
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result!.failCount == 0
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _result!.failCount == 0
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.failCount == 0
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _result!.failCount == 0
                            ? Colors.green
                            : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _result!.failCount == 0
                            ? 'تم الرفع بنجاح'
                            : 'تم الرفع مع أخطاء',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('✅ نجح: ${_result!.successCount} مكان'),
                  if (_result!.failCount > 0) ...[
                    const SizedBox(height: 4),
                    Text('❌ فشل: ${_result!.failCount} صف'),
                    const SizedBox(height: 8),
                    const Text(
                      'الأخطاء:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...(_result!.errors.take(10).map(
                          (e) => Text(
                            '• $e',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                    if (_result!.errors.length > 10)
                      Text(
                        '... و ${_result!.errors.length - 10} خطأ آخر',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
