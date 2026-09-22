// models/merchant_profile.dart
// بيانات إضافية خاصة بالتاجر فقط - منفصلة عن AppUser
// عشان مستخدم عادي ميحملش حقول مالوش لازمة بيها

class MerchantProfile {
  final String uid; // نفس معرّف المستخدم في users
  final String businessName;
  final String phone;
  final List<String> ownedPlaceIds; // الأماكن اللي التاجر ده مالكها
  final bool verified; // هل الأدمن تأكد من صحة بيانات النشاط

  MerchantProfile({
    required this.uid,
    required this.businessName,
    required this.phone,
    this.ownedPlaceIds = const [],
    this.verified = false,
  });

  factory MerchantProfile.fromMap(String uid, Map<String, dynamic> map) {
    return MerchantProfile(
      uid: uid,
      businessName: map['businessName'] ?? '',
      phone: map['phone'] ?? '',
      ownedPlaceIds: List<String>.from(map['ownedPlaceIds'] ?? []),
      verified: map['verified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'phone': phone,
      'ownedPlaceIds': ownedPlaceIds,
      'verified': verified,
    };
  }
}
