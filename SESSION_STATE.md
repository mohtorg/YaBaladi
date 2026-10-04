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
