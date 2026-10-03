# مصفوفة مطابقة يا بلادي — Compliance Matrix

**آخر تحديث:** 2026-10-03

---

## الوثائق الحاكمة

| ID | الوثيقة | الحالة |
|---|---|---|
| DOC-001 | قواعد العمل الهندسي | ✅ APPROVED |
| DOC-002 | سجل خبرة يا بلدي | ✅ APPROVED |
| DOC-003 | حالة المشروع | ✅ APPROVED |
| DOC-004 | بيئات التطوير | ✅ APPROVED |
| DOC-005 | فهرس الوثائق | ✅ APPROVED |
| DOC-006 | معيار هندسة الكود | ✅ APPROVED |
| DOC-007 | الشاشات والأدوار | ✅ APPROVED |
| DOC-008 | صلاحيات Admin/Team | ✅ APPROVED |
| DOC-009 | سياسة الخصوصية | 🟡 DRAFT |
| DOC-010 | GPS Spec | ✅ APPROVED |
| DOC-011 | الشروط والأحكام | 🟡 DRAFT |
| DOC-012 | نظام الاشتراكات | 🟡 REFERENCE |
| DOC-013 | منظومة التفاعل | 🟡 REFERENCE |
| DOC-014 | فلاتر البحث | ✅ APPROVED |
| DOC-015 | الهوية البصرية | ✅ APPROVED |
| DOC-016 | تنسيق العناوين | ✅ APPROVED |
| DOC-017 | Backup & Recovery | ✅ APPROVED |
| DOC-018 | معيار الحوكمة | ✅ APPROVED |

---

## المتطلبات المُنفَّذة

| REQ_ID | المتطلب | Gate | الحالة | الدليل |
|---|---|---|---|---|
| REQ-G0-001 | Clean rebuild | G0 | ✅ VERIFIED | Tag v0.0.1 |
| REQ-G0-002 | GitHub repo | G0 | ✅ VERIFIED | mohtorg/YaBaladi |
| REQ-G1-001 | Flutter builds | G1 | ✅ VERIFIED | APK 148 MB |
| REQ-G1-002 | Firebase setup | G1 | ✅ VERIFIED | Firestore + Rules |
| REQ-G1-003 | App icon | G1 | ✅ VERIFIED | flutter_launcher_icons |
| REQ-G2.1-001 | AR/EN localization | G2.1 | ✅ VERIFIED | Tag v0.2.1 |
| REQ-G2.1-002 | RTL/LTR | G2.1 | ✅ VERIFIED | يعمل فعليًا |
| REQ-G2.2-001 | Design tokens | G2.2 | ✅ VERIFIED | design_tokens.dart |
| REQ-G2.2-002 | Cairo font | G2.2 | ✅ VERIFIED | assets/fonts/ |
| REQ-G2.2-003 | Theme (Light+Dark) | G2.2 | ✅ VERIFIED | app_theme.dart |
| REQ-G2.2-004 | Language picker | G2.2 | ✅ VERIFIED | Dialog + persistence |
| REQ-G2.2-005 | Theme picker | G2.2 | ✅ VERIFIED | Dialog + persistence |
| REQ-G2.2-006 | Settings screen | G2.2 | ✅ VERIFIED | 4 sections |
| REQ-G2.2-007 | Android label | G2.2 | ✅ VERIFIED | "يا بلدي" |

---

## المتطلبات المُعلَّقة

| REQ_ID | المتطلب | Gate | الحالة |
|---|---|---|---|
| REQ-G2.3-001 | go_router | G2.3 | ⏳ NOT_CHECKED |
| REQ-G3-001 | Search | G3 | ⏳ |
| REQ-G3-002 | GPS | G3 | ⏳ |
| REQ-G4-001 | Roles | G4 | ⏳ |
| REQ-G4-002 | Permission matrix | G4 | ⏳ |
| REQ-G5-001 | Admin dashboard | G5 | ⏳ |
| REQ-G5-002 | Audit log | G5 | ⏳ |
| REQ-G6-001 | Ratings | G6 | ⏳ |
| REQ-G6-002 | Offers | G6 | ⏳ |
| REQ-G7-001 | Unit tests | G7 | ⏳ |
| REQ-G7-002 | Accessibility | G7 | ⏳ |

---

## الانحرافات المُثبتة

| ID | الوثيقة | الانحراف | القرار |
|---|---|---|---|
| DEV-001 | Package name | `_rebuild` بدل `yabaladi` | مؤجل بعد G2 |
| DEV-002 | Unit tests | تغطية < 80% | مؤجل G7 |
| DEV-003 | Firestore collections | بعض Collections ناقصة | مؤجل G4 |

---

## إحصائيات الالتزام

| Gate | مكتمل | متبقي | % |
|---|---|---|---|
| G0 | 2 | 0 | 100% |
| G1 | 3 | 0 | 100% |
| G2.1 | 2 | 0 | 100% |
| G2.2 | 7 | 0 | 100% |
| G2.3 | 0 | 3 | 0% |
| G3 | 0 | 5 | 0% |
| G4 | 0 | 4 | 0% |
| G5 | 0 | 3 | 0% |
| G6 | 0 | 4 | 0% |
| G7 | 0 | 5 | 0% |
| **الإجمالي** | **14** | **24** | **37%** |

---

**نهاية مصفوفة المطابقة — الإصدار 1.0**