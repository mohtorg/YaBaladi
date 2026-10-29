// lib/features/places/screens/place_details_screen.dart
//
// [v5.0 — 2026-10-28] — UX MAJOR UPGRADE:
// StreamBuilder, Real Favorites, Bottom CTA, Quick Actions, Amenities, Reviews Preview

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../trip/controllers/trip_bag_controller.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeId;
  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openMap(double lat, double lng) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _whatsapp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final full =
        cleaned.startsWith('0') ? '20${cleaned.substring(1)}' : cleaned;
    final url = Uri.parse('https://wa.me/$full');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullScreen(List<String> images, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenImageViewer(images: images, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المكان')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المكان')),
            body: Center(child: Text('خطأ: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المكان')),
            body: const Center(child: Text('المكان غير موجود')),
          );
        }

        final data = snapshot.data!.data()!;
        final nameAr = data['nameAr']?.toString() ??
            data['name']?.toString() ??
            'بدون اسم';
        final nameEn = data['nameEn']?.toString() ?? '';
        final desc = data['description']?.toString() ?? '';
        final address = data['address']?.toString() ?? '';
        final city = data['city']?.toString() ?? '';
        final gov = data['governorate']?.toString() ?? '';
        final phone = data['phone']?.toString() ??
            data['businessPhone']?.toString() ??
            '';
        final whatsapp = data['whatsapp']?.toString() ?? '';
        final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
        final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
        final isActive = data['isActive'] as bool? ?? true;

        final locationRaw = data['location'];
        final geoPoint = locationRaw is GeoPoint ? locationRaw : null;

        final imagesRaw = data['imageUrls'] as List?;
        final images = imagesRaw?.map((e) => e.toString()).toList() ?? [];

        // المميزات
        final amenities = <(String, IconData)>[];
        if (data['hasWifi'] == true) amenities.add(('واي فاي', Icons.wifi));
        if (data['hasParking'] == true)
          amenities.add(('موقف سيارات', Icons.local_parking));
        if (data['hasRestroom'] == true)
          amenities.add(('دورات مياه', Icons.wc));
        if (data['hasAccessibility'] == true)
          amenities.add(('ذوي الاحتياجات', Icons.accessible));
        if (data['hasDelivery'] == true)
          amenities.add(('توصيل', Icons.delivery_dining));
        if (data['isFamilyFriendly'] == true)
          amenities.add(('عائلي', Icons.family_restroom));
        if (data['hasReservation'] == true)
          amenities.add(('حجوزات', Icons.event_seat));
        if (data['isHalal'] == true) amenities.add(('حلال', Icons.verified));

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ─── 1. شريط الصور (SliverAppBar) ───
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    backgroundColor: theme.colorScheme.surface,
                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                        ),
                      ),
                    ),
                    actions: [
                      _FavoriteButton(placeId: widget.placeId),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildImageGallery(theme, images),
                    ),
                  ),

                  // ─── 2. المحتوى ───
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // العنوان + حالة العمل
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nameAr,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (nameEn.isNotEmpty && nameEn != nameAr)
                                    Text(nameEn,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'مفتوح' : 'مغلق',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // التقييم
                        Row(
                          children: [
                            ...List.generate(
                                5,
                                (i) => Icon(
                                      i < rating.floor()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    )),
                            const SizedBox(width: 8),
                            Text(
                              '${rating.toStringAsFixed(1)} ($reviewCount تقييم)',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // أزرار سريعة (اتصال، واتساب، خريطة)
                        Row(
                          children: [
                            if (phone.isNotEmpty)
                              Expanded(
                                  child: _actionButton(
                                      theme,
                                      Icons.call,
                                      'اتصال',
                                      Colors.green,
                                      () => _call(phone))),
                            if (phone.isNotEmpty) const SizedBox(width: 8),
                            if (whatsapp.isNotEmpty || phone.isNotEmpty)
                              Expanded(
                                  child: _actionButton(
                                      theme,
                                      Icons.chat_bubble_outline,
                                      'واتساب',
                                      Colors.green,
                                      () => _whatsapp(whatsapp.isNotEmpty
                                          ? whatsapp
                                          : phone))),
                            if (whatsapp.isNotEmpty || phone.isNotEmpty)
                              const SizedBox(width: 8),
                            if (geoPoint != null)
                              Expanded(
                                  child: _actionButton(
                                      theme,
                                      Icons.map_outlined,
                                      'الموقع',
                                      Colors.blue,
                                      () => _openMap(geoPoint.latitude,
                                          geoPoint.longitude))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // الوصف
                        if (desc.isNotEmpty) ...[
                          Text('عن المكان',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(desc,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(height: 1.5)),
                          const SizedBox(height: 24),
                        ],

                        // المميزات
                        if (amenities.isNotEmpty) ...[
                          Text('المميزات والخدمات',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: amenities
                                .map((a) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(a.$2,
                                              size: 16,
                                              color: theme.colorScheme.primary),
                                          const SizedBox(width: 6),
                                          Text(a.$1,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // العنوان
                        if (address.isNotEmpty || city.isNotEmpty) ...[
                          Text('العنوان',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                  [address, city, gov]
                                      .where((s) => s.isNotEmpty)
                                      .join(', '),
                                  style: theme.textTheme.bodyMedium,
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // التقييمات
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('أحدث التقييمات',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('$reviewCount',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ReviewsPreview(placeId: widget.placeId),

                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),

              // ─── 3. الشريط السفلي الثابت (CTA) ───
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomBar(
                  placeId: widget.placeId,
                  nameAr: nameAr,
                  categoryName: data['categoryId']?.toString() ?? 'مكان',
                  governorate: gov,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionButton(ThemeData theme, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(ThemeData theme, List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image, size: 64)),
      );
    }

    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openFullScreen(images, 0),
        child: Image.network(
          images.first,
          width: double.infinity,
          fit: BoxFit.cover,
          cacheWidth: 800,
          errorBuilder: (_, __, ___) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.broken_image, size: 50)),
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openFullScreen(images, index),
              child: Image.network(
                images[index],
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child:
                      const Center(child: Icon(Icons.broken_image, size: 50)),
                ),
              ),
            );
          },
        ),
        // تدرج لوني لعرض الأزرار
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        // عداد الصور
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentPage + 1} / ${images.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // نقاط التحديد
        Positioned(
          bottom: 18,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// زر المفضلة (حقيقي يعمل مع Firestore)
// ═══════════════════════════════════════════════════════════
class _FavoriteButton extends StatelessWidget {
  final String placeId;
  const _FavoriteButton({required this.placeId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('placeId', isEqualTo: placeId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final isFav = docs.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            child: IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white,
                size: 20,
              ),
              onPressed: () async {
                try {
                  if (isFav) {
                    await FirebaseFirestore.instance
                        .collection('favorites')
                        .doc(docs.first.id)
                        .delete();
                  } else {
                    await FirebaseFirestore.instance
                        .collection('favorites')
                        .add({
                      'userId': user.uid,
                      'placeId': placeId,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                } catch (e) {
                  debugPrint('Favorite toggle error: $e');
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// معاينة التقييمات
// ═══════════════════════════════════════════════════════════
class _ReviewsPreview extends StatelessWidget {
  final String placeId;
  const _ReviewsPreview({required this.placeId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: placeId)
          .where('status', isEqualTo: 'published')
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 40, color: theme.colorScheme.outline),
                const SizedBox(height: 8),
                Text('لا توجد تقييمات بعد', style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final userName = d['userName']?.toString() ?? 'مستخدم';
            final rating = (d['rating'] as num?)?.toInt() ?? 0;
            final comment = d['comment']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          userName.isNotEmpty ? userName[0] : '؟',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(userName,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: List.generate(
                            5,
                            (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 12,
                                  color: Colors.amber,
                                )),
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(comment,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// الشريط السفلي الثابت (CTA)
// ═══════════════════════════════════════════════════════════
class _BottomBar extends StatelessWidget {
  final String placeId;
  final String nameAr;
  final String categoryName;
  final String governorate;

  const _BottomBar({
    required this.placeId,
    required this.nameAr,
    required this.categoryName,
    required this.governorate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Consumer<TripBagController>(
        builder: (context, bag, _) {
          return Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    bag.addPlace({
                      'id': placeId,
                      'name': nameAr,
                      'categoryName': categoryName,
                      'governorate': governorate,
                    });
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text('✈️ تمت إضافة "$nameAr" إلى رحلتك'),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                      ));
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: Text('أضف إلى الرحلة (${bag.itemCount})'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// عارض الصور بملء الشاشة (كما هو)
// ═══════════════════════════════════════════════════════════
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _FullScreenImageViewer(
      {required this.images, required this.initialIndex});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (_, __, ___) => const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
