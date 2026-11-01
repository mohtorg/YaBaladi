// lib/features/places/screens/search_screen.dart
//
// [v1.1 — 2026-11-01] — LINT FIX: Added 'final' to local variables to satisfy strict analyzer rules.
//   - FIXED: `var docs` → `final docs`
//   - FIXED: `bool matchesSearch` → `final bool matchesSearch`
//   - FIXED: `bool matchesCategory` → `final bool matchesCategory`
//   - FIXED: `bool matchesZone` → `final bool matchesZone`
//   - KEPT: All original search, filtering, and UI logic.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/place_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory; // null تعني "الكل"
  String? _selectedZone; // null تعني "كل الأحياء"

  // قائمة تصنيفات أساسية (يمكنك جلبها ديناميكياً لاحقاً إذا أردت)
  final Map<String, String> _categories = {
    'restaurants': 'مطاعم',
    'cafes': 'مقاهي',
    'pharmacies': 'صيدليات',
    'hospitals': 'مستشفيات',
    'shopping': 'تسوق',
    'hotels': 'فنادق',
    'landmarks': 'معالم',
    'entertainment': 'ترفيه',
  };

  // أحياء بورسعيد (مستخرجة من ملف الـ GeoJSON الخاص بك)
  final List<String> _zones = [
    'الزهور',
    'المناخ',
    'القابوطي',
    'الشرق',
    'المنطقة الثانية',
    'مساكن خالد بن الوليد',
    'مساكن عمر بن الخطاب',
    'مساكن السلام',
    'الجلاء',
    'بورفؤاد',
    'العزب',
    'السلام',
    'غرب بورسعيد',
    'المنطقة الثالثة',
    // يمكنك إضافة باقي الأحياء هنا
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ابحث باسم المكان...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
        ),
      ),
      body: Column(
        children: [
          // ✅ شريط الفلاتر (التصنيف والحي)
          _buildFiltersBar(theme),

          // ✅ قائمة النتائج
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .where('isActive', isEqualTo: true) // نجلب النشطة فقط
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('لا توجد أماكن مضافة حالياً.'));
                }

                // 1. الفلترة محلياً (Client-side)
                // ✅ تم إضافة final هنا
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['nameAr'] ?? '').toString().toLowerCase();
                  final categoryId = data['categoryId']?.toString();
                  final zoneName = data['geoZoneName']?.toString();

                  // شرط البحث النصي
                  // ✅ تم إضافة final هنا
                  final bool matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery.toLowerCase());

                  // شرط التصنيف
                  // ✅ تم إضافة final هنا
                  final bool matchesCategory = _selectedCategory == null ||
                      categoryId == _selectedCategory;

                  // شرط الحي
                  // ✅ تم إضافة final هنا
                  final bool matchesZone = _selectedZone == null ||
                      (zoneName != null && zoneName.contains(_selectedZone!));

                  return matchesSearch && matchesCategory && matchesZone;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text('لا توجد نتائج تطابق بحثك',
                            style: theme.textTheme.bodyLarge),
                        if (_selectedZone != null ||
                            _selectedCategory != null ||
                            _searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedZone = null;
                                _selectedCategory = null;
                              });
                            },
                            child: const Text('مسح الفلاتر'),
                          ),
                      ],
                    ),
                  );
                }

                // 2. عرض النتائج
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final images = (data['imageUrls'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [];

                    return PlaceCard(
                      placeId: docs[index].id,
                      nameAr: data['nameAr'] ?? data['name'] ?? 'بدون اسم',
                      nameEn: data['nameEn'] ?? '',
                      imageUrl: images.isNotEmpty ? images.first : null,
                      rating:
                          (data['averageRating'] as num?)?.toDouble() ?? 0.0,
                      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
                      categoryId: data['categoryId'],
                      geoZoneName: data['geoZoneName'],
                      city: data['city'],
                      governorate: data['governorate'],
                      address: data['address'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Widgets ─────────────────────

  Widget _buildFiltersBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // فلتر الأحياء
            _buildFilterChip(
              theme: theme,
              label: _selectedZone ?? 'كل الأحياء',
              icon: Icons.location_on,
              isActive: _selectedZone != null,
              onTap: () => _showZonePicker(theme),
            ),
            const SizedBox(width: 8),

            // فلتر التصنيفات
            _buildFilterChip(
              theme: theme,
              label: _selectedCategory != null
                  ? _categories[_selectedCategory]!
                  : 'كل التصنيفات',
              icon: Icons.category,
              isActive: _selectedCategory != null,
              onTap: () => _showCategoryPicker(theme),
            ),

            // زر مسح الفلاتر
            if (_selectedZone != null || _selectedCategory != null) ...[
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.clear, size: 16),
                label: const Text('مسح'),
                onPressed: () {
                  setState(() {
                    _selectedZone = null;
                    _selectedCategory = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 18,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showZonePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('اختر الحي',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.map),
                      title: const Text('كل الأحياء'),
                      trailing: _selectedZone == null
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() => _selectedZone = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),
                    ..._zones.map((zone) => ListTile(
                          leading: const Icon(Icons.location_on,
                              size: 20, color: Colors.grey),
                          title: Text(zone),
                          trailing: _selectedZone == zone
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() => _selectedZone = zone);
                            Navigator.pop(context);
                          },
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('اختر التصنيف',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.apps),
                      title: const Text('كل التصنيفات'),
                      trailing: _selectedCategory == null
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),
                    ..._categories.entries.map((entry) => ListTile(
                          leading: const Icon(Icons.category,
                              size: 20, color: Colors.grey),
                          title: Text(entry.value),
                          trailing: _selectedCategory == entry.key
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = entry.key);
                            Navigator.pop(context);
                          },
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
