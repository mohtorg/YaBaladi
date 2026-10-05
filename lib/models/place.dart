// models/place.dart
// Firestore Place model.
import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String nameAr;
  final String nameEn;
  final String description;
  final String categoryId;
  final String ownerId;
  final GeoPoint? location;
  final String address;
  final String city;
  final String governorate;
  final String phone;
  final String whatsapp;
  final List<String> imageUrls;
  final List<String> tags;
  final double averageRating;
  final int reviewCount;

  /// 1=$ · 2=$$ · 3=$$$ · 4=$$$$
  /// 0 = غير محدد
  final int priceLevel;

  final bool isApproved;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Place({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.description = '',
    required this.categoryId,
    this.ownerId = '',
    this.location,
    this.address = '',
    this.city = '',
    this.governorate = '',
    this.phone = '',
    this.whatsapp = '',
    this.imageUrls = const [],
    this.tags = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.priceLevel = 0,
    this.isApproved = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Place.fromMap(String id, Map<String, dynamic> map) {
    return Place(
      id: id,
      nameAr: (map['nameAr'] as String?) ?? '',
      nameEn: (map['nameEn'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      categoryId: (map['categoryId'] as String?) ?? '',
      ownerId: (map['ownerId'] as String?) ?? '',
      location: map['location'] as GeoPoint?,
      address: (map['address'] as String?) ?? '',
      city: (map['city'] as String?) ?? '',
      governorate: (map['governorate'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      whatsapp: (map['whatsapp'] as String?) ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      tags: List<String>.from(map['tags'] ?? const []),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      priceLevel: (map['priceLevel'] as num?)?.toInt() ?? 0,
      isApproved: (map['isApproved'] as bool?) ?? false,
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nameAr': nameAr,
        'nameEn': nameEn,
        'description': description,
        'categoryId': categoryId,
        'ownerId': ownerId,
        'location': location,
        'address': address,
        'city': city,
        'governorate': governorate,
        'phone': phone,
        'whatsapp': whatsapp,
        'imageUrls': imageUrls,
        'tags': tags,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'priceLevel': priceLevel,
        'isApproved': isApproved,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Place copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? description,
    String? categoryId,
    String? ownerId,
    GeoPoint? location,
    String? address,
    String? city,
    String? governorate,
    String? phone,
    String? whatsapp,
    List<String>? imageUrls,
    List<String>? tags,
    double? averageRating,
    int? reviewCount,
    int? priceLevel,
    bool? isApproved,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Place(
        id: id ?? this.id,
        nameAr: nameAr ?? this.nameAr,
        nameEn: nameEn ?? this.nameEn,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        ownerId: ownerId ?? this.ownerId,
        location: location ?? this.location,
        address: address ?? this.address,
        city: city ?? this.city,
        governorate: governorate ?? this.governorate,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        imageUrls: imageUrls ?? this.imageUrls,
        tags: tags ?? this.tags,
        averageRating: averageRating ?? this.averageRating,
        reviewCount: reviewCount ?? this.reviewCount,
        priceLevel: priceLevel ?? this.priceLevel,
        isApproved: isApproved ?? this.isApproved,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'Place($id, $nameAr / $nameEn)';
}