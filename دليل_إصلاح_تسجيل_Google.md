# إصلاح تسجيل Google على الجوال — دليل حاسم

## التشخيص (من فحص الملفات)
1. **بصمة SHA-1 متغيّرة**: `build.gradle.kts` كان يوقّع بمفتاح debug التلقائي. FlutLab ينشئ مفتاح debug جديداً كلما أُعيد إنشاء بيئته، فتتغيّر البصمة. وملف `google-services.json` يحمل **بصمة واحدة فقط** (`c4bfce96…5ba4`). كل بناء ببصمة أخرى يفشل (خطأ Google 10 أو «internal-error»).
2. **إضافة google-services غير مفعّلة** في Gradle أصلاً: لم يكن `google-services.json` يُعالَج، فلا يُولَّد `default_web_client_id`، وهو لازم للحصول على idToken.
3. **المسار القديم** `signInWithProvider` يفتح متصفحاً وسيطاً ويُخفي سبب الفشل، وكان أي خطأ منصة يظهر للمستخدم «لا يوجد اتصال».

## الحل الذي طُبِّق
| التغيير | الأثر |
|---|---|
| مفتاح تطوير ثابت `android/app/yabaladi-dev.jks` تُوقَّع به كل بنايات debug | بصمة واحدة دائماً في FlutLab والجهاز المحلي |
| تفعيل إضافة `com.google.gms.google-services` | معالجة `google-services.json` وتوليد معرّف الويب |
| تسجيل Google بالمسار الأصلي `google_sign_in` + `serverClientId` صريح | اختيار الحساب مباشرة، وأخطاء واضحة |
| رسائل خطأ مفسَّرة (كود 10، 12500، شبكة) | تعرف السبب فوراً من الشاشة |

## بصمات مفتاح التطوير الجديد (سجّلها في Firebase)
- **SHA-1:** `C3:75:D4:A2:E1:0F:28:06:A8:DB:FD:09:06:0F:F0:46:BA:3B:21:37`
- **SHA-256:** `0D:EC:8A:E3:17:26:B3:48:E4:FC:69:93:71:C0:88:5A:5B:34:5F:C9:22:9B:27:D1:43:CC:12:1D:E4:EB:57:9A`

## الخطوات (بالترتيب، لا تتخطَّ شيئاً)
1. انسخ ملفات الحزمة فوق المشروع. **الملف `yabaladi-dev.jks` ثنائي:** في FlutLab ارفعه إلى `android/app/` بالرفع المباشر (ليس لصقاً نصياً).
2. Firebase Console ← إعدادات المشروع ← تطبيقك Android (`com.egypt.yabaladi_rebuild`) ← **Add fingerprint**: أضف SHA-1 ثم SHA-256 أعلاه.
3. نزّل **google-services.json الجديد** من الصفحة نفسها واستبدل به `android/app/google-services.json` و`android/app/src/google-services.json`. تأكد أنه صار فيه `oauth_client` بالبصمة الجديدة.
4. Authentication ← Sign-in method ← **Google مُفعَّل** ومعه «بريد دعم المشروع».
5. Google Cloud Console ← APIs & Services ← OAuth consent screen: إن كانت الحالة **Testing** فأضف بريدك كمستخدم اختبار، أو انقلها **In production**. وإلا ترفض Google الدخول لغير المضافين (خطأ 12500/access_denied).
6. **اعمل `flutter clean` ثم ابنِ، وأزل التطبيق القديم من الهاتف قبل التثبيت** (توقيع مختلف يمنع التحديث فوقه).
7. جرّب. إن ظهر رسالة، فهي تحدد السبب: «كود 10» = البصمة لم تُسجَّل أو ملف json قديم؛ «12500» = بند 4 أو 5.

## عند النشر على Google Play (لاحقاً)
أضف أيضاً: (أ) بصمة مفتاح الرفع (release) الذي تنشئه بـ keytool، و(ب) **بصمة «App signing key» من Play Console ← Setup ← App signing**. بدون (ب) يفشل تسجيل Google عند المستخدمين رغم نجاحه عندك. ثم نزّل json جديداً.

## تنبيهات
- كلمة مرور مفتاح التطوير معلومة (`yabaladi_dev`) ومناسبة للتطوير فقط؛ **لا يُنشر به أبداً**. مفتاح الإصدار يُنشأ عندك سراً (انظر الجولة 2).
- البصمة القديمة `c4bfce96…` تبقى مسجّلة ولا ضرر منها؛ احذفها إن شئت.
- **لم يُجرَّب شيء هنا** (لا Flutter ولا جهاز عندي). إن فشل البناء بعد تفعيل إضافة google-services، أرسل لي نص الخطأ.
- إن بقيت المشكلة بعد الخطوات: شغّل `adb logcat | findstr /i "ApiException GoogleSignIn"` وأرسل الناتج.
