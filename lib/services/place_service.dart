// services/place_service.dart
//
// ┘à╪╡╪»╪▒ ╪د┘╪ص┘é┘è┘é╪ر ┘┘╪ث┘à╪د┘â┘ ┘ç┘ê Firestore ┘┘é╪╖.
// ┘à┘ç┘à: ┘╪د ┘è┘ê╪ش╪» Seed ╪ز┘┘é╪د╪خ┘è ╪╣┘╪» ╪ز╪┤╪║┘è┘ ╪د┘╪ز╪╖╪ذ┘è┘é╪ؤ ╪د┘╪ذ┘è╪د┘╪د╪ز ╪د┘╪ص┘é┘è┘é┘è╪ر ┘è╪ش╪ذ ╪ث┘ ╪ز╪»╪«┘
// ┘à┘ ┘┘ê╪ص╪ر ╪د┘╪ح╪»╪د╪▒╪ر ╪ث┘ê ┘à┘ ┘à╪│╪د╪▒ ┘à┘é╪»┘à ╪د┘╪«╪»┘à╪ر ╪د┘┘à╪╣╪ز┘à╪». ┘ç╪░╪د ┘è┘à┘╪╣ ╪╕┘ç┘ê╪▒ ╪ذ┘è╪د┘╪د╪ز ╪ز╪ش╪▒┘è╪ذ┘è╪ر
// ╪ث┘ê ╪ح╪╣╪د╪»╪ر ╪ح╪»╪«╪د┘ ╪ذ┘è╪د┘╪د╪ز ╪║┘è╪▒ ┘à┘é╪╡┘ê╪»╪ر ┘┘è ╪ذ┘è╪خ╪ر ╪د┘╪ح┘╪ز╪د╪ش.
//
// Firestore ┘è╪│┘à╪ص ╪ذ╪ذ┘┘è╪ر ┘à┘ê╪ص╪»╪ر ┘┘┘à╪│╪ز┘╪»╪د╪ز╪î ┘╪░┘┘â ┘╪│╪ز╪«╪»┘à governorateId ┘êcityId ┘à╪╣┘ï╪د
// ╪د╪│╪ز╪╣╪»╪د╪»┘ï╪د ┘┘╪ز┘ê╪│╪╣ ┘à┘ ┘à╪ص╪د┘╪╕╪ر ┘ê╪د╪ص╪»╪ر ╪ح┘┘ë ┘à╪»┘ ┘ê┘à┘╪د╪╖┘é ┘à╪ز╪╣╪»╪»╪ر.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';

class PlaceService {
  final CollectionReference<Map<String, dynamic>> _placesRef =
      FirebaseFirestore.instance.collection('places');

  Future<List<Place>> getPlacesByCity(String cityId) async {
    try {
      final snapshot = await _placesRef.where('cityId', isEqualTo: cityId).get();
      return snapshot.docs
        .map((doc) => Place.fromMap(doc.id, doc.data()))
        // ╪د┘┘à╪│╪ز┘╪»╪د╪ز ╪د┘┘é╪»┘è┘à╪ر ┘╪د ╪ز╪ص╪ز┘ê┘è isPublished╪ؤ Place.fromMap ┘è╪╣╪ز╪ذ╪▒┘ç╪د ┘à┘╪┤┘ê╪▒╪ر.
        .where((place) => place.isPublished)
        .toList();
    } catch (_) {
      // ╪╣┘╪» ╪د┘┘é╪╖╪د╪╣ ╪د┘╪┤╪ذ┘â╪ر╪î ┘╪╖┘╪ذ ╪د┘┘╪│╪«╪ر ╪د┘┘à╪ص┘┘è╪ر ╪د┘╪ز┘è ╪│╪ذ┘é ╪ث┘ ╪«╪▓┘ّ┘┘ç╪د Firestore.
      final snapshot = await _placesRef
          .where('cityId', isEqualTo: cityId)
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs
          .map((doc) => Place.fromMap(doc.id, doc.data()))
          .where((place) => place.isPublished)
          .toList();
    }
  }

  Future<List<Place>> getPlacesByGovernorate(String governorateId) async {
    final snapshot = await _placesRef
        .where('governorateId', isEqualTo: governorateId)
        .get();

    return snapshot.docs
        .map((doc) => Place.fromMap(doc.id, doc.data()))
        .where((place) => place.isPublished)
        .toList();
  }

  Future<Place?> getPlaceById(String placeId) async {
    final doc = await _placesRef.doc(placeId).get();
    if (!doc.exists || doc.data() == null) return null;
    final place = Place.fromMap(doc.id, doc.data()!);
    return place.isPublished ? place : null;
  }
}
