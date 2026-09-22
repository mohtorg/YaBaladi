// شاشة الزيارات التي ما زالت تنتظر تقييم المستخدم.
// لا نستخدمها كسجل للتقييمات السابقة؛ لذلك تم فصل سجل التقييمات في
// my_ratings_screen.dart حتى يكون اسم كل شاشة مطابقًا لوظيفتها.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import '../models/visit_model.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'submit_rating_screen.dart';

class PendingRatingsScreen extends StatelessWidget {
  const PendingRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';
    final lang = LocaleController.of(context).locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('pending_ratings', lang)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Visit>>(
        stream: RatingService().pendingRatableVisits(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final visits = snapshot.data ?? [];
          if (visits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppStrings.of('no_pending_ratings', lang),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('places').doc(visit.placeId).get(),
                builder: (context, placeSnapshot) {
                  final data = placeSnapshot.data?.data();
                  final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
                  final placeName = lang == 'en'
                      ? (map['name_en'] ?? map['name_ar'] ?? 'Place')
                      : (map['name_ar'] ?? map['name_en'] ?? 'مكان');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.verified, color: Colors.green),
                      title: Text(placeName.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(AppStrings.of('rate_this_visit', lang)),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitRatingScreen(visit: visit))),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
