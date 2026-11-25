// lib/models/place_model.dart
// [v1.4.0 — 2026-11-15] — SMART ADDRESS + LINTER FIX:
//   - Added `fullAddress` getter ("Street - District - Governorate").
//   - Added curly braces to all single-line `if` statements.
// [v1.3.0 — 2026-11-10] — ADDED: pinObfuscated field (for rating verification).
// [v1.2.0 — 2026-11-08] — FIXED: fromMap now supports OSM legacy data.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class PlaceModel {
  final String? id; // معرف Firestore (يكون null عند الإضافة الجديدة)
  final String nameAr;
  final String nameEn;
  final String description;
  final String category; // الفئة (تاريخي، ديني، ترفيهي...)
  final String governorate;
  final String district; // الحي
  final String address;
  final double latitude;
  final double longitude;
  final String mapUrl;
  final DateTime? createdAt;

  /// رمز المكان (base64 من "placeId:pin") — يُستخدم للتحقق من الزيارة.
  /// null = المكان لا يدعم التحقق بالرمز (اختياري).
  final String? pinObfuscated;

  PlaceModel({
    this.id,
    required this.nameAr,
    required this.nameEn,
    required this.description,
    required this.category,
    required this.governorate,
    required this.district,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.mapUrl,
    this.createdAt,
    this.pinObfuscated,
  });

  // ═══════════════════════════════════════════════════════════════
  // ✅ v1.4.0: Smart Address Formatting
  // ═══════════════════════════════════════════════════════════════

  /// يعيد العنوان الكامل بالتنسيق الهرمي الصحيح:
  /// "شارع الجمهورية - حي الشرق - بورسعيد"
  String get fullAddress {
    final List<String> parts = [];

    // 1. المنطقة / الشارع (الأصغر)
    final trimmedAddress = address.trim();
    if (trimmedAddress.isNotEmpty) {
      parts.add(trimmedAddress);
    }

    // 2. الحي (نضيف "حي" بذكاء)
    final trimmedDistrict = district.trim();
    if (trimmedDistrict.isNotEmpty) {
      final String formattedDistrict;
      if (!trimmedDistrict.startsWith('حي ') &&
          !trimmedDistrict.startsWith('مدينة ') &&
          !trimmedDistrict.startsWith('مركز ')) {
        if (trimmedDistrict.startsWith('حي')) {
          formattedDistrict = 'حي ${trimmedDistrict.substring(2).trim()}';
        } else {
          formattedDistrict = 'حي $trimmedDistrict';
        }
      } else {
        formattedDistrict = trimmedDistrict;
      }
      parts.add(formattedDistrict);
    }

    // 3. المحافظة (الأكبر)
    final trimmedGov = governorate.trim();
    if (trimmedGov.isNotEmpty) {
      parts.add(trimmedGov);
    }

    // دمج الأجزاء بفاصل " - "
    return parts.join(' - ');
  }

  // ─────────────────────────────────────────────────────────────
  // 1. التحويل إلى Map لحفظه في Firestore (الصيغة القياسية الجديدة)
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'name_ar': nameAr,
      'name_en': nameEn,
      'description': description,
      'category': category,
      'governorate': governorate,
      'district': district,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'map_url': mapUrl,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'pin_obfuscated': pinObfuscated,
    };
  }

  // ─────────────────────────────────────────────────────────────
  // 2. الإنشاء من Map عند القراءة من Firestore (متوافق مع القديم والجديد)
  // ─────────────────────────────────────────────────────────────
  factory PlaceModel.fromMap(Map<String, dynamic> map, String documentId) {
    // دالة مساعدة لتحويل أي قيمة بأمان إلى نص
    String safeString(dynamic value, [String fallback = '']) {
      if (value == null) {
        return fallback;
      }
      return value.toString().trim();
    }

    // دالة مساعدة لتحويل أي قيمة إلى رقم عشري بأمان
    double safeDouble(dynamic value) {
      if (value == null) {
        return 0.0;
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // دالة مساعدة للتعامل مع التاريخ
    DateTime? safeDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    // قراءة الحقول مع دعم الأسماء القديمة (OSM) والجديدة
    final arName = safeString(map['name_ar']).isNotEmpty
        ? safeString(map['name_ar'])
        : safeString(map['name']);

    final cat = safeString(map['category']).isNotEmpty
        ? safeString(map['category'])
        : safeString(map['categoryId'], 'غير محدد');

    final dist = safeString(map['district']).isNotEmpty
        ? safeString(map['district'])
        : safeString(map['city']);

    final date = safeDate(map['created_at']) ?? safeDate(map['createdAt']);

    // رمز المكان: فارغ → null (لا نستخدم '' لأنه يخلق لبسًا)
    final rawPin = safeString(map['pin_obfuscated']);
    final pin = rawPin.isEmpty ? null : rawPin;

    return PlaceModel(
      id: documentId,
      nameAr: arName,
      nameEn: safeString(map['name_en']),
      description: safeString(map['description']),
      category: cat,
      governorate: safeString(map['governorate'], 'بورسعيد'),
      district: dist,
      address: safeString(map['address']),
      latitude: safeDouble(map['latitude']),
      longitude: safeDouble(map['longitude']),
      mapUrl: safeString(map['map_url']),
      createdAt: date,
      pinObfuscated: pin,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. الإنشاء من صف إكسل (Excel Row)
  // ─────────────────────────────────────────────────────────────
  factory PlaceModel.fromExcelRow(List<Data?> row) {
    // دالة مساعدة لاستخراج النص بأمان من خلية الإكسل
    String getString(int index) {
      if (index >= row.length || row[index] == null) {
        return '';
      }
      return row[index]!.value?.toString().trim() ?? '';
    }

    // دالة مساعدة لاستخراج الأرقام العشرية (الإحداثيات)
    double getDouble(int index) {
      String val = getString(index);

      if (val.isEmpty) {
        return 0.0;
      }

      // 🌟 تحويل الأرقام العربية والفارسية إلى إنجليزية
      const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
      const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

      for (int i = 0; i < 10; i++) {
        val = val.replaceAll(arabicDigits[i], englishDigits[i]);
        val = val.replaceAll(persianDigits[i], englishDigits[i]);
      }

      // معالجة الفاصلة العربية أو الأوروبية
      val = val.replaceAll(',', '.');

      return double.tryParse(val) ?? 0.0;
    }

    return PlaceModel(
      nameAr: getString(0),
      nameEn: getString(1),
      description: getString(2),
      category: getString(3),
      governorate: getString(4).isEmpty ? 'بورسعيد' : getString(4),
      district: getString(5),
      address: getString(6),
      latitude: getDouble(7),
      longitude: getDouble(8),
      mapUrl: getString(9),
      // Excel لا يحتوي على PIN — يبقى null
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. التحقق من صحة البيانات (Validation)
  // ─────────────────────────────────────────────────────────────
  bool get isValid {
    if (nameAr.isEmpty) {
      return false;
    }
    if (latitude == 0.0 || longitude == 0.0) {
      return false;
    }
    if (latitude < -90 || latitude > 90) {
      return false;
    }
    if (longitude < -180 || longitude > 180) {
      return false;
    }
    return true;
  }

  // دالة للحصول على سبب الخطأ (تستخدم في الواجهة)
  String get validationError {
    if (nameAr.isEmpty) {
      return 'الاسم العربي مفقود';
    }
    if (latitude == 0.0 || longitude == 0.0) {
      return 'إحداثيات غير صحيحة (0,0)';
    }
    if (latitude < -90 || latitude > 90) {
      return 'خط العرض خارج النطاق المسموح';
    }
    if (longitude < -180 || longitude > 180) {
      return 'خط الطول خارج النطاق المسموح';
    }
    return 'بيانات صحيحة';
  }

  // دالة لنسخ الكائن مع تعديل حقول معينة (مفيدة عند التحديث)
  PlaceModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? description,
    String? category,
    String? governorate,
    String? district,
    String? address,
    double? latitude,
    double? longitude,
    String? mapUrl,
    DateTime? createdAt,
    String? pinObfuscated,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      category: category ?? this.category,
      governorate: governorate ?? this.governorate,
      district: district ?? this.district,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapUrl: mapUrl ?? this.mapUrl,
      createdAt: createdAt ?? this.createdAt,
      pinObfuscated: pinObfuscated ?? this.pinObfuscated,
    );
  }
}
