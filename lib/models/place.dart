// lib/models/place.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String nameAr;
  final String nameEn;
  final String description;
  final String categoryId;
  final List<String> categories; // 👈 [FIX] الحقل المفقود
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
    this.categories = const [], // 👈 [FIX]
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
    return Place(
      id: id,
      nameAr: map['nameAr'] ?? '',
      nameEn: map['nameEn'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categories: List<String>.from(map['categories'] ?? []), // 👈 [FIX]
      governorate: map['governorate'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      location: map['location'] as GeoPoint?,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      priceLevel: (map['priceLevel'] as num?)?.toInt() ?? 1,
      hasWifi: map['hasWifi'] ?? false,
      hasParking: map['hasParking'] ?? false,
      hasRestroom: map['hasRestroom'] ?? false,
      hasAccessibility: map['hasAccessibility'] ?? false,
      isFamilyFriendly: map['isFamilyFriendly'] ?? false,
      isHalal: map['isHalal'] ?? false,
      hasDelivery: map['hasDelivery'] ?? false,
      hasReservation: map['hasReservation'] ?? false,
      ownerId: map['ownerId'],
      isVerifiedMerchant: map['isVerifiedMerchant'] ?? false,
      businessPhone: map['businessPhone'],
      businessEmail: map['businessEmail'],
      workingHours: map['workingHours'] as Map<String, dynamic>?,
      requiresAdminReview: map['requiresAdminReview'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'description': description,
      'categoryId': categoryId,
      'categories': categories, // 👈 [FIX]
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
      id: id, nameAr: nameAr ?? this.nameAr, nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categories: categories ?? this.categories, // 👈 [FIX]
      governorate: governorate ?? this.governorate, city: city ?? this.city,
      address: address ?? this.address, phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp, location: location ?? this.location,
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
