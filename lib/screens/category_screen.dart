// screens/category_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// بتفتح بعد ما المستخدم يختار فئة من الشاشة الرئيسية (مثلاً "مطاعم").
// كل الفلاتر (جمهور، مجاني/مدفوع، نطاق سعر، فيه عروض) اتنقلوا هنا
// عمدًا عشان الشاشة الرئيسية تفضل بسيطة، والفلترة تبقى مركّزة
// على نفس الفئة اللي المستخدم مهتم بيها فعليًا
// ============================================================

import 'package:flutter/material.dart';
import '../services/place_service.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../models/place.dart';
import '../models/audience_tags.dart';
import '../widgets/place_card.dart';
import 'place_details_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final String categoryLabel;
  final String cityId;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.cityId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Place>> _placesFuture;
  final Set<String> _selectedAudienceTags = {};
  bool? _freeFilter; // null = بدون فلترة، true = مجاني بس، false = مدفوع بس
  String? _priceFilter; // null = الكل، وإلا '$', '$$', '$$$'
  bool _offersOnly = false;
  bool _foodOnly = false; // عرض الأماكن اللي عندها عرض خصم بس

  @override
  void initState() {
    super.initState();
    _placesFuture = PlaceService().getPlacesByCity(widget.cityId);
  }

  // ------------------------------------------------------------
  // الفكرة: كل الفلترة بتتم في الذاكرة (مش استعلام جديد لكل فلتر)
  // لأن عدد الأماكن في المحافظة الواحدة صغير نسبيًا حاليًا -
  // ده أبسط وأسرع من كتابة استعلامات Firestore مركّبة معقدة
  // ------------------------------------------------------------
  List<Place> _applyFilters(List<Place> places) {
    return places.where((p) {
      // category فارغة تعني كل التصنيفات من زر المزيد.
      if (widget.category.isNotEmpty && p.category != widget.category) return false;
      if (_selectedAudienceTags.isNotEmpty &&
          !_selectedAudienceTags.every((tag) => p.audienceTags.contains(tag))) {
        return false;
      }
      if (_freeFilter != null && p.isFree != _freeFilter) return false;
      if (_priceFilter != null && p.priceRange != _priceFilter) return false;
      if (_offersOnly && (p.discountOffer == null || p.discountOffer!.isEmpty)) return false;
      if (_foodOnly && !p.allowFoodInside) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryLabel),
        backgroundColor: const Color(0xFF1454A3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ------------------------------------------------------------
          // الفكرة: صف فلاتر الجمهور - نفس المكوّن المستخدم قبل كده
          // بالظبط، بس دلوقتي هنا بدل الشاشة الرئيسية
          // ------------------------------------------------------------
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: AudienceTags.all.map((tag) {
                final isSelected = _selectedAudienceTags.contains(tag.id);
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    avatar: Icon(tag.icon, size: 16),
                    label: Text(tag.labelAr, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAudienceTags.add(tag.id);
                        } else {
                          _selectedAudienceTags.remove(tag.id);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ------------------------------------------------------------
          // الفكرة: صف الفلاتر الجديدة - مجاني/مدفوع، نطاق السعر، عروض
          // كلهم Chips بسيطة برضو، بس في صف منفصل عشان يبقى واضح
          // إنهم فلاتر من نوع مختلف عن فئات الجمهور
          // ------------------------------------------------------------
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ChoiceChip(
                  label: const Text('مجاني', style: TextStyle(fontSize: 12)),
                  selected: _freeFilter == true,
                  onSelected: (selected) => setState(() => _freeFilter = selected ? true : null),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('مدفوع', style: TextStyle(fontSize: 12)),
                  selected: _freeFilter == false,
                  onSelected: (selected) => setState(() => _freeFilter = selected ? false : null),
                ),
                const SizedBox(width: 6),
                ...['\$', '\$\$', '\$\$\$'].map((price) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(price, style: const TextStyle(fontSize: 12)),
                        selected: _priceFilter == price,
                        onSelected: (selected) => setState(() => _priceFilter = selected ? price : null),
                      ),
                    )),
                ChoiceChip(label: const Text('مسموح الأكل', style: TextStyle(fontSize: 12)), selected: _foodOnly, onSelected: (selected) => setState(() => _foodOnly = selected)),
                const SizedBox(width: 6),
                ChoiceChip(
                  avatar: const Icon(Icons.local_offer, size: 14),
                  label: const Text('فيه عروض', style: TextStyle(fontSize: 12)),
                  selected: _offersOnly,
                  onSelected: (selected) => setState(() => _offersOnly = selected),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<List<String>>(
              stream: FavoritesService().favoriteIdsStream(AuthService().currentUser?.uid ?? ''),
              builder: (context, favSnapshot) {
                final favoriteIds = favSnapshot.data ?? [];

                return FutureBuilder<List<Place>>(
                  future: _placesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('حصل خطأ في تحميل البيانات'));
                    }

                    final places = _applyFilters(snapshot.data ?? []);

                    if (places.isEmpty) {
                      return const Center(child: Text('لا توجد أماكن تطابق الفلاتر المختارة'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        final isFav = favoriteIds.contains(place.id);
                        final uid = AuthService().currentUser?.uid ?? '';
                        return PlaceCard(
                          place: place,
                          isFavorite: isFav,
                          onToggleFavorite: () {
                            if (isFav) {
                              FavoritesService().removeFromFavorites(uid, place.id);
                            } else {
                              FavoritesService().addToFavorites(uid, place.id);
                            }
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PlaceDetailsScreen(place: place)),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
