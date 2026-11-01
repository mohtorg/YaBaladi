// lib/features/notifications/screens/notifications_screen.dart
//
// [v2.0 — 2026-10-28] — MAJOR UPGRADE: Filters + Search + Deep Links

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // 0=all, 1=unread, 2=system, 3=offers, 4=support
  int _filterIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppNotification> _applyFilters(List<AppNotification> all) {
    var result = all;

    // 1. الفلتر
    switch (_filterIndex) {
      case 1: // غير مقروء
        result = result.where((n) => !n.isRead).toList();
        break;
      case 2: // نظام
        result = result
            .where((n) =>
                n.type == NotificationType.systemAnnouncement ||
                n.type == NotificationType.merchantApproved ||
                n.type == NotificationType.merchantRejected ||
                n.type == NotificationType.placeBlocked ||
                n.type == NotificationType.placeUnblocked)
            .toList();
        break;
      case 3: // عروض
        result =
            result.where((n) => n.type == NotificationType.newOffer).toList();
        break;
      case 4: // دعم
        result = result
            .where((n) => n.type == NotificationType.supportReply)
            .toList();
        break;
    }

    // 2. البحث
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  void _openNotification(AppNotification n, NotificationsController c) {
    // 1. تعليم كمقروء
    if (!n.isRead) c.markAsRead(n.id);

    // 2. Deep Link
    final route = n.data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      Navigator.of(context).pop(); // أغلق شاشة الإشعارات
      context.push(route); // افتح الشاشة المستهدفة
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = context.watch<NotificationsController>();
    final filtered = _applyFilters(ctrl.notifications);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('الإشعارات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (ctrl.unreadCount > 0)
            TextButton.icon(
              onPressed: ctrl.markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('قراءة الكل'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── شريط البحث ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ابحث في الإشعارات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ─── الفلاتر ───
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(0, 'الكل', theme, ctrl.notifications.length),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'غير مقروء', theme, ctrl.unreadCount),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'نظام', theme, null),
                const SizedBox(width: 8),
                _buildFilterChip(3, 'عروض', theme, null),
                const SizedBox(width: 8),
                _buildFilterChip(4, 'دعم', theme, null),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── قائمة الإشعارات ───
          Expanded(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final n = filtered[i];
                          return _notificationCard(n, ctrl, theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      int index, String label, ThemeData theme, int? count) {
    final selected = _filterIndex == index;
    final displayLabel = count != null && count > 0 ? '$label ($count)' : label;

    return ChoiceChip(
      label: Text(displayLabel, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _filterIndex = index),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 80, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج لـ "$_searchQuery"'
                : 'لا توجد إشعارات',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب البحث بكلمات أخرى'
                : 'ستظهر هنا التنبيهات المهمة',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(
      AppNotification n, NotificationsController ctrl, ThemeData theme) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ctrl.deleteNotification(n.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: n.isRead
            ? theme.colorScheme.surface
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: n.isRead
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.primary.withValues(alpha: 0.3),
            width: n.isRead ? 1 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => _openNotification(n, ctrl),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.icon, color: n.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight:
                              n.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(n.body, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _timeAgo(n.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (n.data['route'] != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios,
                                size: 10,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'الآن';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
  }
}
