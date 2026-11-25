// ═══════════════════════════════════════════════════════════════
// إدارة أدوار الأدمن والمشرف من جهازك (مجاناً على Spark، دون واجهة داخل التطبيق).
// يكتب الدور في مستند المستخدم ويضبط Custom Claim مطابقاً له.
//   npm i firebase-admin
//   set GOOGLE_APPLICATION_CREDENTIALS=C:\secure\ya-baladi-service-account.json
//   node admin_roles.js set <البريد> <admin|moderator|merchant|user>
//   node admin_roles.js list           -> يعرض الأدمن والمشرفين
//   node admin_roles.js revoke <البريد> -> يعيده user ويمسح الـ claim
// الـ Custom Claim جاهز لتستخدمه القواعد لاحقاً (request.auth.token.role) بدل get()
// لكل طلب؛ القواعد الحالية ما زالت تقرأ الدور من مستند المستخدم.
// المستخدم يحتاج تسجيل خروج ودخول (أو تحديث الرمز) ليظهر الـ claim.
// ═══════════════════════════════════════════════════════════════
const admin = require('firebase-admin');
admin.initializeApp();
const ROLES = ['admin', 'moderator', 'merchant', 'user'];

async function setRole(email, role) {
  if (!ROLES.includes(role)) throw new Error(`دور غير صالح: ${role}`);
  const u = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(u.uid, role === 'user' ? {} : { role });
  await admin.firestore().doc(`users/${u.uid}`).set({ role }, { merge: true });
  await admin.firestore().collection('audit_logs').add({
    action: 'role_changed', targetUid: u.uid, newRole: role, actorId: 'admin_roles_script',
    actorRole: 'system', createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isArchived: false, isDeleted: false,
  });
  console.log(`تم: ${email} (${u.uid}) ← ${role}`);
}

(async () => {
  const [cmd, a, b] = process.argv.slice(2);
  if (cmd === 'set' && a && b) await setRole(a, b);
  else if (cmd === 'revoke' && a) await setRole(a, 'user');
  else if (cmd === 'list') {
    const snap = await admin.firestore().collection('users').where('role', 'in', ['admin', 'moderator']).get();
    snap.forEach((d) => console.log(d.data().role.padEnd(10), d.data().email || '', d.id));
  } else {
    console.log('الاستخدام: node admin_roles.js set <email> <role> | revoke <email> | list');
    process.exit(1);
  }
})().catch((e) => { console.error(e.message); process.exit(1); });
