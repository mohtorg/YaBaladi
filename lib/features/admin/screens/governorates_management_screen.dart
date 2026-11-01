// lib/features/admin/screens/governorates_management_screen.dart
// [v2.0 — 2026-10-29] — WAVE 17: إعادة كتابة كاملة
//   - كل سطر محافظة قابل للنقر → يفتح شاشة التفاصيل.
//   - Switch موجود الآن داخل شاشة التفاصيل (لا هنا).
//   - عرض عدد الأحياء (المفعّلة/الإجمالي) لكل محافظة.
//   - زر التهيئة يستخدم GovernoratesRepository.seedAllGovernorates()
//     (يتحقق بـ nameAr لتجنب التكرار).
//   - إنشاء المحافظات الافتراضي: isActive=false (قرار المستخدم).
//   - KEPT: كل السلوك السابق للتهيئة، الرسائل، والتنقل.

import 'package:flutter/material.dart';

import '../../../models/governorate_config.dart';
import '../../../repositories/governorates_repository.dart';
import 'governorate_details_screen.dart';

class GovernoratesManagementScreen extends StatefulWidget {
  const GovernoratesManagementScreen({super.key});

  @override
  State<GovernoratesManagementScreen> createState() =>
      _GovernoratesManagementScreenState();
}

class _GovernoratesManagementScreenState
    extends State<GovernoratesManagementScreen> {
  final GovernoratesRepository _repo = GovernoratesRepository.instance;

  bool _seeding = false;
  Map<String, int> _activeDistrictCounts = const {};
  Map<String, int> _totalDistrictCounts = const {};

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    try {
      final govs = await _repo.watchAllGovernorates().first;
      final active = <String, int>{};
      final total = <String, int>{};
      for (final g in govs) {
        total[g.docId] = await _repo.countDistricts(govId: g.docId);
        active[g.docId] = await _repo.countDistricts(
          govId: g.docId,
          onlyActive: true,
        );
      }
      if (!mounted) return;
      setState(() {
        _activeDistrictCounts = active;
        _totalDistrictCounts = total;
      });
    } catch (e) {
      debugPrint('Failed to count districts: $e');
    }
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      final created = await _repo.seedAllGovernorates();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created > 0
                ? '✅ تم إنشاء $created محافظة جديدة'
                : 'ℹ️ جميع المحافظات موجودة بالفعل',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshCounts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل التهيئة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _openGovernorate(GovernorateConfig gov) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GovernorateDetailsScreen(govDocId: gov.docId),
      ),
    );
    await _refreshCounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'إدارة المحافظات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GovernorateConfig>>(
        stream: _repo.watchAllGovernorates(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }
          final govs = snap.data ?? const [];
          if (govs.isEmpty) {
            return _buildEmptyState(theme);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: govs.length,
            itemBuilder: (context, i) {
              return _buildGovernorateCard(theme, govs[i]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 80, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'لم يتم تهيئة المحافظات بعد',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'سيتم إنشاء 27 محافظة، جميعها معطّلة افتراضياً. '
              'يمكنك بعدها تفعيلها واحدة واحدة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _seeding ? null : _seed,
            icon: _seeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_seeding ? 'جارٍ التهيئة...' : 'تهيئة الـ 27 محافظة'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(250, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernorateCard(ThemeData theme, GovernorateConfig gov) {
    final total = _totalDistrictCounts[gov.docId] ?? 0;
    final active = _activeDistrictCounts[gov.docId] ?? 0;
    final String subtitle;
    if (total == 0) {
      subtitle = 'لا توجد أحياء';
    } else {
      subtitle = '$total أحياء ($active مفعّل)';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openGovernorate(gov),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gov.isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_city,
                  color: gov.isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gov.nameAr,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gov.nameEn.isNotEmpty ? gov.nameEn : '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: gov.isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                gov.isActive ? Icons.check_circle : Icons.remove_circle_outline,
                color: gov.isActive ? Colors.green : theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
