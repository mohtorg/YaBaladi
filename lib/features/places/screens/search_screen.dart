// lib/features/places/screens/search_screen.dart
// [v4.3 — 2026-11-15] — VERIFIED: Clean file, no linter issues, delegates formatting to PlaceCard.
// [v4.2 — 2026-11-15] — Version bump: Address formatting handled in PlaceCard v3.3.
// [v4.1 — 2026-11-15] — PHASE 12 INTEGRATION.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/place_card.dart';
import '../widgets/places_filter_sheet.dart';
import '../controllers/places_controller.dart';
import '../../filters/controllers/filters_controller.dart';
import '../../../core/services/adjusted_score_service.dart';
import '../../../models/filter_definition.dart';
import '../../../theme/design_tokens.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final PlacesController _placesCtrl = PlacesController();
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
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _placesCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final filtersCtrl = context.read<FiltersController>();
    _placesCtrl.setFiltersMetadata(filtersCtrl.generalFilters);

    await showPlacesFilterSheet(
      context: context,
      controller: _placesCtrl,
      categoryId: null,
    );
    if (mounted) {
      setState(() {});
    }
  }

  bool _matchesDynamicFilters(Map<String, dynamic> data) {
    final filters = _placesCtrl.activeDynamicFilters;
    final metadata = _placesCtrl.filtersMetadata;

    for (final entry in filters.entries) {
      final filter = metadata[entry.key];
      if (filter == null || entry.value.isEmpty) {
        continue;
      }

      switch (filter.type) {
        case FilterType.boolean:
          final wanted = entry.value.values.first == 'true';
          final actual = data[filter.fieldKey] == true;
          if (actual != wanted) {
            return false;
          }
          break;
        case FilterType.singleChoice:
          final value = entry.value.values.first;
          if (data[filter.fieldKey]?.toString() != value) {
            return false;
          }
          break;
        case FilterType.multiChoice:
          final raw = data[filter.fieldKey];
          final list =
              (raw is List) ? raw.map((e) => e.toString()).toSet() : <String>{};
          if (!entry.value.values.every((s) => list.contains(s))) {
            return false;
          }
          break;
        case FilterType.range:
          final min = double.tryParse(entry.value.values.first) ?? 0;
          final v = (data[filter.fieldKey] as num?)?.toDouble() ?? 0;
          if (v < min) {
            return false;
          }
          break;
        case FilterType.sort:
          break;
      }
    }
    return true;
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
        title: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ابحث باسم المكان...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _searchFocus.unfocus(),
        ),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'فلترة',
                onPressed: _openFilters,
              ),
              if (_placesCtrl.activeDynamicFilters.values
                  .any((s) => s.isNotEmpty))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد أماكن مضافة حالياً.'));
          }

          // ✅ فلترة + ترتيب ذكي (Phase 12: rankable أولاً)
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final isActive =
                data['isActive'] != false && data['is_active'] != false;
            if (!isActive) {
              return false;
            }

            if (_searchQuery.isNotEmpty) {
              final name = (data['nameAr'] ?? data['name'] ?? '')
                  .toString()
                  .toLowerCase();
              final nameEn = (data['nameEn'] ?? data['name_en'] ?? '')
                  .toString()
                  .toLowerCase();
              if (!name.contains(_searchQuery) &&
                  !nameEn.contains(_searchQuery)) {
                return false;
              }
            }

            return _matchesDynamicFilters(data);
          }).toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              // ✅ Phase 12: rankable places first
              final aRank = _isRankable(aData);
              final bRank = _isRankable(bData);
              if (aRank != bRank) {
                return aRank ? -1 : 1;
              }

              // ثم ترتيب adjustedScore داخل كل مجموعة
              final aScore = (aData['adjustedScore'] as num?)?.toDouble() ??
                  (aData['averageRating'] as num?)?.toDouble() ??
                  0.0;
              final bScore = (bData['adjustedScore'] as num?)?.toDouble() ??
                  (bData['averageRating'] as num?)?.toDouble() ??
                  0.0;
              return bScore.compareTo(aScore);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'لا توجد نتائج مطابقة للفلاتر'
                        : 'لا توجد نتائج تطابق "$_searchQuery"',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return PlaceCard(
                placeId: docs[index].id,
                nameAr: data['nameAr'] ?? data['name'] ?? 'بدون اسم',
                nameEn: data['nameEn'] ?? data['name_en'] ?? '',
                imageUrl: (data['imageUrls'] as List?)?.isNotEmpty == true
                    ? (data['imageUrls'] as List).first.toString()
                    : null,
                rating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
                reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
                sampleQuality: (data['sampleQuality'] as num?)?.toDouble(),
                isRankable: _isRankable(data), // ✅ Phase 12
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
    );
  }
}
