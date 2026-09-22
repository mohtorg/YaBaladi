// screens/my_visits_screen.dart
// سجل زيارات المستخدم، قراءة فقط من Firestore.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class MyVisitsScreen extends StatelessWidget{const MyVisitsScreen({super.key});@override Widget build(BuildContext c){final uid=FirebaseAuth.instance.currentUser?.uid??'';return Scaffold(appBar:AppBar(title:const Text('سجل الزيارات'),backgroundColor:const Color(0xFF1454A3),foregroundColor:Colors.white),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('visits').where('userId',isEqualTo:uid).snapshots(),builder:(c,s){final ds=s.data?.docs??[];if(ds.isEmpty)return const Center(child:Text('لا توجد زيارات مسجلة'));return ListView(children:ds.map((d)=>ListTile(leading:const Icon(Icons.place),title:Text(d.data()['placeName']??d.data()['placeId']??'مكان'),subtitle:Text(d.data()['visitedAt']?.toString()??''))).toList());}));}}
