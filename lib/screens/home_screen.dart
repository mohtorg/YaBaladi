// lib/screens/home_screen.dart
// [v11.7 — 2026-11-17] — SINGLE-LETTER AVATAR: _MasterWelcomeBanner._initials
//   now returns only the first character of the user's name (e.g., "م").
//   Matches welcome_header.dart v3.6. Design/UI/animations 100% unchanged.
// [v11.6 — 2026-11-17] — CENTRAL FORMATTER APPLIED

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../core/services/offer_cleanup_service.dart';
import '../core/location/location_source_sheet.dart';
import '../core/location/browsing_location_controller.dart';
import '../core/utils/address_formatter.dart';
import '../repositories/geo_zones_repository.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/notifications/widgets/notification_bell.dart';
import '../services/location_service.dart';

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
  String _neighborhood = '';
  String _dbDistrict = '';
  double? _currentLat;
  double? _currentLng;

  bool _isLoadingPlaces = true;
  List<Map<String, dynamic>> _governoratePlaces = [];
  String? _connectionError;

  late Future<List<_LocalCategory>> _categoriesFuture;
  int _fetchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndPlaces();
    _categoriesFuture = _loadCategories();
    OfferCleanupService.cleanExpiredOffers().catchError((Object e) {
      debugPrint('Offer cleanup failed: $e');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _parseColorHex(String colorHex) {
    try {
      return Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _parseIconName(String iconName) {
    if (iconName.contains('restaurant')) return Icons.restaurant;
    if (iconName.contains('cafe')) return Icons.local_cafe;
    if (iconName.contains('hotel')) return Icons.hotel;
    if (iconName.contains('beach')) return Icons.beach_access;
    if (iconName.contains('shop')) return Icons.shopping_bag;
    return Icons.category;
  }

  Future<String?> _fetchZoneName(double lat, double lng) async {
    try {
      final geoZone =
          await GeoZonesRepository.instance.findZoneForPoint(lat, lng);
      return (geoZone != null && geoZone.nameAr.isNotEmpty)
          ? geoZone.nameAr
          : null;
    } catch (e) {
      debugPrint('Error fetching geo zone: $e');
      return null;
    }
  }

  String _buildFormattedLocation() {
    return AddressFormatter.smart(
      dbDistrict: _dbDistrict,
      gpsDistrict: _neighborhood,
      governorate: _currentGovernorate,
      mode: AddressMode.medium,
    );
  }

  double? _getPlaceLat(Map<String, dynamic> p) {
    final loc = p['location'];
    if (loc is GeoPoint) return loc.latitude;
    return (p['latitude'] as num?)?.toDouble();
  }

  double? _getPlaceLng(Map<String, dynamic> p) {
    final loc = p['location'];
    if (loc is GeoPoint) return loc.longitude;
    return (p['longitude'] as num?)?.toDouble();
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<void> _fetchLocationAndPlaces() async {
    if (!mounted) return;
    final requestId = ++_fetchRequestId;
    setState(() {
      _isLoadingLocation = true;
      _isLoadingPlaces = true;
      _connectionError = null;
    });

    try {
      final locData =
          await LocationService.getCurrentLocation(forceRefresh: true);
      if (requestId != _fetchRequestId) return;

      if (locData != null) {
        final String gov = locData.governorate ?? 'بورسعيد';
        final String hood = locData.neighborhood ?? '';
        _currentLat = locData.latitude;
        _currentLng = locData.longitude;

        final String? zoneName =
            await _fetchZoneName(locData.latitude, locData.longitude);

        if (requestId != _fetchRequestId) return;

        _currentGovernorate = gov;
        _neighborhood = hood;
        _dbDistrict = zoneName ?? '';
      }
    } catch (e) {
      debugPrint('Location Service Error: $e');
    }

    if (!mounted || requestId != _fetchRequestId) return;
    setState(() => _isLoadingLocation = false);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('places')
          .where('governorate', isEqualTo: _currentGovernorate)
          .limit(100)
          .get();

      if (requestId != _fetchRequestId) return;

      final places = snap.docs.where((doc) {
        final data = doc.data();
        final isActive =
            data['isActive'] != false && data['is_active'] != false;
        final banReason = (data['banReason'] ?? '').toString();
        return isActive && banReason.isEmpty;
      }).map((doc) {
        return <String, dynamic>{...doc.data(), 'id': doc.id};
      }).toList();

      places.sort((a, b) {
        final ra = (a['averageRating'] as num?)?.toDouble() ?? 0.0;
        final rb = (b['averageRating'] as num?)?.toDouble() ?? 0.0;
        return rb.compareTo(ra);
      });

      if (!mounted || requestId != _fetchRequestId) return;
      setState(() {
        _governoratePlaces = places;
        _isLoadingPlaces = false;
      });
    } catch (e) {
      debugPrint('Places Fetch Error: $e');
      if (!mounted || requestId != _fetchRequestId) return;
      setState(() {
        _isLoadingPlaces = false;
        if (e.toString().contains('failed-precondition')) {
          _connectionError = 'index';
        } else if (e.toString().contains('network-request-failed')) {
          _connectionError = 'network';
        } else if (e.toString().contains('permission-denied')) {
          _connectionError = 'permission';
        }
      });
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
            final parsedColor = _parseColorHex(colorHex);
            final iconName = data['iconName'] as String? ?? 'category';
            final parsedIcon = _parseIconName(iconName);

            return _LocalCategory(
              id: doc.id,
              nameAr: data['nameAr'] as String? ?? '',
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

  Future<void> _openLocationSheet() async {
    final browsingCtrl = context.read<BrowsingLocationController>();
    await LocationSourceSheet.show(
      context,
      controller: browsingCtrl,
      currentLocation: null,
    );
    await _fetchLocationAndPlaces();
  }

  Widget _buildConnectionError(ThemeData theme, AppLocalizations l10n) {
    final bool isIndexError = _connectionError == 'index';
    final bool isPermission = _connectionError == 'permission';

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
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
          Icon(
              isPermission
                  ? Icons.lock_outline
                  : (isIndexError ? Icons.storage : Icons.cloud_off_rounded),
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            isPermission
                ? 'صلاحيات غير كافية'
                : (isIndexError ? 'مطلوب تحديث الفهارس' : l10n.noInternet),
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            isPermission
                ? 'يرجى التحقق من قواعد الأمان (Rules) في Firebase.'
                : (isIndexError
                    ? 'يرجى نشر الفهارس من Firebase Console.'
                    : l10n.error),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _fetchLocationAndPlaces(),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.retry),
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

  Widget _buildEnableLocationCard(ThemeData theme) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off,
                  size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'لم نتمكن من تحديد موقعك',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'قم بتفعيل الموقع لترى الأماكن القريبة منك',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _openLocationSheet,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('تحديد الموقع'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 40),
                  backgroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final displayName = auth.isLoggedIn ? auth.displayName : l10n.guest;
    final photoUrl = auth.photoUrl;

    final topPlaces = _governoratePlaces.take(5).toList();
    final String displayLocation = _buildFormattedLocation();

    final nearbyPlaces = _governoratePlaces.where((p) {
      final lat = _getPlaceLat(p);
      final lng = _getPlaceLng(p);
      if (lat == null ||
          lng == null ||
          _currentLat == null ||
          _currentLng == null) {
        return false;
      }
      final dist = _distanceKm(_currentLat!, _currentLng!, lat, lng);
      p['_distanceKm'] = dist;
      return dist <= 10.0;
    }).toList()
      ..sort((a, b) {
        final da = (a['_distanceKm'] as double?) ?? 999.0;
        final db = (b['_distanceKm'] as double?) ?? 999.0;
        return da.compareTo(db);
      });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _fetchLocationAndPlaces,
        color: theme.colorScheme.primary,
        child: Stack(
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
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _MasterWelcomeBanner(
                        displayName: displayName,
                        photoUrl: photoUrl,
                        isLoadingLocation: _isLoadingLocation,
                        locationText:
                            _isLoadingLocation ? l10n.loading : displayLocation,
                        onRefreshLocation: () => _fetchLocationAndPlaces(),
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
                          hintText: l10n.searchHint,
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: InkWell(
                        onTap: () => context.push('/offers'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade600
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer,
                                  color: Colors.white, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '🔥 أحدث العروض والخصومات',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.discoverPlaces,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 16),
                            ],
                          ),
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
                              Text(l10n.categories,
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
                              child: Text(l10n.filterAll)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<_LocalCategory>>(
                      future: _categoriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 90,
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        final allCats = snapshot.data ?? [];
                        if (allCats.isEmpty) {
                          return SizedBox(
                              height: 90,
                              child: Center(child: Text(l10n.noResults)));
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
                                      context
                                          .push('/categories?gov=$encodedGov');
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
                                        Text(l10n.filterAll,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
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
                                    final encodedGov = Uri.encodeComponent(
                                        _currentGovernorate);
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
                                            color: cat.color
                                                .withValues(alpha: 0.15),
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
                          Text(l10n.discoverPlaces,
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
                            ? _buildConnectionError(theme, l10n)
                            : topPlaces.isEmpty
                                ? _buildEmptyState(theme, l10n.noResults)
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
                          Text(l10n.nearby,
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
                            ? _buildConnectionError(theme, l10n)
                            : nearbyPlaces.isEmpty
                                ? (_currentLat == null
                                    ? _buildEnableLocationCard(theme)
                                    : _buildEmptyState(theme,
                                        'لا توجد أماكن قريبة منك حالياً'))
                                : SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: nearbyPlaces.length,
                                      itemBuilder: (context, index) {
                                        return _PremiumPlaceCard(
                                          place: nearbyPlaces[index],
                                          distanceKm: nearbyPlaces[index]
                                              ['_distanceKm'] as double?,
                                        );
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
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PremiumPlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final double? distanceKm;

  const _PremiumPlaceCard({required this.place, this.distanceKm});

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

  String _formatAddress(String? address, String? city, String? gov) {
    return AddressFormatter.full(
      address: address,
      district: city,
      governorate: gov,
    );
  }

  Widget _buildFilterIcons(ThemeData theme) {
    final activeFilters = <IconData>[];
    if (place['hasWifi'] == true) {
      activeFilters.add(Icons.wifi);
    }
    if (place['hasParking'] == true) {
      activeFilters.add(Icons.local_parking);
    }
    if (place['hasDelivery'] == true) {
      activeFilters.add(Icons.delivery_dining);
    }
    if (place['isFamilyFriendly'] == true) {
      activeFilters.add(Icons.family_restroom);
    }
    if (place['hasReservation'] == true) {
      activeFilters.add(Icons.event_seat);
    }
    if (place['isHalal'] == true) {
      activeFilters.add(Icons.verified);
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

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
    final String placeId = (place['id'] as String?) ?? '';
    final String name =
        (place['nameAr'] ?? place['name'] ?? 'مكان بدون اسم').toString();
    final String? categoryId =
        (place['category'] ?? place['categoryId'])?.toString();

    final String formattedAddress = _formatAddress(
      place['address']?.toString(),
      place['city']?.toString(),
      place['governorate']?.toString(),
    );

    final double rating = (place['averageRating'] as num?)?.toDouble() ?? 0.0;
    final int reviews = (place['reviewCount'] as num?)?.toInt() ?? 0;

    final bool isExcellenceActive =
        (place['isExcellence'] == true) || (rating >= 4.5 && reviews >= 10);
    final Color badgeColor =
        isExcellenceActive ? Colors.amber : Colors.grey.shade300;

    return InkWell(
      onTap: () {
        if (placeId.isEmpty) {
          return;
        }
        context.push('/home/place/$placeId');
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
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('($reviews)',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10)),
                  ],
                ),
                _buildFilterIcons(theme),
              ],
            ),
            const SizedBox(height: 8),
            if (formattedAddress.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formattedAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            if (distanceKm != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car,
                        size: 10, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text('${distanceKm!.toStringAsFixed(1)} كم',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _MasterWelcomeBanner extends StatefulWidget {
  final String displayName;
  final String? photoUrl;
  final bool isLoadingLocation;
  final String locationText;
  final VoidCallback onRefreshLocation;

  const _MasterWelcomeBanner({
    required this.displayName,
    required this.photoUrl,
    required this.isLoadingLocation,
    required this.locationText,
    required this.onRefreshLocation,
  });

  @override
  State<_MasterWelcomeBanner> createState() => _MasterWelcomeBannerState();
}

class _MasterWelcomeBannerState extends State<_MasterWelcomeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  late final Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _waveAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: -0.25), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.25, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _waveController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // ✅ v11.7: حرف واحد فقط
  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '؟';
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final hasPhoto =
        widget.photoUrl != null && widget.photoUrl!.trim().isNotEmpty;

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
                    backgroundImage:
                        hasPhoto ? NetworkImage(widget.photoUrl!) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            _initials(widget.displayName),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                                '${l10n.welcome}، ${widget.displayName}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          AnimatedBuilder(
                            animation: _waveAnim,
                            builder: (_, child) => Transform.rotate(
                              angle: _waveAnim.value,
                              child: child,
                            ),
                            child: const Text(
                              '👋',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(l10n.whereToGo,
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
                        if (widget.isLoadingLocation)
                          Row(children: [
                            SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        theme.colorScheme.primary))),
                            const SizedBox(width: 8),
                            Text(l10n.loading,
                                style: theme.textTheme.bodySmall),
                          ])
                        else
                          Text(widget.locationText,
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
                    onPressed: widget.isLoadingLocation
                        ? null
                        : widget.onRefreshLocation,
                    icon: Icon(Icons.gps_fixed_rounded,
                        color: widget.isLoadingLocation
                            ? theme.colorScheme.outline
                            : theme.colorScheme.primary,
                        size: 20),
                    tooltip: l10n.locationLabel,
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
