// models/user_model.dart
// نموذج بيانات المستخدم العام.
import 'app_experience_mode.dart';

// role يظل محفوظًا للتوافق مع البيانات الحالية (user/merchant)،
// أما الصلاحية الإدارية فلا يختارها المستخدم وتأتي من Firebase Custom Claims/ملف صلاحيات موثوق.

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String role; // "user" | "merchant" | "admin"
  final AppExperienceMode? experienceMode; // resident / visitor للحساب الشخصي فقط
  final Map<String, double>? homeLocation; // {'lat': .., 'lng': ..} اختياري
  final List<String> favoritePlaceIds; // معرّفات الأماكن المحفوظة في المفضلة

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.role = 'user', // أي مستخدم جديد يبقى "عادي" افتراضيًا
    this.experienceMode,
    this.homeLocation,
    this.favoritePlaceIds = const [],
  });

  // لا يوجد getter للصلاحية الإدارية هنا؛ الصلاحية مصدرها Custom Claim/Rules.
  bool get isMerchant => role == 'merchant';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    Map<String, double>? location;
    if (map['homeLocation'] != null) {
      final loc = map['homeLocation'] as Map<String, dynamic>;
      location = {
        'lat': (loc['lat'] ?? 0).toDouble(),
        'lng': (loc['lng'] ?? 0).toDouble(),
      };
    }
    return AppUser(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      experienceMode: AppExperienceModeX.fromValue(map['experienceMode'] as String?),
      homeLocation: location,
      favoritePlaceIds: List<String>.from(map['favoritePlaceIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      if (experienceMode != null) 'experienceMode': experienceMode!.value,
      if (homeLocation != null) 'homeLocation': homeLocation,
      'favoritePlaceIds': favoritePlaceIds,
    };
  }
}
