// lib/features/admin/screens/filters_management_screen.dart
// [v3.0.0 - GENERAL/SPECIFIC TABS]
//   - Added tabs for General Filters and Specific Filters.
//   - Dynamically passes `categoryId` to AddEditFilterDialog.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/design_tokens.dart';
import '../../../core/services/audit_log_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../filters/controllers/filters_controller.dart';
import '../../../models/filter_definition.dart';
import '../widgets/add_edit_filter_dialog.dart';

class FiltersManagementScreen extends StatelessWidget {
  const FiltersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'فلاتر عامة', icon: Icon(Icons.public)),
              Tab(text: 'فلاتر خاصة', icon: Icon(Icons.category)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _FiltersList(categoryId: null),
                _SpecificFiltersCategoriesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. قائمة الفلاتر (تُستخدم للعام والخاص)
// ═══════════════════════════════════════════════════════════════

class _FiltersList extends StatefulWidget {
  final String? categoryId; // null = عام، غير null = خاص

  const _FiltersList({this.categoryId});

  @override
  State<_FiltersList> createState() => _FiltersListState();
}

class _FiltersListState extends State<_FiltersList> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FilterDefinition> _filtered(List<FilterDefinition> all) {
    // 1. فلترة حسب التصنيف (عام/خاص)
    final byCat = all.where((f) {
      // نفترض أن الموديل يحتوي على حقل categoryId
      // إذا لم يكن موجوداً، سنحتاج لتحديث الموديل
      return f.categoryId == widget.categoryId;
    }).toList();

    // 2. فلترة حسب البحث
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return byCat;
    return byCat.where((f) {
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
        // ─── Header ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.categoryId == null
                      ? 'الفلاتر العامة'
                      : 'الفلاتر الخاصة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openAdd(context),
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
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو المعرف...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
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
                      _search.isNotEmpty
                          ? 'لا نتائج لـ "$_search"'
                          : 'لا توجد فلاتر في هذا القسم.',
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
                    isAdmin: auth.isAdmin,
                    onEdit: () => _openEdit(context, ctrl, f),
                    onToggle: () => _toggleActive(context, ctrl, f),
                    onDelete: () => _confirmDelete(context, ctrl, f),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final ctrl = context.read<FiltersController>();
    final admin = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<FilterDefinition>(
      context: context,
      builder: (_) => AddEditFilterDialog(
        suggestedOrder: ctrl.all.length + 1,
        categoryId: widget.categoryId, // ✅ تمرير التصنيف
      ),
    );
    if (result != null && context.mounted) {
      try {
        await ctrl.create(result);
        if (context.mounted) {
          await AuditLogService.logAction(
            action: 'إضافة فلتر',
            adminName: admin.displayName,
            target: result.nameAr,
            severity: 'low',
          );
          _snack('تم إنشاء الفلتر', messenger: messenger);
        }
      } catch (e) {
        if (context.mounted) {
          _snack('فشل: $e', isError: true, messenger: messenger);
        }
      }
    }
  }

  Future<void> _openEdit(
      BuildContext context, FiltersController ctrl, FilterDefinition f) async {
    final admin = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<FilterDefinition>(
      context: context,
      builder: (_) => AddEditFilterDialog(
        existing: f,
        categoryId: widget.categoryId, // ✅ تمرير التصنيف
      ),
    );
    if (result != null && context.mounted) {
      try {
        await ctrl.update(result.id, result);
        if (context.mounted) {
          await AuditLogService.logAction(
            action: 'تعديل فلتر',
            adminName: admin.displayName,
            target: result.nameAr,
            severity: 'low',
          );
          _snack('تم تحديث الفلتر', messenger: messenger);
        }
      } catch (e) {
        if (context.mounted) {
          _snack('فشل: $e', isError: true, messenger: messenger);
        }
      }
    }
  }

  Future<void> _toggleActive(
      BuildContext context, FiltersController ctrl, FilterDefinition f) async {
    final admin = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ctrl.toggleActive(f.id, !f.isActive);
      if (context.mounted) {
        await AuditLogService.logAction(
          action: !f.isActive ? 'تفعيل فلتر' : 'تعطيل فلتر',
          adminName: admin.displayName,
          target: f.nameAr,
          severity: 'low',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _snack('فشل: $e', isError: true, messenger: messenger);
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, FiltersController ctrl, FilterDefinition f) async {
    final admin = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

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
      if (context.mounted) {
        await AuditLogService.logAction(
          action: 'حذف فلتر',
          adminName: admin.displayName,
          target: f.nameAr,
          severity: 'medium',
        );
        _snack('تم حذف الفلتر', messenger: messenger);
      }
    } catch (e) {
      if (context.mounted) {
        _snack('فشل: $e', isError: true, messenger: messenger);
      }
    }
  }

  void _snack(String msg,
      {bool isError = false, ScaffoldMessengerState? messenger}) {
    (messenger ?? ScaffoldMessenger.of(context)).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. شاشة التصنيفات (للفلاتر الخاصة)
// ═══════════════════════════════════════════════════════════════

class _SpecificFiltersCategoriesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('حدث خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد تصنيفات بعد'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final nameAr = data['nameAr'] as String? ?? 'بدون اسم';

            return Card(
              child: ListTile(
                title: Text(nameAr,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text('فلاتر: $nameAr')),
                        body: _FiltersList(categoryId: docs[index].id),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
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
      clipBehavior: Clip.antiAlias,
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
                        Flexible(
                          child: Text(
                            filter.nameAr,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const Text('لا توجد فلاتر في هذا القسم'),
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
