// lib/features/admin/screens/categories_management_screen.dart
//
// [v5.1 — 2026-10-24] — Fix: textDirection outside TextStyle.copyWith
//   - FIX: `textDirection: TextDirection.ltr` moved from inside
//     `style.copyWith(...)` to the `Text(...)` widget itself.
//     In Flutter 3.27+ TextStyle does not accept textDirection;
//     it belongs on the Text widget.
//
// [Wave 10 — file 5/12] — 2026-10-24
// Categories Management Screen (Admin Dashboard)
//
// - Live stream of all categories from Firestore
// - Search, sort (order/name/placesCount), pull-to-refresh
// - Inline active toggle, popup menu (edit/featured/delete)
// - FAB to create new category with auto-suggested order
//
// Depends on:
//   - CategoriesRepository (v2.1)
//   - AddEditCategoryDialog (file 6)
//   - Category v2.0 (icon, color getters)

import 'package:flutter/material.dart';

import '../../../models/category.dart';
import '../../../repositories/categories_repository.dart';
import '../widgets/add_edit_category_dialog.dart';

class CategoriesManagementScreen extends StatefulWidget {
  final CategoriesRepository? repository;

  const CategoriesManagementScreen({super.key, this.repository});

  @override
  State<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends State<CategoriesManagementScreen> {
  late final CategoriesRepository _repo;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SortMode _sortMode = _SortMode.byOrder;
  List<Category> _lastSnapshot = const [];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? CategoriesRepository();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // Filter + Sort
  // ═══════════════════════════════════════════════════════════════
  List<Category> _process(List<Category> all) {
    var list = all.toList();

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        return c.id.toLowerCase().contains(q) ||
            c.nameAr.contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.iconName.toLowerCase().contains(q);
      }).toList();
    }

    switch (_sortMode) {
      case _SortMode.byOrder:
        list.sort((a, b) => a.order.compareTo(b.order));
        break;
      case _SortMode.byNameAr:
        list.sort((a, b) => a.nameAr.compareTo(b.nameAr));
        break;
      case _SortMode.byPlacesCount:
        list.sort((a, b) => b.placesCount.compareTo(a.placesCount));
        break;
    }
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════
  Future<void> _openAdd() async {
    final nextOrder = _lastSnapshot.isEmpty
        ? 1
        : _lastSnapshot.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1;

    final saved = await AddEditCategoryDialog.show(
      context,
      repository: _repo,
      suggestedOrder: nextOrder,
    );
    if (saved == true && mounted) {
      _showSnack('تم إنشاء التصنيف بنجاح', success: true);
    }
  }

  Future<void> _openEdit(Category cat) async {
    final saved = await AddEditCategoryDialog.show(
      context,
      category: cat,
      repository: _repo,
    );
    if (saved == true && mounted) {
      _showSnack('تم تحديث التصنيف', success: true);
    }
  }

  Future<void> _toggleActive(Category cat) async {
    try {
      await _repo.update(cat.id, {'isActive': !cat.isActive});
    } catch (e) {
      if (mounted) _showSnack('فشل التحديث: $e');
    }
  }

  Future<void> _toggleFeatured(Category cat) async {
    try {
      await _repo.update(cat.id, {'isFeatured': !cat.isFeatured});
    } catch (e) {
      if (mounted) _showSnack('فشل التحديث: $e');
    }
  }

  Future<void> _confirmDelete(Category cat) async {
    if (cat.placesCount > 0) {
      _showSnack(
        'لا يمكن حذف "${cat.nameAr}" — يحتوي على ${cat.placesCount} مكان. '
        'عطّله بدلاً من ذلك.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف التصنيف "${cat.nameAr}" نهائياً؟\n\n'
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.delete(cat.id);
      if (mounted) _showSnack('تم حذف التصنيف', success: true);
    } catch (e) {
      if (mounted) _showSnack('فشل الحذف: $e');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        duration: Duration(seconds: success ? 2 : 4),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التصنيفات'),
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: 'ترتيب',
            initialValue: _sortMode,
            onSelected: (m) => setState(() => _sortMode = m),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _SortMode.byOrder,
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 18),
                    SizedBox(width: 10),
                    Text('حسب الترتيب'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortMode.byNameAr,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 18),
                    SizedBox(width: 10),
                    Text('حسب الاسم'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortMode.byPlacesCount,
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 18),
                    SizedBox(width: 10),
                    Text('حسب الاستخدام'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final all = snapshot.data ?? const <Category>[];
          _lastSnapshot = all;
          final filtered = _process(all);

          return Column(
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                count: filtered.length,
                total: all.length,
              ),
              Expanded(
                child: all.isEmpty
                    ? _EmptyState(onAdd: _openAdd)
                    : filtered.isEmpty
                        ? _NoResultsState(query: _query)
                        : RefreshIndicator(
                            onRefresh: () async {
                              await Future.delayed(
                                const Duration(milliseconds: 400),
                              );
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                4,
                                12,
                                90,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final cat = filtered[i];
                                return _CategoryCard(
                                  category: cat,
                                  onEdit: () => _openEdit(cat),
                                  onToggleActive: () => _toggleActive(cat),
                                  onToggleFeatured: () => _toggleFeatured(cat),
                                  onDelete: () => _confirmDelete(cat),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('تصنيف جديد'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════
enum _SortMode { byOrder, byNameAr, byPlacesCount }

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int count;
  final int total;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو المعرف...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'مسح',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              count == total ? '$total تصنيف' : 'عرض $count من $total تصنيف',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleFeatured;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onToggleActive,
    required this.onToggleFeatured,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = category.color;
    final icon = category.icon;
    final isActive = category.isActive;
    final isFeatured = category.isFeatured;
    final canDelete = category.placesCount == 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Icon ───
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isActive ? accent : accent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),

              // ─── Names + Chips ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.nameAr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  isActive ? null : theme.colorScheme.outline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFeatured) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                        ],
                      ],
                    ),
                    // [v5.1 FIX] textDirection moved out of style.copyWith
                    Text(
                      category.nameEn,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniChip(
                          icon: Icons.format_list_numbered,
                          label: '#${category.order}',
                        ),
                        _MiniChip(
                          icon: Icons.place_outlined,
                          label: '${category.placesCount} مكان',
                          highlight: category.placesCount > 0,
                        ),
                        _MiniChip(
                          icon: Icons.tag,
                          label: category.id,
                          monospace: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // ─── Active Switch ───
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: isActive,
                    onChanged: (_) => onToggleActive(),
                    activeTrackColor: accent.withValues(alpha: 0.5),
                    activeThumbColor: accent,
                  ),
                  Text(
                    isActive ? 'نشط' : 'معطل',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive ? accent : theme.colorScheme.outline,
                      fontWeight: isActive ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),

              // ─── Menu ───
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'خيارات',
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'featured':
                      onToggleFeatured();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'featured',
                    child: Row(
                      children: [
                        Icon(
                          isFeatured ? Icons.star : Icons.star_border,
                          size: 18,
                          color: isFeatured ? Colors.amber : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isFeatured ? 'إلغاء التمييز' : 'تمييز',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: canDelete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: canDelete
                              ? Colors.red
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          canDelete
                              ? 'حذف'
                              : 'لا يمكن الحذف (${category.placesCount})',
                          style: TextStyle(
                            color: canDelete ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final bool monospace;

  const _MiniChip({
    required this.icon,
    required this.label,
    this.highlight = false,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlight
        ? Colors.blue.shade50
        : theme.colorScheme.surfaceContainerHighest;
    final fg =
        highlight ? Colors.blue.shade900 : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontFamily: monospace ? 'monospace' : null,
              fontWeight: highlight ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد تصنيفات بعد',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'أنشئ أول تصنيف للبدء',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء تصنيف'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد نتائج لـ "$query"',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل التصنيفات',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
