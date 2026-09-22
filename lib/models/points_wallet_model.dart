// models/points_wallet_model.dart
// نموذج محفظة النقاط للمستخدم.
// لا نسمح من تطبيق الهاتف بتغيير balance مباشرة؛ التعديل المالي/النقطي
// يجب أن يتم عبر Backend موثوق أو Cloud Function بعد التحقق من العملية.

import 'package:cloud_firestore/cloud_firestore.dart';

class PointsWallet {
  final String userId;
  final int balance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final DateTime? updatedAt;

  const PointsWallet({
    required this.userId,
    this.balance = 0,
    this.lifetimeEarned = 0,
    this.lifetimeRedeemed = 0,
    this.updatedAt,
  });

  factory PointsWallet.fromMap(String userId, Map<String, dynamic> map) {
    final rawUpdated = map['updatedAt'];
    return PointsWallet(
      userId: userId,
      balance: ((map['balance'] ?? 0) as num).toInt(),
      lifetimeEarned: ((map['lifetimeEarned'] ?? 0) as num).toInt(),
      lifetimeRedeemed: ((map['lifetimeRedeemed'] ?? 0) as num).toInt(),
      updatedAt: rawUpdated is Timestamp ? rawUpdated.toDate() : null,
    );
  }
}
