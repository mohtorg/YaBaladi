# تسليم حالة الجلسة — Ya Baladi (`yabaladi_rebuild`)

> **الغرض من هذا الملف:** حفظ سياق العمل بين **جهاز العمل** و**جهاز المنزل** عبر GitHub، بحيث يقرأه Antigravity في بداية كل جلسة على أي جهاز ويكمل العمل مباشرةً دون إعادة شرح.

---

## 1. بيانات المشروع والربط
- **الاسم:** `yabaladi_rebuild` (Ya Baladi - Local Discovery Platform for Port Said, Egypt)
- **الإصدار في `pubspec.yaml`:** `1.0.0+6` (SDK `>=3.0.0 <4.0.0`، Flutter `>=3.27.0`)
- **مستودع GitHub:** `https://github.com/mohtorg/YaBaladi.git`
- **الفرع المعتمد للتناوب اليومي:** `main`

---

## 2. حالة الجلسة الحالية (آخر تحديث: 2026-11-26)
- **آخر Commit للتعديلات البرمجية:** `3885e17` على فرع `main`
  - إضافة خدمة التحقق من QR للمكان (`lib/core/services/qr_verification_service.dart`) واختبارها (`test/qr_verification_test.dart`).
  - تحديث مسارات التطبيق (`lib/core/router/app_router.dart`)، وشاشة تفاصيل المكان، وتدفق التقييم والزيارات والمراجعات، ولوحة الإدارة، والمستودعات (`places_repository.dart`, `reviews_repository.dart`).
  - تحديث `pubspec.lock` و`.flutter-plugins-dependencies` و`macos/Flutter/GeneratedPluginRegistrant.swift`.
- **حالة التزامن:** مرفوع على `origin/main` ومطابق بين جهاز العمل وGitHub.

---

## 3. الخطوة القادمة (Next Steps)
- *(حدّث هذا القسم عند نهاية كل جلسة عمل بالمهمة المطلوب استكمالها في الجلسة التالية).*
- تجهيز نسخة جهاز المنزل (فك النسخة الأولية النظيفة أو الاستنساخ + `flutter pub get`) والتحقق من سحب `main` بنجاح.
- استكمال العمل والاختبار على ميزات التقييم والتحقق عبر QR أو أي مهام جديدة يحددها المستخدم.

---

## 4. روتين العمل اليومي بين جهاز العمل وجهاز المنزل

### عند بدء الجلسة على أي جهاز:
```powershell
git checkout main
git pull origin main
flutter pub get
```
ثم افتح المشروع في **Antigravity** واطلب:
> *"اقرأ ملف `HANDOFF.md` لنكمل العمل من حيث توقفنا."*

### عند إنهاء الجلسة (وقبل انتهاء الرصيد المتاح):
اطلب من **Antigravity**:
> *"حدّث `HANDOFF.md` وارفعه مع التعديلات إلى `main` على GitHub."*

---

## 5. ملفات محلية مستبعدة من Git (تُنقل لمرة واحدة عند تأسيس الجهاز الجديد)
هذه الملفات موجودة محلياً على جهاز العمل ومستبعدة من التتبع في Git، لذا لا تصل تلقائياً مع `git pull`:
- `android/app/yabaladi-dev.jks` (مفتاح التوقيع المحلي لنسخة التطوير)
- `seed_node/serviceAccountKey.json` (مطلوب فقط عند تشغيل سكريبتات `seed_node`)
- `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar` (غير متتبعة حالياً في Git؛ تأكد من وجودها على الجهاز الجديد لبناء Android)

> **تنبيه:** لا ترفع أي مفاتيح خاصة أو ملفات `.jks` أو `serviceAccountKey.json` إلى GitHub.
