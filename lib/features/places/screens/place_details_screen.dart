// lib/features/places/screens/place_details_screen.dart
// [v6.4 — 2026-11-01] — TRIP BAG NAVIGATION: Activated navigation to TripBagScreen.
//   - REMOVED: Placeholder SnackBar.
//   - ADDED: Navigator.push to TripBagScreen.
//   - KEPT: All previous logic, category icon, excellence badge.

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../trip/controllers/trip_bag_controller.dart';
import '../../trip/screens/trip_bag_screen.dart'; // ✅ تم إضافة الاستيراد لشاشة الرحلة

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

  // ✅ دالة مساعدة لجلب أيقونة التصنيف
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

  Future<void> _openWebsite(String url) async {
    String finalUrl = url.trim();
    if (finalUrl.isEmpty) return;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    final uri = Uri.tryParse(finalUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFacebook(String input) async {
    String finalUrl = input.trim();
    if (finalUrl.isEmpty) return;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      if (finalUrl.startsWith('facebook.com') ||
          finalUrl.startsWith('www.facebook.com') ||
          finalUrl.startsWith('fb.com') ||
          finalUrl.startsWith('m.facebook.com')) {
        finalUrl = 'https://$finalUrl';
      } else {
        finalUrl = 'https://facebook.com/$finalUrl';
      }
    }
    final uri = Uri.tryParse(finalUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _priceLabel(int level) {
    switch (level) {
      case 1:
        return 'اقتصادي';
      case 2:
        return 'متوسط';
      case 3:
        return 'مرتفع';
      case 4:
        return 'فاخر';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HeroControllerScope.none(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
          final geoZoneName = data['geoZoneName']?.toString() ?? '';
          final phone = data['phone']?.toString() ??
              data['businessPhone']?.toString() ??
              '';
          final whatsapp = data['whatsapp']?.toString() ?? '';
          final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
          final isActive = data['isActive'] as bool? ?? true;
          final website = data['website']?.toString().trim() ?? '';
          final facebookPage = data['facebookPage']?.toString().trim() ?? '';
          final businessEmail = data['businessEmail']?.toString().trim() ?? '';
          final priceLevel = (data['priceLevel'] as num?)?.toInt() ?? 0;
          final categoryId = data['categoryId']?.toString(); // ✅ جلب التصنيف

          final tagsRaw = data['tags'] as List?;
          final tags = tagsRaw
                  ?.map((e) => e.toString().trim())
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              const <String>[];

          final locationRaw = data['location'];
          final geoPoint = locationRaw is GeoPoint ? locationRaw : null;

          final imagesRaw = data['imageUrls'] as List?;
          final images = imagesRaw?.map((e) => e.toString()).toList() ?? [];
          final hasImages = images.isNotEmpty;

          final bool isExcellenceActive = (data['isExcellence'] == true) ||
              (rating >= 4.5 && reviewCount >= 10);
          // ✅ مصدر واحد للون الشارة
          final Color badgeColor =
              isExcellenceActive ? Colors.amber : Colors.grey.shade200;

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
            appBar: AppBar(
              title: const Text('تفاصيل المكان'),
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                const _TripBagIcon(), // ✅ أيقونة سلة الرحلة أعلى الشاشة
                _FavoriteButton(placeId: widget.placeId),
                const SizedBox(width: 8),
              ],
            ),
            bottomNavigationBar: _BottomBar(
              placeId: widget.placeId,
              nameAr: nameAr,
              categoryName: data['categoryId']?.toString() ?? 'مكان',
              governorate: gov,
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (hasImages) ...[
                    SizedBox(
                        height: 250, child: _buildImageGallery(theme, images)),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildComingSoonImageBanner(theme),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ✅ أيقونة التصنيف
                                Icon(
                                  _iconForCategory(categoryId),
                                  color: theme.colorScheme.primary,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nameAr,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // ✅ شارة التميز
                                Tooltip(
                                  message: isExcellenceActive
                                      ? 'مكان مميز'
                                      : 'لم يحصل على التميز بعد',
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isExcellenceActive
                                            ? Colors.amber.shade700
                                            : Colors.grey.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.workspace_premium,
                                      color: isExcellenceActive
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(
                              5,
                              (i) => Icon(
                                  i < rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18)),
                          const SizedBox(width: 6),
                          Text(
                              '${rating.toStringAsFixed(1)} ($reviewCount تقييم)',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      if (priceLevel >= 1 && priceLevel <= 4)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.shade200, width: 1),
                          ),
                          child: Text(
                            '${'\$' * priceLevel}  ${_priceLabel(priceLevel)}',
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildQuickActions(
                    theme,
                    phone: phone,
                    whatsapp: whatsapp,
                    facebookPage: facebookPage,
                    website: website,
                    businessEmail: businessEmail,
                    geoPoint: geoPoint,
                  ),
                  const SizedBox(height: 24),
                  if (geoZoneName.isNotEmpty || city.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [geoZoneName, city]
                                .where((s) => s.isNotEmpty)
                                .join(' • '),
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (desc.isNotEmpty) ...[
                    Text('عن المكان',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(desc,
                        style:
                            theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                    const SizedBox(height: 24),
                  ],
                  if (tags.isNotEmpty) ...[
                    Text('الكلمات المفتاحية',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: theme.colorScheme.primaryContainer,
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tag,
                                        size: 12,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(t,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12)),
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
                                                fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.map, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  [address, city, gov]
                                      .where((s) => s.isNotEmpty)
                                      .join(', '),
                                  style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComingSoonImageBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined,
              color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'الصور قادمة قريباً! نركز حالياً على تقديم أدق التفاصيل والوصف.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme,
      {required String phone,
      required String whatsapp,
      required String facebookPage,
      required String website,
      required String businessEmail,
      required GeoPoint? geoPoint}) {
    final actions = <Widget>[];
    if (phone.isNotEmpty)
      actions.add(_actionButton(
          theme, Icons.call, 'اتصال', Colors.green, () => _call(phone)));
    if (whatsapp.isNotEmpty || phone.isNotEmpty)
      actions.add(_actionButton(
          theme,
          Icons.chat_bubble_outline,
          'واتساب',
          Colors.green.shade700,
          () => _whatsapp(whatsapp.isNotEmpty ? whatsapp : phone)));
    if (facebookPage.isNotEmpty)
      actions.add(_actionButton(theme, Icons.facebook, 'فيسبوك',
          const Color(0xFF1877F2), () => _openFacebook(facebookPage)));
    if (website.isNotEmpty)
      actions.add(_actionButton(theme, Icons.public, 'الموقع',
          Colors.purple.shade600, () => _openWebsite(website)));
    if (businessEmail.isNotEmpty)
      actions.add(_actionButton(theme, Icons.email_outlined, 'بريد',
          Colors.orange.shade700, () => _sendEmail(businessEmail)));
    if (geoPoint != null)
      actions.add(_actionButton(theme, Icons.map_outlined, 'الخريطة',
          Colors.blue, () => _openMap(geoPoint.latitude, geoPoint.longitude)));

    if (actions.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      const double gap = 8;
      const int perRow = 3;
      final double itemWidth =
          (constraints.maxWidth - gap * (perRow - 1)) / perRow;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children:
            actions.map((a) => SizedBox(width: itemWidth, child: a)).toList(),
      );
    });
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
          mainAxisSize: MainAxisSize.min,
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
    if (images.length == 1) {
      return Image.network(images.first,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.broken_image, size: 50))));
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, index) {
            return Image.network(images[index],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                        child: Icon(Icons.broken_image, size: 50))));
          },
        ),
        Positioned(
            bottom: 16,
            right: 16,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${_currentPage + 1} / ${images.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)))),
      ],
    );
  }
}

// ✅ كلاس أيقونة سلة الرحلة
class _TripBagIcon extends StatelessWidget {
  const _TripBagIcon();

  @override
  Widget build(BuildContext context) {
    return Consumer<TripBagController>(
      builder: (context, bag, _) {
        return IconButton(
          tooltip: 'سلة الرحلة',
          icon: Badge(
            isLabelVisible: bag.itemCount > 0,
            label: Text('${bag.itemCount}'),
            backgroundColor: Colors.red,
            textColor: Colors.white,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          onPressed: () {
            // ✅ تفعيل الانتقال لشاشة إدارة الرحلة
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TripBagScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

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
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white, size: 20),
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
                      'createdAt': FieldValue.serverTimestamp()
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
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  border: Border.all(color: theme.colorScheme.outlineVariant)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(userName.isNotEmpty ? userName[0] : '؟',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      theme.colorScheme.onPrimaryContainer))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(userName,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold))),
                      Row(
                          children: List.generate(
                              5,
                              (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 12,
                                  color: Colors.amber))),
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

class _BottomBar extends StatelessWidget {
  final String placeId;
  final String nameAr;
  final String categoryName;
  final String governorate;

  const _BottomBar(
      {required this.placeId,
      required this.nameAr,
      required this.categoryName,
      required this.governorate});

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
                      'governorate': governorate
                    });
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                          content: Text('✈️ تمت إضافة "$nameAr" إلى رحلتك'),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating));
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: Text('أضف إلى الرحلة (${bag.itemCount})'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      backgroundColor: theme.colorScheme.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
