// lib/features/places/screens/place_details_screen.dart
// [v9.8 — 2026-11-15] — LINTER FIX: Added curly braces to all single-line if
//   statements and converted formattedCity to final in _formatFullAddress.
// [v9.7 — 2026-11-15] — ADDRESS FORMAT: Applied "Street - District - Governorate"
//   formatting to the Address section using `_formatFullAddress`.
// [v9.6 — 2026-11-15] — Phase 12: shows "جديد" badge when !isRankable.

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/adjusted_score_service.dart';
import '../../../core/services/qr_verification_service.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/helpers/location_url_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../rating/widgets/ratings_section.dart';
import '../../trip/controllers/trip_bag_controller.dart';
import 'claim_place_screen.dart';

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
  void initState() {
    super.initState();
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  // ✅ v9.8: Smart Address Formatting (Linter Fix)
  // "شارع الجمهورية - حي الشرق - بورسعيد"
  String _formatFullAddress(String address, String city, String gov) {
    final List<String> parts = [];

    // 1. المنطقة / الشارع (الأصغر)
    final trimmedAddress = address.trim();
    if (trimmedAddress.isNotEmpty) {
      parts.add(trimmedAddress);
    }

    // 2. الحي (نضيف "حي" بذكاء)
    final trimmedCity = city.trim();
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

    // 3. المحافظة (الأكبر)
    final trimmedGov = gov.trim();
    if (trimmedGov.isNotEmpty) {
      parts.add(trimmedGov);
    }

    return parts.join(' - ');
  }

  String _smartFormatOffer(String text) {
    if (text.isEmpty) {
      return text;
    }
    final formattedText = text.trim();
    final bool hasEmoji = RegExp(
            r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true)
        .hasMatch(formattedText);
    if (hasEmoji) {
      return formattedText;
    }
    if (formattedText.contains('خصم') || formattedText.contains('%')) {
      return '🔥 $formattedText';
    }
    if (formattedText.contains('مجان') || formattedText.contains('هدية')) {
      return '🎁 $formattedText';
    }
    if (formattedText.contains('افتتاح') || formattedText.contains('جديد')) {
      return '🎉 $formattedText';
    }
    if (formattedText.contains('حصري') || formattedText.contains('مميز')) {
      return '⭐ $formattedText';
    }
    return '🏆 $formattedText';
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

  double? _extractLat(Map<String, dynamic> data) {
    final loc = data['location'];
    if (loc is GeoPoint) {
      return loc.latitude;
    }
    final raw = data['latitude'];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '');
  }

  double? _extractLng(Map<String, dynamic> data) {
    final loc = data['location'];
    if (loc is GeoPoint) {
      return loc.longitude;
    }
    final raw = data['longitude'];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return HeroControllerScope.none(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
                appBar: AppBar(title: Text(l10n.details)),
                body: const Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Scaffold(
                appBar: AppBar(title: Text(l10n.details)),
                body: Center(child: Text('${l10n.error}: ${snapshot.error}')));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
                appBar: AppBar(title: Text(l10n.details)),
                body: Center(child: Text(l10n.noResults)));
          }

          final data = snapshot.data!.data()!;

          final nameAr = data['nameAr']?.toString() ??
              data['name']?.toString() ??
              l10n.appName;
          final nameEn = data['nameEn']?.toString() ?? '';
          final desc = data['description']?.toString() ?? '';
          final address = data['address']?.toString() ?? '';
          final city = data['city']?.toString() ?? '';
          final gov = data['governorate']?.toString() ?? '';
          final geoZoneName = data['geoZoneName']?.toString() ?? '';
          final zoneId = data['zoneId']?.toString();

          final categoryId =
              (data['category'] ?? data['categoryId'])?.toString();

          final ownerId = data['ownerId']?.toString() ?? '';
          final isClaimable = ownerId.isEmpty;

          final phone = data['phone']?.toString() ??
              data['businessPhone']?.toString() ??
              '';
          final whatsapp = data['whatsapp']?.toString() ?? '';

          final rating = (data['averageRating'] is num)
              ? (data['averageRating'] as num).toDouble()
              : double.tryParse(data['averageRating']?.toString() ?? '') ?? 0.0;
          final reviewCount = (data['reviewCount'] is num)
              ? (data['reviewCount'] as num).toInt()
              : int.tryParse(data['reviewCount']?.toString() ?? '') ?? 0;
          final priceLevel = (data['priceLevel'] is num)
              ? (data['priceLevel'] as num).toInt()
              : int.tryParse(data['priceLevel']?.toString() ?? '') ?? 0;

          final sampleQuality = (data['sampleQuality'] as num?)?.toDouble();
          // ✅ Phase 12: fallback if the mirror field is missing
          final isRankable = (data['isRankable'] as bool?) ??
              (reviewCount >= AdjustedScoreService.minRatingsForRanking);

          final isActive = data['isActive'] as bool? ?? true;
          final website = data['website']?.toString().trim() ?? '';
          final facebookPage = data['facebookPage']?.toString().trim() ?? '';
          final businessEmail = data['businessEmail']?.toString().trim() ?? '';

          final placeLat = _extractLat(data) ?? 0.0;
          final placeLng = _extractLng(data) ?? 0.0;
          final pinObfuscated = data['pin_obfuscated']?.toString();

          final tagsRaw = data['tags'] as List?;
          final tags = tagsRaw
                  ?.map((e) => e.toString().trim())
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              const <String>[];

          final locationRaw = data['location'];
          final geoPoint = locationRaw is GeoPoint ? locationRaw : null;

          final imagesRaw = data['imageUrls'] as List?;
          final images = imagesRaw
                  ?.map((e) => e?.toString().trim() ?? '')
                  .where((s) =>
                      s.isNotEmpty &&
                      (s.startsWith('http://') || s.startsWith('https://')))
                  .toList() ??
              [];
          final hasImages = images.isNotEmpty;

          final bool isExcellenceActive = (data['isExcellence'] == true) ||
              (rating >= 4.5 && reviewCount >= 10);
          final Color badgeColor =
              isExcellenceActive ? Colors.amber : Colors.grey.shade200;

          final hasActiveOffer = data['hasActiveOffer'] == true;
          final offerTitle = data['offerTitle']?.toString();
          final offerDetails = data['offerDetails']?.toString();
          final offerExpiry = (data['offerExpiryDate'] is Timestamp)
              ? (data['offerExpiryDate'] as Timestamp).toDate()
              : null;
          final bool isOfferValid = hasActiveOffer &&
              offerExpiry != null &&
              offerExpiry.isAfter(DateTime.now());

          final amenities = <(String, IconData)>[];
          if (data['hasWifi'] == true) {
            amenities.add(('واي فاي', Icons.wifi));
          }
          if (data['hasParking'] == true) {
            amenities.add(('موقف سيارات', Icons.local_parking));
          }
          if (data['hasRestroom'] == true) {
            amenities.add(('دورات مياه', Icons.wc));
          }
          if (data['hasAccessibility'] == true) {
            amenities.add(('ذوي الاحتياجات', Icons.accessible));
          }
          if (data['hasDelivery'] == true) {
            amenities.add(('توصيل', Icons.delivery_dining));
          }
          if (data['isFamilyFriendly'] == true) {
            amenities.add(('عائلي', Icons.family_restroom));
          }
          if (data['hasReservation'] == true) {
            amenities.add(('حجوزات', Icons.event_seat));
          }
          if (data['isHalal'] == true) {
            amenities.add(('حلال', Icons.verified));
          }

          final fullContextLocation = LocationHelper.format(
            governorate: gov,
            district: city,
            zone: geoZoneName,
            mode: LocationDisplayMode.full,
          );

          // ✅ v9.8: استخدام الدالة الجديدة لتنسيق العنوان
          final displayAddress = _formatFullAddress(address, city, gov);

          final shortHeaderLocation = LocationHelper.format(
            district: city,
            zone: geoZoneName,
            mode: LocationDisplayMode.medium,
          );

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              title: Text(l10n.details),
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              elevation: 0,
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop()),
              actions: [
                _QrCodeButton(
                  placeId: widget.placeId,
                  placeName: nameAr,
                  governorate: gov,
                ),
                const _TripBagIcon(),
                _FavoriteButton(placeId: widget.placeId),
                const SizedBox(width: 8),
              ],
            ),
            bottomNavigationBar: _BottomBar(
              placeId: widget.placeId,
              nameAr: nameAr,
              categoryName: categoryId ?? '',
              governorate: gov,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasImages) ...[
                      SizedBox(
                          height: 250,
                          child: _buildImageGallery(theme, images)),
                      const SizedBox(height: 16),
                      _buildNameRow(
                          theme,
                          nameAr,
                          nameEn,
                          categoryId,
                          isActive,
                          isExcellenceActive,
                          badgeColor,
                          sampleQuality,
                          isRankable),
                    ] else ...[
                      _buildCompactHeader(
                          theme,
                          nameAr,
                          nameEn,
                          categoryId,
                          isActive,
                          isExcellenceActive,
                          sampleQuality,
                          isRankable),
                    ],
                    const SizedBox(height: 12),
                    if (priceLevel >= 1 && priceLevel <= 4)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.shade200, width: 1)),
                          child: Text(
                              '${'\$' * priceLevel}  ${_priceLabel(priceLevel)}',
                              style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (isOfferValid && offerTitle != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF7F50), Color(0xFFFF4500)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.deepOrange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_smartFormatOffer(offerTitle),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  if (offerDetails != null &&
                                      offerDetails.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(_smartFormatOffer(offerDetails),
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                      '${offerExpiry.day}/${offerExpiry.month}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildQuickActions(theme,
                        phone: phone,
                        whatsapp: whatsapp,
                        facebookPage: facebookPage,
                        website: website,
                        businessEmail: businessEmail,
                        geoPoint: geoPoint),
                    if (isClaimable) ...[
                      const SizedBox(height: 20),
                      _buildClaimBanner(theme, nameAr),
                    ],
                    const SizedBox(height: 24),
                    if (shortHeaderLocation.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shortHeaderLocation,
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
                                          color: theme
                                              .colorScheme.primaryContainer,
                                          width: 1)),
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
                    if (displayAddress.isNotEmpty) ...[
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
                                child: Text(displayAddress,
                                    style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    RatingsSection(
                      placeId: widget.placeId,
                      placeName: nameAr,
                      placeLat: placeLat,
                      placeLng: placeLng,
                      categoryId: categoryId ?? '',
                      pinObfuscated: pinObfuscated,
                      zoneId: zoneId,
                      fullLocation: fullContextLocation,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClaimBanner(ThemeData theme, String nameAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined,
                  color: Colors.teal.shade800, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'هل أنت صاحب هذا المكان؟',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'يمكنك الآن استلام إدارة صفحة "$nameAr" مجاناً. '
            'ستحصل على أدوات لإدارة البيانات والرد على التقييمات، '
            'ولن تتمكن من تعديل التقييمات السابقة أو حذفها.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.teal.shade800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: () async {
                final claimed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClaimPlaceScreen(
                      placeId: widget.placeId,
                      placeName: nameAr,
                    ),
                  ),
                );
                if (claimed == true && mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.assignment_ind_outlined, size: 18),
              label: const Text('تقديم طلب استلام'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Phase 12: شارة "جديد"
  Widget _buildNewBadge() {
    return Tooltip(
      message: 'مكان جديد — لا توجد بيانات كافية للترتيب بعد',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_new, size: 12, color: Colors.blue.shade800),
            const SizedBox(width: 4),
            Text(
              'جديد',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double? sampleQuality) {
    if (sampleQuality == null) {
      return const SizedBox.shrink();
    }

    final Color bg;
    final Color fg;
    final String label;
    final String tooltip;

    if (sampleQuality >= 0.75) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      label = 'ثقة عالية';
      tooltip = 'البيانات موثوقة — عينة تقييمات وفيرة وحديثة';
    } else if (sampleQuality >= 0.4) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      label = 'ثقة متوسطة';
      tooltip = 'عينة متوسطة — قد تحتاج المزيد من التقييمات';
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      label = 'ثقة منخفضة';
      tooltip = 'عينة صغيرة — التقييم قد لا يعكس جودة المكان بدقة';
    }

    final pct = (sampleQuality * 100).round().clamp(0, 100);

    return Tooltip(
      message: '$tooltip\n($pct%)',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              '$label ($pct%)',
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(
      ThemeData theme,
      String nameAr,
      String nameEn,
      String? categoryId,
      bool isActive,
      bool isExcellenceActive,
      double? sampleQuality,
      bool isRankable) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Icon(_iconForCategory(categoryId),
                color: theme.colorScheme.primary, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(nameAr,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold))),
                    Tooltip(
                        message: isExcellenceActive
                            ? 'مكان مميز'
                            : 'لم يحصل على التميز بعد',
                        child: Icon(Icons.workspace_premium,
                            color: isExcellenceActive
                                ? Colors.amber.shade700
                                : Colors.grey.shade400,
                            size: 20)),
                  ],
                ),
                if (nameEn.isNotEmpty && nameEn != nameAr)
                  Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(nameEn,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(isActive ? 'مفتوح' : 'مغلق',
                          style: TextStyle(
                              color: isActive
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (!isRankable)
                      _buildNewBadge()
                    else
                      _buildConfidenceBadge(sampleQuality),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRow(
      ThemeData theme,
      String nameAr,
      String nameEn,
      String? categoryId,
      bool isActive,
      bool isExcellenceActive,
      Color badgeColor,
      double? sampleQuality,
      bool isRankable) {
    return Row(
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
                  Icon(_iconForCategory(categoryId),
                      color: theme.colorScheme.primary, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(nameAr,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold))),
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
                              width: 1)),
                      child: Icon(Icons.workspace_premium,
                          color: isExcellenceActive
                              ? Colors.white
                              : Colors.grey.shade500,
                          size: 18),
                    ),
                  ),
                ],
              ),
              if (nameEn.isNotEmpty && nameEn != nameAr)
                Text(nameEn,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(isActive ? 'مفتوح' : 'مغلق',
                        style: TextStyle(
                            color: isActive
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (!isRankable)
                    _buildNewBadge()
                  else
                    _buildConfidenceBadge(sampleQuality),
                ],
              ),
            ],
          ),
        ),
      ],
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
    if (phone.isNotEmpty) {
      actions.add(_actionButton(theme, Icons.call, 'اتصال', Colors.green, () {
        LocationUrlHelper.makeCall(phone);
      }));
    }
    if (whatsapp.isNotEmpty || phone.isNotEmpty) {
      actions.add(_actionButton(
          theme, Icons.chat_bubble_outline, 'واتساب', Colors.green.shade700,
          () {
        LocationUrlHelper.openWhatsApp(whatsapp.isNotEmpty ? whatsapp : phone);
      }));
    }
    if (facebookPage.isNotEmpty) {
      actions.add(_actionButton(
          theme, Icons.facebook, 'فيسبوك', const Color(0xFF1877F2), () {
        LocationUrlHelper.openSmart(facebookPage.startsWith('http')
            ? facebookPage
            : 'https://facebook.com/$facebookPage');
      }));
    }
    if (website.isNotEmpty) {
      actions.add(_actionButton(
          theme, Icons.public, 'الموقع', Colors.purple.shade600, () {
        LocationUrlHelper.openSmart(
            website.startsWith('http') ? website : 'https://$website');
      }));
    }
    if (businessEmail.isNotEmpty) {
      actions.add(_actionButton(
          theme, Icons.email_outlined, 'بريد', Colors.orange.shade700, () {
        LocationUrlHelper.openSmart('mailto:$businessEmail');
      }));
    }
    if (geoPoint != null) {
      actions.add(
          _actionButton(theme, Icons.map_outlined, 'الخريطة', Colors.blue, () {
        LocationUrlHelper.openSmart(
            LocationUrlHelper.getSmartMapUrl(location: geoPoint));
      }));
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(builder: (context, constraints) {
      const double gap = 8;
      const int perRow = 3;
      final double itemWidth =
          (constraints.maxWidth - gap * (perRow - 1)) / perRow;
      return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map((a) => SizedBox(width: itemWidth, child: a))
              .toList());
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
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildImageGallery(ThemeData theme, List<String> images) {
    if (images.length == 1) {
      return Image.network(
        images.first,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.broken_image, size: 50))),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, index) => Image.network(
            images[index],
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.broken_image, size: 50))),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12)),
            child: Text('${_currentPage + 1} / ${images.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

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
          onPressed: () => context.push('/bag'),
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
    if (user == null) {
      return const SizedBox.shrink();
    }

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

class _QrCodeButton extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String governorate;

  const _QrCodeButton({
    required this.placeId,
    required this.placeName,
    required this.governorate,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.qr_code_2_rounded),
      tooltip: 'رمز توثيق المكان (QR)',
      onPressed: () => _showQrDialog(context),
    );
  }

  void _showQrDialog(BuildContext context) {
    final payload = QrVerificationService.generatePlaceQrPayload(
      placeId: placeId,
      governorate: governorate,
    );
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'رمز توثيق الزيارة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              placeName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, size: 48),
                  const SizedBox(height: 8),
                  SelectableText(
                    payload,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هذا الرمز هو الهوية المعتمدة للمكان؛ يمكن لصاحب المكان عرضه أو طباعته ليقوم الزوار بمسحه وإثبات زيارتهم وحصول تقييماتهم على أعلى موثوقية.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payload));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ رمز المكان بنجاح'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('نسخ الرمز'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
