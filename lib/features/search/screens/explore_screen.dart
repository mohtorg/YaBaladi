// lib/features/search/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExploreScreen extends StatefulWidget {
  final String? categoryId; // ✅ اختياري لتوافق الراوتر

  const ExploreScreen({super.key, this.categoryId});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // بيانات تجريبية (Mock Data) لعرضها
  late List<Map<String, dynamic>> _places;

  @override
  void initState() {
    super.initState();
    // في التطبيق الحقيقي، ستقوم بجلب البيانات من Firebase هنا بناءً على widget.categoryId
    _loadMockData();
  }

  void _loadMockData() {
    _places = [
      {
        'id': 'p1',
        'name': 'مطعم ريكو',
        'category': 'مطاعم',
        'rating': 4.8,
        'reviewCount': 120,
        'isOpen': true,
        'image':
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500&auto=format&fit=crop&q=60',
      },
      {
        'id': 'p2',
        'name': 'كافيه بورسعيد',
        'category': 'مقاهي',
        'rating': 4.5,
        'reviewCount': 85,
        'isOpen': true,
        'image':
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500&auto=format&fit=crop&q=60',
      },
      {
        'id': 'p3',
        'name': 'مطعم الشرقاوي',
        'category': 'مطاعم',
        'rating': 4.2,
        'reviewCount': 45,
        'isOpen': false,
        'image':
            'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500&auto=format&fit=crop&q=60',
      },
    ];

    // فلترة تجريبية إذا تم تمرير تصنيف
    if (widget.categoryId != null) {
      _places =
          _places.where((p) => p['category'] == widget.categoryId).toList();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.categoryId ?? 'استكشاف الأماكن';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── شريط البحث والفلترة ───
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث داخل هذه النتائج...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                // منطق البحث المحلي
              },
            ),
          ),

          // ─── قائمة النتائج ───
          Expanded(
            child: _places.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return _PlaceListCard(place: place);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 80, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج مطابقة',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ترتيب النتائج حسب',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('الأعلى تقييماً'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.near_me),
                title: const Text('الأقرب إليّ'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('مفتوح الآن'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجت بطاقة المكان في القائمة
// ═══════════════════════════════════════════════════════════════

class _PlaceListCard extends StatelessWidget {
  final Map<String, dynamic> place;

  const _PlaceListCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = place['isOpen'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // الانتقال لصفحة التفاصيل (مسار موجود في الراوتر)
          context.push('/home/place/${place['id']}');
        },
        child: Row(
          children: [
            // الصورة
            SizedBox(
              width: 120,
              height: 120,
              child: Image.network(
                place['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
            // التفاصيل
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            place['name'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // شارة مفتوح/مغلق
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOpen ? 'مفتوح' : 'مغلق',
                            style: TextStyle(
                              fontSize: 10,
                              color: isOpen ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place['category'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${place['rating']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${place['reviewCount']} تقييم)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
