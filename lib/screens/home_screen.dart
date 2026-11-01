// lib/screens/home_screen.dart
// [v8.5 — 2026-11-01] — ZONE SERVICE INTEGRATION
//   - REMOVED: Hardcoded _NeighborhoodPoint list and _determineNeighborhood.
//   - ADDED: ZoneService to auto-detect the exact neighborhood from GeoJSON.
//   - KEPT: All UI, go_router navigation, categories, and premium cards.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/notifications/widgets/notification_bell.dart';
import '../features/places/screens/place_details_screen.dart';
import '../services/location_service.dart';
import '../core/services/zone_service.dart'; // ✅ استيراد خدمة الأحياء

class _LocalCategory {
  final String id;
  final String nameAr;
  final Color color;
  final IconData icon;
  final int order;

  const _LocalCategory({
    required this.id,
    required this.nameAr,
    required this.color,
    required this.icon,
    required this.order,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoadingLocation = true;
  String _currentGovernorate = 'بورسعيد';
  String _neighborhood = 'جاري التحديد...';

  bool _isLoadingPlaces = true;
  List<Map<String, dynamic>> _governoratePlaces = [];

  String? _connectionError;

  late Future<List<_LocalCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndPlaces();
    _categoriesFuture = _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndPlaces() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _isLoadingPlaces = true;
      _connectionError = null;
    });

    try {
      final locData =
          await LocationService.getCurrentLocation(forceRefresh: true);

      if (locData != null) {
        final String gov = locData.governorate ?? 'بورسعيد';
        String hood = locData.neighborhood ?? '';

        // ✅ استخدام ZoneService لمعرفة الحي الدقيق من ملف GeoJSON
        final zoneName = await ZoneService()
            .getZoneName(locData.latitude, locData.longitude);

        if (zoneName != null &&
            zoneName.isNotEmpty &&
            zoneName != 'منطقة غير معروفة') {
          hood = zoneName;
        } else if (hood.isEmpty || hood == gov) {
          hood = 'وسط المدينة'; // خيار احتياطي
        }

        _currentGovernorate = gov;
        _neighborhood = hood;
      }
    } catch (e) {
      debugPrint('Location Service Error: $e');
    }

    if (mounted) setState(() => _isLoadingLocation = false);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('places')
          .where('governorate', isEqualTo: _currentGovernorate)
          .get();

      final places = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      places.sort((a, b) {
        final rA = (a['averageRating'] as num?)?.toDouble() ?? 0.0;
        final rB = (b['averageRating'] as num?)?.toDouble() ?? 0.0;
        return rB.compareTo(rA);
      });

      if (mounted) {
        setState(() {
          _governoratePlaces = places;
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      debugPrint('Places Fetch Error: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
          if (e.toString().contains('network-request-failed')) {
            _connectionError = 'network';
          }
        });
      }
    }
  }

  Future<List<_LocalCategory>> _loadCategories() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('categories').get();
      final loadedCats = snap.docs
          .map((doc) {
            final data = doc.data();
            final isActive = data['isActive'];
            if (isActive == false || isActive == 'false') return null;

            final colorHex = data['colorHex'] as String? ?? '#0D6EFD';
            Color parsedColor = Colors.blue;
            try {
              parsedColor = Color(
                  int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
            } catch (_) {}

            final iconName = data['iconName'] as String? ?? 'category';
            IconData parsedIcon = Icons.category;
            if (iconName.contains('restaurant')) {
              parsedIcon = Icons.restaurant;
            } else if (iconName.contains('cafe')) {
              parsedIcon = Icons.local_cafe;
            } else if (iconName.contains('hotel')) {
              parsedIcon = Icons.hotel;
            } else if (iconName.contains('beach')) {
              parsedIcon = Icons.beach_access;
            } else if (iconName.contains('shop')) {
              parsedIcon = Icons.shopping_bag;
            }

            return _LocalCategory(
              id: doc.id,
              nameAr: data['nameAr'] as String? ?? 'بدون اسم',
              color: parsedColor,
              icon: parsedIcon,
              order: (data['order'] as num?)?.toInt() ?? 100,
            );
          })
          .whereType<_LocalCategory>()
          .toList();

      loadedCats.sort((a, b) => a.order.compareTo(b.order));
      return loadedCats;
    } catch (e) {
      debugPrint('Categories Load Error: $e');
      return [];
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.push('/search?q=${Uri.encodeComponent(query.trim())}');
    }
  }

  Widget _buildConnectionError(ThemeData theme) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'لا يوجد اتصال بالإنترنت',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى التحقق من الشبكة والمحاولة مرة أخرى.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _fetchLocationAndPlaces,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('تحديث'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final displayName = auth.isLoggedIn ? auth.displayName : 'زائر';
    final photoUrl = auth.photoUrl;

    final topPlaces = _governoratePlaces.take(5).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: _MasterWelcomeBanner(
                      displayName: displayName,
                      photoUrl: photoUrl,
                      isLoadingLocation: _isLoadingLocation,
                      city: _currentGovernorate,
                      neighborhood: _neighborhood,
                      onRefreshLocation: _fetchLocationAndPlaces,
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن مطعم، مقهى، مكان...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: () => _performSearch(_searchCtrl.text),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 8),
                            Text('التصنيفات',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        TextButton(
                            onPressed: () {
                              final encodedGov =
                                  Uri.encodeComponent(_currentGovernorate);
                              context.push('/categories?gov=$encodedGov');
                            },
                            child: const Text('عرض الكل')),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<List<_LocalCategory>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                            height: 90,
                            child: Center(child: CircularProgressIndicator()));
                      }
                      final allCats = snapshot.data ?? [];
                      if (allCats.isEmpty) {
                        return const SizedBox(
                            height: 90,
                            child: Center(child: Text('لا توجد تصنيفات')));
                      }
                      final displayedCats = allCats.take(8).toList();

                      return SizedBox(
                        height: 95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayedCats.length + 1,
                          itemBuilder: (context, index) {
                            if (index == displayedCats.length) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: InkWell(
                                  onTap: () {
                                    final encodedGov = Uri.encodeComponent(
                                        _currentGovernorate);
                                    context.push('/categories?gov=$encodedGov');
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: theme.colorScheme
                                                    .outlineVariant)),
                                        child: Icon(Icons.grid_view_rounded,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                            size: 26),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('المزيد',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final cat = displayedCats[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: InkWell(
                                onTap: () {
                                  final encodedName =
                                      Uri.encodeComponent(cat.nameAr);
                                  final encodedGov =
                                      Uri.encodeComponent(_currentGovernorate);
                                  context.push(
                                      '/home/category/${cat.id}?name=$encodedName&gov=$encodedGov');
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                          color:
                                              cat.color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: cat.color
                                                  .withValues(alpha: 0.3),
                                              width: 1.5)),
                                      child: Icon(cat.icon,
                                          color: cat.color, size: 28),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(cat.nameAr,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Text('وجهات تستحق الزيارة',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 20),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _isLoadingPlaces
                      ? const SizedBox(
                          height: 130,
                          child: Center(child: CircularProgressIndicator()))
                      : _connectionError != null
                          ? _buildConnectionError(theme)
                          : topPlaces.isEmpty
                              ? _buildEmptyState(theme,
                                  'لا توجد وجهات مميزة في $_currentGovernorate بعد')
                              : SizedBox(
                                  height: 140,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: topPlaces.length,
                                    itemBuilder: (context, index) {
                                      return _PremiumPlaceCard(
                                          place: topPlaces[index]);
                                    },
                                  ),
                                ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Text('أماكن مميزة حولك',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _isLoadingPlaces
                      ? const SizedBox(
                          height: 130,
                          child: Center(child: CircularProgressIndicator()))
                      : _connectionError != null
                          ? const SizedBox(height: 10)
                          : _governoratePlaces.isEmpty
                              ? _buildEmptyState(theme,
                                  'كن أول من يضيف مكاناً في $_currentGovernorate!')
                              : SizedBox(
                                  height: 140,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: _governoratePlaces.length,
                                    itemBuilder: (context, index) {
                                      return _PremiumPlaceCard(
                                          place: _governoratePlaces[index]);
                                    },
                                  ),
                                ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String text) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_outlined,
                size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(text,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ v8.4: Creative Compact Card (Inline Icon, Soft Layout)
// ═══════════════════════════════════════════════════════════════
class _PremiumPlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;

  const _PremiumPlaceCard({required this.place});

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
      children: activeFilters.take(3).map((icon) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, size: 12, color: theme.colorScheme.primary),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = place['nameAr'] ?? place['name'] ?? 'بدون اسم';
    final categoryId = place['categoryId']?.toString();
    final geoZoneName = place['geoZoneName'] ?? '';
    final city = place['city'] ?? '';
    final rating = (place['averageRating'] as num?)?.toDouble() ?? 0.0;
    final reviews = (place['reviewCount'] as num?)?.toInt() ?? 0;
    final locationText = geoZoneName.isNotEmpty ? geoZoneName : city;

    // ✅ استخدام المتغير badgeColor هنا لحل التحذير وإظهار اللونين
    final bool isExcellenceActive =
        (place['isExcellence'] == true) || (rating >= 4.5 && reviews >= 10);
    final Color badgeColor =
        isExcellenceActive ? Colors.amber : Colors.grey.shade300;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlaceDetailsScreen(placeId: place['id']),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Icon + Name + Badge
            Row(
              children: [
                Icon(_iconForCategory(categoryId),
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // ✅ الشارة تظهر دائماً وتستخدم badgeColor
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    isExcellenceActive
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    color: badgeColor,
                    size: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 2. Rating + Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($reviews)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                _buildFilterIcons(theme),
              ],
            ),

            const SizedBox(height: 8),

            // 3. Location
            if (locationText.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MasterWelcomeBanner extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final bool isLoadingLocation;
  final String city;
  final String neighborhood;
  final VoidCallback onRefreshLocation;

  const _MasterWelcomeBanner({
    required this.displayName,
    required this.photoUrl,
    required this.isLoadingLocation,
    required this.city,
    required this.neighborhood,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2)
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? Icon(Icons.person,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أهلاً بك، $displayName 👋',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('أين تريد أن تذهب اليوم؟',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12)),
                    ],
                  ),
                ),
                const NotificationBell(),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: Icon(Icons.location_on_rounded,
                        color: theme.colorScheme.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoadingLocation)
                          Row(children: [
                            SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        theme.colorScheme.primary))),
                            const SizedBox(width: 8),
                            Text('جاري تحديد الموقع...',
                                style: theme.textTheme.bodySmall),
                          ])
                        else
                          Text('$neighborhood - $city',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: isLoadingLocation ? null : onRefreshLocation,
                    icon: Icon(Icons.gps_fixed_rounded,
                        color: isLoadingLocation
                            ? theme.colorScheme.outline
                            : theme.colorScheme.primary,
                        size: 20),
                    tooltip: 'تحديث الموقع',
                    style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
