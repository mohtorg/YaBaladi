// lib/features/admin/screens/user_statistics_screen.dart
// [v1.1 — FIXED] — SAFETY & UI ENHANCEMENTS:
//   - FIXED: Added 'mounted' check after Future.wait to prevent crashes.
//   - FIXED: Wrapped count in FittedBox to prevent UI overflow with large numbers.
//   - ADDED: Pull-to-refresh functionality (RefreshIndicator).
//   - ADDED: Error handling UI with retry button.
//   - KEPT: All aggregation logic and UI colors intact.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/design_tokens.dart';

class UserStatisticsScreen extends StatefulWidget {
  const UserStatisticsScreen({super.key});

  @override
  State<UserStatisticsScreen> createState() => _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final fs = FirebaseFirestore.instance.collection('users');

    try {
      final results = await Future.wait([
        fs.count().get(), // Total
        fs.where('role', isEqualTo: 'admin').count().get(),
        fs.where('role', isEqualTo: 'moderator').count().get(),
        fs.where('role', isEqualTo: 'merchant').count().get(),
        fs.where('role', isEqualTo: 'member').count().get(),
        fs.where('isBanned', isEqualTo: true).count().get(),
      ]);

      // ✅ فحص mounted لمنع الانهيار إذا خرج المستخدم من الشاشة
      if (!mounted) return;

      setState(() {
        _stats = {
          'total': results[0].count ?? 0,
          'admin': results[1].count ?? 0,
          'moderator': results[2].count ?? 0,
          'merchant': results[3].count ?? 0,
          'member': results[4].count ?? 0,
          'banned': results[5].count ?? 0,
        };
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading user stats: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات المستخدمين'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStats,
              tooltip: 'تحديث',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ أثناء تحميل الإحصائيات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: FilledButton.styleFrom(
                  backgroundColor: YaBaladiDesignTokens.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: YaBaladiDesignTokens.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _statCard('إجمالي المستخدمين', _stats['total'] ?? 0, Colors.blue,
              Icons.people),
          const SizedBox(height: 12),
          _statCard('الأدمن', _stats['admin'] ?? 0, Colors.red,
              Icons.admin_panel_settings),
          _statCard('المشرفون', _stats['moderator'] ?? 0, Colors.orange,
              Icons.verified_user),
          _statCard('التجار / مقدمي الخدمة', _stats['merchant'] ?? 0,
              Colors.teal, Icons.storefront),
          _statCard('الأعضاء العاديون', _stats['member'] ?? 0, Colors.grey,
              Icons.person),
          const Divider(height: 32),
          _statCard('المحظورون (Banned)', _stats['banned'] ?? 0, Colors.black87,
              Icons.block),
        ],
      ),
    );
  }

  Widget _statCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // ✅ تغليف الرقم بـ FittedBox لمنع انهيار الواجهة إذا كان الرقم ضخماً
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
