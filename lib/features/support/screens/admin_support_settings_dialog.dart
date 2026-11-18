// lib/features/support/screens/admin_support_settings_dialog.dart
//
// [v1.2 - CRASH FIX + SMART UX]
//   - FIXED: TextEditingController used after dispose (added mounted checks).
//   - IMPROVED: Auto-converts local Egyptian numbers (e.g. 010...) to
//     international format (e.g. 2010...) on save, instead of blocking them.
//   - KEPT: All merge/validation/UI logic.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportSettingsDialog extends StatefulWidget {
  const AdminSupportSettingsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AdminSupportSettingsDialog(),
    );
  }

  @override
  State<AdminSupportSettingsDialog> createState() =>
      _AdminSupportSettingsDialogState();
}

class _AdminSupportSettingsDialogState
    extends State<AdminSupportSettingsDialog> {
  final _whatsappCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentNumber();
  }

  @override
  void dispose() {
    _whatsappCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───

  String _normalizePhone(String raw) {
    final buffer = StringBuffer();
    for (final c in raw.codeUnits) {
      if (c >= 48 && c <= 57) buffer.writeCharCode(c);
    }
    return buffer.toString();
  }

  // ─── Load ───

  Future<void> _loadCurrentNumber() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('support')
          .get();

      // 🚨 FIX: Check mounted immediately after await, before touching Controller
      if (!mounted) return;

      if (doc.exists) {
        final raw = (doc.data()?['whatsappNumber'] ?? '').toString();
        _whatsappCtrl.text = _normalizePhone(raw);
      }
    } catch (e) {
      debugPrint('Error loading support settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Save ───

  Future<void> _save() async {
    if (_isLoading || _isSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 🚨 UX FIX: Auto-format local number to international format
    String number = _whatsappCtrl.text.trim();
    if (number.startsWith('0')) {
      // 01012345678 -> 201012345678
      number = '20${number.substring(1)}';
    }

    // Validation after formatting
    if (number.isEmpty || number.length < 10 || number.length > 15) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('الرقم غير صالح. يجب أن يكون بين 10 و 15 رقماً.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('support')
          .set(
        {
          'whatsappNumber': number,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 🚨 FIX: Check mounted before pop/snackbar
      if (!mounted) return;

      navigator.pop();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم حفظ رقم الواتساب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Save support settings failed: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعدادات الدعم الفني'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أدخل رقم الواتساب الذي سيتم تحويل المستخدمين إليه عند طلب الدعم.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _whatsappCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    onSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'رقم الواتساب',
                      hintText: '201012345678',
                      helperText:
                          'إذا بدأت بـ 0 سيتم إضافة كود الدولة (20) تلقائياً.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: (_isLoading || _isSaving) ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
