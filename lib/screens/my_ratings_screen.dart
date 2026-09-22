// سجل التقييمات المرسلة فعليًا من المستخدم.
// هذه الشاشة منفصلة عن PendingRatingsScreen حتى لا نخلط بين
// "تقييماتي" و"زيارات بانتظار التقييم".
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/rating_model.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import 'pending_ratings_screen.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    final uid = AuthService().currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('my_ratings', lang)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Rating>>(
        stream: RatingService().userRatings(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final ratings = snapshot.data ?? [];
          if (ratings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_border, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(AppStrings.of('no_ratings_yet', lang)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingRatingsScreen())),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(AppStrings.of('pending_ratings', lang)),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ratings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _RatingTile(rating: ratings[index], lang: lang),
          );
        },
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  final Rating rating;
  final String lang;
  const _RatingTile({required this.rating, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(children: List.generate(5, (i) => Icon(i < rating.stars ? Icons.star : Icons.star_border, size: 20, color: const Color(0xFFD4AF37)))),
                const Spacer(),
                Text(_dateText(rating.createdAt)),
              ],
            ),
            if ((rating.comment ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rating.comment!.trim()),
            ],
            if ((rating.merchantReply ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.withValues(alpha: 0.08),
                ),
                child: Text('${AppStrings.of('merchant_reply', lang)}: ${rating.merchantReply!.trim()}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateText(DateTime value) => '${value.day}/${value.month}/${value.year}';
}
