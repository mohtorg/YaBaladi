# الجولة 2 — إصلاحات نشر لا تحتاج Blaze (جزء من P2)
- `lib/main.dart`: إزالة تشغيل ResetRatingsUtil (كان يمسح كل التقييمات عند تفعيل علم). الملف reset_ratings_util.dart نفسه يُحذف يدوياً: `del lib\core\utils\reset_ratings_util.dart`.
- `android/app/build.gradle.kts`: توقيع release من `android/key.properties` (storeFile, storePassword, keyAlias, keyPassword). أنشئ المفتاح: `keytool -genkey -v -keystore yabaladi.jks -keyalg RSA -keysize 2048 -validity 10000 -alias yabaladi` واحفظه نسخاً احتياطية خارج المشروع.
- `firestore.indexes.json`: إضافة فهارس categoryId وisApproved+isActive التي تستعلم بها الشاشات. انشر: `firebase deploy --only firestore:indexes`.
- `.gitignore`: استثناء المفاتيح.
- حُذف `seed.sh` (كتابات غير موثّقة ببيانات وهمية).
**لم يُجرَّب شيء هنا**: Flutter غير متاح عندي؛ شغّل `flutter analyze` ثم `flutter build appbundle --release`. التراجع: النسخ الأصلية لديك قبل الدمج.
