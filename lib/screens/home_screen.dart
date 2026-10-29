// lib/screens/home_screen.dart
// [v7.9.2 — 2026-10-28] — ADD: NotificationBell in _MasterWelcomeBanner

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/notifications/widgets/notification_bell.dart'; // ✅ استيراد الجرس
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

class _NeighborhoodPoint {
  final String name;
  final double lat;
  final double lng;
  const _NeighborhoodPoint(this.name, this.lat, this.lng);
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

  // ✅ متغير جديد لتتبع حالة الخطأ (خاص بالشبكة)
  String? _connectionError;

  late Future<List<_LocalCategory>> _categoriesFuture;

  final List<_NeighborhoodPoint> _portSaidNeighborhoods = const [
    _NeighborhoodPoint('حي الشرق', 31.265, 32.305),
    _NeighborhoodPoint('حي المناخ', 31.250, 32.280),
    _NeighborhoodPoint('حي الزهور', 31.260, 32.290),
    _NeighborhoodPoint('حي العرب', 31.240, 32.290),
    _NeighborhoodPoint('حي الجنوب', 31.200, 32.300),
    _NeighborhoodPoint('حي غرب', 31.260, 32.260),
    _NeighborhoodPoint('حي الضواحي', 31.230, 32.320),
  ];

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
      _connectionError = null; // مسح الخطأ عند إعادة المحاولة
    });

    try {
      final locData =
          await LocationService.getCurrentLocation(forceRefresh: true);

      if (locData != null) {
        final String gov = locData.governorate ?? 'بورسعيد';
        String hood = locData.neighborhood ?? '';

        if (gov.contains('بورسعيد') &&
            (hood.isEmpty || hood.contains('بورسعيد') || hood == gov)) {
          hood = _determineNeighborhood(locData.latitude, locData.longitude);
        } else if (hood.isEmpty || hood == gov) {
          hood = 'وسط المدينة';
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

  String _determineNeighborhood(double lat, double lng) {
    double minDistance = double.infinity;
    String closestNeighborhood = 'وسط المدينة';

    for (final hood in _portSaidNeighborhoods) {
      final distance = Geolocator.distanceBetween(lat, lng, hood.lat, hood.lng);
      if (distance < minDistance) {
        minDistance = distance;
        closestNeighborhood = hood.name;
      }
    }
    return closestNeighborhood;
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
                          height: 200,
                          child: Center(child: CircularProgressIndicator()))
                      : _connectionError != null
                          ? _buildConnectionError(theme)
                          : topPlaces.isEmpty
                              ? _buildEmptyState(theme,
                                  'لا توجد وجهات مميزة في $_currentGovernorate بعد')
                              : SizedBox(
                                  height: 220,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: topPlaces.length,
                                    itemBuilder: (context, index) {
                                      return _PremiumPlaceCard(
                                          place: topPlaces[index],
                                          rank: index + 1);
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
                          height: 150,
                          child: Center(child: CircularProgressIndicator()))
                      : _connectionError != null
                          ? const SizedBox(height: 10)
                          : _governoratePlaces.isEmpty
                              ? _buildEmptyState(theme,
                                  'كن أول من يضيف مكاناً في $_currentGovernorate!')
                              : SizedBox(
                                  height: 220,
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

class _PremiumPlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final int? rank;

  const _PremiumPlaceCard({required this.place, this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = place['nameAr'] ?? place['name'] ?? 'بدون اسم';
    final rating = (place['averageRating'] as num?)?.toDouble() ?? 0.0;
    final images = place['imageUrls'] as List?;

    final imageUrl = (images != null && images.isNotEmpty)
        ? images[0]
        : 'https://images.unsplash.com/photo-1542314831-c6a4d146682c?w=500';

    return Container(
      width: 220,
      margin: const EdgeInsets.only(left: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
        child: InkWell(
          onTap: () => context.push('/home/place/${place['id']}'),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              if (rank != null && rank! <= 3)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? Colors.amber
                          : (rank == 2
                              ? Colors.grey.shade300
                              : Colors.brown.shade300),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('TOP $rank',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                // ✅ إضافة زر الإشعارات هنا
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
