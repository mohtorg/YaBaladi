# دليل تجهيز جهاز المنزل بالكامل عبر موجه الأوامر (CMD)

> **ملاحظة:** جميع الأوامر أدناه مخصصة للتنفيذ في **Command Prompt (CMD)** على نظام **Windows 10 / 11**، وبافتراض أن جهاز المنزل غير مجهّز نهائياً للمشروع.
> - بعد تثبيت أي أداة جديدة (مثل Git أو Flutter أو Node.js)، **أغلق نافذة CMD وافتح نافذة جديدة** حتى تتحدث متغيرات البيئة (`PATH`).

---

## 1. تثبيت الأدوات الأساسية (Git و Node.js و GitHub CLI و Android Studio)

```cmd
winget install --id Git.Git -e --source winget
winget install --id OpenJS.NodeJS.LTS -e --source winget
winget install --id GitHub.cli -e --source winget
winget install --id Google.AndroidStudio -e --source winget
```

> **ملاحظة:** برنامج **Antigravity IDE** يُثبّت من الموقع الرسمي ثم تُسجّل الدخول فيه بنفس حسابك.

---

## 2. تثبيت Flutter SDK وإضافته إلى PATH

### أ) تحميل Flutter SDK في `C:\src\flutter`
*(افتح نافذة CMD جديدة بعد تثبيت Git)*:

```cmd
mkdir C:\src
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
```

### ب) إضافة Flutter إلى مسار المستخدم (`PATH`) بأمان
```cmd
powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('Path','User'); if ($p -notlike '*C:\src\flutter\bin*') { [Environment]::SetEnvironmentVariable('Path', ($p.TrimEnd(';') + ';C:\src\flutter\bin'), 'User') }"
```

> **مهم:** أغلق نافذة CMD وافتح نافذة جديدة ثم تحقق من التثبيت:

```cmd
flutter --version
git --version
node -v
```

---

## 3. استكمال إعداد Android Studio ورخص Android SDK

1. افتح **Android Studio** للمرة الأولى واتركه يحمّل **Android SDK** و **Android SDK Platform-Tools** و **Android SDK Build-Tools**.
2. من داخل Android Studio: افتح `Settings > Languages & Frameworks > Android SDK > SDK Tools` وتأكد من تفعيل **Android SDK Command-line Tools (latest)**.
3. من نافذة **CMD** وافق على الرخص وتحقق من جاهزية البيئة:

```cmd
flutter doctor --android-licenses
flutter doctor -v
```

---

## 4. فك ضغط نسخة المشروع النظيفة في نفس المسار (`C:\ya_baladi_rebuild`)

> افترض أنك نقلت الملف المضغوط `ya_baladi_clean.zip` إلى سطح المكتب (`%USERPROFILE%\Desktop\ya_baladi_clean.zip`).

```cmd
tar -xf "%USERPROFILE%\Desktop\ya_baladi_clean.zip" -C C:\
dir C:\ya_baladi_rebuild
```

*(إذا طُلبت صلاحيات للكتابة مباشرة في `C:\`، شغّل CMD كمسؤول Run as administrator، أو فك الضغط في مسار آخر مثل `%USERPROFILE%\Projects` وعدّل المسار في باقي الأوامر).*

---

## 5. إعداد Git والربط مع GitHub

### أ) تعريف الاسم والبريد في Git
```cmd
git config --global user.name "Mohseen El torgoman"
git config --global user.email "mohtorg1971@gmail.com"
```

### ب) تسجيل الدخول إلى GitHub
```cmd
gh auth login
```
*(اختر: `GitHub.com` ← `HTTPS` ← `Yes` ← `Login with a web browser` واتبع الخطوات).*

### ج) التحقق من الربط وسحب آخر تحديثات `main`
```cmd
cd /d C:\ya_baladi_rebuild
git remote -v
git checkout main
git pull origin main
git status
```

---

## 6. تهيئة المشروع على جهاز المنزل وتشغيل الفحص والاختبار

```cmd
cd /d C:\ya_baladi_rebuild
flutter pub get
flutter analyze
flutter test test\qr_verification_test.dart
```

---

## 7. (اختياري) تجهيز أدوات Firebase و Node.js
*(تحتاجها فقط إذا كنت ستنشر قواعد Firestore/Storage أو تشغّل اختبارات القواعد أو سكريبتات `seed_node` من جهاز المنزل)*:

```cmd
npm install -g firebase-tools
firebase login
cd /d C:\ya_baladi_rebuild\seed_node && npm install
cd /d C:\ya_baladi_rebuild\firebase_rules_tests && npm install
```

---

## 8. بدء العمل مع Antigravity على جهاز المنزل
1. افتح مجلد المشروع `C:\ya_baladi_rebuild` في **Antigravity**.
2. في بداية المحادثة اطلب منه:
   > *"اقرأ ملف `HANDOFF.md` لنكمل العمل من آخر نقطة توقفنا عندها."*

---

## 9. أوامر التناوب اليومي السريع (منزل ⇄ عمل)

### عند بدء الجلسة في أي جهاز:
```cmd
cd /d C:\ya_baladi_rebuild && git checkout main && git pull origin main && flutter pub get
```

### عند إنهاء الجلسة (قبل المغادرة أو انتهاء الرصيد):
```cmd
cd /d C:\ya_baladi_rebuild && git status && git add -A && git commit -m "Update session work" && git push origin main
```
