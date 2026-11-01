// lib/features/admin/screens/governorate_details_screen.dart
// [v1.1 — 2026-10-29] — WAVE 17: إضافة زر زرع أحياء أولية
//   - يظهر الزر فقط عند: وجود بيانات أولية في DistrictsSeedData + قائمة أحياء فارغة.
//   - يضيف الأحياء الثمانية دفعة واحدة مع تقرير بالنتائج.
//   - KEPT: كل السلوك السابق (المفاتيح الثلاثة، إضافة/تعديل/حذف/تفعيل حي).

import 'package:flutter/material.dart';

import '../../../models/district.dart';
import '../../../models/governorate_config.dart';
import '../../../repositories/governorates_repository.dart';
import '../seed/districts_seed_data.dart';
import '../widgets/district_form_dialog.dart';

class GovernorateDetailsScreen extends StatefulWidget {
  final String govDocId;
  const GovernorateDetailsScreen({super.key, required this.govDocId});

  @override
  State<GovernorateDetailsScreen> createState() =>
      _GovernorateDetailsScreenState();
}

class _GovernorateDetailsScreenState extends State<GovernorateDetailsScreen> {
  final GovernoratesRepository _repo = GovernoratesRepository.instance;

  bool _togglingGov = false;
  bool _togglingDelivery = false;
  bool _togglingTrips = false;
  bool _seeding = false;
  final Set<String> _busyDistricts = {};

  Stream<GovernorateConfig?> _watchThisGov() {
    return _repo.watchAllGovernorates().map((list) {
      for (final g in list) {
        if (g.docId == widget.govDocId) return g;
      }
      return null;
    });
  }

  Future<void> _setGovActive(bool v) async {
    setState(() => _togglingGov = true);
    try {
      await _repo.setGovernorateActive(widget.govDocId, v);
    } catch (e) {
      _showError('تعذر التحديث: $e');
    } finally {
      if (mounted) setState(() => _togglingGov = false);
    }
  }

  Future<void> _setDelivery(bool v) async {
    setState(() => _togglingDelivery = true);
    try {
      await _repo.setDeliveryEnabled(widget.govDocId, v);
    } catch (e) {
      _showError('تعذر التحديث: $e');
    } finally {
      if (mounted) setState(() => _togglingDelivery = false);
    }
  }

  Future<void> _setTrips(bool v) async {
    setState(() => _togglingTrips = true);
    try {
      await _repo.setTripsEnabled(widget.govDocId, v);
    } catch (e) {
      _showError('تعذر التحديث: $e');
    } finally {
      if (mounted) setState(() => _togglingTrips = false);
    }
  }

  Future<void> _toggleDistrict(District d) async {
    if (_busyDistricts.contains(d.id)) return;
    setState(() => _busyDistricts.add(d.id));
    try {
      await _repo.setDistrictActive(
        govId: widget.govDocId,
        districtId: d.id,
        isActive: !d.isActive,
      );
    } catch (e) {
      _showError('تعذر التحديث: $e');
    } finally {
      if (mounted) setState(() => _busyDistricts.remove(d.id));
    }
  }

  Future<void> _addDistrict() async {
    final result = await DistrictFormDialog.show(context);
    if (result == null) return;
    try {
      await _repo.createDistrict(
        govId: widget.govDocId,
        nameAr: result['nameAr']!,
        nameEn: result['nameEn'] ?? '',
        displayOrder: DateTime.now().millisecondsSinceEpoch,
      );
      _showSuccess('✅ تم إضافة الحي');
    } catch (e) {
      _showError('تعذر الإضافة: $e');
    }
  }

  Future<void> _editDistrict(District d) async {
    final result = await DistrictFormDialog.show(context, initial: d);
    if (result == null) return;
    try {
      await _repo.updateDistrict(
        govId: widget.govDocId,
        districtId: d.id,
        nameAr: result['nameAr'],
        nameEn: result['nameEn'],
      );
      _showSuccess('✅ تم التحديث');
    } catch (e) {
      _showError('تعذر التحديث: $e');
    }
  }

  Future<void> _deleteDistrict(District d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحي'),
        content: Text('هل أنت متأكد من حذف "${d.nameAr}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteDistrict(govId: widget.govDocId, districtId: d.id);
      _showSuccess('🗑️ تم الحذف');
    } catch (e) {
      _showError('تعذر الحذف: $e');
    }
  }

  // ─── Wave 17: زرع أحياء أولية ───
  Future<void> _seedDistricts() async {
    final seedData = DistrictsSeedData.forGovernorate(widget.govDocId);
    if (seedData == null || seedData.isEmpty) {
      _showError('لا توجد بيانات أولية لهذه المحافظة');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة أحياء أولية'),
        content: Text(
          'سيتم إضافة ${seedData.length} حي إلى هذه المحافظة:\n\n'
          '${seedData.map((d) => '• ${d['nameAr']}').join('\n')}\n\n'
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _seeding = true);
    int added = 0;
    int failed = 0;
    try {
      for (var i = 0; i < seedData.length; i++) {
        final d = seedData[i];
        try {
          await _repo.createDistrict(
            govId: widget.govDocId,
            nameAr: d['nameAr']!,
            nameEn: d['nameEn'] ?? '',
            displayOrder: i + 1,
          );
          added++;
        } catch (e) {
          debugPrint('Failed to seed district ${d['nameAr']}: $e');
          failed++;
        }
      }
      if (!mounted) return;
      if (failed == 0) {
        _showSuccess('✅ تم إضافة $added حي بنجاح');
      } else {
        _showError('تم إضافة $added حي، فشل $failed');
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<GovernorateConfig?>(
      stream: _watchThisGov(),
      builder: (context, govSnap) {
        if (govSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المحافظة')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final gov = govSnap.data;
        if (gov == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المحافظة')),
            body: const Center(child: Text('المحافظة غير موجودة')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(gov.nameAr),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_location_alt),
                tooltip: 'إضافة حي',
                onPressed: _addDistrict,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildConfigCard(theme, gov),
              const SizedBox(height: 24),
              _buildDistrictsHeader(theme),
              const SizedBox(height: 12),
              _buildDistrictsList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigCard(ThemeData theme, GovernorateConfig gov) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إعدادات المحافظة',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildConfigRow(
              icon: Icons.public,
              title: 'تفعيل المحافظة',
              subtitle: 'عند التعطيل، لا تظهر في قوائم الاختيار',
              value: gov.isActive,
              onChanged: _togglingGov ? null : _setGovActive,
            ),
            const Divider(height: 1),
            _buildConfigRow(
              icon: Icons.delivery_dining,
              title: 'تفعيل التوصيل',
              subtitle: 'هل التوصيل متاح داخل المحافظة؟',
              value: gov.deliveryEnabled,
              onChanged: _togglingDelivery ? null : _setDelivery,
            ),
            const Divider(height: 1),
            _buildConfigRow(
              icon: Icons.route,
              title: 'تفعيل الرحلات',
              subtitle: 'هل مولد الرحلات يعمل هنا؟',
              value: gov.tripsEnabled,
              onChanged: _togglingTrips ? null : _setTrips,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDistrictsHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          'الأحياء',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _addDistrict,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة'),
        ),
      ],
    );
  }

  Widget _buildDistrictsList() {
    return StreamBuilder<List<District>>(
      stream: _repo.watchDistricts(widget.govDocId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('تعذر تحميل الأحياء: ${snap.error}'),
            ),
          );
        }
        final districts = snap.data ?? const [];
        if (districts.isEmpty) {
          return _buildEmptyDistricts();
        }
        return Column(
          children: districts.map((d) => _buildDistrictTile(d)).toList(),
        );
      },
    );
  }

  Widget _buildEmptyDistricts() {
    final seedData = DistrictsSeedData.forGovernorate(widget.govDocId);
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text('لا توجد أحياء بعد'),
            const SizedBox(height: 8),
            const Text(
              'أضف أول حي لتتمكن من استخدامه في عنوان الأماكن',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            if (seedData != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _seeding ? null : _seedDistricts,
                  icon: _seeding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(
                    _seeding
                        ? 'جارٍ الإضافة...'
                        : 'إضافة ${seedData.length} أحياء أولية',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictTile(District d) {
    final theme = Theme.of(context);
    final busy = _busyDistricts.contains(d.id);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: d.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.location_on,
            size: 20,
            color: d.isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        title: Text(
          d.nameAr,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: d.nameEn.isNotEmpty ? Text(d.nameEn) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: d.isActive,
                onChanged: (_) => _toggleDistrict(d),
              ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _editDistrict(d);
                if (v == 'delete') _deleteDistrict(d);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('تعديل'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('حذف', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
