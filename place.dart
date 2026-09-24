// models/place.dart
//
// النموذج الموحد للمحتوى المكاني في "يا بلدي".
// مهم: governorateId وcityId منفصلان معماريًا حتى نستطيع التوسع داخل
// المحافظة إلى مدن/مراكز/مناطق دون إعادة بناء قاعدة البيانات.
// audienceTags وproperties لا تعتمد على نوع المكان، لذلك يمكن استخدامها
// مع الحديقة والفعالية ومقدم الخدمة بنفس القواعد.

import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String governorateId;
  final String cityId;
  final String? ownerId;
  final String contentType;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String addressAr;
  final String addressEn;
  final String category;
  final String imageUrl;
  final double rating;
  final int ratingCount;
  final String openingHoursAr;
  final String openingHoursEn;
  final double latitude;
  final double longitude;
  final List<String> audienceTags;
  final bool isFeatured;
  final bool featuredRequestPending;
  final String? discountOffer;
  final bool allowFoodInside;
  final bool isFree;
  final String priceRange;
  final bool hasParking;
  final bool hasWifi;
  final bool acceptsElectronicPayment;
  final bool hasDelivery;
  final bool requiresReservation;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? eventStart;
  final DateTime? eventEnd;

  Place({
    required this.id,
    this.governorateId = '',
    required this.cityId,
    this.ownerId,
    this.contentType = 'public_place',
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.addressAr,
    required this.addressEn,
    required this.category,
    required this.imageUrl,
    this.rating = 0,
    this.ratingCount = 0,
    required this.openingHoursAr,
    required this.openingHoursEn,
    required this.latitude,
    required this.longitude,
    this.audienceTags = const [],
    this.isFeatured = false,
    this.featuredRequestPending = false,
    this.discountOffer,
    this.allowFoodInside = false,
    this.isFree = false,
    this.priceRange = '',
    this.hasParking = false,
    this.hasWifi = false,
    this.acceptsElectronicPayment = false,
    this.hasDelivery = false,
    this.requiresReservation = false,
    this.isPublished = true,
    this.publishedAt,
    this.eventStart,
    this.eventEnd,
  });

  String nameFor(String lang) => lang == 'en' ? nameEn : nameAr;
  String descriptionFor(String lang) => lang == 'en' ? descriptionEn : descriptionAr;
  String addressFor(String lang) => lang == 'en' ? addressEn : addressAr;
  String openingHoursFor(String lang) => lang == 'en' ? openingHoursEn : openingHoursAr;

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  factory Place.fromMap(String id, Map<String, dynamic> map) {
    final ownerId = map['ownerId'] as String?;
    final category = map['category'] ?? '';
    final inferredType = category == 'فعالية'
        ? 'event'
        : category == 'حديقة'
            ? 'garden'
            : ownerId == null
                ? 'public_place'
                : 'service_provider';

    return Place(
      id: id,
      governorateId: map['governorateId'] ?? map['cityId'] ?? '',
      cityId: map['cityId'] ?? '',
      ownerId: ownerId,
      contentType: map['contentType'] ?? inferredType,
      nameAr: map['name_ar'] ?? '',
      nameEn: map['name_en'] ?? '',
      descriptionAr: map['description_ar'] ?? '',
      descriptionEn: map['description_en'] ?? '',
      addressAr: map['address_ar'] ?? '',
      addressEn: map['address_en'] ?? '',
      category: category,
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: (map['ratingCount'] ?? 0).toInt(),
      openingHoursAr: map['openingHours_ar'] ?? '',
      openingHoursEn: map['openingHours_en'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      audienceTags: List<String>.from(map['audienceTags'] ?? []),
      isFeatured: map['isFeatured'] ?? false,
      featuredRequestPending: map['featuredRequestPending'] ?? false,
      discountOffer: map['discountOffer'],
      allowFoodInside: map['allowFoodInside'] ?? map['allow_food_inside'] ?? false,
      isFree: map['isFree'] ?? false,
      priceRange: map['priceRange'] ?? '',
      hasParking: map['hasParking'] ?? false,
      hasWifi: map['hasWifi'] ?? false,
      acceptsElectronicPayment: map['acceptsElectronicPayment'] ?? false,
      hasDelivery: map['hasDelivery'] ?? false,
      requiresReservation: map['requiresReservation'] ?? false,
      // المستندات القديمة لا تحتوي isPublished؛ نعتبرها منشورة حتى لا تختفي بياناتك الحالية.
      isPublished: map['isPublished'] != false,
      publishedAt: _date(map['publishedAt']),
      eventStart: _date(map['eventStart']),
      eventEnd: _date(map['eventEnd']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'governorateId': governorateId.isEmpty ? cityId : governorateId,
      'cityId': cityId,
      if (ownerId != null) 'ownerId': ownerId,
      'contentType': contentType,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'address_ar': addressAr,
      'address_en': addressEn,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'openingHours_ar': openingHoursAr,
      'openingHours_en': openingHoursEn,
      'latitude': latitude,
      'longitude': longitude,
      'audienceTags': audienceTags,
      'isFeatured': isFeatured,
      'featuredRequestPending': featuredRequestPending,
      if (discountOffer != null) 'discountOffer': discountOffer,
      'allowFoodInside': allowFoodInside,
      'isFree': isFree,
      'priceRange': priceRange,
      'hasParking': hasParking,
      'hasWifi': hasWifi,
      'acceptsElectronicPayment': acceptsElectronicPayment,
      'hasDelivery': hasDelivery,
      'requiresReservation': requiresReservation,
      'isPublished': isPublished,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (eventStart != null) 'eventStart': Timestamp.fromDate(eventStart!),
      if (eventEnd != null) 'eventEnd': Timestamp.fromDate(eventEnd!),
    };
  }
}
