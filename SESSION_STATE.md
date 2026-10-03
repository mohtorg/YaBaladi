# Ya Baladi — Session State

**آخر تحديث:** 2026-10-03
**آخر commit:** `[hash]` (سيُملأ بعد commit G2.2)
**آخر tag:** `v0.2.1-g2.1-localization`

---

## 🎯 المرحلة الحالية

| البوابة | الحالة |
|---|---|
| **G0** Baseline | ✅ مكتمل |
| **G1** Build Foundation | ✅ مكتمل |
| **G2.1** Localization | ✅ مكتمل |
| **G2.2** Design System | 🟡 95% مكتمل |
| **G2.3** Navigation | ⏳ التالي |
| **G3** Discovery | ⏳ |
| **G4** Security | ⏳ |
| **G5** Admin | ⏳ |
| **G6** Product | ⏳ |
| **G7** Release | ⏳ |

---

## 📊 البيئات

| البيئة | المسار | الدور |
|---|---|---|
| **Primary** | GitHub Codespaces (`glowing waffle`) | بناء + تطوير |
| **Secondary** | WORK (`C:\ya_baladi_rebuild`) | احتياطي |
| **Reference** | HOME (`D:\ya_baladi_rebuild`) | تصميم/توثيق |

**GitHub:** `https://github.com/mohtorg/YaBaladi`

---

## ✅ ما تم في G2.2 (Design System)

### الملفات المُنشأة/المُحدَّثة
lib/theme/
├── design_tokens.dart (Semantic + Dark mode)
├── app_typography.dart (Body + Label + Display)
└── app_theme.dart (Light + Dark + Cairo)

lib/l10n/
├── locale_controller.dart (SharedPreferences)
├── theme_controller.dart (SharedPreferences)
├── app_ar.arb (~100 مفتاح)
└── app_en.arb (~100 مفتاح)

lib/widgets/
├── language_picker_dialog.dart
└── theme_picker_dialog.dart

lib/screens/
├── settings_screen.dart (4 أقسام)
└── main_shell.dart (4 tabs)

lib/main.dart (StatefulWidget)

assets/fonts/
├── Cairo-Regular.ttf
├── Cairo-Medium.ttf
├── Cairo-SemiBold.ttf
└── Cairo-Bold.ttf

### الميزات
- ✅ Cairo font في كل التطبيق
- ✅ Design Tokens مركزية (لا ألوان عشوائية)
- ✅ Light + Dark themes
- ✅ Language Picker Dialog (AR/EN)
- ✅ Theme Picker Dialog (System/Light/Dark)
- ✅ حفظ الاختيارات (SharedPreferences)
- ✅ Settings Screen احترافي
- ✅ RTL/LTR يعمل
- ✅ `flutter analyze = 0 issues`

---

## 🚧 المشاكل المفتوحة

- 🟡 `app_strings.dart` و `locale_controller.dart` القديمان (يجب حذفهما)
- 🟡 اختبارات Unit مفقودة (مؤجلة لـG7)
- 🟡 Accessibility لم يُختبر (مؤجل لـG7)

---

## 🎯 الخطوة التالية الفورية

1. `flutter build apk --debug`
2. اختبار على الموبايل
3. `git commit + push`
4. `git tag v0.2.2-g2.2-design`
5. بدء G2.3 Navigation

---

## 📋 الخطوات التالية (G2.3)

- إضافة `go_router`
- `app_router.dart`
- Bottom Nav → Routes
- Back behavior
- اختبار التنقل

---

## 🔑 مفاتيح التشغيل السريع

```bash
# في Codespaces
cd /workspaces/YaBaladi
git pull origin main
flutter pub get
flutter analyze
flutter build apk --debug

5. **`Ctrl + S`**

---

## 🚦 المهمة 2: تحديث سجل الخبرة (10 دقائق)

### 📍 المسار
docs/experience_log.md (ملف جديد)


**أو:**
سجل_خبرة_يا_بلدي.md (إذا موجود في الجذر)


### 📝 الكود الكامل

**أنشئ الملف `docs/experience_log.md`:**

```markdown
# سجل خبرة يا بلدي — Experience Log

> كل تجربة مهمة تُسجَّل هنا. القاعدة الذهبية: لا نبدأ من الصفر.

---

## EXP-2026-10-01-001 — مشكلة `C:\ya_baladi`

**المشكلة:** `flutter build apk` يفشل بـ `Directory 'C:\ya_baladi' does not contain a Gradle build` على HOME.

**الأعراض:**
- Gradle يبحث عن مشروع في مسار قديم.
- لا يحل حتى بعد حذف Gradle cache.

**الفحص:**
- `flutter doctor` — كل شيء سليم.
- `.gitignore` — سليم.
- `android/local.properties` — سليم.

**السبب المثبت:**
- ملف `Microsoft.PowerShell_profile.ps1` على HOME يحتوي `Set-Location C:\ya_baladi`.
- عند كل جلسة PowerShell، يبحث عن المشروع القديم.

**الإجراء:**
- تعطيل السطر في PowerShell Profile.
- الملف: `C:\Users\<user>\OneDrive\...\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`.

**النتيجة:** ✅ حُلّت — `flutter build apk` يعمل.

**ما يجب تجنبه:**
- لا نضع `Set-Location` لمسار قديم في PowerShell Profile.
- عند تغيير مسار المشروع، حدّث كل الإشارات إليه.

---

## EXP-2026-10-02-002 — GitHub Codespaces = بيئة البناء المثالية

**المشكلة:** HOME (1.8 GB RAM) بطيء جدًا في البناء (45+ دقيقة).

**الحل المكتشف:**
- **GitHub Codespaces** (8 GB RAM, 2-core).
- وقت البناء: **120–370 ثانية**.
- 5 tags رسمية على GitHub.

**الإجراء:**
- اعتماد Codespaces كبيئة البناء الرسمية.
- HOME/WORK للتصميم/التوثيق فقط.

**النتيجة:** ✅ توفير 40 دقيقة لكل بناء.

**ما يجب تجنبه:**
- لا نستخدم HOME للبناء (RAM منخفضة).
- لا نستخدم WORK كبيئة أساسية.

---

## EXP-2026-10-02-003 — `git reset --soft HEAD~N` خطير

**المشكلة:** `git reset --soft HEAD~2` على HOME أزال 5 commits (بدل 2).

**الأعراض:**
- HEAD انتقل لـ`c1a9b42` بدل `30c3ad1`.
- المخاطرة: فقدان commits مهمة.

**السبب:**
- HOME كان متأخرًا عن origin بـ3 commits.
- `HEAD~2` يشير لـcommit مختلف عن المتوقع.

**الإجراء:**
- `git reset --hard HEAD` — العودة لآخر commit.
- `git pull origin main` — fast-forward.
- استعادة كل commits من GitHub.

**النتيجة:** ✅ لم يُفقد شيء — كل شيء آمن على GitHub.

**ما يجب تجنبه:**
- قبل أي `reset`، تأكد: `git status` + `git log --oneline -5`.
- لا تستخدم `reset --soft HEAD~N` بدون التأكد.
- دائمًا `git pull` أولًا، ثم `reset`.

---

## EXP-2026-10-02-004 — Flutter SDK في Codespaces

**المشكلة:** `flutter: command not found` في Codespaces.

**السبب:**
- Codespace جديد لم يُهيَّأ Flutter.
- PATH لا يحتوي `flutter/bin`.

**الإجراء:**
```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
export PATH="$PATH:$HOME/flutter/bin"
flutter config --android-sdk /home/codespace/android-sdk
النتيجة: ✅ Flutter يعمل في 10 ثوان.

ما يجب تجنبه:

لا نفتح Codespace جديد بدون تثبيت Flutter.

احفظ ~/.bashrc دائمًا.