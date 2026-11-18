// lib/features/places/screens/category_places_screen.dart
// [v2.3 — 2026-11-15] — SYNTAX FIX: Reverted to correct collection-if for empty state buttons.
// [v2.2 — 2026-11-15] — LINTER FIX: Converted isActive to final with definite assignment.
// [v2.1 — 2026-11-15] — PHASE 12 INTEGRATION.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/place_card.dart';
import '../../../core/services/adjusted_score_service.dart';
import '../../../theme/design_tokens.dart';

class CategoryPlacesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String governorate;

  const CategoryPlacesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.governorate,
  });

  @override
  State<CategoryPlacesScreen> createState() => _CategoryPlacesScreenState();
}

class _CategoryPlacesScreenState extends State<CategoryPlacesScreen> {
  String _sortBy = 'quality'; // 'quality' | 'trusted' | 'newest'
  bool _isGridView = false;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchCtrl.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'quality':
        return 'مرتبة حسب الجودة';
      case 'trusted':
        return 'مرتبة حسب الثقة';
      default:
        return 'مرتبة حسب الأحدث';
    }
  }

  /// ✅ Phase 12: هل المكان قابل للترتيب؟
  bool _isRankable(Map<String, dynamic> data) {
    return (data['isRankable'] as bool?) ??
        (((data['reviewCount'] as num?)?.toInt() ?? 0) >=
            AdjustedScoreService.minRatingsForRanking);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'عرض كقائمة' : 'عرض كشبكة',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'ترتيب حسب',
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'quality',
                child: Row(children: [
                  Icon(Icons.workspace_premium, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('الأعلى جودة'),
                ]),
              ),
              const PopupMenuItem(
                value: 'trusted',
                child: Row(children: [
                  Icon(Icons.verified_user, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('الأكثر ثقة'),
                ]),
              ),
              const PopupMenuItem(
                value: 'newest',
                child: Row(children: [
                  Icon(Icons.access_time, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('الأحدث إضافة'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'ابحث داخل هذه النتائج...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _searchFocus.unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .where('categoryId', isEqualTo: widget.categoryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }

                final allDocs = snapshot.data?.docs ?? [];

                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final gov = data['governorate']?.toString().trim() ?? '';
                  final govMatch = gov.contains(widget.governorate.trim()) ||
                      widget.governorate.trim().contains(gov);

                  // ✅ Linter Fix: final with definite assignment
                  final bool isActive;
                  if (data.containsKey('isActive')) {
                    isActive = data['isActive'] == true;
                  } else if (data.containsKey('is_active')) {
                    isActive = data['is_active'] == true;
                  } else {
                    isActive = true;
                  }

                  final name = (data['nameAr'] ?? data['name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final nameEn = (data['nameEn'] ?? data['name_en'] ?? '')
                      .toString()
                      .toLowerCase();
                  final searchMatch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      nameEn.contains(_searchQuery);

                  return govMatch && isActive && searchMatch;
                }).toList();

                if (docs.isEmpty) {
                  return _buildEmptyState(theme);
                }

                // ✅ الترتيب الذكي (Phase 12: rankable أولاً)
                final sortedDocs = docs.toList();
                sortedDocs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  // rankable قبل non-rankable
                  final aRank = _isRankable(dataA);
                  final bRank = _isRankable(dataB);
                  if (aRank != bRank) {
                    return aRank ? -1 : 1;
                  }

                  if (_sortBy == 'quality') {
                    final aScore =
                        (dataA['adjustedScore'] as num?)?.toDouble() ??
                            (dataA['averageRating'] as num?)?.toDouble() ??
                            0.0;
                    final bScore =
                        (dataB['adjustedScore'] as num?)?.toDouble() ??
                            (dataB['averageRating'] as num?)?.toDouble() ??
                            0.0;
                    return bScore.compareTo(aScore);
                  } else if (_sortBy == 'trusted') {
                    final aQ =
                        (dataA['sampleQuality'] as num?)?.toDouble() ?? 0.0;
                    final bQ =
                        (dataB['sampleQuality'] as num?)?.toDouble() ?? 0.0;
                    return bQ.compareTo(aQ);
                  } else {
                    final tA = (dataA['createdAt'] ?? dataA['created_at'])
                        as Timestamp?;
                    final tB = (dataB['createdAt'] ?? dataB['created_at'])
                        as Timestamp?;
                    return (tB?.seconds ?? 0).compareTo(tA?.seconds ?? 0);
                  }
                });

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${sortedDocs.length} مكان',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(_sortLabel, style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isGridView
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: sortedDocs.length,
                              itemBuilder: (context, index) {
                                final data = sortedDocs[index].data()
                                    as Map<String, dynamic>;
                                return PlaceCard(
                                  placeId: sortedDocs[index].id,
                                  nameAr: data['nameAr'] ??
                                      data['name'] ??
                                      'بدون اسم',
                                  nameEn:
                                      data['nameEn'] ?? data['name_en'] ?? '',
                                  imageUrl: (data['imageUrls'] as List?)
                                              ?.isNotEmpty ==
                                          true
                                      ? (data['imageUrls'] as List)
                                          .first
                                          .toString()
                                      : null,
                                  rating: (data['averageRating'] as num?)
                                          ?.toDouble() ??
                                      0.0,
                                  reviewCount:
                                      (data['reviewCount'] as num?)?.toInt() ??
                                          0,
                                  sampleQuality: (data['sampleQuality'] as num?)
                                      ?.toDouble(),
                                  isRankable: _isRankable(data), // ✅ Phase 12
                                  categoryId: data['categoryId'],
                                  geoZoneName: data['geoZoneName'],
                                  city: data['city'],
                                  governorate: data['governorate'],
                                  address: data['address'],
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: sortedDocs.length,
                              itemBuilder: (context, index) {
                                final data = sortedDocs[index].data()
                                    as Map<String, dynamic>;
                                return PlaceCard(
                                  placeId: sortedDocs[index].id,
                                  nameAr: data['nameAr'] ??
                                      data['name'] ??
                                      'بدون اسم',
                                  nameEn:
                                      data['nameEn'] ?? data['name_en'] ?? '',
                                  imageUrl: (data['imageUrls'] as List?)
                                              ?.isNotEmpty ==
                                          true
                                      ? (data['imageUrls'] as List)
                                          .first
                                          .toString()
                                      : null,
                                  rating: (data['averageRating'] as num?)
                                          ?.toDouble() ??
                                      0.0,
                                  reviewCount:
                                      (data['reviewCount'] as num?)?.toInt() ??
                                          0,
                                  sampleQuality: (data['sampleQuality'] as num?)
                                      ?.toDouble(),
                                  isRankable: _isRankable(data), // ✅ Phase 12
                                  categoryId: data['categoryId'],
                                  geoZoneName: data['geoZoneName'],
                                  city: data['city'],
                                  governorate: data['governorate'],
                                  address: data['address'],
                                );
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 80, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'لا توجد نتائج تطابق "$_searchQuery"'
                  : 'لا توجد أماكن مضافة في "${widget.categoryName}" حتى الآن في ${widget.governorate}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // ✅ Collection-If (valid in children list, no braces, no return needed)
            if (_searchQuery.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('مسح البحث'),
              )
            else
              FilledButton.icon(
                onPressed: () => context.push('/home'),
                icon: const Icon(Icons.home),
                label: const Text('العودة للرئيسية'),
                style: FilledButton.styleFrom(
                    backgroundColor: YaBaladiDesignTokens.primaryBlue),
              ),
          ],
        ),
      ),
    );
  }
}
