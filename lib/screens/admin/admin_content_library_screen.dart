// screens/admin/admin_content_library_screen.dart
// إدارة مكتبة المحتوى. النشر لا يظهر للجمهور إلا مع usageApproved=true وpublished=true.

import 'package:flutter/material.dart';
import '../../models/egypt_governorates.dart';
import '../../models/library_content.dart';
import '../../services/library_content_service.dart';
import '../../theme/app_colors.dart';

class AdminContentLibraryScreen extends StatefulWidget {
  const AdminContentLibraryScreen({super.key});
  @override
  State<AdminContentLibraryScreen> createState() => _AdminContentLibraryScreenState();
}

class _AdminContentLibraryScreenState extends State<AdminContentLibraryScreen> {
  final _service = LibraryContentService();
  late Future<List<LibraryContent>> _future;

  @override
  void initState() { super.initState(); _load(); }
  void _load() { _future = _service.getAllForAdmin(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة المحتوى'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('إضافة مادة')),
      body: FutureBuilder<List<LibraryContent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المكتبة: ${snapshot.error}'));
          final items = snapshot.data ?? const <LibraryContent>[];
          if (items.isEmpty) return const Center(child: Text('لا توجد مواد بعد. أضف أول مادة إلى المكتبة.'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _item(items[index]),
          );
        },
      ),
    );
  }

  Widget _item(LibraryContent item) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: CircleAvatar(backgroundColor: item.published && item.usageApproved ? AppColors.secondary.withValues(alpha: .12) : AppColors.highlight.withValues(alpha: .14), child: Icon(Icons.photo_library_outlined, color: item.published && item.usageApproved ? AppColors.secondary : AppColors.highlight)),
      title: Text(item.titleAr, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${LibraryContentType.labelAr(item.contentType)} • ${item.scope == 'national' ? 'وطنية' : 'محلية'}\n${item.published && item.usageApproved ? 'منشورة ومعتمدة' : item.published ? 'منشورة بدون اعتماد استخدام' : 'غير منشورة'}'),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(onSelected: (value) async { if (value == 'edit') await _edit(item); if (value == 'delete') await _delete(item); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))]),
    ),
  );

  Future<void> _edit([LibraryContent? existing]) async {
    final result = await showDialog<LibraryContent>(context: context, builder: (_) => _LibraryEditor(existing: existing));
    if (result == null) return;
    await _service.save(result);
    if (mounted) setState(_load);
  }

  Future<void> _delete(LibraryContent item) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('حذف المادة؟'), content: Text('سيتم حذف «${item.titleAr}» من المكتبة.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))]));
    if (ok == true) { await _service.delete(item.id); if (mounted) setState(_load); }
  }
}

class _LibraryEditor extends StatefulWidget {
  final LibraryContent? existing;
  const _LibraryEditor({this.existing});
  @override State<_LibraryEditor> createState() => _LibraryEditorState();
}

class _LibraryEditorState extends State<_LibraryEditor> {
  late final TextEditingController _titleAr, _titleEn, _descAr, _descEn, _media, _thumb, _source, _credit, _license, _order;
  String _type = LibraryContentType.image;
  String _scope = 'governorate';
  String _governorate = EgyptGovernorates.activeGovernorateId;
  bool _approved = false;
  bool _published = false;

  @override
  void initState() {
    super.initState();
    final x = widget.existing;
    _titleAr = TextEditingController(text: x?.titleAr ?? '');
    _titleEn = TextEditingController(text: x?.titleEn ?? '');
    _descAr = TextEditingController(text: x?.descriptionAr ?? '');
    _descEn = TextEditingController(text: x?.descriptionEn ?? '');
    _media = TextEditingController(text: x?.mediaUrl ?? '');
    _thumb = TextEditingController(text: x?.thumbnailUrl ?? '');
    _source = TextEditingController(text: x?.sourceUrl ?? '');
    _credit = TextEditingController(text: x?.credit ?? '');
    _license = TextEditingController(text: x?.license ?? '');
    _order = TextEditingController(text: '${x?.sortOrder ?? 0}');
    _type = x?.contentType ?? _type; _scope = x?.scope ?? _scope; _governorate = x?.governorateId.isNotEmpty == true ? x!.governorateId : _governorate; _approved = x?.usageApproved ?? false; _published = x?.published ?? false;
  }

  @override
  void dispose() { for (final c in [_titleAr,_titleEn,_descAr,_descEn,_media,_thumb,_source,_credit,_license,_order]) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'إضافة مادة للمكتبة' : 'تعديل مادة المكتبة'),
    content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_titleAr, 'العنوان بالعربية *'), _field(_titleEn, 'العنوان بالإنجليزية *'),
      DropdownButtonFormField<String>(initialValue: _type, decoration: const InputDecoration(labelText: 'نوع المحتوى'), items: LibraryContentType.all.map((x) => DropdownMenuItem(value: x, child: Text(LibraryContentType.labelAr(x)))).toList(), onChanged: (v) => setState(() => _type = v!)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: _scope, decoration: const InputDecoration(labelText: 'النطاق'), items: const [DropdownMenuItem(value: 'national', child: Text('مكتبة وطنية مشتركة')), DropdownMenuItem(value: 'governorate', child: Text('مكتبة محافظة'))], onChanged: (v) => setState(() => _scope = v!)),
      if (_scope == 'governorate') DropdownButtonFormField<String>(initialValue: _governorate, decoration: const InputDecoration(labelText: 'المحافظة'), items: EgyptGovernorates.all.map((g) => DropdownMenuItem(value: g.id, child: Text(g.nameAr))).toList(), onChanged: (v) => setState(() => _governorate = v!)),
      _field(_descAr, 'الوصف بالعربية', maxLines: 3), _field(_descEn, 'الوصف بالإنجليزية', maxLines: 3),
      _field(_media, 'رابط الوسائط'), _field(_thumb, 'رابط الصورة المصغرة (اختياري)'), _field(_source, 'رابط المصدر'), _field(_credit, 'الائتمان / اسم المصور'), _field(_license, 'الترخيص / الإذن'), _field(_order, 'ترتيب الظهور', keyboard: TextInputType.number),
      SwitchListTile(title: const Text('اعتماد الاستخدام'), subtitle: const Text('لا يظهر المحتوى للجمهور بدون هذا الاعتماد.'), value: _approved, onChanged: (v) => setState(() => _approved = v)),
      SwitchListTile(title: const Text('نشر المادة'), subtitle: const Text('لا يتم النشر إلا مع اعتماد الاستخدام.'), value: _published, onChanged: (v) => setState(() => _published = v)),
    ]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: _save, child: const Text('حفظ'))],
  );

  Widget _field(TextEditingController c, String label, {int maxLines = 1, TextInputType? keyboard}) => Padding(padding: const EdgeInsets.only(top: 10), child: TextField(controller: c, maxLines: maxLines, keyboardType: keyboard, decoration: InputDecoration(labelText: label)));

  void _save() {
    if (_titleAr.text.trim().isEmpty || _titleEn.text.trim().isEmpty) return;
    if (_published && !_approved) return;
    final item = LibraryContent(id: widget.existing?.id ?? '', scope: _scope, governorateId: _scope == 'national' ? '' : _governorate, contentType: _type, titleAr: _titleAr.text.trim(), titleEn: _titleEn.text.trim(), descriptionAr: _descAr.text.trim(), descriptionEn: _descEn.text.trim(), mediaUrl: _media.text.trim(), thumbnailUrl: _thumb.text.trim(), sourceUrl: _source.text.trim(), credit: _credit.text.trim(), license: _license.text.trim(), usageApproved: _approved, published: _published, publishedAt: widget.existing?.publishedAt, sortOrder: int.tryParse(_order.text.trim()) ?? 0);
    Navigator.pop(context, item);
  }
}

