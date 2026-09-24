# Ya Baladi — Firebase Admin Tools

## Migration

هذه الأدوات تعمل من بيئة موثوقة فقط. لا تضع Service Account JSON داخل المشروع ولا ترسله لأحد.

### 1) Dry Run

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\firebase-secure\ya-baladi-service-account.json"
cd C:\ya_baladi\tools\firebase-admin
npm install
node migrate_places_schema.js
```

يعرض المستندات التي ستتغير دون كتابة أي شيء.

### 2) Apply

بعد أخذ نسخة احتياطية ومراجعة Dry Run:

```powershell
node migrate_places_schema.js --apply
```

الترحيل:
- يضيف `governorateId` من `cityId` إذا كان مفقودًا.
- يحدد `contentType` عند غيابه.
- يضيف `isPublished: true` للمستندات القديمة حتى لا تختفي من التطبيق.
- لا يحذف أي بيانات ولا يستبدل قيمة موجودة.
