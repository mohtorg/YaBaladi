// lib/features/admin/screens/filters_management_screen.dart
//
// [v1.3 — 2026-10-25] — FIX: Tab-safe (no nested Scaffold/AppBar/FAB)
//   - REMOVED: Scaffold + AppBar → replaced with Column header
//     (caused DOUBLE AppBar when embedded in AdminDashboardScreen's IndexedStack)
//   - REMOVED: FloatingActionButton.extended → moved to header FilledButton.icon
//     (matches _CategoriesTab / _UsersTab pattern; no FAB inside tab)
//   - KEPT: Consumer<FiltersController> (no setState-during-build crash)
//   - KEPT: all CRUD, RBAC, empty/error states, search
//
// [v1.2 — 2026-10-25] — FIX: "setState() called during build" crash
//   - REMOVED: StreamBuilder calling bindStream() inside build()
//   - REPLACED with: Consumer<FiltersController> reading ctrl.all

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../filters/controllers/filters_controller.dart';
import '../../../models/filter_definition.dart';
import '../widgets/add_edit_filter_dialog.dart';

class FiltersManagementScreen extends StatefulWidget {
  const FiltersManagementScreen({super.key});

  @override
  State<FiltersManagementScreen> createState() =>
      _FiltersManagementScreenState();
}

class _FiltersManagementScreenState extends State<FiltersManagementScreen> {
  String _search = '';

  List<FilterDefinition> _filtered(List<FilterDefinition> all) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((f) {
      return f.id.toLowerCase().contains(q) ||
          f.nameAr.contains(q) ||
          f.nameEn.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Column(
      children: [
        // ─── Header (بدل AppBar + FAB) ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'إدارة الفلاتر',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _openAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('فلتر جديد'),
                style: FilledButton.styleFrom(
                  backgroundColor: YaBaladiDesignTokens.primaryBlue,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),
        // ─── Search bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو المعرف...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _search = ''),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        // ─── List ───
        Expanded(
          child: Consumer<FiltersController>(
            builder: (context, ctrl, _) {
              if (ctrl.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ctrl.error != null) {
                return _ErrorState(error: ctrl.error!);
              }

              if (ctrl.all.isEmpty) {
                return const _EmptyState();
              }

              final filtered = _filtered(ctrl.all);

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'لا نتائج لـ "$_search"',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final f = filtered[i];
                  return _FilterCard(
                    filter: f,
                    isAdmin: auth.role == 'admin',
                    onEdit: () => _openEdit(ctrl, f),
                    onToggle: () => _toggleActive(ctrl, f),
                    onDelete: () => _confirmDelete(ctrl, f),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openAdd() async {
    final ctrl = context.read<FiltersController>();
    final result = await showDialog<FilterDefinition>(
      context: context,
      builder: (_) => AddEditFilterDialog(
        suggestedOrder: ctrl.all.length + 1,
      ),
    );
    if (result != null && mounted) {
      try {
        await ctrl.create(result);
        if (mounted) _snack('تم إنشاء الفلتر');
      } catch (e) {
        if (mounted) _snack('فشل: $e', isError: true);
      }
    }
  }

  Future<void> _openEdit(FiltersController ctrl, FilterDefinition f) async {
    final result = await showDialog<FilterDefinition>(
      context: context,
      builder: (_) => AddEditFilterDialog(existing: f),
    );
    if (result != null && mounted) {
      try {
        await ctrl.update(result.id, result);
        if (mounted) _snack('تم تحديث الفلتر');
      } catch (e) {
        if (mounted) _snack('فشل: $e', isError: true);
      }
    }
  }

  Future<void> _toggleActive(FiltersController ctrl, FilterDefinition f) async {
    try {
      await ctrl.toggleActive(f.id, !f.isActive);
    } catch (e) {
      if (mounted) _snack('فشل: $e', isError: true);
    }
  }

  Future<void> _confirmDelete(
      FiltersController ctrl, FilterDefinition f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الفلتر "${f.nameAr}" نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(c, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ctrl.delete(f.id);
      if (mounted) _snack('تم حذف الفلتر');
    } catch (e) {
      if (mounted) _snack('فشل: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _FilterCard extends StatelessWidget {
  final FilterDefinition filter;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _FilterCard({
    required this.filter,
    required this.isAdmin,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  String get _typeLabel {
    switch (filter.type) {
      case FilterType.singleChoice:
        return 'اختيار واحد';
      case FilterType.multiChoice:
        return 'اختيار متعدد';
      case FilterType.range:
        return 'نطاق';
      case FilterType.boolean:
        return 'تبديل';
      case FilterType.sort:
        return 'ترتيب';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          filter.nameAr,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeLabel,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filter.nameEn,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: filter.options
                          .take(3)
                          .map((o) => Chip(
                                label: Text(o.labelAr,
                                    style: const TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: filter.isActive,
                onChanged: (_) => onToggle(),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  if (isAdmin)
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_off,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('لا توجد فلاتر بعد'),
          const SizedBox(height: 4),
          Text(
            'اضغط "فلتر جديد" لإضافة أول فلتر.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('خطأ: $error', textAlign: TextAlign.center),
      ),
    );
  }
}
