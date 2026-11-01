الصق هذا المحتوى:

markdown
# 📘 وثيقة يا بلدي الجامعة الشاملة
## Ya Baladi — Master Comprehensive Technical Plan v1.0

**تاريخ الإصدار:** 2026-10-04
**المرجع:** تجميع وتحليل 25 وثيقة حاكمة
**الحالة:** معتمدة كمرجع تقني موحد
**الفلسفة:** *بناء تدريجي، توسع بلا إعادة بناء*

---

## 📑 الفهرس التنفيذي

| الفصل | المحتوى |
|---|---|
| 1 | الملخص التنفيذي والرؤية |
| 2 | معمارية المشروع والأساس التقني |
| 3 | خارطة الطريق (G0 → G7) |
| 4 | الخطة الزمنية التفصيلية (يوم/ساعة) |
| 5 | القواعد الحاكمة والمحاذير |
| 6 | منظومة الجودة والأمان |
| 7 | منظومة الصلاحيات والأدوار |
| 8 | خطة التوسع المستقبلي |
| 9 | مصفوفة المخاطر والقرارات |
| 10 | قوائم التحقق والإغلاق |

---

## الفصل الأول — الملخص التنفيذي والرؤية

### 1.1 الرؤية

**يا بلدي** منصة اكتشاف محلية مصرية تربط:
- **المستخدمين** (عضو / زائر) بالأماكن والخدمات
- **مقدمي الخدمة** (تجار) بالجمهور المستهدف
- **فريق يا بلدي** بأدوات إدارة المحتوى والجودة
- **الإدارة** بلوحات تحكم وتقارير

**المبدأ الحاكم:** بناء تدريجي على بوابات (Gates) — لا نبدأ بوابة قبل إغلاق السابقة.

### 1.2 النطاق في MVP (25 شاشة / 3 أدوار أساسية)

| الدور | الرمز | النطاق |
|---|---|---|
| Visitor | `visitor` | تصفح + بحث (بدون تسجيل) |
| Member | `member` | حساب + مفضلة + تقييمات |
| Super Admin | `admin` | إدارة كاملة |

**مؤجل لـ Phase 2:** Merchant Dashboard, Moderator, Team, Loyalty Core.

### 1.3 المخرج النهائي لـ MVP

- APK يعمل على 3 أجهزة ✅
- 10 أماكن حقيقية في Firestore ✅
- 5 مستخدمين حقيقيين مسجلين ✅
- لا crash في ساعة استخدام ✅
- البحث يعمل + تفاصيل المكان ✅
- Admin يضيف/يعدّل الأماكن ✅
- RTL/LTR + Design System ✅
- Firebase Rules مختبرة ✅

---

## الفصل الثاني — معمارية المشروع والأساس التقني

### 2.1 المكدس التقني (Tech Stack)

| الطبقة | التقنية | الإصدار |
|---|---|---|
| Framework | Flutter | 3.47.x |
| Language | Dart | 3.13.x |
| Backend | Firebase | — |
| Auth | firebase_auth | 5.3.x |
| Database | cloud_firestore | 5.4.x |
| Core | firebase_core | 3.6.x |
| Navigation | go_router | 18.0.x |
| State | provider | 6.1.x |
| Storage | shared_preferences | 2.5.x |
| i18n | flutter_localizations + intl | SDK |

**قاعدة صارمة:** لا ترقية packages بدون سبب تقني موثق + نقطة رجوع.

### 2.2 البنية المعمارية
lib/
├── core/router/ ← GoRouter + Guards
├── features/ ← Feature-first
│ ├── auth/
│ ├── data/
│ │ ├── models/
│ │ └── repositories/
│ ├── categories/
│ ├── favorites/
│ └── profile/
├── l10n/ ← Localization
├── screens/ ← Shell + standalone
├── theme/ ← Design System
├── widgets/ ← Shared widgets
└── main.dart

text

### 2.3 نموذج الصلاحيات
Authentication → Role → Permission → Scope → Action

text

**قاعدة ذهبية:** `Authentication ≠ Authorization`

### 2.4 مخطط Firestore

| Collection | الغرض |
|---|---|
| `users/{uid}` | الأعضاء |
| `categories/{id}` | التصنيفات |
| `places/{id}` | الأماكن |
| `places/{id}/reviews/{rid}` | التقييمات |
| `users/{uid}/favorites/{pid}` | المفضلة |
| `merchants/{id}` | التجار (Phase 2) |
| `audit_log/{id}` | سجل التدقيق |

### 2.5 نموذج التصميم البصري

**الألوان:**
- Navy: `#0B2D5B`
- Primary Blue: `#0D6EFD`
- Orange (Accent): `#FF8A00`
- White: `#FFFFFF`

**الخط:** Cairo (4 أوزان)

**التدرج الطباعي:**
| المستوى | الحجم | الوزن | الاستخدام |
|---|---|---|---|
| H1 | 22 | Bold | عنوان الشاشة |
| H2 | 18 | SemiBold | عنوان القسم |
| H3 | 16 | Medium | عنوان البطاقة |
| H4 | 13 | SemiBold | تسمية مصغّرة |

**المسافات:** 4/8/16/24/32
**الزوايا:** 8/12/16
**أحجام اللمس:** ≥ 48dp

---

## الفصل الثالث — خارطة الطريق (G0 → G7)

| Gate | الهدف | الحالة |
|---|---|---|
| **G0** | Baseline | ✅ مكتمل |
| **G1** | Build Foundation | ✅ مكتمل |
| **G2** | Core UX | ✅ مكتمل |
| **G3** | Discovery | ⏳ التالي |
| **G4** | Roles/Security | ⏳ |
| **G5** | Admin | ⏳ |
| **G6** | Product Features | ⏳ |
| **G7** | Release Candidate | ⏳ |

### تفصيل G2 (المكتمل)

| المرحلة | المحتوى | الحالة |
|---|---|---|
| G2.1 | Localization (AR/EN + RTL) | ✅ |
| G2.2 | Design System | ✅ |
| G2.3 | Navigation (go_router) | ✅ |
| G2.3.1 | Controllers (Provider) | ✅ |
| G2.4 | Authentication | ✅ |
| G2.4-hotfix | Bug Fixes | ✅ |
| **G2.5** | **Firestore Models** | ⏳ **التالي** |
| G2.6 | Category Screens | ⏳ |

### تفصيل G3-G7

**G3 Discovery:** Search + Filters + Place Details + Map + GPS + Offline

**G4 Security:** Role Matrix + Scope + Rules + Merchant Lifecycle + Audit

**G5 Admin:** Dashboard + Users + Merchants + Places + Reports + Print

**G6 Product:** Ratings + Offers + QR + Visits + Loyalty + Rewards

**G7 Release:** Tests + A11y + Performance + Security + Release APK

---

## الفصل الرابع — الخطة الزمنية

**الفترة:** 40 يومًا (2026-10-04 → 2026-11-14)

| الأسبوع | المرحلة | الفترة |
|---|---|---|
| 1 | G2.5 Models + G2.6 Categories | 4-10 أكتوبر |
| 2 | G3 Discovery | 11-17 أكتوبر |
| 3 | G4 Security & Roles | 18-24 أكتوبر |
| 4 | G5 Admin Panel | 25-31 أكتوبر |
| 5 | G6 Product Features | 1-7 نوفمبر |
| 6 | G7 Release Candidate + MVP | 8-14 نوفمبر |

**التفاصيل اليومية الكاملة:** انظر `ROADMAP_40_DAYS.md`

---

## الفصل الخامس — القواعد الحاكمة والمحاذير

### 5.1 القواعد الذهبية (10)

1. **لا نبدأ من الصفر** — استمر من آخر نقطة مثبتة
2. **تشخيص → سبب مثبت → أقل تعديل → اختبار → تسجيل**
3. **لا تعديل حساس بدون نقطة رجوع**
4. **لا نعيد اختبار ما ثبت إلا بدليل جديد**
5. **افصل بين:** حقيقة مثبتة / نتيجة اختبار / افتراض / اقتراح
6. **تعديل واحد في التجربة الواحدة**
7. **لا ترقية packages بدون سبب تقني**
8. **Authentication ≠ Authorization**
9. **إخفاء الزر ليس حماية**
10. **الأولوية:** سلامة → استقرار → وظائف → أداء → شكل

### 5.2 قواعد Git

**قبل أي تغيير حساس:**
```bash
git status
git log --oneline -5
git tag -a vX.Y.Z-<desc> -m "..."
ممنوع بدون مراجعة:

git reset --hard

git clean -fd

git push --force

5.3 قواعد Firebase
Rules = المصدر الحقيقي للصلاحيات

لا تفترض Firebase سبب مشكلة

لا تفتح read/write للعامة

لا تحذف Rule دون اختبار

firestore.rules يدخل دورة Git

5.4 قواعد الكود
معيار:

UpperCamelCase للأنواع

lowerCamelCase للمتغيرات

lowercase_with_underscores للملفات

dart format . قبل كل commit

flutter analyze نظيف

ممنوع:

! null assertion عشوائي

dynamic بدون حاجة

منطق طويل في build()

منطق صلاحيات في UI فقط

APIs deprecated

5.5 قواعد UI/UX
الهوية:

هادئة + متوازنة

مساحات بيضاء وفيرة

البرتقالي للتأكيد فقط

عنصر بصري رئيسي واحد لكل شاشة

ممنوع:

Gradient مبالغ

Shadows قوية

نصوص < 12

أزرار < 48dp

أكثر من H1

RTL/LTR:

النصوص تتغير فعليًا

الأسهم الاتجاهية تنعكس

الأيقونات غير الاتجاهية لا تنعكس

5.6 قواعد الأدوار
الدور	الصلاحيات
Visitor	تصفح عام
Member	حساب + مفضلة + تقييمات
Merchant	نشاطه فقط
Team	مهامه
Moderator	مراجعة ضمن النطاق
Manager	إدارة الفريق
Admin	كل شيء
قاعدة صارمة:

لا تجعل Moderator = Admin

لا تجعل Member = Team

فصل Permission عن Scope

5.7 Definition of Done
text
[✓] الكود مكتوب + مراجع
[✓] flutter analyze = 0 أخطاء
[✓] اختبار الوحدة/التكامل
[✓] APK Debug ناجح
[✓] Commit مسجل + push
[✓] سجل الخبرة محدّث
[✓] نقطة رجوع محفوظة
الفصل السادس — منظومة الجودة والأمان
6.1 إطار الجودة
المعيار	التطبيق
ISO/IEC 25010:2023	جودة عامة
OWASP MASVS	أمن محمول
WCAG 2.2	A11y
Material 3	تصميم
6.2 الأهداف الداخلية
المقياس	الهدف
Cold start	≤ 2.5s
Warm start	≤ 1.5s
Frame time (60Hz)	≤ 16ms
Touch target	≥ 48dp
Text contrast	≥ 4.5:1
6.3 اختبارات الصلاحيات
الحالة	المستخدم	البيانات	العملية	النتيجة
زائر	غير مصادق	عامة	read	وفق Rule
عضو	مصادق	بياناته	read/update	ضمن النطاق
تاجر	مصادق	نشاطه	read/update	الملكية
مشرف	مصادق	نطاقه	read/update	الصلاحيات
Admin	مصادق	إداري	read/write	كامل
خارج النطاق	أي دور	لا يملكها	read/update	يُرفض
6.4 سجل التدقيق
يُسجّل:

تغيير صلاحية

اعتماد/رفض محتوى

إنشاء/تعديل تاجر

إنشاء/تصدير تقرير

عمليات إدارية حساسة

الفصل السابع — منظومة الصلاحيات والأدوار
7.1 المصفوفة الكاملة
المجال	Visitor	Member	Merchant	Team	Moderator	Manager	Admin
المحتوى العام	R	R	R	R	R	R	CRUD
الحساب	—	✓	✓	✓	✓	✓	✓
بيانات النشاط	—	—	✓	—	—	—	✓
التجار	—	—	بياناته	محدود	نطاق	تفويض	✓
الأماكن	R	R	بياناته	محدود	نطاق	تفويض	✓
التقارير	—	—	لا	لا	محدود	تفويض	✓
طباعة	—	—	لا	لا	reports.print	تفويض	✓
Audit	—	—	—	محدود	محدود	تفويض	✓
الصلاحيات	—	—	—	—	—	—	✓
7.2 مفاتيح الصلاحيات
text
users.read / users.write
places.read / places.write
merchants.read / merchants.write
reports.read / reports.export / reports.print
analytics.read / analytics.export
audit.read
team.read / team.write
moderators.read / moderators.write
governorates.read / governorates.write
content.read / content.write
offers.write
rewards.write
subscriptions.write
notifications.write
complaints.write
support.read / support.write
featured.write
الفصل الثامن — خطة التوسع المستقبلي
8.1 المبدأ
التوسع عبر Events + Records + Rules — لا شاشات مكررة.

8.2 الكيانات الجاهزة للتوسع
الكيان	يُغذّي
UserProfile	كل شيء
Place	الاكتشاف
Merchant	الحملات
Visit	الولاء
Offer	الترويج
Reward	المكافآت
PointsLedger	سجل النقاط
Referral	النمو
Challenge	التفاعل
Badge	الإنجازات
Campaign	الحملات
FeaturedPlacement	الظهور
AnalyticsEvent	التحليلات
8.3 نموذج الأحداث الموحد
text
place_viewed, place_saved, visit_verified,
rating_submitted, offer_viewed, offer_redeemed,
reward_earned, reward_redeemed, points_earned,
points_spent, referral_qualified, challenge_progressed,
challenge_completed, badge_earned, achievement_completed,
campaign_interaction, community_submission_approved
8.4 المراحل المستقبلية
Phase	المحتوى
Phase 2	Merchant Dashboard + Offers + Campaigns
Phase 3	Loyalty Core (Visits + Points + Rewards)
Phase 4	Community (Referrals + Challenges + Badges)
Phase 5	Growth (Recommendations + Analytics + Insights)
8.5 قائمة "لا تفعل" للتوسع
❌ لا Collection مستقلة لكل شاشة

❌ لا رصيد دون Ledger

❌ لا نقاط من الواجهة مباشرة

❌ لا مكافأة بفتح الصفحة

❌ لا تتبع موقع

❌ لا بيانات شخصية للتاجر

❌ لا خلط الظهور المدفوع بالترتيب العضوي

❌ لا شاشات مكررة

الفصل التاسع — مصفوفة المخاطر
9.1 المخاطر التقنية
#	المخاطرة	الاحتمال	الأثر	التخفيف
1	نفاد RAM (4GB)	عالي	عالي	gradle.properties مضبوط
2	Firebase Rules مفتوحة	متوسط	حرج	مراجعة قبل كل commit
3	APK Debug كبير	مؤكد	متوسط	release signing في G5
4	فقدان عمل محلي	متوسط	عالي	commit + push
5	ترقية عشوائية	متوسط	عالي	ممنوع بدون سبب
6	تكرار شاشات	متوسط	متوسط	Registries
7	مشاكل GPS	متوسط	متوسط	اختبار 3 أجهزة
8	RTL/LTR	منخفض	متوسط	اختبار كل شاشة
9.2 مصفوفة القرارات
#	القرار	الحالة
1	Production vs Emulator	✅ Production
2	go_router vs auto_route	✅ go_router
3	Provider vs Riverpod	✅ Provider
4	Email verification	⏳ Phase 2
5	Google Sign-In	⏳ G2.6+
6	Phone Sign-In	⏳ Phase 2
7	Release signing	⏳ G5
الفصل العاشر — قوائم التحقق
10.1 قائمة إغلاق كل Gate
text
[✓] كل المهام مكتملة
[✓] flutter analyze = 0
[✓] flutter test يمر
[✓] APK Debug ناجح
[✓] اختبار على جهاز
[✓] RTL/LTR
[✓] A11y
[✓] Commit + Tag
[✓] Push إلى GitHub
[✓] Release على GitHub
[✓] تحديث SESSION_STATE.md
[✓] تحديث RESUME.md
[✓] تحديث PROJECT_STATE.md
[✓] تحديث EXPERIENCE_LOG.md
[✓] نقطة رجوع موثقة
10.2 نموذج تقرير نهاية المرحلة
text
المرحلة: G2.X
التاريخ: YYYY-MM-DD
البيئة: WORK / Codespaces
Commit: <hash>
Tag: vX.Y.Z-<desc>

ما تم: ...
ما لم يتم: ...
الاختبارات: ...
الانحرافات: ...
الخبرة الجديدة: ...
الخطوة التالية: ...
خلاصة الوثيقة
المكون	العدد
وثائق مُجمّعة	25
بوابات	8
مراحل فرعية	30+
أدوار	7
مفاتيح صلاحيات	25+
شاشات MVP	25
Collections	7+
أيام حتى MVP	40
ساعات تقديرية	~320
المبادئ النهائية
بناء تدريجي على بوابات

حماية ما يعمل قبل إضافة الجديد

التوسع عبر Events + Records

الصلاحيات في Rules

نقطة رجوع قبل كل تغيير حساس

تسجيل كل خبرة

الأولوية: سلامة → استقرار → وظائف → أداء → شكل

RTL/LTR + A11y جزء من الإنجاز

كل شاشة: Screen ID + Function ID + Permission + Scope + Route

الأمان ≠ إخفاء الزر

نهاية وثيقة يا بلدي الجامعة الشاملة — v1.0
التاريخ: 2026-10-04
الحالة: معتمدة كمرجع تقني موحد

text

**احفظ الملف (Ctrl+S).**

---

# 🎯 الخطوة 3 — الملف الثاني: خارطة الطريق 40 يومًا

**أنشئ الملف:** `docs\YA_BALADI_ROADMAP_40_DAYS.md`

**الصق هذا المحتوى:**

```markdown
# 🗓️ خارطة طريق يا بلدي — 40 يومًا

**الفترة:** 2026-10-04 → 2026-11-14
**الهدف:** MVP Release

---

## نظرة عامة

| الأسبوع | المرحلة | المخرج |
|---|---|---|
| 1 | G2.5 + G2.6 | Firestore Models + Categories |
| 2 | G3 | Discovery (Search + GPS) |
| 3 | G4 | Security & Roles |
| 4 | G5 | Admin Panel |
| 5 | G6 | Product Features |
| 6 | G7 | Release Candidate |

---

## الأسبوع الأول (4-10 أكتوبر) — G2.5 + G2.6

### يوم 1 — الأحد 4 أكتوبر

| الوقت | المهمة |
|---|---|
| 09:00-09:30 | مراجعة حالة WORK + git pull |
| 09:30-10:00 | تثبيت provider |
| 10:00-11:00 | Models: Category, Place |
| 11:00-12:00 | Models: Review, Favorite |
| 13:00-14:30 | Repositories (4 ملفات) |
| 14:30-15:30 | Controllers |
| 15:30-16:00 | flutter analyze + test |
| 16:00-17:00 | Commit + Tag v0.2.5 |

### يوم 2 — الاثنين 5 أكتوبر

| الوقت | المهمة |
|---|---|
| 09:00-10:00 | Seed: 9 categories |
| 10:00-11:30 | Seed: 12 places |
| 11:30-12:30 | تشغيل Seed |
| 13:00-14:30 | home_screen Grid 3×3 |
| 14:30-15:30 | أيقونات ملوّنة |
| 15:30-16:30 | AllCategoriesScreen |
| 16:30-17:00 | Commit |

### يوم 3 — الثلاثاء 6 أكتوبر

| الوقت | المهمة |
|---|---|
| 09:00-10:30 | CategoryPlacesScreen |
| 10:30-12:00 | PlaceDetailsScreen |
| 13:00-14:30 | app_router updates |
| 14:30-15:30 | l10n updates |
| 15:30-16:30 | اختبار + Commit + Tag v0.2.6 |

### أيام 4-7 (7-10 أكتوبر)

| اليوم | المهمة |
|---|---|
| الأربعاء 7 | اختبار APK + bug fixes |
| الخميس 8 | FavoritesScreen كامل |
| الجمعة 9 | UI + Pull to refresh |
| السبت 10 | مراجعة + تحديث التوثيق |

---

## الأسبوع الثاني (11-17 أكتوبر) — G3 Discovery

| اليوم | المهمة |
|---|---|
| الأحد 11 | Search Screen |
| الاثنين 12 | Filter Chips |
| الثلاثاء 13 | Place Details كامل |
| الأربعاء 14 | geolocator + permissions |
| الخميس 15 | Nearby + geohash |
| الجمعة 16 | Offline cache |
| السبت 17 | Commit + Tag v0.3.0 |

---

## الأسبوع الثالث (18-24 أكتوبر) — G4 Security

| اليوم | المهمة |
|---|---|
| الأحد 18 | Role enum + Permission Matrix |
| الاثنين 19 | Scope Filters |
| الثلاثاء 20 | Firestore Rules |
| الأربعاء 21 | Merchant Lifecycle |
| الخميس 22 | Audit Log |
| الجمعة 23 | Permission tests |
| السبت 24 | Commit + Tag v0.4.0 |

---

## الأسبوع الرابع (25-31 أكتوبر) — G5 Admin

| اليوم | المهمة |
|---|---|
| الأحد 25 | Admin Dashboard |
| الاثنين 26 | Users + Merchants + Places |
| الثلاثاء 27 | Approvals |
| الأربعاء 28 | Reports + Filters |
| الخميس 29 | Export + Print |
| الجمعة 30 | Audit Viewer |
| السبت 31 | Commit + Tag v0.5.0 |

---

## الأسبوع الخامس (1-7 نوفمبر) — G6 Product

| اليوم | المهمة |
|---|---|
| الأحد 1 | Ratings + Reviews |
| الاثنين 2 | Reply + Report |
| الثلاثاء 3 | Offers |
| الأربعاء 4 | QR Scanner + Generator |
| الخميس 5 | Verified Visits |
| الجمعة 6 | Loyalty Core |
| السبت 7 | Commit + Tag v0.6.0 |

---

## الأسبوع السادس (8-14 نوفمبر) — G7 Release

| اليوم | المهمة |
|---|---|
| الأحد 8 | Unit + Integration Tests |
| الاثنين 9 | Performance + A11y |
| الثلاثاء 10 | Security Pen Test |
| الأربعاء 11 | Full Regression |
| الخميس 12 | Release APK + Signing |
| الجمعة 13 | App Distribution |
| **السبت 14** | **🎉 MVP RELEASE** |

---

## قواعد الجدولة

1. **كل يوم ينتهي بـ commit** (حتى لو العمل غير مكتمل — WIP commit)
2. **كل مرحلة كبرى تنتهي بـ tag**
3. **الجمعة = مراجعة أسبوعية**
4. **السبت = توثيق + تخطيط الأسبوع القادم**
5. **الأحد → الخميس = تنفيذ**

## مؤشرات التقدم اليومية
[✓] flutter analyze = 0
[✓] flutter test يمر
[✓] Commit واحد على الأقل
[✓] تحديث SESSION_STATE.md

text

---

**نهاية خارطة الطريق**