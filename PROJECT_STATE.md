# حالة مشروع يا بلادي — Project State

**آخر تحديث:** 2026-10-03
**المرحلة:** G2.2 — مكتمل تقنيًا
**آخر tag:** `v0.2.1-g2.1-localization`

---

## 🎯 حالة البوابات

| Gate | الحالة | التاريخ |
|---|---|---|
| G0 — Baseline | ✅ | 2026-10-01 |
| G1 — Build Foundation | ✅ | 2026-10-02 |
| G2.1 — Localization | ✅ | 2026-10-02 |
| G2.2 — Design System | ✅ تقنيًا | 2026-10-03 |
| G2.3 — Navigation | ⏳ | — |
| G3 — Discovery | ⏳ | — |
| G4 — Security | ⏳ | — |
| G5 — Admin | ⏳ | — |
| G6 — Product | ⏳ | — |
| G7 — Release | ⏳ | — |

---

## ✅ ما تم إنجازه

### G0 (Baseline)
- مشروع Clean Rebuild
- Git مُهيأ
- GitHub repo: `mohtorg/YaBaladi`
- Tag `v0.0.1-baseline`

### G1 (Build Foundation)
- Flutter 3.47.6 على Codespaces
- Android SDK 36.0.0
- APK Debug (120s)
- أيقونة رسمية (1254×1254)
- Firebase + Firestore Rules احترافية
- Collections: places, users, visit_requests, visits, ratings, coupons, cities
- Release على GitHub
- Tag `v0.1.1-g1-complete`

### G2.1 (Localization)
- `flutter_localizations` + `intl`
- `l10n.yaml` + ARB files
- `main.dart` + `home_screen.dart` محدَّثان
- Tag `v0.2.1-g2.1-localization`

### G2.2 (Design System)
- Design Tokens (Semantic + Dark)
- Cairo font (4 ملفات)
- Theme (Light + Dark)
- `LocaleController` + `ThemeController` (SharedPreferences)
- Language Picker Dialog + Theme Picker Dialog
- Settings Screen (4 أقسام)
- Main Shell (4 tabs)
- Android label = "يا بلدي"
- `flutter analyze = 0`

---

## 🚧 المشاكل المفتوحة

| المشكلة | الأولوية | الإجراء |
|---|---|---|
| `app_strings.dart` (قديم) | 🟢 | يُحذف بعد G2.3 |
| `locale_controller.dart` (قديم) | 🟢 | يُحذف بعد G2.3 |
| اختبارات Unit | 🟡 | G7 |
| Accessibility | 🟡 | G7 |
| Package name `_rebuild` | 🟠 | بعد G2 |

---

## 📊 الإحصائيات

| العنصر | العدد |
|---|---|
| Commits | 15+ |
| Tags | 5 |
| ملفات Dart | 25+ |
| ARB keys | ~100 |
| Screens | 4 |
| Widgets | 2 |
| Controllers | 2 |

---

## 🎯 الخطوة التالية

1. `flutter build apk --debug`
2. اختبار على الموبايل
3. Commit + Tag `v0.2.2-g2.2-design`
4. بدء G2.3 Navigation (go_router)

---

## 🔑 نقاط حرجة

- **بيئة البناء الرسمية:** GitHub Codespaces (`glowing waffle`)
- **الفرع:** `main`
- **مرجع الحقيقة:** الكود + الاختبار + GitHub
- **قاعدة ذهبية:** لا نعدّل شيئًا حساسًا بدون نقطة رجوع

---

**نهاية حالة المشروع — الإصدار 1.0**