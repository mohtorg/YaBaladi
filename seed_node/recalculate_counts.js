// seed_node/recalculate_counts.js
//
// يعيد حساب حقل placesCount في كل تصنيف
// بناءً على العدد الفعلي للأماكن في مجموعة places.
//
// ✅ Idempotent — يمكن تشغيله عدة مرات دون مشاكل.
// ✅ آمن — يستخدم batch.commit() (atomic).
// ✅ يطبع تقريراً كاملاً قبل التحديث وبعده.
//
// التشغيل:
//   cd C:\ya_baladi_rebuild\seed_node
//   node recalculate_counts.js

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');

// ═══ تهيئة Firebase Admin ═══
const app = initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore(app);

async function recalculate() {
  console.log('');
  console.log('═══════════════════════════════════════════════');
  console.log('  🔄 recalculate placesCount');
  console.log('═══════════════════════════════════════════════');
  console.log('');

  // ─── 1. حساب عدد الأماكن لكل تصنيف ───
  console.log('📖 جاري قراءة الأماكن من Firestore...');
  const placesSnap = await db.collection('places').get();
  console.log(`   → وُجد ${placesSnap.size} مكان.`);
  console.log('');

  const counts = {};
  placesSnap.forEach((doc) => {
    const data = doc.data();
    const catId = data.categoryId || data.category || 'other';
    counts[catId] = (counts[catId] || 0) + 1;
  });

  // ─── 2. طباعة التوزيع الحالي ───
  console.log('📊 التوزيع الحالي للأماكن:');
  Object.keys(counts)
    .sort((a, b) => counts[b] - counts[a])
    .forEach((catId) => {
      console.log(`   ${catId.padEnd(15)} → ${counts[catId]} مكان`);
    });
  console.log('');

  // ─── 3. قراءة التصنيفات وتحديث placesCount ───
  console.log('📝 جاري تحديث التصنيفات...');
  const categoriesSnap = await db.collection('categories').get();
  console.log(`   → وُجد ${categoriesSnap.size} تصنيف.`);
  console.log('');

  const batch = db.batch();
  let updatedCount = 0;
  let unchangedCount = 0;

  categoriesSnap.forEach((doc) => {
    const newCount = counts[doc.id] || 0;
    const currentCount = doc.data().placesCount || 0;

    if (currentCount !== newCount) {
      batch.update(doc.ref, { placesCount: newCount });
      console.log(`   ✅ ${doc.id.padEnd(15)} ${currentCount} → ${newCount}`);
      updatedCount++;
    } else {
      console.log(`   ⏭️  ${doc.id.padEnd(15)} ${newCount} (لا تغيير)`);
      unchangedCount++;
    }
  });

  // ─── 4. Commit ───
  console.log('');
  if (updatedCount > 0) {
    await batch.commit();
    console.log(`🎉 تم تحديث ${updatedCount} تصنيف بنجاح.`);
  } else {
    console.log('✨ جميع الأعداد صحيحة بالفعل — لا حاجة للتحديث.');
  }

  console.log(`   (${unchangedCount} تصنيف بدون تغيير)`);
  console.log('');
  console.log('═══════════════════════════════════════════════');
  console.log('  ✅ اكتمل التشغيل بنجاح.');
  console.log('═══════════════════════════════════════════════');
  console.log('');
}

recalculate()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('');
    console.error('❌ خطأ:');
    console.error(err);
    process.exit(1);
  });