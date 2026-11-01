// lib/features/admin/screens/place_statistics_screen.dart
// [v1.2 — 2026-10-21] — Removed unnecessary cast + finalized medalColor

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/design_tokens.dart';

class PlaceStatisticsScreen extends StatefulWidget {
  const PlaceStatisticsScreen({super.key});

  @override
  State<PlaceStatisticsScreen> createState() => _PlaceStatisticsScreenState();
}

class _PlaceStatisticsScreenState extends State<PlaceStatisticsScreen> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    final fs = FirebaseFirestore.instance.collection('places');

    try {
      final results = await Future.wait([
        fs.count().get(),
        fs.where('isApproved', isEqualTo: true).count().get(),
        fs.where('isApproved', isEqualTo: false).count().get(),
        fs.where('isActive', isEqualTo: true).count().get(),
        fs.where('isActive', isEqualTo: false).count().get(),
        fs.where('hasWifi', isEqualTo: true).count().get(),
        fs.where('hasParking', isEqualTo: true).count().get(),
        fs.where('hasRestroom', isEqualTo: true).count().get(),
        fs.where('hasAccessibility', isEqualTo: true).count().get(),
        fs.where('isFamilyFriendly', isEqualTo: true).count().get(),
        fs.where('isHalal', isEqualTo: true).count().get(),
        fs.where('hasDelivery', isEqualTo: true).count().get(),
        fs.where('hasReservation', isEqualTo: true).count().get(),
      ]);

      final topRated = await fs
          .where('averageRating', isGreaterThan: 0)
          .orderBy('averageRating', descending: true)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _stats = {
            'total': results[0].count ?? 0,
            'approved': results[1].count ?? 0,
            'unapproved': results[2].count ?? 0,
            'active': results[3].count ?? 0,
            'inactive': results[4].count ?? 0,
            'hasWifi': results[5].count ?? 0,
            'hasParking': results[6].count ?? 0,
            'hasRestroom': results[7].count ?? 0,
            'hasAccessibility': results[8].count ?? 0,
            'isFamilyFriendly': results[9].count ?? 0,
            'isHalal': results[10].count ?? 0,
            'hasDelivery': results[11].count ?? 0,
            'hasReservation': results[12].count ?? 0,
            'topRated': topRated.docs.map((d) {
              // ✅ FIX: لا يوجد cast زائد
              final data = d.data();
              return <String, dynamic>{'id': d.id, ...data};
            }).toList(),
          };
          _loading = false;
          _refreshing = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading place stats: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (mounted) setState(() => _refreshing = true);
    await _loadStats();
  }

  int _getInt(String key) => (_stats[key] as int?) ?? 0;
  double _safeRatio(int count, int total) {
    final t = total > 0 ? total : 1;
    return (count / t).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إحصائيات الأماكن',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
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
      onRefresh: _onRefresh,
      color: YaBaladiDesignTokens.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          _buildTotalCard(),
          const SizedBox(height: 16),
          _buildStatusCards(),
          const SizedBox(height: 16),
          _buildServicesSection(),
          const SizedBox(height: 16),
          _buildTopRatedSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final total = _getInt('total');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.place, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الأماكن المسجلة',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'مكان',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    final total = _getInt('total');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حالة الأماكن',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _circularStatCard(
                'معتمد',
                _getInt('approved'),
                total,
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _circularStatCard(
                'غير معتمد',
                _getInt('unapproved'),
                total,
                Colors.orange,
                Icons.pending_actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _circularStatCard(
                'نشط',
                _getInt('active'),
                total,
                Colors.teal,
                Icons.bolt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _circularStatCard(
                'غير نشط',
                _getInt('inactive'),
                total,
                Colors.grey,
                Icons.block,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circularStatCard(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final ratio = _safeRatio(count, total);
    final percent = (ratio * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            '($count من $total)',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final total = _getInt('total');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'توافر الخدمات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'نسبة الأماكن التي تدعم كل خدمة',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 12),
        _serviceCard(
            'واي فاي', _getInt('hasWifi'), total, Icons.wifi, Colors.blue),
        _serviceCard('موقف سيارات', _getInt('hasParking'), total,
            Icons.local_parking, Colors.purple),
        _serviceCard('دورة مياه', _getInt('hasRestroom'), total, Icons.wc,
            Colors.indigo),
        _serviceCard('سهولة الوصول', _getInt('hasAccessibility'), total,
            Icons.accessible, Colors.cyan),
        _serviceCard('مناسب للعائلات', _getInt('isFamilyFriendly'), total,
            Icons.family_restroom, Colors.pink),
        _serviceCard('حلال', _getInt('isHalal'), total, Icons.restaurant_menu,
            Colors.green),
        _serviceCard('توصيل', _getInt('hasDelivery'), total,
            Icons.delivery_dining, Colors.red),
        _serviceCard('حجز مسبق', _getInt('hasReservation'), total,
            Icons.event_seat, Colors.brown),
      ],
    );
  }

  Widget _serviceCard(
    String label,
    int count,
    int total,
    IconData icon,
    Color color,
  ) {
    final ratio = _safeRatio(count, total);
    final percent = (ratio * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              '$count ($percent%)',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRatedSection() {
    final topRated = (_stats['topRated'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أعلى 10 أماكن تقييماً',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (topRated.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.star_border, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد تقييمات بعد',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ستظهر الأماكن الأعلى تقييماً هنا عند إضافة تقييمات',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ...topRated.asMap().entries.map((entry) {
            final index = entry.key;
            final place = entry.value as Map<String, dynamic>;
            return _topRatedCard(
              index + 1,
              (place['nameAr'] ?? place['name'] ?? 'بدون اسم').toString(),
              (place['governorate'] ?? '').toString(),
              (place['averageRating'] as num? ?? 0).toDouble(),
              (place['reviewCount'] as num? ?? 0).toInt(),
            );
          }),
      ],
    );
  }

  Widget _topRatedCard(
    int rank,
    String name,
    String governorate,
    double rating,
    int reviews,
  ) {
    // ✅ FIX: final بدلاً من Color (لا يُعاد تعيينه)
    final medalColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey.shade400
            : rank == 3
                ? Colors.brown.shade300
                : Colors.blueGrey.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: medalColor == Colors.amber
                      ? Colors.orange.shade900
                      : medalColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (governorate.isNotEmpty)
                  Text(
                    governorate,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                '($reviews)',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
