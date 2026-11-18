// lib/features/places/widgets/place_card.dart
// [v3.3 — 2026-11-15] — LINTER FIX: Converted `formattedCity` to final with
//   definite assignment in _formatAddress.
// [v3.2 — 2026-11-15] — ADDRESS FORMAT: Replaced LocationHelper with a local
//   formatter to display "Street - District - Governorate" with smart "حي" prefix.
// [v3.1 — 2026-11-15] — Phase 12: shows "جديد" badge if !isRankable.

import 'package:flutter/material.dart';
import '../../places/screens/place_details_screen.dart';

class PlaceCard extends StatelessWidget {
  final String placeId;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final double? sampleQuality;
  final bool isRankable;
  final String? categoryId;
  final String? geoZoneName;
  final String? city;
  final String? governorate;
  final String? address;
  final double? distanceInKm;
  final bool hasActiveOffer;
  final String? offerTitle;

  const PlaceCard({
    super.key,
    required this.placeId,
    required this.nameAr,
    this.nameEn = '',
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.sampleQuality,
    this.isRankable = true,
    this.categoryId,
    this.geoZoneName,
    this.city,
    this.governorate,
    this.address,
    this.distanceInKm,
    this.hasActiveOffer = false,
    this.offerTitle,
  });

  IconData _getCategoryIcon(String? id) {
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

  /// ✅ v3.3: تنسيق العنوان "الشارع - الحي - المحافظة"
  String _formatAddress(String? address, String? city, String? governorate) {
    final List<String> parts = [];

    // 1. المنطقة / الشارع (الأصغر)
    final trimmedAddress = address?.trim() ?? '';
    if (trimmedAddress.isNotEmpty) {
      parts.add(trimmedAddress);
    }

    // 2. الحي (نضيف "حي" بذكاء)
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

    // 3. المحافظة (الأكبر)
    final trimmedGov = governorate?.trim() ?? '';
    if (trimmedGov.isNotEmpty) {
      parts.add(trimmedGov);
    }

    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ v3.3: استخدام دالة التنسيق الجديدة
    final locationText = _formatAddress(address, city, governorate);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailsScreen(placeId: placeId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                      )
                    : _buildPlaceholder(theme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getCategoryIcon(categoryId),
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nameAr,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (nameEn.isNotEmpty)
                      Text(
                        nameEn,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (hasActiveOffer && offerTitle != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer,
                                size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              offerTitle!,
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (locationText.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationText,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviewCount)',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (!isRankable) ...[
                          const SizedBox(width: 6),
                          _buildNewBadge(),
                        ] else if (sampleQuality != null) ...[
                          const SizedBox(width: 6),
                          _buildConfidenceBadge(sampleQuality!),
                        ],
                        const Spacer(),
                        if (distanceInKm != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${distanceInKm!.toStringAsFixed(1)} كم',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

  /// ✅ Phase 12: شارة "جديد" — تُظهر أن المكان لم يبلغ حد الترتيب بعد.
  Widget _buildNewBadge() {
    return Tooltip(
      message: 'مكان جديد — لا توجد بيانات كافية للترتيب بعد',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_new, size: 10, color: Colors.blue.shade800),
            const SizedBox(width: 2),
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

  Widget _buildConfidenceBadge(double quality) {
    final Color bg;
    final Color fg;

    if (quality >= 0.75) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (quality >= 0.4) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
    }

    final pct = (quality * 100).round().clamp(0, 100);

    return Tooltip(
      message: quality >= 0.75
          ? 'ثقة عالية — التقييم مبني على عينة وفيرة وحديثة'
          : quality >= 0.4
              ? 'ثقة متوسطة — قد تحتاج المزيد من التقييمات'
              : 'ثقة منخفضة — التقييم مبني على عينة صغيرة',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 10, color: fg),
            const SizedBox(width: 3),
            Text(
              '$pct%',
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

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 90,
      height: 90,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported, color: theme.colorScheme.outline),
    );
  }
}
