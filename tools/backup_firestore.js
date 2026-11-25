// ═══════════════════════════════════════════════════════════════
// نسخ احتياطي واستعادة Firestore على خطة Spark (مجاناً، من جهازك).
// الاستخدام:
//   npm i firebase-admin
//   set GOOGLE_APPLICATION_CREDENTIALS=C:\secure\ya-baladi-service-account.json
//   node backup_firestore.js backup  [مجلد]      -> ينشئ ملف JSON مؤرّخ
//   node backup_firestore.js restore <ملف.json>  -> يستعيد (يكتب فوق الموجود)
// تنبيه: مفتاح حساب الخدمة سرّ كامل الصلاحية؛ لا يوضع في المشروع ولا في Git.
// أنشئ نسخة يومياً/أسبوعياً، واحفظ نسخة خارج الجهاز (قرص خارجي أو سحابة خاصة).
// ═══════════════════════════════════════════════════════════════
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
admin.initializeApp();
const db = admin.firestore();

// تحويل الأنواع الخاصة إلى JSON قابل للاستعادة.
function enc(v) {
  if (v === null || v === undefined) return v;
  if (v instanceof admin.firestore.Timestamp) return { __t: 'ts', s: v.seconds, n: v.nanoseconds };
  if (v instanceof admin.firestore.GeoPoint) return { __t: 'geo', lat: v.latitude, lng: v.longitude };
  if (v instanceof admin.firestore.DocumentReference) return { __t: 'ref', p: v.path };
  if (Array.isArray(v)) return v.map(enc);
  if (typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)]));
  return v;
}
function dec(v) {
  if (v === null || typeof v !== 'object') return v;
  if (Array.isArray(v)) return v.map(dec);
  if (v.__t === 'ts') return new admin.firestore.Timestamp(v.s, v.n);
  if (v.__t === 'geo') return new admin.firestore.GeoPoint(v.lat, v.lng);
  if (v.__t === 'ref') return db.doc(v.p);
  return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, dec(x)]));
}

// نسخ كل الوثائق بما فيها المجموعات الفرعية (users/{uid}/favorites ...).
async function dumpCollection(colRef, out) {
  const snap = await colRef.get();
  for (const d of snap.docs) {
    out.push({ path: d.ref.path, data: enc(d.data()) });
    for (const sub of await d.ref.listCollections()) await dumpCollection(sub, out);
  }
}

(async () => {
  const [cmd, arg] = process.argv.slice(2);
  if (cmd === 'backup') {
    const out = [];
    for (const c of await db.listCollections()) await dumpCollection(c, out);
    const dir = arg || '.';
    fs.mkdirSync(dir, { recursive: true });
    const file = path.join(dir, `yabaladi_backup_${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
    fs.writeFileSync(file, JSON.stringify(out));
    console.log(`تم: ${out.length} وثيقة -> ${file}`);
  } else if (cmd === 'restore' && arg) {
    const docs = JSON.parse(fs.readFileSync(arg, 'utf8'));
    let batch = db.batch(), n = 0, total = 0;
    for (const d of docs) {
      batch.set(db.doc(d.path), dec(d.data)); n++; total++;
      if (n === 400) { await batch.commit(); batch = db.batch(); n = 0; }
    }
    if (n) await batch.commit();
    console.log(`تمت الاستعادة: ${total} وثيقة`);
  } else {
    console.log('الاستخدام: node backup_firestore.js backup [مجلد] | restore <ملف.json>');
    process.exit(1);
  }
})().catch((e) => { console.error(e); process.exit(1); });
