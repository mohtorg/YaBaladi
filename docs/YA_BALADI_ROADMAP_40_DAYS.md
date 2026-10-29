📘 وثيقة يا بلدي الجامعة الشاملة
Ya Baladi — Master Comprehensive Technical Plan v1.0
تاريخ الإصدار: 2026-10-04
المرجع: تجميع وتحليل 25 وثيقة حاكمة
الحالة: معتمدة كمرجع تقني موحد
الفلسفة: بناء تدريجي، توسع بلا إعادة بناء

📑 الفهرس التنفيذي
الفصل	المحتوى
1	الملخص التنفيذي والرؤية
2	معمارية المشروع والأساس التقني
3	خارطة الطريق (G0 → G7)
4	الخطة الزمنية التفصيلية (يوم/ساعة)
5	القواعد الحاكمة والمحاذير
6	منظومة الجودة والأمان
7	منظومة الصلاحيات والأدوار
8	خطة التوسع المستقبلي
9	مصفوفة المخاطر والقرارات
10	قوائم التحقق والإغلاق
الفصل الأول — الملخص التنفيذي والرؤية
1.1 الرؤية
يا بلدي منصة اكتشاف محلية مصرية تربط:

المستخدمين (عضو / زائر) بالأماكن والخدمات.

مقدمي الخدمة (تجار) بالجمهور المستهدف.

فريق يا بلدي بأدوات إدارة المحتوى والجودة.

الإدارة بلوحات تحكم وتقارير.

المبدأ الحاكم: بناء تدريجي على بوابات (Gates) — لا نبدأ بوابة قبل إغلاق السابقة.

1.2 النطاق في MVP (25 شاشة / 3 أدوار أساسية)
الدور	الرمز	النطاق
Visitor	visitor	تصفح + بحث (بدون تسجيل)
Member	member	حساب + مفضلة + تقييمات
Super Admin	admin	إدارة كاملة
مؤجل لـ Phase 2: Merchant Dashboard, Moderator, Team, Loyalty Core.

1.3 المخرج النهائي لـ MVP
APK يعمل على 3 أجهزة ✅

10 أماكن حقيقية في Firestore ✅

5 مستخدمين حقيقيين مسجلين ✅

لا crash في ساعة استخدام ✅

البحث يعمل + تفاصيل المكان ✅

Admin يضيف/يعدّل الأماكن ✅

RTL/LTR + Design System ✅

Firebase Rules مختبرة ✅

الفصل الثاني — معمارية المشروع والأساس التقني
2.1 المكدس التقني (Tech Stack)
الطبقة	التقنية	الإصدار
Framework	Flutter	3.47.x
Language	Dart	3.13.x
Backend	Firebase	—
— Auth	firebase_auth	5.3.x
— Database	cloud_firestore	5.4.x
— Core	firebase_core	3.6.x
Navigation	go_router	18.0.x
State	provider	6.1.x
Storage	shared_preferences	2.5.x
Localization	flutter_localizations + intl	SDK
قاعدة صارمة: لا ترقية packages بدون سبب تقني موثق + نقطة رجوع.

2.2 البنية المعمارية (Separation of Concerns)
text
lib/
├── core/
│   └── router/                    ← GoRouter + Guards
│       ├── app_router.dart
│       ├── route_guards.dart
│       ├── route_names.dart
│       └── route_paths.dart
│
├── features/                      ← Feature-first structure
│   ├── auth/
│   │   ├── controllers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── data/                      ← Models + Repositories
│   │   ├── models/
│   │   └── repositories/
│   ├── categories/
│   │   ├── controllers/
│   │   └── screens/
│   ├── favorites/
│   └── profile/
│
├── l10n/                          ← Localization
│   ├── app_ar.arb
│   ├── app_en.arb
│   ├── locale_controller.dart
│   └── theme_controller.dart
│
├── screens/                       ← Shell + standalone screens
│   ├── main_shell.dart
│   ├── home_screen.dart
│   ├── search_screen.dart
│   └── settings_screen.dart
│
├── theme/                         ← Design System
│   ├── app_theme.dart
│   ├── app_typography.dart
│   └── design_tokens.dart
│
├── widgets/                       ← Shared widgets
│   ├── language_picker_dialog.dart
│   └── theme_picker_dialog.dart
│
└── main.dart                      ← App entry + MultiProvider
المبادئ:

Feature-first — كل ميزة في مجلد مستقل

Separation of Concerns — UI / Logic / Data منفصلة

Single Source of Truth — كل معلومة في مكان واحد

Permission ≠ UI — الحماية في Rules + Services، لا في إخفاء الأزرار

2.3 نموذج الصلاحيات (Role + Permission + Scope)
text
Authentication
      ↓
    Role (visitor/member/merchant/team/moderator/manager/admin)
      ↓
  Permission (users.read, places.write, reports.print, ...)
      ↓
    Scope (governorate/city/category/ownerId)
      ↓
    Action
قاعدة ذهبية: Authentication ≠ Authorization — تسجيل الدخول ≠ صلاحية.

2.4 مخطط Firestore (Collections)
Collection	الغرض	الحقول الرئيسية
users/{uid}	الأعضاء	uid, email, role, displayName, createdAt
categories/{id}	التصنيفات	nameAr, nameEn, iconName, order, placesCount
places/{id}	الأماكن	nameAr, nameEn, categoryId, location, images, rating
places/{id}/reviews/{rid}	التقييمات	userId, stars, text, createdAt
users/{uid}/favorites/{pid}	المفضلة	placeId, createdAt
merchants/{id}	التجار (Phase 2)	ownerId, status, verified
audit_log/{id}	سجل التدقيق	userId, action, target, timestamp
قواعد Firestore: Authentication ≠ Authorization — تُفرض في Rules وليس الواجهة.

2.5 نموذج التصميم البصري
الألوان الأساسية:

Navy: #0B2D5B

Primary Blue: #0D6EFD

Orange (Accent): #FF8A00

White: #FFFFFF

الخط: Cairo (4 أوزان: Regular/Medium/SemiBold/Bold)

التدرج الطباعي (Typography):

المستوى	الحجم	الوزن	الاستخدام
H1	22	Bold	عنوان الشاشة
H2	18	SemiBold	عنوان القسم
H3	16	Medium	عنوان البطاقة
H4	13	SemiBold	تسمية مصغّرة
Body	14-16	Regular	نص عادي
Caption	12	Regular	تلميحات
المسافات: 4 / 8 / 16 / 24 / 32 (multiples of 4)
الزوايا: 8 / 12 / 16
أحجام اللمس: ≥ 48dp (Android Accessibility)

الفصل الثالث — خارطة الطريق (G0 → G7)
3.1 البوابات المعتمدة
Gate	الهدف	شرط المرور	الحالة
G0	Baseline	وثائق + Git + Recovery + بيئة	✅ مكتمل
G1	Build Foundation	APK + CI + Analyze	✅ مكتمل
G2	Core UX	Localization + Design System + Navigation	✅ مكتمل
G3	Discovery	Search + Location + Place Details	⏳ التالي
G4	Roles/Security	Auth + Permission + Scope + Merchant Lifecycle	⏳
G5	Admin	Admin/Team/Moderator + Reports + Audit	⏳
G6	Product Features	Ratings + Offers + QR + Loyalty Core	⏳
G7	Release Candidate	Regression + A11y + Performance + Security + Backup	⏳
3.2 تفصيل G2 (المكتمل)
المرحلة	المحتوى	الحالة
G2.1	Localization (AR/EN + RTL)	✅
G2.2	Design System (Tokens + Cairo + Theme)	✅
G2.3	Navigation (go_router + ShellRoute)	✅
G2.3.1	Controllers (Provider: Locale/Theme)	✅
G2.4	Authentication (Firebase Auth + Guards)	✅
G2.4-hotfix	Bug Fixes (Back button + Press again to exit)	✅
G2.5	Firestore Models + Repositories	⏳ التالي
G2.6	Category Screens (Home Grid + Places List)	⏳
3.3 تفصيل G3 (Discovery)
المرحلة	المحتوى
G3.1	Search Screen (Text + Filters chips)
G3.2	Search Results + Pagination
G3.3	Place Details (images + rating + reviews)
G3.4	Map View + Nearby (GPS)
G3.5	Advanced Filters (price, rating, distance)
G3.6	Offline Cache (Hive/Isar)
3.4 تفصيل G4 (Security & Roles)
المرحلة	المحتوى
G4.1	Role enum + Permission Matrix
G4.2	Scope Filters (governorate/city)
G4.3	Firestore Rules + Storage Rules
G4.4	Merchant Lifecycle (register → approve → publish)
G4.5	Audit Log
G4.6	Permission Tests (allow/deny)
3.5 تفصيل G5 (Admin)
المرحلة	المحتوى
G5.1	Admin Dashboard
G5.2	Users + Merchants + Places Management
G5.3	Approvals (content review)
G5.4	Reports + Export (Excel/PDF)
G5.5	Audit Log Viewer
G5.6	Team/Supervisor Management
3.6 تفصيل G6 (Product Features)
المرحلة	المحتوى
G6.1	Ratings + Reviews System
G6.2	Offers + Coupons
G6.3	QR Scanner + Generator
G6.4	Verified Visits (check-in)
G6.5	Loyalty Core (Points + Rewards)
G6.6	Referrals + Achievements
3.7 تفصيل G7 (Release Candidate)
المرحلة	المحتوى
G7.1	Unit + Integration Tests
G7.2	Performance Testing
G7.3	Accessibility Testing
G7.4	Security Pen Test
G7.5	Full Regression
G7.6	Release APK + AAB
G7.7	Firebase App Distribution
الفصل الرابع — الخطة الزمنية التفصيلية (يوم/ساعة)
الفترة المتبقية: 40 يومًا (2026-10-04 → 2026-11-14)
الهدف: MVP Release

4.1 الأسبوع الأول (4-10 أكتوبر) — G2.5 + G2.6
يوم 1 — الأحد 4 أكتوبر (اليوم الحالي)
الوقت	المهمة	المخرج
09:00-09:30	مراجعة حالة WORK + git pull	✅ متزامن
09:30-10:00	تثبيت provider + التحقق	✅
10:00-11:00	إنشاء Models: Category, Place	ملفان
11:00-12:00	إنشاء Models: Review, Favorite	ملفان
12:00-13:00	استراحة + مراجعة	—
13:00-14:30	إنشاء Repositories (4 ملفات)	ملفات
14:30-15:30	Controllers: CategoriesController + PlacesController	ملفان
15:30-16:00	flutter analyze + flutter test	✅
16:00-17:00	Commit + Tag v0.2.5-g2.5-models	✅
يوم 2 — الاثنين 5 أكتوبر
الوقت	المهمة	المخرج
09:00-10:00	Seed Script: 9 تصنيفات	script
10:00-11:30	Seed Script: 12 مكان تجريبي	script
11:30-12:30	تشغيل Seed + التحقق من Firestore	✅
13:00-14:30	تحديث home_screen.dart — Grid 3×3	UI
14:30-15:30	أيقونات Material 3 ملوّنة للتصنيفات	UI
15:30-16:30	AllCategoriesScreen (للمزيد)	شاشة
16:30-17:00	اختبار + Commit	✅
يوم 3 — الثلاثاء 6 أكتوبر
الوقت	المهمة	المخرج
09:00-10:30	CategoryPlacesScreen — قائمة أماكن	شاشة
10:30-12:00	PlaceDetailsScreen — تفاصيل مكان	شاشة
13:00-14:30	تحديث app_router.dart — routes جديدة	router
14:30-15:30	تحديث app_ar.arb + app_en.arb	20 مفتاح
15:30-16:30	اختبار تنقل + Commit + Tag v0.2.6-g2.6-categories	✅
يوم 4-7 — الأربعاء → السبت (7-10 أكتوبر)
اليوم	المهمة
الأربعاء 7	اختبار APK على الجهاز + إصلاح bugs
الخميس 8	FavoritesScreen مع قائمة حقيقية + Toggle
الجمعة 9	تحسينات UI + Pull to refresh
السبت 10	مراجعة أسبوعية + تحديث التوثيق
4.2 الأسبوع الثاني (11-17 أكتوبر) — G3 Discovery
اليوم	المهمة الرئيسية
الأحد 11	Search Screen — TextInput + Results
الاثنين 12	Filter Chips (نوع، سعر، تقييم)
الثلاثاء 13	Place Details كامل (صور + تقييمات + خريطة)
الأربعاء 14	Integration: geolocator + Location permission
الخميس 15	Nearby Places (geohash + distance)
الجمعة 16	Offline cache (SharedPreferences/Hive)
السبت 17	مراجعة + Commit + Tag v0.3.0-g3-discovery
4.3 الأسبوع الثالث (18-24 أكتوبر) — G4 Security
اليوم	المهمة الرئيسية
الأحد 18	Role enum + Permission Matrix in code
الاثنين 19	Scope Filters (governorate/city)
الثلاثاء 20	Firestore Rules + Storage Rules
الأربعاء 21	Merchant Lifecycle (states + UI)
الخميس 22	Audit Log Service + Screen
الجمعة 23	Permission tests (allow/deny scenarios)
السبت 24	مراجعة + Commit + Tag v0.4.0-g4-security
4.4 الأسبوع الرابع (25-31 أكتوبر) — G5 Admin
اليوم	المهمة الرئيسية
الأحد 25	Admin Dashboard + Statistics
الاثنين 26	Users Management + Merchants + Places
الثلاثاء 27	Approvals (content review workflow)
الأربعاء 28	Reports + Filters
الخميس 29	Export (PDF/Excel) + Print
الجمعة 30	Audit Log Viewer
السبت 31	مراجعة + Commit + Tag v0.5.0-g5-admin
4.5 الأسبوع الخامس (1-7 نوفمبر) — G6 Product Features
اليوم	المهمة الرئيسية
الأحد 1	Ratings + Reviews UI
الاثنين 2	Reply to reviews + Report
الثلاثاء 3	Offers System (create/toggle)
الأربعاء 4	QR Scanner + Generator
الخميس 5	Verified Visits (check-in)
الجمعة 6	Loyalty Core (Points + Rewards)
السبت 7	مراجعة + Commit + Tag v0.6.0-g6-product
4.6 الأسبوع السادس (8-14 نوفمبر) — G7 Release Candidate
اليوم	المهمة الرئيسية
الأحد 8	Unit + Integration Tests
الاثنين 9	Performance + Accessibility
الثلاثاء 10	Security Pen Test
الأربعاء 11	Full Regression
الخميس 12	Release APK + AAB + Signing
الجمعة 13	Firebase App Distribution + Beta
السبت 14	MVP RELEASE 🎉
4.7 الجدول الزمني المجمّع
text
┌─────────────────────────────────────────────────────────────┐
│  الأسبوع 1  │ G2.5 Models + G2.6 Categories │ 4-10 أكتوبر  │
├─────────────────────────────────────────────────────────────┤
│  الأسبوع 2  │ G3 Discovery (Search+GPS)      │ 11-17 أكتوبر │
├─────────────────────────────────────────────────────────────┤
│  الأسبوع 3  │ G4 Security & Roles            │ 18-24 أكتوبر │
├─────────────────────────────────────────────────────────────┤
│  الأسبوع 4  │ G5 Admin Panel                 │ 25-31 أكتوبر │
├─────────────────────────────────────────────────────────────┤
│  الأسبوع 5  │ G6 Product Features            │ 1-7 نوفمبر   │
├─────────────────────────────────────────────────────────────┤
│  الأسبوع 6  │ G7 Release Candidate + MVP     │ 8-14 نوفمبر  │
└─────────────────────────────────────────────────────────────┘
الفصل الخامس — القواعد الحاكمة والمحاذير
5.1 القواعد الذهبية (10)
لا نبدأ من الصفر — استمر من آخر نقطة مثبتة

تشخيص → سبب مثبت → أقل تعديل → اختبار → تسجيل

لا تعديل حساس بدون نقطة رجوع

لا نعيد اختبار ما ثبت إلا بدليل جديد

افصل بين: حقيقة مثبتة / نتيجة اختبار / افتراض / اقتراح

تعديل واحد في التجربة الواحدة لعزل السبب

لا ترقية packages بدون سبب تقني

Authentication ≠ Authorization — الحماية في Rules

إخفاء الزر ليس حماية

الأولوية: سلامة → استقرار → وظائف → أداء → شكل

5.2 قواعد Git والنسخ
قبل أي تغيير حساس:

bash
git status
git log --oneline -5
git tag -a vX.Y.Z-<desc> -m "..."
ممنوع بدون مراجعة:

git reset --hard

git clean -fd

git push --force

git checkout .

قبل التغيير الحساس (Firebase/Rules/Auth/DB/Android):

نقطة رجوع (tag + ZIP)

تحديد السبب

تحديد النطاق

تحديد ما لن يتغير

5.3 قواعد Firebase
Rules = المصدر الحقيقي للصلاحيات (لا الواجهة)

لا تفترض Firebase سبب مشكلة — أثبت العلاقة

لا تفتح read/write للعامة كحل سريع

لا تحذف Rule دون اختبار الأثر الأمني

firestore.rules يدخل دورة Git مثل أي كود حساس

اختبار Permission Denied بالترتيب:

العملية الفاشلة (read/create/update/delete)

المسار (collection/document)

الدور + حالة المصادقة

Rule الحالية

الشرط المطلوب

مقارنة الشرط مع البيانات الفعلية

5.4 قواعد الكود (Dart/Flutter)
معيار الهندسة:

UpperCamelCase للأنواع

lowerCamelCase للمتغيرات والدوال

lowercase_with_underscores للملفات

dart format . قبل كل commit

flutter analyze نظيف قبل أي commit

ممنوع:

! null assertion عشوائي

dynamic بدون حاجة

Future.delayed كحل تزامن

منطق طويل في build()

منطق صلاحيات في UI فقط

تكرار نصوص عربية/إنجليزية

APIs deprecated في الكود الجديد

5.5 قواعد UI/UX
الهوية البصرية:

هادئة + متوازنة

مساحات بيضاء وفيرة

البرتقالي للتأكيد فقط (ليس لكل CTA)

بطاقات نظيفة قليلة

أيقونات موحدة

عنصر بصري رئيسي واحد لكل شاشة

ممنوع:

Gradient مبالغ

Glassmorphism ثقيل

Shadows قوية

نصوص صغيرة (< 12)

أزرار صغيرة (< 48dp)

أكثر من H1 في الشاشة الواحدة

RTL/LTR:

التغيير يتغير النصوص فعليًا (ليس الاتجاه فقط)

الأسهم الاتجاهية تنعكس

الأيقونات غير الاتجاهية لا تنعكس

الأحجام لا تتكسر

5.6 قواعد الأدوار والصلاحيات
7 أدوار:

الدور	الصلاحيات الأساسية
Visitor	تصفح عام فقط
Member	حساب + مفضلة + تقييمات
Merchant	نشاطه فقط
Team Member	مهامه الموكلة
Moderator	مراجعة ضمن النطاق
Team Manager	إدارة الفريق
Super Admin	كل شيء
قاعدة صارمة:

لا تجعل Moderator = Admin

لا تجعل Member = Team Member

فصل Permission عن Scope

5.7 قواعد الاعتماد النهائي (Definition of Done)
text
[✓] الكود مكتوب + مراجع
[✓] flutter analyze = 0 أخطاء
[✓] اختبار الوحدة/التكامل
[✓] APK Debug ناجح
[✓] Commit مسجل + push
[✓] سجل الخبرة محدّث
[✓] توثيق المقاييس المهمة
[✓] نقطة رجوع محفوظة
الفصل السادس — منظومة الجودة والأمان
6.1 إطار الجودة
المعيار	التطبيق
ISO/IEC 25010:2023	جودة عامة
OWASP MASVS	أمن التطبيقات المحمولة
WCAG 2.2	إمكانية الوصول
Material 3	تصميم
Effective Dart	كتابة Dart
6.2 الأهداف الداخلية
المقياس	الهدف
Cold start	≤ 2.5 ثانية
Warm start	≤ 1.5 ثانية
Hot start	≤ 1.0 ثانية
Frame time (60Hz)	≤ 16ms
Touch target	≥ 48dp
Text contrast	≥ 4.5:1 (عادي) / ≥ 3:1 (كبير)
6.3 اختبارات الأمان (Firebase)
مصفوفة اختبار الصلاحيات:

الحالة	المستخدم	البيانات	العملية	النتيجة
زائر	غير مصادق	عامة	read	يسمح وفق Rule
عضو	مصادق	بياناته	read/update	ضمن النطاق
تاجر	مصادق	نشاطه	read/update	الملكية
مشرف	مصادق	نطاقه	read/update	الصلاحيات
Admin	مصادق	إداري	read/write	كامل
خارج النطاق	أي دور	لا يملكها	read/update	يُرفض
6.4 اختبارات الأداء
flutter drive --profile

قياس: Frame build time, Raster time, Jank

بطاريات: لا GPS مستمر, لا polling

6.5 اختبارات A11y
TalkBack على Android

VoiceOver على iOS

تكبير النص 200%

تباين الألوان

Semantics على H1

6.6 سجل التدقيق (Audit Log)
العمليات المسجلة:

تغيير صلاحية

اعتماد/رفض محتوى

إنشاء/تعديل تاجر

إنشاء/تصدير/طباعة تقرير

حذف حساب

عمليات إدارية حساسة

الحقول: userId, action, target, timestamp, metadata.

الفصل السابع — منظومة الصلاحيات والأدوار
7.1 المصفوفة الكاملة
المجال	Visitor	Member	Merchant	Team	Moderator	Manager	Admin
المحتوى العام	CRUD?	CRUD?	CRUD?	CRUD?	CRUD?	CRUD?	كامل
الحساب الشخصي	—	✓	✓	✓	✓	✓	✓
بيانات نشاطه	—	—	✓	—	—	—	✓
مستخدمون آخرون	—	—	—	محدود	محدود	محدود	✓
التجار	—	—	بياناته	محدود	نطاق	تفويض	✓
الأماكن	قراءة	قراءة	بياناته	محدود	نطاق	تفويض	✓
التقارير	—	—	لا	لا	محدود	تفويض	✓
تصدير	—	—	لا	لا	محدود	تفويض	✓
طباعة	—	—	لا	لا	reports.print	تفويض	✓
Analytics	—	—	نشاطه	محدود	نطاق	تفويض	كامل
Audit	—	—	—	محدود	محدود	تفويض	✓
إدارة الفريق	—	—	—	—	—	محدود	✓
إدارة الصلاحيات	—	—	—	—	—	—	✓
المحافظات	—	—	—	محدود	نطاق	تفويض	✓
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
7.3 Navigation Map حسب الدور
Visitor:

text
الرئيسية → البحث → النتائج → التفاصيل → العودة
        → التصنيفات → قائمة الأماكن → التفاصيل
Member:

text
الرئيسية + المفضلة + الإشعارات + الحساب
الحساب → بيانات + QR + تقييمات + إعدادات
Merchant:

text
لوحة التاجر → نشاطي → تعديل
            → العروض → إدارة
            → التقييمات → الردود
            → الإحصائيات
            → الحساب
Team/Moderator/Manager/Admin:

text
لوحة الإدارة → المستخدمون
              → التجار
              → الأماكن
              → المحتوى
              → الفريق
              → التقارير
              → Audit
              → الإعدادات
الفصل الثامن — خطة التوسع المستقبلي
8.1 المبدأ: التوسع بلا إعادة بناء
الفكرة: تصور 19 موضوعًا مستقبليًا كطبقات فوق كيانات أساسية موجودة، دون الحاجة لتعديل البنية الجوهرية.

8.2 الكيانات الأساسية الجاهزة للتوسع
الكيان	يُغذّي
UserProfile	كل شيء
Place	الاكتشاف
Merchant	الحملات والعروض
Visit	الولاء والمكافآت
Offer	الترويج
Reward	المكافآت
PointsLedger	سجل النقاط
Referral	النمو
Challenge	التفاعل
Badge	الإنجازات
Campaign	الحملات
FeaturedPlacement	الظهور المميز
CommunityContribution	المحتوى المجتمعي
AnalyticsEvent	التحليلات
8.3 نموذج الأحداث الموحد (Event Model)
text
place_viewed
place_saved
visit_verified
rating_submitted
offer_viewed
offer_redeemed
reward_earned
reward_redeemed
points_earned
points_spent
referral_qualified
challenge_progressed
challenge_completed
badge_earned
achievement_completed
campaign_interaction
community_submission_approved
الميزة: كل ميزة جديدة تُستهلك نفس طبقة الأحداث — لا حاجة لـ Collection جديد.

8.4 المراحل المستقبلية (Phase 2-5)
Phase 2 — Merchant Dashboard
Merchant onboarding كامل

Offer management + campaigns

Analytics

Verified badge

Phase 3 — Loyalty Core
Visits + Points Ledger

Rewards + Redemption

Streaks

Phase 4 — Community
Referrals + Challenges

Badges + Achievements

Digital Passport

Phase 5 — Growth
Personalized Recommendations

Merchant Analytics

Customer Insights

Seasonal Campaigns

8.5 القاعدة الذهبية للتوسع
لا نضيف Collection أو Service أو Route أو Rule أو Screen جديد دون اعتماد، ودون التأكد من عدم وجود ما يؤدّي الغرض.

الفكرة: التوسع عبر Events + Records + Rules، وليس عبر شاشات جديدة لكل ميزة.

8.6 قائمة "لا تفعل" للتوسع
❌ لا تنشئ Collection مستقلة لكل شاشة

❌ لا تخزن الرصيد الحالي دون Ledger

❌ لا تمنح نقاطًا من الواجهة مباشرة

❌ لا تربط المكافأة بفتح الصفحة

❌ لا تستخدم الموقع للتتبع

❌ لا تمنح التاجر بيانات شخصية

❌ لا تخلط الظهور المدفوع بالترتيب العضوي

❌ لا تنشئ خوارزمية توصيات معقدة قبل البيانات

❌ لا تنشئ شاشات مكررة

❌ لا تعدّل Rules أثناء تجربة ميزة

الفصل التاسع — مصفوفة المخاطر والقرارات
9.1 المخاطر التقنية
#	المخاطرة	الاحتمال	الأثر	التخفيف
1	نفاد RAM على WORK (4 GB)	عالي	عالي	gradle.properties مُضبوط + Build على Codespaces للأعمال الثقيلة
2	Firebase Rules مفتوحة عن طريق الخطأ	متوسط	حرج	مراجعة قبل كل commit + اختبار allow/deny
3	تضخم APK Debug (169 MB)	مؤكد	متوسط	release signing في G5
4	فقدان عمل محلي غير مدفوع	متوسط	عالي	commit + push بعد كل مرحلة
5	الترقية العشوائية للـ packages	متوسط	عالي	ممنوع بدون سبب تقني + نقطة رجوع
6	تكرار الشاشات/الوظائف	متوسط	متوسط	Screen/Function Registry
7	مشاكل GPS على أجهزة مختلفة	متوسط	متوسط	اختبار على 3 أجهزة
8	عدم اتساق RTL/LTR	منخفض	متوسط	اختبار كل شاشة في اللغتين
9.2 المخاطر الأمنية
#	المخاطرة	التخفيف
1	الوصول غير المصرح للبيانات	Firestore Rules + اختبارات allow/deny
2	تسرب بيانات شخصية	تقليل البيانات + Scope Filters
3	تزوير زيارات/نقاط	Idempotency + Fraud Review
4	تخمين كلمات المرور	Firebase Auth limits
5	اختراق حساب	Email verification + 2FA (Phase 2)
9.3 مصفوفة القرارات المعلقة
#	القرار	الحالة	التوصية
1	Emulator vs Production	✅ Production	—
2	go_router vs auto_route	✅ go_router	—
3	Provider vs Riverpod	✅ Provider	—
4	Email verification	⏳	تأجيل لـ Phase 2
5	Google Sign-In	⏳	G2.6+
6	Phone Sign-In	⏳	Phase 2
7	Release signing	⏳	G5
8	Package name _rebuild	⏳	بعد G2
الفصل العاشر — قوائم التحقق والإغلاق
10.1 قائمة تحقق G2.5 (اليوم)
□ provider مثبت
□ Category model
□ Place model
□ Review model
□ Favorite model
□ CategoryRepository
□ PlaceRepository
□ ReviewRepository
□ FavoritesRepository
□ CategoriesController
□ PlacesController
□ flutter analyze نظيف
□ flutter test يمر
□ Commit + Tag v0.2.5-g2.5-models
10.2 قائمة تحقق G2.6 (غدًا)
□ Seed script: 9 categories
□ Seed script: 12 places
□ تشغيل seed + التحقق
□ home_screen.dart Grid 3×3
□ أيقونات Material 3 ملوّنة
□ AllCategoriesScreen
□ CategoryPlacesScreen
□ PlaceDetailsScreen (basic)
□ تحديث app_router.dart
□ تحديث app_ar.arb + app_en.arb
□ اختبار تنقل
□ Commit + Tag v0.2.6-g2.6-categories
10.3 قائمة إغلاق كل Gate
text
[✓] كل المهام مكتملة
[✓] flutter analyze = 0 أخطاء
[✓] flutter test = كلها تنجح
[✓] APK Debug ناجح
[✓] APK Release (عند انطباق)
[✓] اختبار على جهاز حقيقي
[✓] اختبارات RTL/LTR
[✓] اختبارات A11y
[✓] Commit + Tag
[✓] Push إلى GitHub
[✓] Release على GitHub
[✓] تحديث SESSION_STATE.md
[✓] تحديث RESUME.md
[✓] تحديث PROJECT_STATE.md
[✓] تحديث EXPERIENCE_LOG.md
[✓] تحديث COMPLIANCE_MATRIX.md
[✓] نقطة رجوع موثقة
10.4 نموذج تقرير نهاية المرحلة
text
المرحلة: G2.X
التاريخ: YYYY-MM-DD
البيئة: WORK / Codespaces
Commit: <hash>
Tag: vX.Y.Z-<desc>

ما تم:
- ...
- ...

ما لم يتم:
- ...

الاختبارات:
- flutter analyze: ✅ / ❌
- flutter test: ✅ / ❌
- APK Debug: ✅ / ❌

الانحرافات:
- ...

الخبرة الجديدة:
- ...

الخطوة التالية:
- ...
🎯 خلاصة الوثيقة الجامعة
ما تحتويه هذه الوثيقة
المكون	العدد
وثائق مُجمّعة	25
بوابات (Gates)	8
مراحل فرعية	30+
أدوار مستخدمين	7
مفاتيح صلاحيات	25+
شاشات MVP	25
Collections Firestore	7+
Models مطلوبة	15+
Repositories مطلوبة	10+
اختبارات مطلوبة	6 أنواع
أيام حتى MVP	40
ساعات تقديرية	~320
المبادئ الحاكمة النهائية
بناء تدريجي على بوابات — لا بوابة تُفتح قبل إغلاق السابقة

حماية ما يعمل قبل إضافة الجديد — stability first

التوسع عبر Events + Records — لا شاشات مكررة

الصلاحيات في Rules — لا في الواجهة

نقطة رجوع قبل كل تغيير حساس

تسجيل كل خبرة — لا نفقد معرفة

الأولوية: سلامة → استقرار → وظائف → أداء → شكل

RTL/LTR + A11y جزء من الإنجاز — لا تحسين لاحق

كل شاشة: Screen ID + Function ID + Permission + Scope + Route

الأمان ≠ إخفاء الزر — الأمان في الطبقات الموثوقة

الرؤية النهائية
تطبيق يا بلدي = منصة اكتشاف محلية مصرية، تُبنى مرة واحدة بمعمارية تسمح بالتوسع عبر 5 مراحل دون إعادة بناء، وتُدار عبر بوابات جودة صارمة، وتُوثّق كل خطوة فيها.

نهاية وثيقة يا بلدي الجامعة الشاملة — v1.0

التاريخ: 2026-10-04
الحالة: معتمدة كمرجع تقني موحد