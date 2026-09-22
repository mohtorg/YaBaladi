// screens/notifications_screen.dart
// سجل إشعارات المستخدم. القراءة من Firestore، وتحديث isRead فقط عند الفتح.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class NotificationsScreen extends StatelessWidget { const NotificationsScreen({super.key});
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid??'';return Scaffold(appBar:AppBar(title:const Text('الإشعارات'),backgroundColor:const Color(0xFF1454A3),foregroundColor:Colors.white),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('notifications').where('userId',isEqualTo:uid).snapshots(),builder:(c,s){final docs=s.data?.docs??[];if(docs.isEmpty)return const Center(child:Text('لا توجد إشعارات'));return ListView.builder(itemCount:docs.length,itemBuilder:(c,i){final d=docs[i];final m=d.data();final read=m['isRead']==true;return ListTile(leading:Icon(read?Icons.notifications_none:Icons.notifications_active),title:Text(m['title']??'يا بلدي'),subtitle:Text(m['body']??''),tileColor:read?null:const Color(0xFFF2F6FB),onTap:()=>d.reference.update({'isRead':true,'readAt':FieldValue.serverTimestamp()}).catchError((_){ }));});}));}
}
