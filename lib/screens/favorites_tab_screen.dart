// المفضلة: وضع تحديد جماعي لإدارة عدة عناصر بسرعة.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../models/place.dart';
import '../widgets/place_card.dart';
import 'place_details_screen.dart';
class FavoritesTabScreen extends StatefulWidget { const FavoritesTabScreen({super.key}); @override State<FavoritesTabScreen> createState()=>_FavoritesState(); }
class _FavoritesState extends State<FavoritesTabScreen> {
  bool selecting=false; final selected=<String>{};
  @override Widget build(BuildContext context) {
    final uid=AuthService().currentUser?.uid??'';
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        backgroundColor: const Color(0xFF1454A3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => setState(() => selecting = !selecting), icon: Icon(selecting ? Icons.close : Icons.checklist)),
          if (selecting) IconButton(onPressed: selected.isEmpty ? null : () async { for (final id in selected) { await FavoritesService().removeFromFavorites(uid, id); } setState(selected.clear); }, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: FavoritesService().favoriteIdsStream(uid),
        builder: (context, snapshot) {
          final ids = snapshot.data ?? [];
          if (ids.isEmpty) return const Center(child: Text('لا توجد أماكن في المفضلة بعد'));
          return FutureBuilder<List<Place>>(
            future: Future.wait(ids.map((id) async {
              final d = await FirebaseFirestore.instance.collection('places').doc(id).get();
              return d.exists ? Place.fromMap(d.id, d.data()!) : null;
            })).then((x) => x.whereType<Place>().toList()),
            builder: (context, ps) {
              final places = ps.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: places.length,
                itemBuilder: (context, i) {
                  final p = places[i];
                  return Row(
                    children: [
                      if (selecting) Checkbox(value: selected.contains(p.id), onChanged: (v) => setState(() => v == true ? selected.add(p.id) : selected.remove(p.id))),
                      Expanded(child: PlaceCard(place: p, isFavorite: true, onToggleFavorite: () => FavoritesService().removeFromFavorites(uid, p.id), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: p)))))
                    ],
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
