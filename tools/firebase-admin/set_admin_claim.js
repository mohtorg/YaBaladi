// tools/firebase-admin/set_admin_claim.js
//
// يمنح Custom Claim للأدمن من بيئة خادمية موثوقة فقط.
// يحافظ على الـclaims الحالية ويضيف admin=true بدل استبدالها.
// لا تستخدم هذا الملف من تطبيق الهاتف.

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

initializeApp({ credential: applicationDefault() });

function arg(name) {
  const index = process.argv.indexOf(`--${name}`);
  return index >= 0 ? process.argv[index + 1] : null;
}

async function main() {
  const email = arg('email');
  const uid = arg('uid');
  if (!email && !uid) {
    throw new Error('Use --email "admin@example.com" or --uid "FIREBASE_UID"');
  }

  const auth = getAuth();
  const user = uid ? await auth.getUser(uid) : await auth.getUserByEmail(email);
  const currentClaims = user.customClaims || {};
  await auth.setCustomUserClaims(user.uid, { ...currentClaims, admin: true });

  console.log(`admin=true set for ${user.email || user.uid}`);
  console.log('The user must sign in again or force-refresh the ID token.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
