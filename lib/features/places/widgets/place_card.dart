// lib/features/places/widgets/place_card.dart

import 'package:flutter/material.dart';
import '../../places/screens/place_details_screen.dart';
import '../../../core/utils/location_helper.dart';

class PlaceCard extends StatelessWidget {
  final String placeId;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String? categoryId;
  final String? geoZoneName;
  final String? city;
  final String? governorate;
  final String? address;
  final double? distanceInKm;

  // ✅ الحقول الجديدة للعروض
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationText = LocationHelper.formatLocation(
      geoZoneName: geoZoneName,
      city: city,
      governorate: governorate,
      address: address,
    );

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
              // الصورة
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
              // التفاصيل
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

                    // ✅ شارة العرض النشط
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
                    // الموقع
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
                    // التقييم والمسافة
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviewCount)',
                          style: theme.textTheme.bodySmall,
                        ),
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

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 90,
      height: 90,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported, color: theme.colorScheme.outline),
    );
  }
}
