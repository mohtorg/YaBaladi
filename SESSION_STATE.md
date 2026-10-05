# Ya Baladi — Session State

**آخر تحديث:** 2026-10-03
**آخر commit:** `403395a`
**آخر tag:** `v0.2.2-g2.2-design`

---

## 🎯 المرحلة الحالية

| البوابة | الحالة |
|---|---|
| **G0** Baseline | ✅ مكتمل |
| **G1** Build Foundation | ✅ مكتمل |
| **G2.1** Localization | ✅ مكتمل |
| **G2.2** Design System | ✅ مكتمل (`v0.2.2-g2.2-design`) |
| **G2.3** Navigation | 🟡 التالي |
| **G3** Discovery | ⏳ |
| **G4** Security | ⏳ |
| **G5** Admin | ⏳ |
| **G6** Product | ⏳ |
| **G7** Release | ⏳ |

---

## 📊 البيئات

| البيئة | المسار | الدور |
|---|---|---|
| **Primary** | Codespaces (`glowing waffle`) | بناء + تطوير |
| **Secondary** | WORK (`C:\ya_baladi_rebuild`) | احتياطي |
| **Reference** | HOME (`D:\ya_baladi_rebuild`) | تصميم/توثيق |

**GitHub:** `https://github.com/mohtorg/YaBaladi`
**Releases:** `https://github.com/mohtorg/YaBaladi/releases`

---

## ✅ ما تم في G2.2

### ملفات جديدة
- `lib/theme/app_theme.dart`
- `lib/l10n/theme_controller.dart`
- `lib/widgets/language_picker_dialog.dart`
- `lib/widgets/theme_picker_dialog.dart`
- `lib/screens/settings_screen.dart`
- `assets/fonts/Cairo-{Regular,Medium,SemiBold,Bold}.ttf`

### ملفات محدَّثة
- `pubspec.yaml` (shared_preferences + Cairo + go_router later)
- `lib/theme/design_tokens.dart`
- `lib/theme/app_typography.dart`
- `lib/l10n/locale_controller.dart`
- `lib/l10n/app_ar.arb` (~100 مفتاح)
- `lib/l10n/app_en.arb`
- `lib/screens/main_shell.dart` (4 tabs)
- `lib/main.dart` (StatefulWidget + Controllers)
- `android/gradle.properties` (Xmx=2048m, Metaspace=768m)
- `test/bottom_navigation_test.dart`

### ملفات حوكمة (في الجذر)
- `SESSION_STATE.md`
- `EXPERIENCE_LOG.md`
- `PROJECT_STATE.md`
- `COMPLIANCE_MATRIX.md`

### APK
- `app-debug.apk` (161 MB) على GitHub Release `v0.2.2-g2.2-design`

---

## 📋 Tags الرسمية (6)
backup-before-encoding-20260924
v0.0.1-baseline
v0.1.0-g1-pass
v0.1.1-g1-complete
v0.2.0-g2.1-localization
v0.2.2-g2.2-design ← آخر tag

---

## 🚧 المشاكل المفتوحة

- 🟡 `locale_controller.dart` القديم (تم استبداله — لا يزال موجودًا)
- 🟡 اختبارات Unit (مؤجلة لـG7)
- 🟡 Accessibility (مؤجل لـG7)
- 🟠 Package name `_rebuild` (يُوحَّد بعد G2)

---

## 🎯 الخطوة التالية — G2.3 Navigation

1. إضافة `go_router: ^14.6.2` إلى `pubspec.yaml`
2. إنشاء `lib/navigation/app_routes.dart`
3. إنشاء `lib/navigation/app_router.dart`
4. تحديث `main.dart` (MaterialApp.router)
5. تحديث `main_shell.dart` (ShellRoute + BottomNav)
6. `flutter analyze`
7. `flutter build apk --debug`
8. Commit + Tag `v0.2.3-g2.3-navigation`

---

## 🔑 أوامر البدء السريع

```bash
# في Codespaces
cd /workspaces/YaBaladi
git pull origin main
flutter pub get
flutter analyze
الوثائق المرجعية
في المشروع (GitHub):

SESSION_STATE.md ← هذا الملف

EXPERIENCE_LOG.md

PROJECT_STATE.md

COMPLIANCE_MATRIX.md

MVP.md

في HOME:

D:\Ya_Baladi\ — كل الوثائق

D:\YA_BALADI_BACKUPS\ — النسخ الاحتياطية


**احفظ.**

---

### الخطوة 2: Commit + Push

```bash
cd /workspaces/YaBaladi
git add SESSION_STATE.md
git commit -m "docs: update session state at end of G2.2"
git push origin main
git log --oneline -3

## إضافة 2026-10-04

### Documentation Release
- ✅ docs/YA_BALADI_MASTER_PLAN_v1.0.md
- ✅ docs/YA_BALADI_ROADMAP_40_DAYS.md
- ✅ docs/YA_BALADI_GUARDRAILS.md
- ✅ Tag v0.2.5.2-docs-master-plan
- ✅ GitHub Release published

## إضافة 2026-10-04 (مساءً)

### FCM Background Handler Fix
- ✅ lib/main.dart: أضفت _firebaseMessagingBackgroundHandler
- ✅ Firebase.initializeApp() جوه الـ handler
- ✅ FirebaseMessaging.onBackgroundMessage() في main()
- ✅ حل مشكلة [core/no-app] No Firebase App
- ✅ حل مشكلة Gradle journal lock (PID عالقة)

### معلّق للجلسة القادمة
- ⏳ تثبيت GitHub CLI (gh) — فشل winget بخطأ 1603
  → الحل: تنزيل gh_2.102.0_windows_amd64.msi يدويًا
  → رابط: https://github.com/cli/cli/releases/latest
- ⏳ إنشاء Release على GitHub لـ v0.2.5.2-docs-master-plan
  → الأمر: gh release create v0.2.5.2-docs-master-plan --repo mohtorg/YaBaladi --title "v0.2.5.2 - Master Plan & Roadmap" --notes-file notes.md
  → بديل: من المتصفح https://github.com/mohtorg/YaBaladi/releases/new
- ⏳ اختبار FCM background notification على الجهاز

### نقاط مهمة
- Tag v0.2.5.2-docs-master-plan مثبّت على commit 43fe895 ✅
- ملفات docs (3 ملفات) مرفوعة على main ✅
- التطبيق يبني ويشتغل بدون أخطاء Gradle ✅

## إضافة 2026-10-04 (ليلاً)

### G2.5 — مكتمل ✅
- 4 models: Category, Place, Review, Favorite
- 4 repositories: Categories, Places, Reviews, Favorites
- 2 controllers: Categories, Places
- Tag: v0.2.5-g2.5-models

### G2.6 — جزء 1 (Seed) مكتمل ✅
- lib/services/seed_service.dart
- lib/main_seed.dart
- seed.sh (REST API)
- زرع 21 doc في Firestore (9 categories + 12 places)
- Firestore rules محدّثة (categories, favorites, reviews)

### الحالة الحالية
- الـ APK: build/app/outputs/flutter-apk/app-release.apk (56.2 MB)
- Rules: النسخة الدائمة (isAdmin)
- Firestore: 9 categories + 12 places

### معلّق للجلسة القادمة — G2.6 جزء 2
- ⏳ تحديث home_screen.dart — Grid 3×3 للتصنيفات
- ⏳ إضافة route جديد /category/:id
- ⏳ PlacesListScreen لعرض أماكن كل تصنيف
- ⏳ تسجيل CategoriesController في main.dart Provider

### ملفات محتاج أشوفها في الجلسة القادمة
- lib/screens/home_screen.dart (الحالي)
- lib/core/router/route_names.dart
- lib/core/router/route_paths.dart
- lib/core/router/app_router.dart
- lib/main.dart (لتسجيل Provider)

### ملاحظة عن Codespaces
- flutter SDK في: /workspaces/flutter-sdk/flutter/bin
- لو Codespace اتعمله restart، تأكد من:
  flutter --version
  cd /workspaces/YaBaladi && git pull origin main

  ## إضافة 2026-10-05 (ليلاً)

### G2.6 — Category Grid + Places List ✅
- main.dart: CategoriesController + PlacesController في Provider
- route_paths/names: /category/:id
- app_router: PlacesListScreen route
- home_screen: Grid 3×3 للتصنيفات من Firestore
- places_list_screen: قائمة أماكن التصنيف

### Line-up الحالي
- G2.5 ✅ v0.2.5-g2.5-models
- G2.6 ✅ v0.2.6-g2.6-category-grid
- Guest Mode Stage 1 ✅ 04e34b0

### الخطوة القادمة (Stage 2 + Place Details)
- حماية profile/favorites للزوار
- Place Details Screen (G3.3)
- Search يعرض التصنيفات + الأماكن
