// lib/features/search/screens/explore_screen.dart
//
// [v9.7 — 2026-11-17] — UNUSED VARIABLE FIX: Removed `geoZoneName` from
//   _PlaceListCard (no longer needed since address formatting uses
//   address/city/governorate directly).
// [v9.6 — 2026-11-15] — SMART ADDRESS + LINTER FIX

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

  late final Stream<QuerySnapshot> _placesStream;

  List<Map<String, dynamic>> _dynamicFilters = [];
  final Map<String, dynamic> _selectedFilters = {};

  bool _openNowOnly = false;
  double _minRating = 0.0;

  LocationData? _userLocation;
  GeoZone? _myZone;
  bool _isLoadingZone = true;

  String _sortOption = 'rating'; // 'rating', 'distance', 'price'

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.searchQuery ?? '';
    _placesStream = _buildQuery().snapshots();
    _fetchDynamicFilters();
    _detectZoneAndLocation();
  }

  Future<void> _detectZoneAndLocation() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      if (loc != null) {
        if (!mounted) {
          return;
        }
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
        if (mounted) {
          setState(() => _isLoadingZone = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingZone = false);
      }
    }
  }

  Future<void> _fetchDynamicFilters() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('filters')
          .where('isActive', isEqualTo: true)
          .get();

      if (!mounted) {
        return;
      }
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
      // 1. Governorate match
      if (widget.governorate != null && widget.governorate!.isNotEmpty) {
        final placeGov = place['governorate']?.toString().trim() ?? '';
        if (placeGov != widget.governorate!.trim()) {
          return false;
        }
      }

      // 2. Open Now
      if (_openNowOnly && place['isOpen'] != true) {
        return false;
      }

      // 3. Minimum Rating
      final placeRating = (place['rating'] as num?)?.toDouble() ?? 0.0;
      if (_minRating > 0 && placeRating < _minRating) {
        return false;
      }

      // 4. Text Search
      if (query.isNotEmpty) {
        final searchable =
            "${place['name']} ${place['description']} ${place['categoryName']}"
                .toLowerCase();
        if (!searchable.contains(query)) {
          return false;
        }
      }

      // 5. Dynamic Filters
      for (final entry in _selectedFilters.entries) {
        final key = entry.key;
        final selectedVal = entry.value;

        if (selectedVal is bool) {
          if (selectedVal == true && place[key] != true) {
            return false;
          }
        } else if (selectedVal is String) {
          if (place[key]?.toString() != selectedVal) {
            return false;
          }
        } else if (selectedVal is num) {
          if ((place[key] as num? ?? 0) < selectedVal) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      if (_sortOption == 'distance' && _userLocation != null) {
        final locA = a['location'] as GeoPoint?;
        final locB = b['location'] as GeoPoint?;
        if (locA != null && locB != null) {
          final distA = Geolocator.distanceBetween(_userLocation!.latitude,
              _userLocation!.longitude, locA.latitude, locA.longitude);
          final distB = Geolocator.distanceBetween(_userLocation!.latitude,
              _userLocation!.longitude, locB.latitude, locB.longitude);
          return distA.compareTo(distB);
        }
        if (locA != null) {
          return -1;
        }
        if (locB != null) {
          return 1;
        }
      } else if (_sortOption == 'price') {
        final pA = (a['priceLevel'] as num?)?.toInt() ?? 0;
        final pB = (b['priceLevel'] as num?)?.toInt() ?? 0;
        return pA.compareTo(pB);
      }

      final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
      final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
      if (rA != rB) {
        return rB.compareTo(rA);
      }

      final cA = (a['reviewCount'] as num?)?.toInt() ?? 0;
      final cB = (b['reviewCount'] as num?)?.toInt() ?? 0;
      return cB.compareTo(cA);
    });

    return filtered;
  }

  void _onSearchChanged(String _) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {});
      }
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                            _sortOption = 'rating';
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
                        DropdownButtonFormField<String>(
                          value: _sortOption,
                          decoration: const InputDecoration(
                            labelText: 'ترتيب حسب',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'rating', child: Text('الأعلى تقييماً')),
                            DropdownMenuItem(
                                value: 'distance', child: Text('الأقرب إليّ')),
                            DropdownMenuItem(
                                value: 'price',
                                child: Text('السعر (الأقل أولاً)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => _sortOption = val);
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 16),
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
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text(
                        'تطبيق الفلاتر',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
    FocusManager.instance.primaryFocus?.unfocus();
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String title =
        widget.searchQuery != null && widget.searchQuery!.isNotEmpty
            ? 'نتائج البحث'
            : (widget.categoryName ?? 'استكشاف الأماكن');

    final int activeFiltersCount = _selectedFilters.length +
        (_openNowOnly ? 1 : 0) +
        (_minRating > 0 ? 1 : 0) +
        (_sortOption != 'rating' ? 1 : 0);

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
          SizedBox(
            height: 52,
            child: _isLoadingZone
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  )
                : _myZone != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.2)),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
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
              stream: _placesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final allPlaces = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isActive = data['isActive'] != false;
                  final banReason = (data['banReason'] ?? '').toString().trim();
                  return isActive && banReason.isEmpty;
                }).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  data['name'] = data['nameAr'] ?? data['name'] ?? 'بدون اسم';
                  data['categoryName'] =
                      data['category'] ?? data['categoryId'] ?? 'تصنيف';
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
                                _sortOption = 'rating';
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
// Creative List Card (Full Width, Elegant)
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

  /// ✅ v9.7: تنسيق العنوان "الشارع - حي الشرق - بورسعيد"
  String _formatAddress(String? address, String? city, String? gov) {
    final List<String> parts = [];

    final trimmedAddress = address?.trim() ?? '';
    if (trimmedAddress.isNotEmpty) {
      parts.add(trimmedAddress);
    }

    final trimmedCity = city?.trim() ?? '';
    if (trimmedCity.isNotEmpty) {
      final String formattedCity;
      if (!trimmedCity.startsWith('حي ')) {
        if (trimmedCity.startsWith('حي')) {
          formattedCity = 'حي ${trimmedCity.substring(2).trim()}';
        } else {
          formattedCity = 'حي $trimmedCity';
        }
      } else {
        formattedCity = trimmedCity;
      }
      parts.add(formattedCity);
    }

    final trimmedGov = gov?.trim() ?? '';
    if (trimmedGov.isNotEmpty) {
      parts.add(trimmedGov);
    }

    return parts.join(' - ');
  }

  Widget _buildFilterChips(ThemeData theme) {
    final List<Widget> chips = [];

    void addChip(IconData icon, String label, dynamic condition) {
      if (condition == true) {
        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    addChip(Icons.wifi, 'واي فاي', place['hasWifi']);
    addChip(Icons.local_parking, 'موقف', place['hasParking']);
    addChip(Icons.wc, 'دورة مياه', place['hasRestroom']);
    addChip(Icons.accessible, 'إتاحة', place['hasAccessibility']);
    addChip(Icons.family_restroom, 'عائلات', place['isFamilyFriendly']);
    addChip(Icons.beach_access, 'ظل', place['hasShade']);
    addChip(Icons.delivery_dining, 'توصيل', place['hasDelivery']);
    addChip(Icons.event_seat, 'حجز', place['hasReservation']);
    addChip(Icons.verified, 'حلال', place['isHalal']);

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
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
    final categoryId =
        place['category'] as String? ?? place['categoryId'] as String?;
    // ✅ v9.7: تم حذف geoZoneName (غير مستخدم)
    final governorate = place['governorate'] as String? ?? '';
    final city = place['city'] as String? ?? '';
    final address = place['address'] as String? ?? '';
    final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = (place['reviewCount'] as num?)?.toInt() ?? 0;
    final phone = (place['phone'] as String?)?.trim() ?? '';
    final whatsapp = (place['whatsapp'] as String?)?.trim() ?? '';
    final facebook = (place['facebookPage'] as String?)?.trim() ?? '';
    final isOpen = place['isOpen'] as bool? ?? true;

    final views = (place['viewCount'] as num?)?.toInt() ?? 0;
    final priceLevel = (place['priceLevel'] as num?)?.toInt() ?? 0;
    final hasActiveOffer = place['hasActiveOffer'] == true;
    final offerExpiry = (place['offerExpiryDate'] as Timestamp?)?.toDate();
    final isOfferValid = hasActiveOffer &&
        offerExpiry != null &&
        offerExpiry.isAfter(DateTime.now());

    final formattedAddress = _formatAddress(address, city, governorate);

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
          context.push('/home/place/${place['id']}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Name & Badges
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
                  if (isOfferValid) ...[
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF7F50), Color(0xFFFF4500)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '🔥 عرض',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      isExcellenceActive
                          ? Icons.workspace_premium
                          : Icons.workspace_premium_outlined,
                      color: badgeColor,
                      size: 20,
                    ),
                  ),
                  if (!isOpen) ...[
                    const SizedBox(width: 6),
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

              // Row 2: Rating & Views
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
                      if (views > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.visibility,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('$views',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      if (priceLevel >= 1 && priceLevel <= 4) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '\$' * priceLevel,
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
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

              // Row 3: Full Filter Chips
              _buildFilterChips(theme),

              const SizedBox(height: 10),

              // Row 4: Location & Action Chips
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formattedAddress.isNotEmpty
                          ? formattedAddress
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
