// screens/place_details_screen.dart
// شاشة عرض تفاصيل المكان

import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/audience_tags.dart';
import '../l10n/locale_controller.dart';
import '../widgets/rating_stars.dart';
import 'my_qr_screen.dart';
import 'place_reviews_screen.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.nameFor(lang)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          // ------------------------------------------------------------
          // الفكرة: StreamBuilder صغير بيتابع حالة المفضلة بتاعة المكان ده
          // بس (مش كل القائمة)، عشان الأداء يفضل خفيف حتى لو المفضلة كبرت
          // ------------------------------------------------------------
          StreamBuilder<List<String>>(
            stream: FavoritesService().favoriteIdsStream(AuthService().currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final isFav = (snapshot.data ?? []).contains(widget.place.id);
              final uid = AuthService().currentUser?.uid ?? '';
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                onPressed: () {
                  if (isFav) {
                    FavoritesService().removeFromFavorites(uid, widget.place.id);
                  } else {
                    FavoritesService().addToFavorites(uid, widget.place.id);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                widget.place.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // اسم المكان
            Text(
              widget.place.nameFor(lang),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // الفئة والمدينة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.place.category,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // التقييم العام
            Row(
              children: [
                RatingStars(rating: widget.place.rating),
                const SizedBox(width: 8),
                Text(
                  widget.place.rating.toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // الوصف
            const Text(
              '📝 الوصف:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.place.descriptionFor(lang),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // العنوان
            const Text(
              '📍 العنوان:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.place.addressFor(lang),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // ساعات العمل
            const Text(
              '🕐 ساعات العمل:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.place.openingHoursFor(lang),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // وسوم الجمهور المناسب
            if (widget.place.audienceTags.isNotEmpty) ...[
              const Text(
                '👥 مناسب لـ:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.place.audienceTags.map((tagId) {
                  final tag = AudienceTags.getById(tagId);
                  if (tag == null) return const SizedBox.shrink();
                  return Chip(
                    avatar: Icon(tag.icon, size: 16, color: const Color(0xFF1A237E)),
                    label: Text(tag.labelFor(lang)),
                    backgroundColor: Colors.grey[100],
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // زرار الحصول على كود الزيارة الموثّقة
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyQrScreen(place: widget.place),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('احصل على كود الزيارة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'التقييم بيتفتح بعد ما التاجر يوثّق زيارتك الفعلية بالكود',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // زرار مشاهدة كل التقييمات والتعليقات (وضع عرض بس، بدون رد)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaceReviewsScreen(placeId: widget.place.id),
                  ),
                );
              },
              icon: const Icon(Icons.reviews),
              label: const Text('شاهد كل التقييمات والتعليقات'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}