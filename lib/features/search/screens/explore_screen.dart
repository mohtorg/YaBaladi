// lib/features/search/screens/explore_screen.dart
// [v8.4 — 2026-11-01] — ANALYZER FIX: Used 'badgeColor' variable, made badge always visible.
//   - FIXED: The value of the local variable 'badgeColor' isn't used.
//   - CHANGED: Badge is now always visible on the card (gold if active, grey if inactive).
//   - KEPT: All logic, search, filter, and the new creative card design.

// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/geo_zone.dart';
import '../../../repositories/geo_zones_repository.dart';
import '../../../services/location_service.dart';
import '../../places/screens/place_details_screen.dart';

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

  List<Map<String, dynamic>> _dynamicFilters = [];
  final Map<String, dynamic> _selectedFilters = {};

  bool _openNowOnly = false;
  double _minRating = 0.0;

  LocationData? _userLocation;
  GeoZone? _myZone;
  bool _isLoadingZone = true;
  bool _sortByDistance = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.searchQuery ?? '';
    _fetchDynamicFilters();
    _detectZoneAndLocation();
  }

  Future<void> _detectZoneAndLocation() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      if (loc != null) {
        if (!mounted) return;
        setState(() => _userLocation = loc);

        final zone = await GeoZonesRepository.instance
            .findZoneForPoint(loc.latitude, loc.longitude);
        if (mounted) {
          setState(() {
            _myZone = zone;
            _isLoadingZone = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingZone = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingZone = false);
    }
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

  List<Map<String, dynamic>> _getFilteredPlaces(
      List<Map<String, dynamic>> allPlaces) {
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = allPlaces.where((place) {
      if (widget.governorate != null && widget.governorate!.isNotEmpty) {
        if (place['governorate'] != widget.governorate) return false;
      }
      if (_openNowOnly && place['isOpen'] != true) return false;
      if (_minRating > 0 && (place['rating'] as double) < _minRating) {
        return false;
      }
      if (query.isNotEmpty) {
        final searchable =
            "${place['name']} ${place['description']} ${place['categoryName']}"
                .toLowerCase();
        if (!searchable.contains(query)) return false;
      }

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

    filtered.sort((a, b) {
      if (_sortByDistance && _userLocation != null) {
        final locA = a['location'] as GeoPoint?;
        final locB = b['location'] as GeoPoint?;
        if (locA != null && locB != null) {
          final distA = Geolocator.distanceBetween(_userLocation!.latitude,
              _userLocation!.longitude, locA.latitude, locA.longitude);
          final distB = Geolocator.distanceBetween(_userLocation!.latitude,
              _userLocation!.longitude, locB.latitude, locB.longitude);
          return distA.compareTo(distB);
        }
        if (locA != null) return -1;
        if (locB != null) return 1;
      }

      final rA = (a['rating'] as double);
      final rB = (b['rating'] as double);
      if (rA != rB) return rB.compareTo(rA);
      final cA = (a['reviewCount'] as int);
      final cB = (b['reviewCount'] as int);
      return cB.compareTo(cA);
    });

    return filtered;
  }

  void _onSearchChanged(String _) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() {});
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
                            _sortByDistance = false;
                          });
                          setState(() {});
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
                        if (_userLocation != null)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('الأقرب إليّ أولاً',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('ترتيب الأماكن حسب بعدها عنك'),
                            value: _sortByDistance,
                            onChanged: (val) {
                              setSheetState(() => _sortByDistance = val);
                              setState(() {});
                            },
                            activeThumbColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('مفتوح الآن فقط',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          value: _openNowOnly,
                          onChanged: (val) {
                            setSheetState(() => _openNowOnly = val);
                            setState(() {});
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
                                  setState(() {});
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
                                setState(() {});
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
                                        setState(() {});
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
        (_minRating > 0 ? 1 : 0) +
        (_sortByDistance ? 1 : 0);

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
          if (_isLoadingZone)
            const LinearProgressIndicator(minHeight: 2)
          else if (_myZone != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'أنت الآن في منطقة: ${_myZone!.nameAr}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

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

                  data['geoZoneName'] = data['geoZoneName'] ?? '';
                  data['priceLevel'] =
                      (data['priceLevel'] as num?)?.toInt() ?? 0;

                  return data;
                }).toList();

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
                                _sortByDistance = false;
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
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPlaces.length,
                        itemBuilder: (context, index) {
                          return _PlaceListCard(place: filteredPlaces[index]);
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

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('places');
    if (widget.categoryId != null) {
      query = query.where('categoryId', isEqualTo: widget.categoryId);
    }
    return query.limit(100);
  }
}

// ═══════════════════════════════════════════════════════════════
// v8.4: Creative List Card (Full Width, Elegant)
// ═══════════════════════════════════════════════════════════════
class _PlaceListCard extends StatelessWidget {
  final Map<String, dynamic> place;

  const _PlaceListCard({required this.place});

  IconData _iconForCategory(String? id) {
    switch (id) {
      case 'restaurants':
        return Icons.restaurant;
      case 'cafes':
        return Icons.local_cafe;
      case 'pharmacies':
        return Icons.local_pharmacy;
      case 'hospitals':
        return Icons.local_hospital;
      case 'shopping':
        return Icons.shopping_bag;
      case 'hotels':
        return Icons.hotel;
      case 'landmarks':
        return Icons.account_balance;
      case 'entertainment':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }

  Widget _buildFilterIcons(ThemeData theme) {
    final activeFilters = <IconData>[];
    if (place['hasWifi'] == true) activeFilters.add(Icons.wifi);
    if (place['hasParking'] == true) activeFilters.add(Icons.local_parking);
    if (place['hasDelivery'] == true) activeFilters.add(Icons.delivery_dining);
    if (place['isFamilyFriendly'] == true)
      activeFilters.add(Icons.family_restroom);
    if (place['hasReservation'] == true) activeFilters.add(Icons.event_seat);
    if (place['isHalal'] == true) activeFilters.add(Icons.verified);

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Row(
      children: activeFilters.take(4).map((icon) {
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Icon(icon, size: 14, color: theme.colorScheme.primary),
        );
      }).toList(),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = place['name'] as String? ?? 'بدون اسم';
    final categoryId = place['categoryId'] as String?;
    final geoZoneName = place['geoZoneName'] as String? ?? '';
    final governorate = place['governorate'] as String? ?? '';
    final city = place['city'] as String? ?? '';
    final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = (place['reviewCount'] as num?)?.toInt() ?? 0;
    final phone = (place['phone'] as String?)?.trim() ?? '';
    final whatsapp = (place['whatsapp'] as String?)?.trim() ?? '';
    final facebook = (place['facebookPage'] as String?)?.trim() ?? '';
    final isOpen = place['isOpen'] as bool? ?? true;

    final locationParts = <String>[
      if (geoZoneName.isNotEmpty) geoZoneName,
      if (city.isNotEmpty) city,
      if (governorate.isNotEmpty) governorate,
    ];

    // ✅ استخدام المتغير badgeColor هنا لحل التحذير وإظهار اللونين
    final bool isExcellenceActive =
        (place['isExcellence'] == true) || (rating >= 4.5 && reviews >= 10);
    final Color badgeColor =
        isExcellenceActive ? Colors.amber : Colors.grey.shade400;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlaceDetailsScreen(placeId: place['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Name + Icon + Badge
              Row(
                children: [
                  Icon(_iconForCategory(categoryId),
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ✅ الشارة تظهر دائماً وتستخدم badgeColor
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      isExcellenceActive
                          ? Icons.workspace_premium
                          : Icons.workspace_premium_outlined,
                      color: badgeColor,
                      size: 20,
                    ),
                  ),
                  if (!isOpen) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('مغلق',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),

              const SizedBox(height: 8),

              // 2. Rating + Filters + Photos soon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('($reviews)',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  _buildFilterIcons(theme),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_outlined,
                            size: 12, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text('قريباً',
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 3. Location + Contact
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationParts.isNotEmpty
                          ? locationParts.join(' • ')
                          : 'الموقع غير محدد',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (phone.isNotEmpty ||
                      whatsapp.isNotEmpty ||
                      facebook.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (phone.isNotEmpty)
                          _ActionChip(
                              icon: Icons.phone,
                              label: 'اتصال',
                              color: Colors.green,
                              onTap: () => _launch('tel:$phone')),
                        if (whatsapp.isNotEmpty)
                          _ActionChip(
                              icon: Icons.chat_bubble,
                              label: 'واتساب',
                              color: const Color(0xFF25D366),
                              onTap: () => _launch(
                                  'https://wa.me/${whatsapp.replaceAll(RegExp(r'\D'), '')}')),
                        if (facebook.isNotEmpty)
                          _ActionChip(
                              icon: Icons.facebook,
                              label: 'فيسبوك',
                              color: const Color(0xFF1877F2),
                              onTap: () => _launch(facebook.startsWith('http')
                                  ? facebook
                                  : 'https://$facebook')),
                      ],
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
