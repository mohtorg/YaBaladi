// tools/firebase-admin/migrate_places_schema.js
//
// ترحيل آمن ومتكرر التنفيذ لمستندات places القديمة.
// افتراضيًا يعمل Dry Run ولا يكتب شيئًا. استخدم --apply فقط بعد أخذ نسخة احتياطية.
// لا يحذف أي مستند ولا يستبدل حقولًا موجودة؛ يضيف الحقول الجديدة عند غيابها فقط.

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const apply = process.argv.includes('--apply');

function inferContentType(data) {
  if (data.contentType) return null;
  if (data.category === 'فعالية') return 'event';
  if (data.category === 'حديقة') return 'garden';
  if (data.ownerId) return 'service_provider';
  return 'public_place';
}

async function main() {
  const snapshot = await db.collection('places').get();
  let changed = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const updates = {};

    if (!data.governorateId && data.cityId) {
      updates.governorateId = data.cityId;
    }

    const contentType = inferContentType(data);
    if (contentType) updates.contentType = contentType;

    if (typeof data.isPublished !== 'boolean') {
      updates.isPublished = true;
    }

    if (Object.keys(updates).length === 0) continue;

    changed++;
    console.log(`${apply ? 'UPDATE' : 'WOULD UPDATE'} ${doc.id}`, updates);

    if (apply) {
      batch.update(doc.ref, updates);
      batchCount++;
      if (batchCount === 450) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }

  if (apply && batchCount > 0) await batch.commit();
  console.log(`Finished. ${changed} place documents ${apply ? 'updated' : 'would be updated'}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
