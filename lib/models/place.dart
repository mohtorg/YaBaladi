// lib/models/place.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String nameAr;
  final String nameEn;
  final String description;
  final String categoryId;
  final List<String> categories;
  final String governorate;
  final String city;
  final String address;
  final String phone;
  final String whatsapp;
  final GeoPoint? location;
  final List<String> imageUrls;
  final double averageRating;
  final int reviewCount;
  final bool isApproved;
  final bool isActive;
  final DateTime? createdAt;

  // الفلاتر (Wave 11)
  final int priceLevel;
  final bool hasWifi;
  final bool hasParking;
  final bool hasRestroom;
  final bool hasAccessibility;
  final bool isFamilyFriendly;
  final bool isHalal;
  final bool hasDelivery;
  final bool hasReservation;

  // 🆕 حقول التاجر (Wave 13)
  final String? ownerId;
  final bool isVerifiedMerchant;
  final String? businessPhone;
  final String? businessEmail;
  final Map<String, dynamic>? workingHours;
  final bool requiresAdminReview;

  const Place({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.description = '',
    required this.categoryId,
    this.categories = const [],
    required this.governorate,
    this.city = '',
    this.address = '',
    this.phone = '',
    this.whatsapp = '',
    this.location,
    this.imageUrls = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isApproved = false,
    this.isActive = true,
    this.createdAt,
    this.priceLevel = 1,
    this.hasWifi = false,
    this.hasParking = false,
    this.hasRestroom = false,
    this.hasAccessibility = false,
    this.isFamilyFriendly = false,
    this.isHalal = false,
    this.hasDelivery = false,
    this.hasReservation = false,
    this.ownerId,
    this.isVerifiedMerchant = false,
    this.businessPhone,
    this.businessEmail,
    this.workingHours,
    this.requiresAdminReview = false,
  });

  factory Place.fromMap(String id, Map<String, dynamic> map) {
    // ✅ حماية ضد أخطاء النوع (Type Casting)
    List<String> safeList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return Place(
      id: id,
      nameAr: map['nameAr']?.toString() ?? '',
      nameEn: map['nameEn']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      categories: safeList(map['categories']),
      governorate: map['governorate']?.toString() ?? '', // ✅ آمن
      city: map['city']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      whatsapp: map['whatsapp']?.toString() ?? '',
      location:
          map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      imageUrls: safeList(map['imageUrls']),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isApproved: map['isApproved'] == true,
      isActive: map['isActive'] != false, // القيمة الافتراضية true
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      priceLevel: (map['priceLevel'] as num?)?.toInt() ?? 1,
      hasWifi: map['hasWifi'] == true,
      hasParking: map['hasParking'] == true,
      hasRestroom: map['hasRestroom'] == true,
      hasAccessibility: map['hasAccessibility'] == true,
      isFamilyFriendly: map['isFamilyFriendly'] == true,
      isHalal: map['isHalal'] == true,
      hasDelivery: map['hasDelivery'] == true,
      hasReservation: map['hasReservation'] == true,
      ownerId: map['ownerId']?.toString(),
      isVerifiedMerchant: map['isVerifiedMerchant'] == true,
      businessPhone: map['businessPhone']?.toString(),
      businessEmail: map['businessEmail']?.toString(),
      workingHours: map['workingHours'] is Map
          ? Map<String, dynamic>.from(map['workingHours'])
          : null,
      requiresAdminReview: map['requiresAdminReview'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'description': description,
      'categoryId': categoryId,
      'categories': categories,
      'governorate': governorate,
      'city': city,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      if (location != null) 'location': location,
      'imageUrls': imageUrls,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'isApproved': isApproved,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'priceLevel': priceLevel,
      'hasWifi': hasWifi,
      'hasParking': hasParking,
      'hasRestroom': hasRestroom,
      'hasAccessibility': hasAccessibility,
      'isFamilyFriendly': isFamilyFriendly,
      'isHalal': isHalal,
      'hasDelivery': hasDelivery,
      'hasReservation': hasReservation,
      if (ownerId != null) 'ownerId': ownerId,
      'isVerifiedMerchant': isVerifiedMerchant,
      if (businessPhone != null) 'businessPhone': businessPhone,
      if (businessEmail != null) 'businessEmail': businessEmail,
      if (workingHours != null) 'workingHours': workingHours,
      'requiresAdminReview': requiresAdminReview,
    };
  }

  Place copyWith({
    String? nameAr,
    String? nameEn,
    String? description,
    String? categoryId,
    List<String>? categories,
    String? governorate,
    String? city,
    String? address,
    String? phone,
    String? whatsapp,
    GeoPoint? location,
    List<String>? imageUrls,
    double? averageRating,
    int? reviewCount,
    bool? isApproved,
    bool? isActive,
    DateTime? createdAt,
    int? priceLevel,
    bool? hasWifi,
    bool? hasParking,
    bool? hasRestroom,
    bool? hasAccessibility,
    bool? isFamilyFriendly,
    bool? isHalal,
    bool? hasDelivery,
    bool? hasReservation,
    String? ownerId,
    bool? isVerifiedMerchant,
    String? businessPhone,
    String? businessEmail,
    Map<String, dynamic>? workingHours,
    bool? requiresAdminReview,
  }) {
    return Place(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categories: categories ?? this.categories,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      priceLevel: priceLevel ?? this.priceLevel,
      hasWifi: hasWifi ?? this.hasWifi,
      hasParking: hasParking ?? this.hasParking,
      hasRestroom: hasRestroom ?? this.hasRestroom,
      hasAccessibility: hasAccessibility ?? this.hasAccessibility,
      isFamilyFriendly: isFamilyFriendly ?? this.isFamilyFriendly,
      isHalal: isHalal ?? this.isHalal,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      hasReservation: hasReservation ?? this.hasReservation,
      ownerId: ownerId ?? this.ownerId,
      isVerifiedMerchant: isVerifiedMerchant ?? this.isVerifiedMerchant,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      workingHours: workingHours ?? this.workingHours,
      requiresAdminReview: requiresAdminReview ?? this.requiresAdminReview,
    );
  }
}
