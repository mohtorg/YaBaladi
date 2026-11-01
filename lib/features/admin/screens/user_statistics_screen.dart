// lib/features/admin/screens/user_statistics_screen.dart
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
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إحصائيات المستخدمين')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات المستخدمين'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
