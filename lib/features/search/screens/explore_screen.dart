// lib/features/search/screens/explore_screen.dart
//
// [v7.1 — 2026-10-28] — FATAL FIX: Removed setState() from build, implemented local non-state filtering

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExploreScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final String? governorate;
  final String? searchQuery;

  const ExploreScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.governorate,
    this.searchQuery,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // ─── الفلاتر الديناميكية ───
  List<Map<String, dynamic>> _dynamicFilters = [];
  final Map<String, dynamic> _selectedFilters = {};

  // ─── الفلاتر الثابتة ───
  bool _openNowOnly = false;
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.searchQuery ?? '';
    _fetchDynamicFilters();
  }

  Future<void> _fetchDynamicFilters() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('filters')
          .where('isActive', isEqualTo: true)
          .get();

      if (!mounted) return;
      setState(() {
        _dynamicFilters = snap.docs.map((d) => d.data()).toList();
        _dynamicFilters.sort((a, b) => ((a['order'] as num?) ?? 100)
            .compareTo((b['order'] as num?) ?? 100));
      });
    } catch (e) {
      debugPrint('Error fetching dynamic filters: $e');
    }
  }

  // ✅ دالة فلترة محلية صرفة (لا تحتوي على setState)
  List<Map<String, dynamic>> _getFilteredPlaces(
      List<Map<String, dynamic>> allPlaces) {
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = allPlaces.where((place) {
      // 1. فلتر المحافظة
      if (widget.governorate != null && widget.governorate!.isNotEmpty) {
        if (place['governorate'] != widget.governorate) return false;
      }

      // 2. فلتر مفتوح الآن
      if (_openNowOnly && place['isOpen'] != true) return false;

      // 3. فلتر التقييم
      if (_minRating > 0 && (place['rating'] as double) < _minRating) {
        return false;
      }

      // 4. فلتر البحث النصي
      if (query.isNotEmpty) {
        final searchable =
            "${place['name']} ${place['description']} ${place['categoryName']}"
                .toLowerCase();
        if (!searchable.contains(query)) return false;
      }

      // 5. الفلاتر الديناميكية
      for (final entry in _selectedFilters.entries) {
        final key = entry.key;
        final selectedVal = entry.value;

        if (selectedVal is bool) {
          if (selectedVal == true && place[key] != true) return false;
        } else if (selectedVal is String) {
          if (place[key]?.toString() != selectedVal) return false;
        } else if (selectedVal is num) {
          if ((place[key] as num? ?? 0) < selectedVal) return false;
        }
      }

      return true;
    }).toList();

    // ✅ الفرز الذكي
    filtered.sort((a, b) {
      final rA = (a['rating'] as double);
      final rB = (b['rating'] as double);
      if (rA != rB) return rB.compareTo(rA);
      final cA = (a['reviewCount'] as int);
      final cB = (b['reviewCount'] as int);
      return cB.compareTo(cA);
    });

    return filtered;
  }

  // ✅ دالة المستمع للكتابة (Debounce)
  void _onSearchChanged(String _) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() {}); // إعادة بناء الواجهة فقط
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الفلاتر',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedFilters.clear();
                            _openNowOnly = false;
                            _minRating = 0;
                          });
                          setState(() {}); // تحديث الشاشة الرئيسية
                        },
                        child: const Text('مسح الكل',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('مفتوح الآن فقط',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          value: _openNowOnly,
                          onChanged: (val) {
                            setSheetState(() => _openNowOnly = val);
                            setState(() {}); // تحديث الشاشة الرئيسية
                          },
                          activeThumbColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        const Text('أقل تقييم',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            Expanded(
                              child: Slider(
                                value: _minRating,
                                min: 0,
                                max: 5,
                                divisions: 10,
                                label: _minRating == 0
                                    ? 'الكل'
                                    : '${_minRating.toStringAsFixed(1)}+',
                                onChanged: (val) {
                                  setSheetState(() => _minRating = val);
                                  setState(() {}); // تحديث الشاشة الرئيسية
                                },
                              ),
                            ),
                            Text(_minRating == 0
                                ? 'الكل'
                                : '${_minRating.toStringAsFixed(1)}+'),
                          ],
                        ),
                        const Divider(),
                        ..._dynamicFilters.map((filter) {
                          final type = filter['type'] ?? 'boolean';
                          final fieldKey = filter['fieldKey'];
                          final name = filter['nameAr'] ?? fieldKey;

                          if (type == 'boolean' || type == 'sort') {
                            final val =
                                _selectedFilters[fieldKey] as bool? ?? false;
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              value: val,
                              onChanged: (newVal) {
                                setSheetState(() {
                                  if (newVal) {
                                    _selectedFilters[fieldKey] = true;
                                  } else {
                                    _selectedFilters.remove(fieldKey);
                                  }
                                });
                                setState(() {}); // تحديث الشاشة الرئيسية
                              },
                              activeThumbColor:
                                  Theme.of(context).colorScheme.primary,
                            );
                          }

                          if (type == 'single_choice' ||
                              type == 'multi_choice') {
                            final options = filter['options'] as List? ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: options.map((opt) {
                                    final optVal = opt['value'];
                                    final optLabel = opt['labelAr'] ?? optVal;
                                    final isSelected =
                                        _selectedFilters[fieldKey]
                                                ?.toString() ==
                                            optVal.toString();

                                    return FilterChip(
                                      label: Text(optLabel),
                                      selected: isSelected,
                                      onSelected: (sel) {
                                        setSheetState(() {
                                          if (sel) {
                                            _selectedFilters[fieldKey] = optVal;
                                          } else {
                                            _selectedFilters.remove(fieldKey);
                                          }
                                        });
                                        setState(
                                            () {}); // تحديث الشاشة الرئيسية
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          }
                          return const SizedBox();
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title = widget.categoryName ?? 'استكشاف الأماكن';
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      title = 'نتائج البحث';
    }

    final int activeFiltersCount = _selectedFilters.length +
        (_openNowOnly ? 1 : 0) +
        (_minRating > 0 ? 1 : 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // ✅ شريط البحث + زر القمع
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث داخل هذه النتائج...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: activeFiltersCount > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: Badge(
                      isLabelVisible: activeFiltersCount > 0,
                      label: Text('$activeFiltersCount',
                          style: const TextStyle(fontSize: 10)),
                      child: Icon(
                        Icons.filter_alt,
                        color: activeFiltersCount > 0
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    onPressed: _showFilterSheet,
                    tooltip: 'الفلاتر',
                  ),
                ),
              ],
            ),
          ),

          // ✅ StreamBuilder للتحديث الفوري
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // 1. تحويل البيانات
                final allPlaces = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  data['name'] = data['nameAr'] ?? data['name'] ?? 'بدون اسم';
                  data['categoryName'] = data['categoryId'] ?? 'تصنيف';
                  data['rating'] =
                      (data['averageRating'] as num?)?.toDouble() ?? 0.0;
                  data['reviewCount'] =
                      (data['reviewCount'] as num?)?.toInt() ?? 0;
                  data['isOpen'] = data['isActive'] ?? true;
                  data['governorate'] = data['governorate'] ?? '';

                  final images = data['imageUrls'] as List?;
                  data['image'] = (images != null && images.isNotEmpty)
                      ? images[0]
                      : 'https://images.unsplash.com/photo-1542314831-c6a4d146682c?w=500';

                  return data;
                }).toList();

                // 2. تطبيق الفلاتر محلياً (بدون setState)
                final filteredPlaces = _getFilteredPlaces(allPlaces);

                if (filteredPlaces.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 80, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('لا توجد أماكن مطابقة',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('جرّب تعديل كلمة البحث أو مسح الفلاتر',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedFilters.clear();
                                _openNowOnly = false;
                                _minRating = 0;
                                _searchCtrl.clear();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة تعيين الفلاتر'),
                          )
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // شريط عدد النتائج
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: theme.colorScheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'الأماكن المتاحة',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${filteredPlaces.length} مكان',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // قائمة النتائج
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPlaces.length,
                        itemBuilder: (context, index) {
                          final place = filteredPlaces[index];
                          return _PlaceListCard(place: place);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // بناء الاستعلام الأساسي
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('places');

    if (widget.categoryId != null) {
      query = query.where('categoryId', isEqualTo: widget.categoryId);
    }

    return query.limit(100);
  }
}

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
        onTap: () => context.push('/home/place/${place['id']}'),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Image.network(
                place['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
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
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place['categoryName'] as String,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          (place['rating'] as double).toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${place['reviewCount']} تقييم)',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
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
