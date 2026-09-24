// ┘┘ê╪ص╪ر ╪د┘╪ز╪د╪ش╪▒.
// ╪د┘┘ê╪╕╪د╪خ┘ ╪د┘╪ث╪│╪د╪│┘è╪ر ┘à┘ê╪▓╪╣╪ر ╪╣┘┘ë: ╪د┘╪▒╪خ┘è╪│┘è╪ر╪î ╪ث┘à╪د┘â┘┘è╪î ╪د┘┘╪┤╪د╪╖╪î ╪د┘┘à╪▓┘è╪».
// ┘╪د ┘╪╢╪╣ ╪ح╪╣╪»╪د╪»╪د╪ز ╪ث┘ê ╪ح╪ش╪▒╪د╪ة╪د╪ز ╪┤╪«╪╡┘è╪ر ┘┘è ╪ث┘â╪س╪▒ ┘à┘ ┘à┘â╪د┘.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../services/auth_service.dart';
import '../models/place.dart';
import 'scan_qr_screen.dart';
import 'redeem_coupon_screen.dart';
import 'place_reviews_screen.dart';
import 'support_center_screen.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    final uid = AuthService().currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').where('ownerId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot>[];
        final places = docs.map((doc) => Place.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

        final pages = [
          _MerchantOverview(places: places, loading: snapshot.connectionState == ConnectionState.waiting, onScan: () => _scan(context)),
          _MerchantPlaces(places: places, onOpenReviews: (place) => _reviews(context, place)),
          _MerchantActivity(places: places, onScan: () => _scan(context), onRedeem: () => _redeem(context), onOpenReviews: (place) => _reviews(context, place)),
          _MerchantMore(lang: lang, onLogout: () => AuthService().signOut()),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.of('merchant_dashboard', lang)),
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), label: AppStrings.of('home', lang)),
              BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), label: AppStrings.of('merchant_places', lang)),
              BottomNavigationBarItem(icon: const Icon(Icons.insights_outlined), label: AppStrings.of('merchant_activity', lang)),
              BottomNavigationBarItem(icon: const Icon(Icons.more_horiz), label: AppStrings.of('more', lang)),
            ],
          ),
        );
      },
    );
  }

  void _scan(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQrScreen()));
  void _redeem(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const RedeemCouponScreen()));
  void _reviews(BuildContext context, Place place) => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceReviewsScreen(placeId: place.id, isMerchantView: true)));
}

class _MerchantOverview extends StatelessWidget {
  final List<Place> places;
  final bool loading;
  final VoidCallback onScan;
  const _MerchantOverview({required this.places, required this.loading, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    if (loading) return const Center(child: CircularProgressIndicator());
    final featured = places.where((p) => p.isFeatured).length;
    final totalReviews = places.fold<int>(0, (sum, p) => sum + p.ratingCount);
    final average = places.isEmpty ? 0.0 : places.fold<double>(0, (sum, p) => sum + p.rating * p.ratingCount) / (totalReviews == 0 ? places.length : totalReviews);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppStrings.of('merchant_overview', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _StatCard(title: AppStrings.of('merchant_places', lang), value: '${places.length}', icon: Icons.storefront_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(title: AppStrings.of('merchant_reviews', lang), value: '$totalReviews', icon: Icons.star_outline)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard(title: AppStrings.of('merchant_average_rating', lang), value: average.toStringAsFixed(1), icon: Icons.star)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(title: AppStrings.of('merchant_featured', lang), value: '$featured', icon: Icons.workspace_premium_outlined)),
        ]),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(AppStrings.of('merchant_scan_qr', lang), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(AppStrings.of('merchant_overview_hint', lang), style: const TextStyle(color: Colors.grey, height: 1.5)),
      ],
    );
  }
}

class _MerchantPlaces extends StatelessWidget {
  final List<Place> places;
  final ValueChanged<Place> onOpenReviews;
  const _MerchantPlaces({required this.places, required this.onOpenReviews});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    if (places.isEmpty) return Center(child: Text(AppStrings.of('merchant_no_places', lang), textAlign: TextAlign.center));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: places.length,
      itemBuilder: (context, index) => _PlaceCard(place: places[index], lang: lang, onOpenReviews: onOpenReviews),
    );
  }
}

class _MerchantActivity extends StatelessWidget {
  final List<Place> places;
  final VoidCallback onScan;
  final VoidCallback onRedeem;
  final ValueChanged<Place> onOpenReviews;
  const _MerchantActivity({required this.places, required this.onScan, required this.onRedeem, required this.onOpenReviews});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppStrings.of('merchant_activity', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Card(child: ListTile(leading: const Icon(Icons.qr_code_scanner), title: Text(AppStrings.of('merchant_scan_qr', lang)), onTap: onScan)),
        Card(child: ListTile(leading: const Icon(Icons.card_giftcard), title: Text(AppStrings.of('merchant_redeem_coupon', lang)), onTap: onRedeem)),
        const SizedBox(height: 8),
        Text(AppStrings.of('merchant_reviews', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...places.map((place) => ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(place.nameAr),
              subtitle: Text('ظص ${place.rating.toStringAsFixed(1)} (${place.ratingCount})'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => onOpenReviews(place),
            )),
      ],
    );
  }
}

class _MerchantMore extends StatelessWidget {
  final String lang;
  final VoidCallback onLogout;
  const _MerchantMore({required this.lang, required this.onLogout});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const Icon(Icons.support_agent), title: Text(AppStrings.of('support_center', lang)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportCenterScreen())))),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onLogout, icon: const Icon(Icons.logout, color: Colors.red), label: Text(AppStrings.of('logout', lang), style: const TextStyle(color: Colors.red))),
        ],
      );
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final String lang;
  final ValueChanged<Place> onOpenReviews;
  const _PlaceCard({required this.place, required this.lang, required this.onOpenReviews});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(place.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ظص ${place.rating.toStringAsFixed(1)} (${place.ratingCount} ${AppStrings.of('merchant_review_count', lang)})'),
            trailing: place.isFeatured ? const Icon(Icons.star, color: Color(0xFFD4AF37)) : null,
            onTap: () => onOpenReviews(place),
          ),
          if (!place.isFeatured)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: place.featuredRequestPending
                  ? Text(AppStrings.of('merchant_featured_pending', lang), style: const TextStyle(color: Colors.orange))
                  : Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => FirebaseFirestore.instance.collection('places').doc(place.id).update({'featuredRequestPending': true}),
                        icon: const Icon(Icons.star_border, size: 18),
                        label: Text(AppStrings.of('merchant_request_featured', lang)),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: const Color(0xFF1A237E)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}
