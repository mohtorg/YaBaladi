// lib/models/place.dart
// [v3.4 — 2026-11-15] — LINTER FIX: Converted formattedCity to final in fullAddress.
// [v3.3 — 2026-11-15] — ADDED: `fullAddress` getter to format address as
//   "Street - District - Governorate", auto-prefixing "حي" to city if missing.
// [v3.2 — 2026-11-15] — No logic change. Version bump only.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/adjusted_score_service.dart';

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
  final int viewCount;
  final bool isApproved;
  final bool isActive;
  final DateTime? createdAt;

  // ✅ Phase 12
  final bool isRankable;

  final double? adjustedScore;
  final double? sampleQuality;
  final String? confidenceLabel;

  final int priceLevel;
  final bool hasWifi;
  final bool hasParking;
  final bool hasRestroom;
  final bool hasAccessibility;
  final bool isFamilyFriendly;
  final bool isHalal;
  final bool hasDelivery;
  final bool hasReservation;

  final String? ownerId;
  final bool isVerifiedMerchant;
  final String? businessPhone;
  final String? businessEmail;
  final Map<String, dynamic>? workingHours;
  final bool requiresAdminReview;

  final String? website;
  final List<String> tags;
  final String? facebookPage;

  final String? parentId;
  final bool isBranch;

  final bool hasActiveOffer;
  final String? offerTitle;
  final String? offerDetails;
  final DateTime? offerExpiryDate;
  final DateTime? offerCreatedAt;

  final bool isOfferFeatureEnabled;
  final bool offerRequestPending;

  final String? banReason;
  final DateTime? bannedAt;
  final String? bannedBy;

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
    this.viewCount = 0,
    this.isApproved = false,
    this.isActive = true,
    this.createdAt,
    this.isRankable = false,
    this.adjustedScore,
    this.sampleQuality,
    this.confidenceLabel,
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
    this.website,
    this.tags = const [],
    this.facebookPage,
    this.parentId,
    this.isBranch = false,
    this.hasActiveOffer = false,
    this.offerTitle,
    this.offerDetails,
    this.offerExpiryDate,
    this.offerCreatedAt,
    this.isOfferFeatureEnabled = false,
    this.offerRequestPending = false,
    this.banReason,
    this.bannedAt,
    this.bannedBy,
  });

  factory Place.fromMap(String id, Map<String, dynamic> map) {
    List<String> safeList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    final reviewCount = (map['reviewCount'] as num?)?.toInt() ?? 0;
    // fallback: derive from reviewCount if the mirror flag is absent
    final isRankable = (map['isRankable'] as bool?) ??
        (reviewCount >= AdjustedScoreService.minRatingsForRanking);

    return Place(
      id: id,
      nameAr: map['nameAr']?.toString() ?? '',
      nameEn: map['nameEn']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      categories: safeList(map['categories']),
      governorate: map['governorate']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      whatsapp: map['whatsapp']?.toString() ?? '',
      location:
          map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      imageUrls: safeList(map['imageUrls']),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: reviewCount,
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
      isApproved: map['isApproved'] == true,
      isActive: map['isActive'] != false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      isRankable: isRankable,
      adjustedScore: (map['adjustedScore'] as num?)?.toDouble(),
      sampleQuality: (map['sampleQuality'] as num?)?.toDouble(),
      confidenceLabel: map['confidenceLabel']?.toString(),
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
      website: map['website']?.toString(),
      tags: safeList(map['tags']),
      facebookPage: map['facebookPage']?.toString(),
      parentId: map['parentId']?.toString(),
      isBranch: map['isBranch'] == true,
      hasActiveOffer: map['hasActiveOffer'] == true,
      offerTitle: map['offerTitle']?.toString(),
      offerDetails: map['offerDetails']?.toString(),
      offerExpiryDate: map['offerExpiryDate'] is Timestamp
          ? (map['offerExpiryDate'] as Timestamp).toDate()
          : null,
      offerCreatedAt: map['offerCreatedAt'] is Timestamp
          ? (map['offerCreatedAt'] as Timestamp).toDate()
          : null,
      isOfferFeatureEnabled: map['isOfferFeatureEnabled'] == true,
      offerRequestPending: map['offerRequestPending'] == true,
      banReason: map['banReason']?.toString(),
      bannedAt: map['bannedAt'] is Timestamp
          ? (map['bannedAt'] as Timestamp).toDate()
          : null,
      bannedBy: map['bannedBy']?.toString(),
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
      'viewCount': viewCount,
      'isApproved': isApproved,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isRankable': isRankable,
      if (adjustedScore != null) 'adjustedScore': adjustedScore,
      if (sampleQuality != null) 'sampleQuality': sampleQuality,
      if (confidenceLabel != null) 'confidenceLabel': confidenceLabel,
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
      if (website != null && website!.isNotEmpty) 'website': website,
      if (tags.isNotEmpty) 'tags': tags,
      if (facebookPage != null && facebookPage!.isNotEmpty)
        'facebookPage': facebookPage,
      if (parentId != null) 'parentId': parentId,
      'isBranch': isBranch,
      'hasActiveOffer': hasActiveOffer,
      if (offerTitle != null) 'offerTitle': offerTitle,
      if (offerDetails != null) 'offerDetails': offerDetails,
      if (offerExpiryDate != null)
        'offerExpiryDate': Timestamp.fromDate(offerExpiryDate!),
      if (offerCreatedAt != null)
        'offerCreatedAt': Timestamp.fromDate(offerCreatedAt!),
      'isOfferFeatureEnabled': isOfferFeatureEnabled,
      'offerRequestPending': offerRequestPending,
      if (banReason != null) 'banReason': banReason,
      if (bannedAt != null) 'bannedAt': Timestamp.fromDate(bannedAt!),
      if (bannedBy != null) 'bannedBy': bannedBy,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ v3.4: Smart Address Formatting
  // ═══════════════════════════════════════════════════════════════

  /// يعيد العنوان الكامل بالتنسيق الهرمي الصحيح:
  /// "شارع الجمهورية - حي الشرق - بورسعيد"
  ///
  /// - يتجاهل الحقول الفارغة تلقائياً.
  /// - يضيف بادئة "حي " لحقل المدينة إذا لم تكن موجودة.
  /// - يمنع التكرار أو الأخطاء الإملائية.
  String get fullAddress {
    final List<String> parts = [];

    // 1. المنطقة / الشارع (الأصغر)
    final trimmedAddress = address.trim();
    if (trimmedAddress.isNotEmpty) {
      parts.add(trimmedAddress);
    }

    // 2. الحي (نضيف "حي" بذكاء)
    final trimmedCity = city.trim();
    if (trimmedCity.isNotEmpty) {
      final String formattedCity;
      if (!trimmedCity.startsWith('حي ')) {
        if (trimmedCity.startsWith('حي')) {
          // التعامل مع حالة "حيالشرق" (بدون مسافة)
          formattedCity = 'حي ${trimmedCity.substring(2).trim()}';
        } else {
          // التعامل مع حالة "الشرق" (إضافة حي)
          formattedCity = 'حي $trimmedCity';
        }
      } else {
        formattedCity = trimmedCity;
      }
      parts.add(formattedCity);
    }

    // 3. المحافظة (الأكبر)
    final trimmedGov = governorate.trim();
    if (trimmedGov.isNotEmpty) {
      parts.add(trimmedGov);
    }

    // دمج الأجزاء بفاصل " - "
    return parts.join(' - ');
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
    int? viewCount,
    bool? isApproved,
    bool? isActive,
    DateTime? createdAt,
    bool? isRankable,
    double? adjustedScore,
    double? sampleQuality,
    String? confidenceLabel,
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
    String? website,
    List<String>? tags,
    String? facebookPage,
    String? parentId,
    bool? isBranch,
    bool? hasActiveOffer,
    String? offerTitle,
    String? offerDetails,
    DateTime? offerExpiryDate,
    DateTime? offerCreatedAt,
    bool? isOfferFeatureEnabled,
    bool? offerRequestPending,
    String? banReason,
    DateTime? bannedAt,
    String? bannedBy,
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
      viewCount: viewCount ?? this.viewCount,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      isRankable: isRankable ?? this.isRankable,
      adjustedScore: adjustedScore ?? this.adjustedScore,
      sampleQuality: sampleQuality ?? this.sampleQuality,
      confidenceLabel: confidenceLabel ?? this.confidenceLabel,
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
      website: website ?? this.website,
      tags: tags ?? this.tags,
      facebookPage: facebookPage ?? this.facebookPage,
      parentId: parentId ?? this.parentId,
      isBranch: isBranch ?? this.isBranch,
      hasActiveOffer: hasActiveOffer ?? this.hasActiveOffer,
      offerTitle: offerTitle ?? this.offerTitle,
      offerDetails: offerDetails ?? this.offerDetails,
      offerExpiryDate: offerExpiryDate ?? this.offerExpiryDate,
      offerCreatedAt: offerCreatedAt ?? this.offerCreatedAt,
      isOfferFeatureEnabled:
          isOfferFeatureEnabled ?? this.isOfferFeatureEnabled,
      offerRequestPending: offerRequestPending ?? this.offerRequestPending,
      banReason: banReason ?? this.banReason,
      bannedAt: bannedAt ?? this.bannedAt,
      bannedBy: bannedBy ?? this.bannedBy,
    );
  }
}
