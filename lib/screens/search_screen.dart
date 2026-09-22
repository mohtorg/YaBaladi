// screens/search_screen.dart
// بحث شامل فعلي في الأماكن داخل المحافظة. الفلاتر لا تظهر إلا عندما يكون
// لدينا أكثر من نتيجة، حتى لا نثقل الواجهة عندما تكون النتيجة مفردة.
import 'package:flutter/material.dart';
import '../services/place_service.dart';
import '../models/place.dart';
import '../models/audience_tags.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../widgets/place_card.dart';
import 'place_details_screen.dart';
class SearchScreen extends StatefulWidget { final String cityId; const SearchScreen({super.key,required this.cityId}); @override State<SearchScreen> createState()=>_SearchScreenState(); }
class _SearchScreenState extends State<SearchScreen>{ final c=TextEditingController(); late Future<List<Place>> future; final tags=<String>{}; bool? free; String? price; bool offers=false; bool food=false; bool parking=false; bool wifi=false; bool electronicPayment=false; bool delivery=false; bool reservation=false;
 @override void initState(){super.initState();future=PlaceService().getPlacesByCity(widget.cityId);}
 List<Place> filter(List<Place> all){final q=c.text.trim().toLowerCase();return all.where((p){if(q.isNotEmpty&&!('${p.nameAr} ${p.nameEn} ${p.descriptionAr} ${p.descriptionEn} ${p.category}').toLowerCase().contains(q))return false;if(tags.isNotEmpty&&!tags.every(p.audienceTags.contains))return false;if(free!=null&&p.isFree!=free)return false;if(price!=null&&p.priceRange!=price)return false;if(offers&&(p.discountOffer==null||p.discountOffer!.isEmpty))return false;if(food&&!p.allowFoodInside)return false;if(parking&&!p.hasParking)return false;if(wifi&&!p.hasWifi)return false;if(electronicPayment&&!p.acceptsElectronicPayment)return false;if(delivery&&!p.hasDelivery)return false;if(reservation&&!p.requiresReservation)return false;return true;}).toList();}
 @override
 Widget build(BuildContext context) => Scaffold(
   appBar: AppBar(
     title: const Text('البحث'),
     backgroundColor: const Color(0xFF1454A3),
     foregroundColor: Colors.white,
   ),
   body: FutureBuilder<List<Place>>(
     future: future,
     builder: (ctx, s) {
       final results = filter(s.data ?? []);
       return Column(
         children: [
           Padding(
             padding: const EdgeInsets.all(12),
             child: TextField(
               controller: c,
               onChanged: (_) => setState(() {}),
               autofocus: true,
               decoration: InputDecoration(
                 hintText: 'ابحث عن مكان أو خدمة...',
                 prefixIcon: const Icon(Icons.search),
                 suffixIcon: c.text.isEmpty
                     ? null
                     : IconButton(
                         onPressed: () {
                           c.clear();
                           setState(() {});
                         },
                         icon: const Icon(Icons.clear),
                       ),
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                 ),
               ),
             ),
           ),
           if (results.length > 1) _filters(),
           Expanded(
             child: results.isEmpty
                 ? const Center(child: Text('لا توجد نتائج مطابقة'))
                 : StreamBuilder<List<String>>(
                     stream: FavoritesService().favoriteIdsStream(
                       AuthService().currentUser?.uid ?? '',
                     ),
                     builder: (ctx, f) {
                       final fav = f.data ?? [];
                       return ListView.builder(
                         itemCount: results.length,
                         itemBuilder: (ctx, i) {
                           final p = results[i];
                           final uid =
                               AuthService().currentUser?.uid ?? '';
                           return PlaceCard(
                             place: p,
                             isFavorite: fav.contains(p.id),
                             onToggleFavorite: () => fav.contains(p.id)
                                 ? FavoritesService()
                                     .removeFromFavorites(uid, p.id)
                                 : FavoritesService()
                                     .addToFavorites(uid, p.id),
                             onTap: () => Navigator.push(
                               ctx,
                               MaterialPageRoute(
                                 builder: (_) =>
                                     PlaceDetailsScreen(place: p),
                               ),
                             ),
                           );
                         },
                       );
                     },
                   ),
           ),
         ],
       );
     },
   ),
 );
  Widget _filters() => SizedBox(
    height: 98,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        ...AudienceTags.all.map((t) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: FilterChip(
            label: Text(t.labelAr),
            selected: tags.contains(t.id),
            onSelected: (v) => setState(() => v ? tags.add(t.id) : tags.remove(t.id)),
          ),
        )),
        ChoiceChip(label: const Text('مجاني'), selected: free == true, onSelected: (v) => setState(() => free = v ? true : null)),
        ChoiceChip(label: const Text('مسموح الأكل'), selected: food, onSelected: (v) => setState(() => food = v)),
        ChoiceChip(label: const Text('موقف'), selected: parking, onSelected: (v) => setState(() => parking = v)),
        ChoiceChip(label: const Text('Wi-Fi'), selected: wifi, onSelected: (v) => setState(() => wifi = v)),
        ChoiceChip(label: const Text('دفع إلكتروني'), selected: electronicPayment, onSelected: (v) => setState(() => electronicPayment = v)),
        ChoiceChip(label: const Text('توصيل'), selected: delivery, onSelected: (v) => setState(() => delivery = v)),
        ChoiceChip(label: const Text('حجز'), selected: reservation, onSelected: (v) => setState(() => reservation = v)),
        ChoiceChip(label: const Text('عروض'), selected: offers, onSelected: (v) => setState(() => offers = v)),
        ...['\$', '\$\$', '\$\$\$'].map((x) => ChoiceChip(
          label: Text(x),
          selected: price == x,
          onSelected: (v) => setState(() => price = v ? x : null),
        )),
      ],
    ),
  );
}
