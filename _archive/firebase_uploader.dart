import 'dart:convert';
import 'dart:io';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

void main() async {
  print('🚀 بدء رفع البيانات إلى Firebase...');

  // 1. تحميل ملف الصلاحيات (Service Account)
  final serviceAccountFile = File('serviceAccountKey.json');
  if (!serviceAccountFile.existsSync()) {
    print('❌ خطأ: ملف serviceAccountKey.json غير موجود في هذا المجلد!');
    print('👉 يرجى نسخ الملف من مشروع ya_baladi_seeder ووضعه هنا.');
    return;
  }

  // 2. تهيئة Firebase Admin بالـ Project ID الصحيح
  final admin = FirebaseAdminApp.initializeApp(
    'ya-baladi', // ✅ تم تعديل الـ Project ID هنا
    Credential.fromServiceAccount(serviceAccountFile),
  );

  // 3. إنشاء نسخة Firestore
  final firestore = Firestore(admin);

  // 4. قراءة ملف البيانات
  final jsonFile = File('port_said_osm_data.json');
  if (!jsonFile.existsSync()) {
    print('❌ خطأ: ملف port_said_osm_data.json غير موجود!');
    return;
  }
  
  final places = json.decode(jsonFile.readAsStringSync()) as List;
  print('📦 تم العثور على ${places.length} مكان لرفعه.');

  // 5. الرفع إلى مجموعة (places)
  final collection = firestore.collection('places');
  int successCount = 0;

  for (var place in places) {
    try {
      // التحقق من عدم وجود المكان مسبقاً
      final query = await collection.where('osm_id', WhereFilter.equal, place['osm_id']).get();
      
      if (query.docs.isNotEmpty) {
        print('⏩ المكان (${place['name']}) موجود بالفعل، تم تخطيه.');
        continue;
      }

      await collection.add(place);
      successCount++;
      print('✅ تم رفع: ${place['name']}');
    } catch (e) {
      print('❌ فشل رفع ${place['name']}: $e');
    }
  }

  print('🎉 اكتمل الرفع! تم إضافة $successCount مكان جديد إلى Firebase.');
  
  // إنهاء السكريبت بنجاح
  exit(0);
}