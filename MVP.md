# Ya Baladi MVP v1.0
## النطاق: 25 شاشة، 3 أدوار، 6 أسابيع

**التاريخ:** 2026-10-02
**الهدف:** إطلاق MVP لـ«يا بلادي» — منصة اكتشاف محلية
**الحالة:** معتمد — جاهز للتنفيذ

---

## 1. الأدوار في MVP

| الدور | الرمز | الصلاحيات |
|---|---|---|
| **Visitor** | `visitor` | تصفح + بحث (بدون تسجيل) |
| **Member** | `member` | حساب + مفضلة + تقييمات |
| **Super Admin** | `admin` | إدارة كاملة |

### مؤجل لـPhase 2
- Merchant (عرض فقط في MVP، إدارة كاملة لاحقًا)
- Moderator
- Team Member
- Manager

---

## 2. الشاشات (25)

### Auth (4)
1. Splash
2. Login
3. Register
4. Forgot Password

### Discovery (7)
5. Home
6. Search
7. Search Results
8. Category List
9. Place Details
10. Map View
11. Nearby

### Member (5)
12. Profile
13. Edit Profile
14. Favorites
15. Settings
16. Notifications

### Admin Minimal (7)
17. Admin Dashboard
18. Users List
19. Places List
20. Merchants List
21. Place Edit
22. Merchant Approve/Reject
23. Audit Log View

### Common (2)
24. Error Screen
25. Empty State

---

## 3. Firebase Collections (MVP)

```text
users/           { uid, role, profile, createdAt }
places/          { name, category, location, images, publishedAt }
merchants/       { ownerId, status, name, verified }
ratings/         { userId, placeId, stars, text }
favorites/       { userId, placeId, createdAt }


---

## 4. معايير القبول

- ✅ APK يعمل على 3 أجهزة
- ✅ 10 أماكن حقيقية في Firestore
- ✅ 5 مستخدمين حقيقيين
- ✅ لا crash في ساعة استخدام
- ✅ البحث يعمل
- ✅ تفاصيل المكان تعمل
- ✅ Admin يضيف/يعدّل الأماكن
- ✅ RTL/LTR يعمل
- ✅ Design System متناسق
- ✅ Firebase Rules مختبرة

---

## 5. ما لا يشمله MVP

- ❌ Merchant dashboard كامل
- ❌ Offers + Rewards + QR
- ❌ Loyalty + Points
- ❌ Moderators + Team
- ❌ Reports متقدمة
- ❌ iOS
- ❌ Web Admin كامل
- ❌ AI Recommendations

### يُنفَّذ في
- **Phase 2:** Merchant + Offers + QR
- **Phase 3:** Loyalty + Rewards
- **Phase 4:** Moderation + Reports
- **Phase 5:** AI + Growth

---

## 6. الجدول الزمني

| الأسبوع | النطاق | المخرج |
|---|---|---|
| **W1** | MVP.md + Firebase + Localization | G2 (جزئي) |
| **W2** | Design System + Navigation | G2 (كامل) |
| **W3** | Auth + Discovery | G3 |
| **W4** | Admin + Polish | G4 |
| **W5** | Integration + Beta | G5 |
| **W6** | Beta Testing + MVP Release | G6 |

**البداية:** 2026-10-03 (السبت)
**النهاية المتوقعة:** 2026-11-14 (السبت)

---

## 7. Design System

### الألوان
- Navy: `#0B2D5B`
- Primary Blue: `#0D6EFD`
- Orange: `#FF8A00`
- White: `#FFFFFF`

### الخط
- **Cairo** (عربي/لاتيني)

### Heading System
- H1: 22 Bold
- H2: 18 SemiBold
- H3: 16 Medium
- H4: 13 SemiBold

### Spacing
- 4 / 8 / 16 / 24 / 32

### Radius
- 8 / 12 / 16

### Components (MVP)
- Button (Primary/Secondary/Text)
- Card (Standard/Compact)
- Chip (Filter/Status)
- Input (Text/Search/Password)
- Dialog (Confirm/Info)
- BottomSheet
- AppBar

---

## 8. Firebase Setup Required

- [ ] Firebase Project موجود
- [ ] `google-services.json` في `android/app/`
- [ ] Firestore Database مُنشأ
- [ ] Authentication: Email/Password مُفعَّل
- [ ] Firestore Rules أساسية
- [ ] `firebase_options.dart` محدَّث
- [ ] Firebase App Check (اختياري للمرحلة الأولى)

---

## 9. Git Workflow

### Tag Names
- `v0.0.1-baseline` — G0
- `v0.1.0-g1-pass` — G1 APK
- `v0.1.1-g1-complete` — G1 + Icon
- `v0.2.0-g2-complete` — G2 (قادم)
- `v1.0.0-mvp` — MVP Release (الهدف)

### Branches
- `main` — الفرع الرئيسي
- `feature/*` — للميزات (عند الحاجة)

### Commit Rules
- رسالة واضحة
- `docs:`, `fix:`, `feat:`, `chore:`
- لا push بدون اختبار

---

## 10. Build Environment

### Primary (رئيسي)
**GitHub Codespaces** (`glowing waffle`)
- 8 GB RAM, 2-core
- Flutter 3.47.6
- Android SDK 36.0.0
- Build time: ~120-370 seconds

### Secondary (احتياطي)
**WORK (Chamber-PC)**
- 4 GB RAM
- Flutter 3.47.4
- Build time: ~328 seconds

### Tertiary (تصميم/توثيق)
**HOME (mohto)**
- 1.8 GB RAM
- Flutter 3.47.2
- Build: لا يُستخدم

---

## 11. MVP Success Criteria

### MVP ناجح إذا
- ✅ 5 مستخدمين حقيقيين سجّلوا
- ✅ كل مستخدم استخدم التطبيق 10 دقائق
- ✅ لا crash رئيسي
- ✅ 10 أماكن في Firestore
- ✅ البحث يعمل
- ✅ Admin يقدر يضيف مكان

### MVP فاشل إذا
- ❌ crash عند الفتح
- ❌ البحث لا يعمل
- ❌ المستخدم لا يستطيع التسجيل
- ❌ Admin لا يعمل
- ❌ الأداء سيء

---

## 12. المراجعة الأسبوعية

**كل جمعة:**
- ما أنجزناه
- ما تعطل
- القرارات الجديدة
- تعديل الجدول القادم

---

## 13. المراجع

- `YA_BALADI_MASTER_ENGINEERING_EXECUTION_REGISTER_v3.0`
- `YA_BALADI_CLEAN_REBUILD_MASTER_EXECUTION_PLAN_v1.0`
- `YA_BALADI_MANDATORY_CODE_ENGINEERING_STANDARD`
- `YA_BALADI_SCREEN_PERMISSION_NAVIGATION_FUNCTION_REGISTRY`

---

## 14. سجل التحديث

| الإصدار | التاريخ | التغيير |
|---|---|---|
| 1.0 | 2026-10-02 | إنشاء وثيقة MVP |

**نهاية وثيقة MVP**

**الخطوة التالية:** Firebase Setup → G2 Localization
