// widgets/place_card.dart
// بطاقة عرض المكان في القائمة الرئيسية

import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/audience_tags.dart';
import '../l10n/locale_controller.dart';
import 'rating_stars.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final double? distanceKm; // اختياري - بتتحط بس لو ميزة "الأقرب مني" مفعّلة
  final bool? isFavorite; // null = مخفي، true/false = يظهر القلب بالحالة دي
  final VoidCallback? onToggleFavorite;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.distanceKm,
    this.isFavorite,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // صورة المكان + أيقونة المفضلة فوقها لو مفعّلة
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      place.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  if (isFavorite != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(
                            isFavorite! ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite! ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.nameFor(lang),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // المسافة - بتظهر بس لما المستخدم يفعّل "الأقرب مني"
                    if (distanceKm != null)
                      Text(
                        '📍 ${distanceKm!.toStringAsFixed(1)} كم',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E)),
                      ),
                    const SizedBox(height: 4),
                    RatingStars(rating: place.rating),
                    if (place.audienceTags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: place.audienceTags.take(3).map((tagId) {
                          final tag = AudienceTags.getById(tagId);
                          if (tag == null) return const SizedBox.shrink();
                          return Icon(tag.icon, size: 14, color: Colors.grey[500]);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}