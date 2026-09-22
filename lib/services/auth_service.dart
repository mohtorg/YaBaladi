// services/auth_service.dart
// خدمة مركزية لكل عمليات تسجيل الدخول والخروج
// وربط المستخدم المسجّل بمستنده في Firestore (بما فيه الدور: user/merchant/admin)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/merchant_profile.dart';
import '../models/app_experience_mode.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await _ensureUserDocumentExists(userCredential.user!);
  }

  Future<void> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserDocumentExists(userCredential.user!);
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserDocumentExists(userCredential.user!, fullName: fullName);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // بيتأكد إن للمستخدم مستند في Firestore
  // لو مستخدم جديد تمامًا: بيتسجل بـ role فاضي (يعني "لسه ما اختارش نوع الحساب العام").
  // لا يوجد هنا أي مسار لاختيار admin؛ الإدارة تُمنح خارج واجهة الجمهور فقط.
  Future<void> _ensureUserDocumentExists(User firebaseUser, {String? fullName}) async {
    final docRef = _db.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUser = AppUser(
        uid: firebaseUser.uid,
        fullName: fullName ?? firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        role: '', // فاضي = لسه محتاج يختار (مستخدم عادي / تاجر) في أول دخول
      );
      await docRef.set(newUser.toMap());
    }
  }

  // جلب بيانات المستخدم الكاملة (بما فيها الدور) من Firestore
  // يحدد هل الحساب مشرف مخصص، حتى لو ظل role في users هو user/merchant.
  // لا يمنح الصلاحية بنفسه؛ هو فقط يقرأ ملف الصلاحيات الذي أنشأه الأدمن الأعلى.

  // مهم أمنيًا: الوصول الإداري لا يُستنتج من اختيار المستخدم لنوع الحساب.
  // Firebase Custom Claims هي المصدر الأساسي لصلاحية الأدمن الأعلى.
  Future<bool> hasAdminClaim() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  // يعيد ملف المشرف الحالي لاستخدامه في التحكم في واجهة لوحة الإدارة.
  // هذا لا يستبدل Firestore Rules؛ هو فقط يمنع إظهار أدوات لا يحتاجها المشرف.
  Future<Map<String, dynamic>?> getModeratorProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('admin_profiles').doc(uid).get();
    if (!doc.exists || doc.data()?['active'] != true) return null;
    return doc.data();
  }

  Future<bool> isModerator() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _db.collection('admin_profiles').doc(uid).get();
    return doc.exists && (doc.data()?['active'] == true);
  }

  Future<AppUser?> getCurrentAppUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(firebaseUser.uid, doc.data()!);
  }

  // نسخة Stream من نفس البيانات - بتتحدث لحظيًا لحظة ما الدور يتغيّر
  // (مهم عشان شاشة AuthGate تنتقل تلقائيًا بعد اختيار نوع الحساب من غير أي navigation يدوي)
  Stream<AppUser?> get currentAppUserStream {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return Stream.value(null);

    return _db.collection('users').doc(firebaseUser.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(firebaseUser.uid, doc.data()!);
    });
  }

  // ملاحظة التعديل:
  // لا توجد هنا أي إمكانية لمنح دور admin. قواعد Firestore تمنع ذلك أيضًا،
  // بينما admin الحقيقي يجب منحه عبر Custom Claim من بيئة موثوقة.
  // تحديد نوع الحساب لأول مرة - بيتنفذ من شاشة اختيار نوع الحساب
  // لو "تاجر": بينشئ كمان مستند merchants بجانب تحديث الدور
  // تغيير وضع الاستخدام للحساب الشخصي فقط.
  // لا يغيّر role ولا يمنح أي صلاحية إدارية، ولذلك يظل الفصل الأمني
  // بين user/merchant/admin قائمًا كما هو.
  Future<void> setExperienceMode(AppExperienceMode mode) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    final role = (doc.data()?['role'] ?? 'user').toString();
    if (role != 'user') {
      throw StateError('وضع المقيم/الزائر متاح للحساب الشخصي فقط');
    }

    await doc.reference.update({'experienceMode': mode.value});
  }

  Future<void> setAccountType({
    required String role, // "user" أو "merchant"
    String? businessName,
    String? phone,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;
    if (role != 'user' && role != 'merchant') {
      throw ArgumentError('نوع الحساب غير مسموح به');
    }

    await _db.collection('users').doc(firebaseUser.uid).update({'role': role});

    if (role == 'merchant') {
      final merchant = MerchantProfile(
        uid: firebaseUser.uid,
        businessName: businessName ?? '',
        phone: phone ?? '',
      );
      await _db.collection('merchants').doc(firebaseUser.uid).set(merchant.toMap());
    }
  }
}
