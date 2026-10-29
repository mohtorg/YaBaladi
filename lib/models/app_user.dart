// lib/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/auth/role.dart'; // ✅ استيراد UserRole الأساسي للمشروع

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final bool isBanned;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = UserRole.member,
    this.isBanned = false,
    this.createdAt,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      uid: id,
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? 'مستخدم',
      photoUrl: map['photoUrl']?.toString(),
      role: _parseRole(map['role']),
      isBanned: (map['isBanned'] as bool?) ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // دالة داخلية لتحويل النص إلى UserRole بأمان
  static UserRole _parseRole(dynamic raw) {
    if (raw is! String) return UserRole.member;
    final lower = raw.toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name == lower,
      orElse: () => UserRole.member,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'isBanned': isBanned,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    bool? isBanned,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
