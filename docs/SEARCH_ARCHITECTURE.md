# 📐 YaBaladi — Search Architecture & Execution Plan

> Version: 1.0
> Status: Ready for Review
> Date: 2026-10-08
> Plan: Firebase Spark (Free)
> Duration: 18-22 يوم عمل
> Tasks: 47 مهمة ذرية

---

## الفهرس

1. الملخص التنفيذي
2. تحليل الوضع الحالي
3. المشكلة الجذرية
4. الرؤية المستهدفة
5. المعمارية المقترحة
6. القيود التقنية
7. الخطة المرحلية
8. المهام الذرية
9. الجدول الزمني
10. معايير النجاح
11. إدارة المخاطر
12. ملاحق

---

## 1. الملخص التنفيذي

### الهدف
إعادة بناء منظومة البحث في YaBaladi من "شاشات منفصلة" إلى منظومة موحدة قابلة للتوسع، بدون تكلفة إضافية.

### القرارات المحورية
| القرار | الاختيار | السبب |
|--------|----------|-------|
| محرك البحث | Firestore كما هو | التكلفة = 0 |
| المعمارية | Layered + Abstract Repository | جاهز للترقية |
| التطبيع العربي | Client-side | لا يحتاج تعديل بيانات |
| الفلاتر | Client-side | مرونة كاملة |

### المدة
- المسار السريع: 18 يوم
- المسار الكامل: 22 يوم
- الجهد اليومي: 3-5 ساعات

### المخرج
- منظومة بحث موحدة
- 9 ملفات جديدة + 6 معدّلة
- جاهزية 100% لتبديل المحرك

---

## 2. تحليل الوضع الحالي

### المكونات
| الملف | الدور | الحالة |
|-------|------|--------|
| lib/screens/search_screen.dart | شاشة البحث | مشكلة info |
| lib/screens/home_screen.dart | الرئيسية | شريط ميت |
| lib/services/search_history_service.dart | السجل | غير مكتمل |
| firestore.rules | الأمان | موجودة |
| docs/PROJECT_BACKLOG.md | المهام | 39 ملاحظة |

### نقاط الألم
| # | المشكلة | الأولوية |
|---|---------|----------|
| P1 | لا فلاتر في البحث | عالية |
| P2 | التصنيفات غير مرتبطة | عالية |
| P3 | شريط البحث ميت | متوسطة |
| P4 | شاشات التصنيفات بلا بحث | عالية |
| P5 | history غير مربوط | متوسطة |
| P6 | مشكلة info | عالية |
| P7 | لا تطبيع عربي | متوسطة |

---

## 3. المشكلة الجذرية

### التشخيص
المشكلة معمارية، ليست في شاشة واحدة.

الوضع الحالي: Islands Architecture
- Home ←→ Search ←→ Category
- لا تواصل بين الشاشات

الوضع المستهدف: Centralized Service
- كل الشاشات → SearchService
- SearchService → Repository (abstract)
- Repository → Firestore Implementation

### النتيجة المرجوة
- صفر تكرار كود
- سلوك موحد
- إضافة ميزة = تعديل واحد
- تبديل المحرك = ملف واحد


---

## 4. الرؤية المستهدفة

### رحلة المستخدم
- مسار استكشاف: تصنيف → ExploreScreen (بحث + فلاتر + نتائج)
- مسار بحث: شريط → SearchScreen (autocomplete + instant + history)
- مسار تصفية: أي مسار → Filters

### المبادئ
| المبدأ | الوصف |
|--------|-------|
| M1 | كل شاشة مكتفية بذاتها |
| M2 | بحث فوري أثناء الكتابة |
| M3 | تصفية تدريجية: Chips → Sheet |
| M4 | اقتراحات ذكية |
| M5 | صفر تكلفة |

---

## 5. المعمارية

### الطبقات
- Layer 1: Presentation (Screens + Widgets + Controllers)
- Layer 2: Domain (SearchRepository abstract + Models)
- Layer 3: Data (Firestore Impl / Algolia Impl / Mock)
- Layer 4: Utils (TextNormalizer + QueryParser)

### هيكل المجلدات
lib/core/search/domain/ - العقود
lib/core/search/data/firestore/ - التطبيق
lib/core/search/utils/ - الأدوات
lib/features/search/screens/ - الشاشات
lib/features/search/widgets/ - الودجات
lib/features/search/controllers/ - التحكم

### العقود
- SearchRepository (abstract)
- SearchQuery (text + categoryId + filters + limit + offset + sortBy)
- SearchResult (items + total + hasMore)
- SearchFilters (minRating + priceRange + open24h + maxDistance)
- SearchError (types)

---

## 6. القيود التقنية

### Firestore Spark Plan
| القيد | القيمة |
|-------|--------|
| قراءات/يوم | 50,000 |
| كتابات/يوم | 20,000 |
| تخزين | 1 GiB |
| Full-text search | غير مدعوم |
| array-contains-any | مدعوم (10) |

### القيود المقبولة
| الميزة | الآن | لاحقاً |
|--------|------|--------|
| Typo tolerance | لا | مع Algolia |
| الجذور العربية | جزئي | تحسين |
| البحث الصوتي | لا | مستقبلي |
| ترتيب AI | لا | مستقبلي |


---

## 7. الخطة المرحلية

### المراحل الست
| المرحلة | المدة | المهام |
|---------|-------|--------|
| Phase 0: Analysis | 1 يوم | 4 |
| Phase 1: Domain Layer | 2 أيام | 8 |
| Phase 2: Firestore Impl | 3 أيام | 10 |
| Phase 3: Explore Screen | 4 أيام | 12 |
| Phase 4: Search Screen | 3 أيام | 8 |
| Phase 5: Filters System | 3 أيام | 8 |
| Phase 6: Polish | 2 أيام | 7 |
| الإجمالي | 18 يوم | 57 |

### مبادئ التنفيذ
- Atomic: كل مهمة ≤ 4 ساعات
- Testable: مخرج قابل للاختبار
- Reversible: على فرع/commit منفصل
- Documented: ملاحظة في Backlog

---

## 8. المهام الذرية

### Phase 0 (4 مهام)
- P0.1: استخراج الملفات الحالية (30 د)
- P0.2: تحليل search_screen (1 س)
- P0.3: تحليل home_screen (1 س)
- P0.4: تحليل history + models (1.5 س)

### Phase 1 (8 مهام)
- P1.1: إنشاء مجلدات domain (15 د)
- P1.2: search_query.dart (1 س)
- P1.3: search_result.dart (1 س)
- P1.4: search_filters.dart (1.5 س)
- P1.5: search_error.dart (30 د)
- P1.6: search_repository.dart abstract (1 س)
- P1.7: text_normalizer.dart (2 س)
- P1.8: query_parser.dart (1.5 س)

### Phase 2 (10 مهام)
- P2.1: إنشاء مجلدات firestore (15 د)
- P2.2: firestore_search_mapper.dart (2 س)
- P2.3: _prefixSearch (2 س)
- P2.4: _categoryFilter (1 س)
- P2.5: _applyClientFilters (2 س)
- P2.6: _sortResults (1 س)
- P2.7: suggest() للـ autocomplete (2 س)
- P2.8: recordHistory + getHistory (2 س)
- P2.9: firestore_search_repository.dart كامل (3 س)
- P2.10: unit tests (3 س)

### Phase 3 (12 مهمة)
- P3.1: إنشاء مجلدات features/search/screens (15 د)
- P3.2: explore_controller.dart (2 س)
- P3.3: explore_screen.dart (2 س)
- P3.4: search_bar.dart (2 س)
- P3.5: ربط search_bar بـ controller (1.5 س)
- P3.6: results_list.dart (2 س)
- P3.7: empty_state.dart (1 س)
- P3.8: دمج التصنيفات (2 س)
- P3.9: pagination (3 س)
- P3.10: ربط زر Home بـ Explore (1 س)
- P3.11: اختبار يدوي (2 س)
- P3.12: إصلاح bugs (3 س)

### Phase 4 (8 مهام)
- P4.1: إعادة كتابة search_screen (2 س)
- P4.2: ربط search_bar (1.5 س)
- P4.3: search_controller.dart (2 س)
- P4.4: autocomplete (3 س)
- P4.5: سجل البحث (2 س)
- P4.6: إصلاح info (1 س)
- P4.7: instant search (3 س)
- P4.8: اختبار + إصلاح (3 س)

### Phase 5 (8 مهام)
- P5.1: filter_chips.dart (2 س)
- P5.2: ربط chips (1.5 س)
- P5.3: filter_sheet.dart (3 س)
- P5.4: فلتر Rating (1.5 س)
- P5.5: فلتر Price (1.5 س)
- P5.6: فلتر Open 24h (1 س)
- P5.7: Reset Filters (1 س)
- P5.8: دمج في Explore + Search (3 س)

### Phase 6 (7 مهام)
- P6.1: animations (2 س)
- P6.2: Error handling (2 س)
- P6.3: ربط history service (2 س)
- P6.4: اختبار جهاز حقيقي (3 س)
- P6.5: تحديث firestore.rules (1 س)
- P6.6: docstrings (2 س)
- P6.7: بناء APK (3 س)

---

## 9. الجدول الزمني

### Gantt (18 يوم)
- Phase 0: أيام 1
- Phase 1: أيام 2-3
- Phase 2: أيام 4-6
- Phase 3: أيام 7-10
- Phase 4: أيام 11-13
- Phase 5: أيام 14-16
- Phase 6: أيام 17-18

### Critical Path
P0.1 → P0.2 → P1.6 → P2.9 → P3.10 → P4.2 → P5.8 → P6.7

### مؤشرات المتابعة
| المقياس | المستهدف |
|---------|----------|
| مهام/يوم | 2-3 |
| Commits/يوم | 3-5 |
| PRs/أسبوع | 2-3 |
| Coverage | 70%+ |


---

## 10. معايير النجاح (KPIs)

### تقنية
| KPI | قبل | بعد |
|-----|-----|-----|
| زمن البحث P95 | غير معروف | < 500ms |
| أول نتيجة | غير معروف | < 300ms |
| نتائج صفرية | غير معروف | < 10% |
| Coverage | ~0% | 70%+ |

### تجربة مستخدم
| KPI | قبل | بعد |
|-----|-----|-----|
| خطوات للنتيجة | 4-6 | 2-3 |
| تدفقات | 1 | 3 |
| الفلاتر | 0 | 5+ |
| Autocomplete | لا | نعم |
| History | جزئي | كامل |

### صيانة
- ملفات جديدة: 9
- ملفات معدّلة: 6
- LOC: ~2,500
- Coupling: Low

---

## 11. إدارة المخاطر

| # | المخاطرة | الاحتمال | التأثير | التخفيف |
|---|----------|----------|---------|---------|
| R1 | Firestore محدود | متوسط | عالي | Client-side fallback |
| R2 | تطبيع عربي معقد | متوسط | متوسط | مكتبة + tests |
| R3 | تعارض فروع | منخفض | عالي | فرع منفصل |
| R4 | تغيير schema | منخفض | عالي | Abstract layer |
| R5 | طاقة تطوير | متوسط | متوسط | مهام ذرية |
| R6 | APK size | منخفض | متوسط | ProGuard |

### Rollback
- كل مرحلة على فرع منفصل: feat/search-p0, feat/search-p1, ...
- في حالة مشكلة: git revert <commit>

---

## 12. ملاحق

### المراجع
- Firestore Queries: firebase.google.com/docs/firestore/query-data/queries
- Arabic Normalization: en.wikipedia.org/wiki/Arabic_diacritics

### أوامر مرجعية
للتحليل: find lib -name "*.dart" | grep -E "search|home|model"

### الملفات الجديدة (9)
1. lib/core/search/domain/search_repository.dart
2. lib/core/search/domain/search_query.dart
3. lib/core/search/domain/search_result.dart
4. lib/core/search/domain/search_filters.dart
5. lib/core/search/domain/search_error.dart
6. lib/core/search/data/firestore/firestore_search_repository.dart
7. lib/core/search/data/firestore/firestore_search_mapper.dart
8. lib/core/search/utils/text_normalizer.dart
9. lib/core/search/utils/query_parser.dart

### الملفات المعدّلة (6)
1. lib/screens/home_screen.dart
2. lib/screens/search_screen.dart
3. lib/services/search_history_service.dart
4. lib/features/search/screens/explore_screen.dart
5. firestore.rules
6. pubspec.yaml

### سجل المراجعات
| الإصدار | التاريخ | التغيير |
|---------|---------|---------|
| 1.0 | 2026-10-08 | إنشاء أولي |

---

## الخطوة التالية

1. مراجعة الوثيقة
2. تحديد إدارة الحالة: Provider / Riverpod / Bloc؟
3. تحديد اسم collection: places / businesses؟
4. بدء Phase 0

عند الاتفاق → تنفيذ Phase 0.

---

نهاية الوثيقة
