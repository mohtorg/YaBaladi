// services/rewards_service.dart
// الخدمة المركزية للنقاط والمكافآت.
// القراءة آمنة للمستخدم، أما خصم النقاط/إصدار المكافأة فلا ننفذه من العميل
// لأن ذلك يسمح بالتلاعب بالرصيد. نرسل طلب استبدال فقط، ثم تتم التسوية من Backend.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/points_wallet_model.dart';
import '../models/reward_model.dart';

class RewardsService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RewardsService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<Reward>> watchActiveRewards() {
    return _db.collection('rewards').where('active', isEqualTo: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Reward.fromMap(doc.id, doc.data())).toList(),
        );
  }

  Stream<PointsWallet> watchMyWallet() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('points_wallets').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return PointsWallet(userId: uid);
      return PointsWallet.fromMap(uid, doc.data() ?? {});
    });
  }

  Future<void> requestRedemption(Reward reward) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('يجب تسجيل الدخول أولاً');
    if (!reward.active) throw StateError('المكافأة غير متاحة حالياً');
    if (reward.pointsCost <= 0) throw StateError('تكلفة المكافأة غير صحيحة');

    // إنشاء طلب فقط؛ لا نعدل الرصيد من الهاتف.
    await _db.collection('reward_redemption_requests').add({
      'userId': uid,
      'rewardId': reward.id,
      'pointsCost': reward.pointsCost,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
