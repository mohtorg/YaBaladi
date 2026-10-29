// seed_node/normalize_categories.js
//
// يوحّد categoryId لجميع الأماكن ليطابق 9 تصنيفات معتمدة.
//
// يحل:
//   - مفرد → جمع (restaurant → restaurants)
//   - عربي → إنجليزي (مطعم → restaurants)
//   - تصنيفات شاذة (attraction → landmarks)
//   - Places بـ `category` بدلاً من `categoryId` → يضيف categoryId
//
// ✅ Idempotent — يمكن تشغيله عدة مرات.
// ⚠️  يطبع تقريراً بكل مكان سيُعدّل قبل الحفظ.

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');
const app = initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore(app);

// ═══ خريطة التطبيع ═══
const NORMALIZE = {
  // مفرد → جمع
  'restaurant': 'restaurants',
  'cafe': 'cafes',
  'hotel': 'hotels',
  'beach': 'beaches',
  'park': 'parks',
  'event': 'events',
  'landmark': 'landmarks',
  'shop': 'shopping',
  'store': 'shopping',
  'mall': 'shopping',

  // synonyms
  'attraction': 'landmarks',
  'attractions': 'landmarks',
  'monument': 'landmarks',
  'historic': 'landmarks',
  'coffee': 'cafes',
  'restaurants_food': 'restaurants',
  'food': 'restaurants',
  'dining': 'restaurants',

  // عربي → إنجليزي
  'مطعم': 'restaurants',
  'مطاعم': 'restaurants',
  'مقهى': 'cafes',
  'مقاهي': 'cafes',
  'كافيه': 'cafes',
  'كافيهات': 'cafes',
  'قهوة': 'cafes',
  'شاطئ': 'beaches',
  'شواطئ': 'beaches',
  'بلاج': 'beaches',
  'فندق': 'hotels',
  'فنادق': 'hotels',
  'منتجع': 'hotels',
  'حديقة': 'parks',
  'حدائق': 'parks',
  'متنزه': 'parks',
  'فعالية': 'events',
  'فعاليات': 'events',
  'معلم': 'landmarks',
  'معالم': 'landmarks',
  'اثري': 'landmarks',
  'تسوق': 'shopping',
  'مول': 'shopping',
  'متجر': 'shopping',
  'ترفيه': 'family',
  'عائلي': 'family',
};

const VALID_SLUGS = [
  'restaurants', 'cafes', 'beaches', 'hotels',
  'family', 'landmarks', 'shopping', 'parks', 'events',
];

async function normalize() {
  console.log('');
  console.log('═══════════════════════════════════════════════');
  console.log('  🔧 normalize categoryId in places');
  console.log('═══════════════════════════════════════════════');
  console.log('');

  const placesSnap = await db.collection('places').get();
  console.log(`📖 قراءة ${placesSnap.size} مكان...\n`);

  const batch = db.batch();
  let updated = 0;
  let skipped = 0;
  const report = [];

  placesSnap.forEach((doc) => {
    const data = doc.data();
    const rawId = data.categoryId || data.category || '';

    // ─── التطبيع ───
    let normalizedId = rawId.trim().toLowerCase();

    // 1. تحقق من الخريطة (مفرد، عربي، synonyms)
    if (NORMALIZE[rawId.trim()]) {
      normalizedId = NORMALIZE[rawId.trim()];
    } else if (NORMALIZE[normalizedId]) {
      normalizedId = NORMALIZE[normalizedId];
    }

    // 2. تحقق أنه slug صالح
    if (!VALID_SLUGS.includes(normalizedId)) {
      // تصنيف غير معروف
      report.push({
        id: doc.id,
        name: data.nameAr || data.nameEn || doc.id,
        from: rawId,
        to: '⚠️  (غير معروف — يحتاج تدخل يدوي)',
        action: 'skip',
      });
      skipped++;
      return;
    }

    // 3. هل يحتاج تعديل؟
    const needsUpdate =
      rawId !== normalizedId || !data.categoryId || data.category;

    if (needsUpdate) {
      batch.update(doc.ref, {
        categoryId: normalizedId,
        // إزالة الحقل القديم
        ...(data.category && !data.categoryId ? {} : { category: null }),
      });
      report.push({
        id: doc.id,
        name: data.nameAr || data.nameEn || doc.id,
        from: rawId,
        to: normalizedId,
        action: 'update',
      });
      updated++;
    } else {
      skipped++;
    }
  });

  // ─── طباعة التقرير ───
  console.log('📋 التعديلات المطلوبة:\n');
  report.forEach((r) => {
    if (r.action === 'update') {
      console.log(`   ✅ ${r.id.padEnd(25)} "${r.from}" → "${r.to}"`);
    } else {
      console.log(`   ⚠️  ${r.id.padEnd(25)} "${r.from}" ${r.to}`);
    }
  });

  console.log('');
  console.log(`📊 ملخص: ${updated} تعديل، ${skipped} بدون تعديل.`);

  // ─── Commit ───
  if (updated > 0) {
    console.log('\n💾 جاري حفظ التعديلات...');
    await batch.commit();
    console.log('✅ تم الحفظ بنجاح.');
  } else {
    console.log('\n✨ لا حاجة لأي تعديل.');
  }

  console.log('');
  console.log('═══════════════════════════════════════════════');
  console.log('  ✅ اكتمل التطبيع.');
  console.log('═══════════════════════════════════════════════');
  console.log('');
}

normalize()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('\n❌ خطأ:', err);
    process.exit(1);
  });