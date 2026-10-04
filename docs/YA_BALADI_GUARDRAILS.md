# 🛡️ قواعد ومحاذير يا بلدي — Guardrails

**الهدف:** مرجع سريع للقواعد الحاكمة عند التطوير اليومي

---

## 10 قواعد ذهبية

1. **لا نبدأ من الصفر** — استمر من آخر نقطة مثبتة
2. **تشخيص → سبب → أقل تعديل → اختبار → تسجيل**
3. **لا تعديل حساس بدون نقطة رجوع**
4. **لا نعيد اختبار ما ثبت إلا بدليل جديد**
5. **افصل بين:** حقيقة / اختبار / افتراض / اقتراح
6. **تعديل واحد في التجربة**
7. **لا ترقية packages بدون سبب**
8. **Auth ≠ Authorization**
9. **إخفاء الزر ليس حماية**
10. **الأولوية:** سلامة → استقرار → وظائف → أداء → شكل

---

## قواعد Git

### قبل أي تغيير
```bash
git status
git log --oneline -5
قبل تغيير حساس
bash
git tag -a vX.Y.Z-<desc> -m "..."
ممنوع بدون مراجعة
git reset --hard

git clean -fd

git push --force

git checkout .

قواعد Firebase
Rules = المصدر الحقيقي

لا تفترض Firebase سبب مشكلة

لا تفتح read/write للعامة

لا تحذف Rule دون اختبار

firestore.rules في Git

تشخيص Permission Denied
العملية (read/create/update/delete)

المسار (collection/document)

الدور + المصادقة

Rule الحالية

الشرط المطلوب

مقارنة مع البيانات

قواعد Dart/Flutter
التسمية
UpperCamelCase للأنواع

lowerCamelCase للمتغيرات

lowercase_with_underscores للملفات

إلزامي
dart format . قبل commit

flutter analyze نظيف

Null safety محترم

ممنوع
! عشوائي

dynamic بدون حاجة

منطق في build()

صلاحيات في UI فقط

APIs deprecated

Future.delayed كحل

قواعد UI/UX
الهوية
هادئة + متوازنة

مساحات بيضاء

البرتقالي للتأكيد

عنصر رئيسي واحد

ممنوع
Gradient مبالغ

Shadows قوية

نصوص < 12

أزرار < 48dp

أكثر من H1

RTL/LTR
النصوص تتغير

الأسهم تنعكس

الأيقونات لا تنعكس

قواعد الأدوار
الدور	الصلاحيات
Visitor	تصفح عام
Member	حساب + مفضلة
Merchant	نشاطه فقط
Team	مهامه
Moderator	مراجعة ضمن النطاق
Manager	إدارة الفريق
Admin	كل شيء
صارم
Moderator ≠ Admin

Member ≠ Team

Permission ≠ Scope

قواعد التوسع
افعل
Events موحدة

Records + Ledger

Rules في Rules

Reuse الموجود

لا تفعل
Collection لكل شاشة

رصيد بدون Ledger

نقاط من الواجهة

مكافأة بفتح الصفحة

تتبع موقع

بيانات شخصية للتاجر

خلط مدفوع/عضوي

Definition of Done
text
[✓] الكود مكتوب + مراجع
[✓] flutter analyze = 0
[✓] flutter test يمر
[✓] APK Debug ناجح
[✓] Commit + push
[✓] سجل الخبرة محدّث
[✓] نقطة رجوع
عند الخطأ
أوقف — لا تعدّل عشوائي

اقرأ الخطأ كاملاً

حدد الطبقة (UI/Logic/Data/Rules)

افحص المسارات والـ imports

أثبت السبب

طبّق أقل تعديل

اختبر

سجّل النتيجة

نهاية القواعد

text

**احفظ.**

---

# 🎯 الخطوة 5 — Commit + Push إلى GitHub

**في CMD:**

```cmd
cd C:\ya_baladi_rebuild

git add docs/YA_BALADI_MASTER_PLAN_v1.0.md
git add docs/YA_BALADI_ROADMAP_40_DAYS.md
git add docs/YA_BALADI_GUARDRAILS.md

git status
المتوقع:

text
new file: docs/YA_BALADI_MASTER_PLAN_v1.0.md
new file: docs/YA_BALADI_ROADMAP_40_DAYS.md
new file: docs/YA_BALADI_GUARDRAILS.md
ثم:

cmd
git commit -m "docs: add master plan, roadmap, and guardrails

- YA_BALADI_MASTER_PLAN_v1.0.md: comprehensive technical plan
  synthesized from 25 governance documents
- YA_BALADI_ROADMAP_40_DAYS.md: day-by-day roadmap to MVP
  (Oct 4 → Nov 14, 2026)
- YA_BALADI_GUARDRAILS.md: quick reference for daily rules
  and constraints

References:
- MVP.md, COMPLIANCE_MATRIX.md, PROJECT_STATE.md
- Engineering Execution Plan v1.0
- Screen Registry + Permission Matrix
- Firebase Operational Security Standard
- Location GPS Spec, Design System, Code Standard
- Backup & Recovery Standard, GitHub WORK/HOME Standard"
ثم:

cmd
git push origin main
ثم:

cmd
git log --oneline -3
المتوقع:

text
<hash> (HEAD -> main, origin/main) docs: add master plan, roadmap, and guardrails
3ed3180 (tag: v0.2.5.1-g2.4-hotfix) fix(G2.4): bug fixes + Profile/Settings cleanup
...
