// models/library_content.dart
//
// مكتبة "يا بلدي": طبقة محتوى ثقافي/بصري مستقلة عن places.
// national = محتوى مشترك على مستوى مصر، governorate = محتوى محلي لمحافظة محددة.
// لا يظهر أي عنصر للمستخدم إلا إذا كان published && usageApproved.

import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryContentType {
  static const image = 'image';
  static const video = 'video';
  static const story = 'story';
  static const landmark = 'landmark';
  static const food = 'food';
  static const crafts = 'crafts';
  static const event = 'event';
  static const dayTrip = 'day_trip';

  static const all = [image, video, story, landmark, food, crafts, event, dayTrip];

  static String labelAr(String type) {
    switch (type) {
      case video: return 'فيديوهات';
      case story: return 'حكايات';
      case landmark: return 'معالم';
      case food: return 'أطعمة ومأكولات';
      case crafts: return 'تراث وحرف';
      case event: return 'فعاليات';
      case dayTrip: return 'رحلة اليوم';
      default: return 'صور';
    }
  }

  static String labelEn(String type) {
    switch (type) {
      case video: return 'Videos';
      case story: return 'Stories';
      case landmark: return 'Landmarks';
      case food: return 'Food';
      case crafts: return 'Heritage & Crafts';
      case event: return 'Events';
      case dayTrip: return 'Day Trips';
      default: return 'Photos';
    }
  }
}

class LibraryContent {
  final String id;
  final String scope; // national | governorate
  final String governorateId;
  final String contentType;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String mediaUrl;
  final String thumbnailUrl;
  final String sourceUrl;
  final String credit;
  final String license;
  final bool usageApproved;
  final bool published;
  final DateTime? publishedAt;
  final int sortOrder;

  const LibraryContent({
    required this.id,
    this.scope = 'governorate',
    this.governorateId = '',
    required this.contentType,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.mediaUrl = '',
    this.thumbnailUrl = '',
    this.sourceUrl = '',
    this.credit = '',
    this.license = '',
    this.usageApproved = false,
    this.published = false,
    this.publishedAt,
    this.sortOrder = 0,
  });

  String titleFor(String lang) => lang == 'en' ? titleEn : titleAr;
  String descriptionFor(String lang) => lang == 'en' ? descriptionEn : descriptionAr;

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  factory LibraryContent.fromMap(String id, Map<String, dynamic> map) {
    return LibraryContent(
      id: id,
      scope: (map['scope'] ?? 'governorate') as String,
      governorateId: (map['governorateId'] ?? '') as String,
      contentType: (map['contentType'] ?? LibraryContentType.image) as String,
      titleAr: (map['title_ar'] ?? '') as String,
      titleEn: (map['title_en'] ?? '') as String,
      descriptionAr: (map['description_ar'] ?? '') as String,
      descriptionEn: (map['description_en'] ?? '') as String,
      mediaUrl: (map['mediaUrl'] ?? '') as String,
      thumbnailUrl: (map['thumbnailUrl'] ?? '') as String,
      sourceUrl: (map['sourceUrl'] ?? '') as String,
      credit: (map['credit'] ?? '') as String,
      license: (map['license'] ?? '') as String,
      usageApproved: map['usageApproved'] == true,
      published: map['published'] == true,
      publishedAt: _date(map['publishedAt']),
      sortOrder: (map['sortOrder'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'scope': scope,
    'governorateId': governorateId,
    'contentType': contentType,
    'title_ar': titleAr,
    'title_en': titleEn,
    'description_ar': descriptionAr,
    'description_en': descriptionEn,
    'mediaUrl': mediaUrl,
    'thumbnailUrl': thumbnailUrl,
    'sourceUrl': sourceUrl,
    'credit': credit,
    'license': license,
    'usageApproved': usageApproved,
    'published': published,
    if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
    'sortOrder': sortOrder,
  };
}
