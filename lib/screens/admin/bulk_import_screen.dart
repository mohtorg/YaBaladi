// lib/screens/admin/bulk_import_screen.dart
// [v3.2.0] — ADDED: Detailed UI for parsing results with visual checkmarks.

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:yabaladi_rebuild/features/admin/services/excel_import_service.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final ExcelImportService _excelService = ExcelImportService();

  bool _isLoading = false;
  String _statusMessage = '';
  bool _isError = false;

  ParseResult? _parseResult;

  Future<void> _downloadTemplate() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري تحضير القالب وتحميله...';
      _isError = false;
    });

    try {
      await _excelService.generateAndDownloadTemplate();
      if (!mounted) return;
      setState(() => _statusMessage = 'تم تحميل القالب بنجاح!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'حدث خطأ: $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndParseFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري قراءة الملف والتحقق من البيانات...';
      _isError = false;
      _parseResult = null;
    });

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'تم إلغاء اختيار الملف.';
          _isLoading = false;
        });
        return;
      }

      final Uint8List bytes = result.files.single.bytes!;

      // ✅ هنا نستقبل نتيجة الفرز التفصيلية
      final parsedData = await _excelService.parseExcel(bytes);

      if (!mounted) return;

      setState(() {
        _parseResult = parsedData;
        if (parsedData.validPlaces.isEmpty) {
          _statusMessage =
              'لم يتم العثور على أي بيانات صالحة للرفع. يرجى مراجعة الأخطاء أدناه.';
          _isError = true;
        } else {
          _statusMessage =
              'تم قراءة الملف بنجاح. يرجى مراجعة الأماكن المقبولة والمرفوضة.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'حدث خطأ أثناء القراءة: $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadToFirestore() async {
    if (_parseResult == null || _parseResult!.validPlaces.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري رفع البيانات إلى قاعدة البيانات...';
      _isError = false;
    });

    try {
      final result =
          await _excelService.uploadToFirestore(_parseResult!.validPlaces);

      if (!mounted) return;

      final String finalMsg = '🎉 تم رفع ${result.successCount} معلم بنجاح!'
          '${result.failCount > 0 ? '\n⚠️ فشل رفع ${result.failCount} معلم.' : ''}';

      setState(() {
        _statusMessage = finalMsg;
        _isError = result.failCount > 0;
        _parseResult = null;
      });

      if (result.successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت عملية الرفع المجمع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'حدث خطأ أثناء الرفع: $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('إدارة المعالم (رفع مجمع)'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.table_view, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'قم بتحميل القالب، تعبئته، ثم رفعه لفرز البيانات.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildActionButton(
              icon: Icons.download,
              label: '1. تحميل قالب الإكسل',
              color: Colors.blue,
              onPressed: _isLoading ? null : _downloadTemplate,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.upload_file,
              label: '2. اختيار ملف الإكسل ومراجعته',
              color: Colors.orange,
              onPressed: _isLoading ? null : _pickAndParseFile,
            ),
            const SizedBox(height: 30),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_statusMessage.isNotEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _isError ? Colors.red : Colors.green),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isError ? Colors.red : Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (_parseResult != null) _buildDetailedResultCard(),
            const SizedBox(height: 20),
            if (_parseResult != null && _parseResult!.validPlaces.isNotEmpty)
              _buildActionButton(
                icon: Icons.cloud_upload,
                label:
                    '3. تأكيد رفع ${_parseResult!.validPlaces.length} معلم للقاعدة',
                color: Colors.green.shade700,
                onPressed: _isLoading ? null : _uploadToFirestore,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ✅ الواجهة الجديدة لعرض النتائج بالتفصيل مع علامات الصح والخطأ
  Widget _buildDetailedResultCard() {
    final validPlaces = _parseResult!.validPlaces;
    final errors = _parseResult!.errors;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 تقرير الفرز التفصيلي:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Text('✅ معالم تم قبولها: ${validPlaces.length}',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),

            // عرض قائمة الأماكن المقبولة مع علامة صح
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: validPlaces.length,
                itemBuilder: (context, index) {
                  final place = validPlaces[index];
                  return ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(place['name'] ?? 'بدون اسم',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${place['categoryId']} - ${place['governorate']}'),
                  );
                },
              ),
            ),

            if (errors.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('❌ أسطر تم رفضها (${errors.length}):',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: errors.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: Text(errors[index],
                          style:
                              const TextStyle(fontSize: 13, color: Colors.red)),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
