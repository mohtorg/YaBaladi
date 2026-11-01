// lib/features/admin/screens/review_statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/design_tokens.dart';

class ReviewStatisticsScreen extends StatefulWidget {
  const ReviewStatisticsScreen({super.key});

  @override
  State<ReviewStatisticsScreen> createState() => _ReviewStatisticsScreenState();
}

class _ReviewStatisticsScreenState extends State<ReviewStatisticsScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final fs = FirebaseFirestore.instance.collection('reviews');

    try {
      // ✅ 6 استعلامات تجميعية فقط (بدون قراءة المستندات)
      final results = await Future.wait([
        fs.count().get(), // 0: Total
        fs.where('rating', isEqualTo: 5).count().get(), // 1
        fs.where('rating', isEqualTo: 4).count().get(), // 2
        fs.where('rating', isEqualTo: 3).count().get(), // 3
        fs.where('rating', isEqualTo: 2).count().get(), // 4
        fs.where('rating', isEqualTo: 1).count().get(), // 5
      ]);

      final total = results[0].count ?? 0;
      final c5 = results[1].count ?? 0;
      final c4 = results[2].count ?? 0;
      final c3 = results[3].count ?? 0;
      final c2 = results[4].count ?? 0;
      final c1 = results[5].count ?? 0;

      // ✅ حساب المتوسط رياضياً (بدون استخدام select)
      final sumOfRatings = (5 * c5) + (4 * c4) + (3 * c3) + (2 * c2) + (1 * c1);
      final avg = total > 0 ? sumOfRatings / total : 0.0;

      setState(() {
        _stats = {
          'total': total,
          '5': c5,
          '4': c4,
          '3': c3,
          '2': c2,
          '1': c1,
          'avg': avg,
        };
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading review stats: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إحصائيات التقييمات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = _stats['total'] as int? ?? 0;
    final avg = (_stats['avg'] as double? ?? 0.0).toStringAsFixed(1);
    final totalSafe = total > 0 ? total : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات التقييمات'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'إجمالي التقييمات',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text(
                      'متوسط التقييم',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          avg,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'توزيع النجوم',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _ratingBar(
              '5 نجوم', (_stats['5'] as int?) ?? 0, totalSafe, Colors.green),
          _ratingBar('4 نجوم', (_stats['4'] as int?) ?? 0, totalSafe,
              Colors.lightGreen),
          _ratingBar(
              '3 نجوم', (_stats['3'] as int?) ?? 0, totalSafe, Colors.amber),
          _ratingBar(
              '2 نجوم', (_stats['2'] as int?) ?? 0, totalSafe, Colors.orange),
          _ratingBar(
              'نجمة واحدة', (_stats['1'] as int?) ?? 0, totalSafe, Colors.red),
        ],
      ),
    );
  }

  Widget _ratingBar(String label, int count, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count / total,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
