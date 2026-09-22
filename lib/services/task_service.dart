// services/task_service.dart
// خدمة المهام الشخصية. نستخدم serverTimestamp للحفظ المتسق مع خادم Firebase.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
class TaskService {
  final _db=FirebaseFirestore.instance; final _auth=FirebaseAuth.instance;
  Stream<List<UserTask>> watchMine(){ final uid=_auth.currentUser?.uid; if(uid==null)return const Stream.empty();
    return _db.collection('tasks').where('userId',isEqualTo:uid).snapshots().map((s)=>s.docs.map((d)=>UserTask.fromMap(d.id,d.data())).toList()..sort((a,b)=>a.scheduledAt.compareTo(b.scheduledAt))); }
  Future<void> add(String title,DateTime when) async { final uid=_auth.currentUser?.uid; if(uid==null)throw StateError('يجب تسجيل الدخول أولاً'); if(title.trim().isEmpty)throw ArgumentError('عنوان المهمة مطلوب'); await _db.collection('tasks').add({'userId':uid,'title':title.trim(),'scheduledAt':Timestamp.fromDate(when),'completed':false,'createdAt':FieldValue.serverTimestamp()}); }
  Future<void> setCompleted(String id,bool value)=>_db.collection('tasks').doc(id).update({'completed':value});
  Future<void> delete(String id)=>_db.collection('tasks').doc(id).delete();
}
