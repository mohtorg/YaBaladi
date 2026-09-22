// إعدادات الإشعارات الشخصية للمستخدم ومقدم الخدمة.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class NotificationSettingsScreen extends StatefulWidget { const NotificationSettingsScreen({super.key}); @override State<NotificationSettingsScreen> createState()=>_NotificationSettingsState(); }
class _NotificationSettingsState extends State<NotificationSettingsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final keys = ['general','events','offers','places','rewards','favorites','nearby','announcements','security','subscriptions'];
  final labels = ['الإشعارات العامة','الفعاليات','العروض','الأماكن الجديدة','المكافآت','المفضلة','الأماكن القريبة','إعلانات يا بلدي','الأمان والحساب','الاشتراكات'];
  final local = <String,bool>{};
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إدارة الإشعارات'), backgroundColor: const Color(0xFF1454A3), foregroundColor: Colors.white),
    body: StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream: FirebaseFirestore.instance.collection('notification_preferences').doc(uid).snapshots(), builder: (context,snapshot) {
      final data = snapshot.data?.data() ?? {};
      return ListView.builder(itemCount: keys.length, itemBuilder: (context,i) {
        final key = keys[i]; final value = local[key] ?? (data[key] ?? true) as bool;
        return SwitchListTile(title: Text(labels[i]), value: value, onChanged: (v) { setState(()=>local[key]=v); FirebaseFirestore.instance.collection('notification_preferences').doc(uid).set({key:v,'updatedAt':FieldValue.serverTimestamp()}, SetOptions(merge:true)); });
      });
    }),
  );
}
