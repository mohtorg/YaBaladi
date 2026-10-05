# Ya Baladi — RESUME (للمحادثة الجديدة)

## 🎯 انسخ هذا في DeepSeek:

مشروع: يا بلدي (Ya Baladi)
GitHub: https://github.com/mohtorg/YaBaladi
آخر tag: v0.2.2-g2.2-design
آخر commit: 403395a
المرحلة الحالية: G2.3 Navigation (يبدأ)
Codespace: glowing waffle

## 📊 سياق سريع

- Flutter 3.47.6 + Dart 3.13.5
- Firebase project: ya-baladi
- Cairo font + Design System مكتمل
- Localization AR/EN + RTL/LTR مكتمل
- Language + Theme Pickers مكتملة
- Settings Screen مكتمل
- Main Shell 4 tabs
- APK v0.2.2-g2.2-design على GitHub

## 🎯 المطلوب في G2.3

1. إضافة go_router: ^14.6.2
2. إنشاء lib/navigation/app_routes.dart
3. إنشاء lib/navigation/app_router.dart
4. تحديث main.dart (MaterialApp.router)
5. تحديث main_shell.dart (ShellRoute + BottomNav)
6. flutter analyze = 0
7. flutter build apk --debug
8. Commit + Tag v0.2.3-g2.3-navigation

## 🔑 أوامر البدء

```bash
# افتح Codespaces: glowing waffle
cd /workspaces/YaBaladi
git pull origin main
flutter pub get
flutter analyze
cat SESSION_STATE.md
القواعد الحاكمة
لا تعديل بدون نقطة رجوع

flutter analyze = 0 قبل كل commit

dائمًا flutter clean قبل flutter build apk

لا ترفع حزم بدون سبب

لا تعمل push قسري

**`Ctrl + S`**

**ثم:**

```bash
git add RESUME.md
git commit -m "docs: add RESUME file for new chat sessions"
git push origin main
