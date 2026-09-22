// screens/admin/admin_governorate_visuals_screen.dart
//
// إدارة الهوية البصرية المحلية للمحافظات.
// الشاشة لا ترفع ملفات؛ تحفظ رابط الصورة وبيانات المصدر والترخيص.
// السبب: مصدر الصورة وحق الاستخدام جزء من بيانات المحتوى، وليس مجرد ملاحظة جانبية.
// لا تُنشر الصورة إلا إذا كانت usageApproved=true وpublished=true.

import 'package:flutter/material.dart';
import '../../models/egypt_governorates.dart';
import '../../models/governorate_visual_profile.dart';
import '../../services/governorate_visual_service.dart';
import '../../theme/app_colors.dart';

class AdminGovernorateVisualsScreen extends StatefulWidget {
  const AdminGovernorateVisualsScreen({super.key});

  @override
  State<AdminGovernorateVisualsScreen> createState() => _AdminGovernorateVisualsScreenState();
}

class _AdminGovernorateVisualsScreenState extends State<AdminGovernorateVisualsScreen> {
  String _selectedId = EgyptGovernorates.activeGovernorateId;
  final _heroUrl = TextEditingController();
  final _credit = TextEditingController();
  final _sourceUrl = TextEditingController();
  final _license = TextEditingController();
  final _photographer = TextEditingController();
  bool _approved = false;
  bool _published = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load(_selectedId);
  }

  @override
  void dispose() {
    _heroUrl.dispose();
    _credit.dispose();
    _sourceUrl.dispose();
    _license.dispose();
    _photographer.dispose();
    super.dispose();
  }

  Future<void> _load(String id) async {
    setState(() => _loading = true);
    final profile = await GovernorateVisualService().getForAdmin(id);
    if (!mounted) return;
    _heroUrl.text = profile?.heroImageUrl ?? '';
    _credit.text = profile?.credit ?? '';
    _sourceUrl.text = profile?.sourceUrl ?? '';
    _license.text = profile?.license ?? '';
    _photographer.text = profile?.photographer ?? '';
    setState(() {
      _approved = profile?.usageApproved ?? false;
      _published = profile?.published ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final url = _heroUrl.text.trim();
    if (url.isEmpty && _published) {
      _show('لا يمكن نشر المحافظة بدون رابط صورة غلاف.');
      return;
    }
    if (_published && !_approved) {
      _show('يجب تأكيد حق استخدام الصورة قبل نشرها.');
      return;
    }

    setState(() => _saving = true);
    try {
      await GovernorateVisualService().saveForAdmin(
        GovernorateVisualProfile(
          governorateId: _selectedId,
          heroImageUrl: url,
          credit: _credit.text,
          sourceUrl: _sourceUrl.text,
          license: _license.text,
          photographer: _photographer.text,
          usageApproved: _approved,
          published: _published,
        ),
      );
      if (mounted) _show('تم حفظ الهوية البصرية للمحافظة.');
    } catch (e) {
      if (mounted) _show('تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final governorate = EgyptGovernorates.getById(_selectedId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('صور المحافظات والهوية المحلية'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'نظام الصور الوطني',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'اربط صورة حقيقية مصرح باستخدامها بالمحافظة. لن تظهر الصورة للمستخدمين إلا بعد اعتماد حق الاستخدام والنشر.',
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _selectedId,
                  decoration: const InputDecoration(labelText: 'المحافظة'),
                  items: EgyptGovernorates.all
                      .map((g) => DropdownMenuItem(value: g.id, child: Text(g.nameAr)))
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() => _selectedId = id);
                    _load(id);
                  },
                ),
                const SizedBox(height: 12),
                Text('المحافظة الحالية: ${governorate?.nameAr ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _heroUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'رابط صورة الغلاف',
                    hintText: 'https://...',
                    helperText: 'يفضل رابطًا ثابتًا من مصدر تملك يا بلدي حق استخدامه.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: _photographer, decoration: const InputDecoration(labelText: 'اسم المصور')),
                const SizedBox(height: 12),
                TextField(controller: _credit, decoration: const InputDecoration(labelText: 'الائتمان الظاهر للمستخدم')),
                const SizedBox(height: 12),
                TextField(
                  controller: _sourceUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'رابط المصدر/صفحة الحقوق'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _license,
                  decoration: const InputDecoration(labelText: 'نوع الترخيص / إثبات حق الاستخدام'),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تم التحقق من حق الاستخدام'),
                  subtitle: const Text('لا تفعلها إلا بعد مراجعة المصدر والترخيص.'),
                  value: _approved,
                  onChanged: (v) => setState(() => _approved = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('نشر الصورة للمستخدمين'),
                  value: _published,
                  onChanged: (v) => setState(() => _published = v),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('حفظ'),
                ),
              ],
            ),
    );
  }
}
