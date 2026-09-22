# Firebase Deploy Runbook — Ya Baladi

## قبل النشر
1. احتفظ بالنسخة الاحتياطية التي تم أخذها قبل هذه المرحلة.
2. لا تضع Service Account JSON داخل المشروع أو Git.
3. راجع `firestore.rules` ثم انشره من Firebase Console بعد الاختبار.
4. لا تفعل App Check Enforcement قبل التأكد من نسخة الهاتف.

## Custom Claim للأدمن
استخدم Firebase Admin SDK من بيئة موثوقة لإضافة `admin: true` للحساب الإداري. لا تُنشئ الـclaim من تطبيق الهاتف.

## Firestore
- `places` هو المصدر الموحد للمحتوى المكاني.
- `governorateId` يحدد المحافظة، و`cityId` يحافظ على التوافق الحالي ويمهد للمدن/المراكز.
- `contentType` يفصل دورة تشغيل المحتوى عن `category`.
- `audienceTags` وخصائص المكان قابلة لإعادة الاستخدام عبر كل أنواع المحتوى.

## قبل الإنتاج
- ترحيل المستندات القديمة لإضافة `governorateId` و`isPublished` بشكل صريح.
- بعدها يمكن تشديد `places` إلى القراءة العامة للمحتوى المنشور فقط.
- نقل منح النقاط والتسويات الحساسة إلى Backend موثوق.
