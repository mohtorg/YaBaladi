// ═══════════════════════════════════════════════════════════════
// اختبارات قواعد YaBaladi (الجولة 1 — حزم P0-أ إلى P0-د)
// الغاية: كل محاولة محظورة تفشل، وكل مسار مشروع يعمل بدوره الصحيح.
// التشغيل:  npm install && npm test            (على القواعد الجديدة)
//           npm run test:baseline              (على القواعد الأصلية: يجب أن تفشل اختبارات الثغرات)
// ═══════════════════════════════════════════════════════════════
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, serverTimestamp, getDocs, query, where } from 'firebase/firestore';
import { ref, uploadBytes, deleteObject } from 'firebase/storage';
import { beforeAll, afterAll, beforeEach, describe, test } from 'vitest';

const useBaseline = process.env.RULES_DIR === 'baseline';
const fsRules = useBaseline ? resolve('baseline/firestore.rules') : resolve('../firestore.rules');
const stRules = useBaseline ? resolve('baseline/storage.rules') : resolve('../storage.rules');

let env;
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-yabaladi',
    firestore: { rules: readFileSync(fsRules, 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: readFileSync(stRules, 'utf8'), host: '127.0.0.1', port: 9199 },
  });
});
afterAll(async () => { await env.cleanup(); });

// ─── بيانات أساسية: أدمن، مشرف، تاجر مالك للمكان p1، مستخدمان، مستخدم محظور ───
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const base = { createdAt: new Date(), isBanned: false, publishedRatingsCount: 0, trustScore: 0, hasConfirmedReports: false };
    await setDoc(doc(db, 'users/admin1'), { ...base, role: 'admin', email: 'a@x.com' });
    await setDoc(doc(db, 'users/mod1'), { ...base, role: 'moderator', email: 'm@x.com' });
    await setDoc(doc(db, 'users/merchant1'), { ...base, role: 'merchant', email: 'mr@x.com' });
    await setDoc(doc(db, 'users/user1'), { ...base, role: 'user', email: 'u1@x.com' });
    await setDoc(doc(db, 'users/user2'), { ...base, role: 'user', email: 'u2@x.com' });
    await setDoc(doc(db, 'users/banned1'), { ...base, role: 'user', isBanned: true, email: 'b@x.com' });
    await setDoc(doc(db, 'places/p1'), {
      ownerId: 'merchant1', isApproved: true, averageRating: 4, reviewCount: 3, viewCount: 10,
      adjustedScore: 3.9, sampleQuality: 0.5, isRankable: true, nameAr: 'مكان',
    });
    await setDoc(doc(db, 'ratings/r1'), {
      userId: 'user1', placeId: 'p1', status: 'PUBLISHED', overall: 4, helpfulCount: 0, reportCount: 0,
      createdAt: new Date(),
    });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

// ═══════════════ P0-أ: places ═══════════════
describe('P0-أ places', () => {
  test('✗ مجهول لا يزيد viewCount', async () => {
    await assertFails(updateDoc(doc(anon(), 'places/p1'), { viewCount: 11 }));
  });
  test('✓ مسجّل يزيد viewCount بمقدار 1', async () => {
    await assertSucceeds(updateDoc(doc(as('user1'), 'places/p1'), { viewCount: 11 }));
  });
  test('✗ مسجّل لا يقفز بـ viewCount', async () => {
    await assertFails(updateDoc(doc(as('user1'), 'places/p1'), { viewCount: 99999 }));
  });
  test('✗ مسجّل لا يضع averageRating خارج 0..5', async () => {
    await assertFails(updateDoc(doc(as('user1'), 'places/p1'), { averageRating: 50 }));
  });
  test('✗ مسجّل لا يقفز بـ reviewCount أكثر من 1', async () => {
    await assertFails(updateDoc(doc(as('user1'), 'places/p1'), { reviewCount: 500 }));
  });
  test('✓ مسار AggregateService المشروع: خطوة 1 ضمن النطاق', async () => {
    await assertSucceeds(updateDoc(doc(as('user1'), 'places/p1'), {
      averageRating: 4.1, reviewCount: 4, adjustedScore: 3.95, sampleQuality: 0.6, isRankable: true,
    }));
  });
  test('✗ مسجّل لا يغيّر حقول أخرى مع التقييم (مثل ownerId)', async () => {
    await assertFails(updateDoc(doc(as('user1'), 'places/p1'), { ownerId: 'user1' }));
  });
  test('✗ تاجر لا يعتمد مكانه ولا يعدّل حقول التقييم', async () => {
    await assertFails(updateDoc(doc(as('merchant1'), 'places/p1'), { isApproved: false }));
    await assertFails(updateDoc(doc(as('merchant1'), 'places/p1'), { adjustedScore: 5 }));
  });
  test('✓ تاجر يعدّل بيانات مكانه العادية', async () => {
    await assertSucceeds(updateDoc(doc(as('merchant1'), 'places/p1'), { phone: '0123' }));
  });
  test('✗ مستخدم عادي لا ينشئ مكاناً معتمداً', async () => {
    await assertFails(setDoc(doc(as('user1'), 'places/p2'), { ownerId: 'user1', isApproved: true }));
  });
  test('✗ إنشاء مكان بتقييم مصطنع', async () => {
    await assertFails(setDoc(doc(as('user1'), 'places/p2'), { ownerId: 'user1', isApproved: false, averageRating: 5, reviewCount: 100 }));
  });
  test('✓ إنشاء مكان غير معتمد بعدادات صفرية (مسار التاجر)', async () => {
    await assertSucceeds(setDoc(doc(as('user1'), 'places/p2'), {
      ownerId: 'user1', isApproved: false, averageRating: 0.0, reviewCount: 0, nameAr: 'جديد',
    }));
  });
  test('✓ الأدمن ينشئ مكاناً معتمداً', async () => {
    await assertSucceeds(setDoc(doc(as('admin1'), 'places/p3'), { ownerId: 'admin1', isApproved: true }));
  });
});

// ═══════════════ P0-ب: users ═══════════════
describe('P0-ب users', () => {
  const fresh = (over = {}) => ({
    uid: 'newbie', email: 'n@x.com', name: 'جديد', role: 'user', isBanned: false,
    publishedRatingsCount: 0, trustScore: 0.0, hasConfirmedReports: false, createdAt: serverTimestamp(), ...over,
  });
  test('✓ إنشاء مستند بقيم ابتدائية صحيحة (مسار التطبيق)', async () => {
    await assertSucceeds(setDoc(doc(as('newbie'), 'users/newbie'), fresh()));
  });
  test('✗ إنشاء بدور أدمن', async () => {
    await assertFails(setDoc(doc(as('newbie'), 'users/newbie'), fresh({ role: 'admin' })));
  });
  test('✗ إنشاء بثقة أو عدّاد مضخّم', async () => {
    await assertFails(setDoc(doc(as('newbie'), 'users/newbie'), fresh({ trustScore: 99 })));
    await assertFails(setDoc(doc(as('newbie'), 'users/newbie'), fresh({ publishedRatingsCount: 500 })));
    await assertFails(setDoc(doc(as('newbie'), 'users/newbie'), fresh({ merchantVerified: true })));
    await assertFails(setDoc(doc(as('newbie'), 'users/newbie'), fresh({ subscriptionTier: 'pro' })));
  });
  test('✗ مستخدم يرفع دوره أو يفك حظره أو يوثّق نفسه', async () => {
    await assertFails(updateDoc(doc(as('user1'), 'users/user1'), { role: 'admin' }));
    await assertFails(updateDoc(doc(as('banned1'), 'users/banned1'), { isBanned: false }));
    await assertFails(updateDoc(doc(as('user1'), 'users/user1'), { merchantVerified: true }));
    await assertFails(updateDoc(doc(as('user1'), 'users/user1'), { confirmedReportsCount: 0, subscriptionTier: 'pro' }));
  });
  test('✓ مسار دفتر التقييم: +1 ومعامل ثقة معقول', async () => {
    await assertSucceeds(updateDoc(doc(as('user1'), 'users/user1'), {
      publishedRatingsCount: 1, userTrustFactor: 0.8, lastRatedAt: serverTimestamp(),
    }));
  });
  test('✗ دفتر التقييم: قفزة العداد أو معامل ثقة خارج النطاق', async () => {
    await assertFails(updateDoc(doc(as('user1'), 'users/user1'), { publishedRatingsCount: 50 }));
    await assertFails(updateDoc(doc(as('user1'), 'users/user1'), { userTrustFactor: 99 }));
  });
  test('✓ تعديل الاسم العادي', async () => {
    await assertSucceeds(updateDoc(doc(as('user1'), 'users/user1'), { name: 'اسم جديد' }));
  });
  test('✗ المحظور لا يحذف مستنده (تهرّب من الحظر)', async () => {
    await assertFails(deleteDoc(doc(as('banned1'), 'users/banned1')));
  });
  test('✓ غير المحظور يحذف حسابه (حق المستخدم)', async () => {
    await assertSucceeds(deleteDoc(doc(as('user2'), 'users/user2')));
  });
  test('✗ مستخدم لا يقرأ مستند غيره', async () => {
    await assertFails(getDoc(doc(as('user1'), 'users/user2')));
  });
  test('✓ رموز FCM: لصاحبها فقط', async () => {
    await assertSucceeds(setDoc(doc(as('user1'), 'users/user1/fcm_tokens/tok1'), { token: 'tok1' }));
    await assertFails(setDoc(doc(as('user2'), 'users/user1/fcm_tokens/tok2'), { token: 'tok2' }));
    await assertFails(getDoc(doc(as('user2'), 'users/user1/fcm_tokens/tok1')));
  });
});

// ═══════════════ P0-ج: مجموعات بلا قواعد + audit_logs ═══════════════
describe('P0-ج مجموعات الإشراف والتدقيق', () => {
  test('✓ طلب استلام مكان: ينشئه صاحبه بحالة pending', async () => {
    await assertSucceeds(addDoc(collection(as('user1'), 'owner_claim_requests'), {
      placeId: 'p1', placeName: 'مكان', userId: 'user1', userDisplayName: 'أ', userEmail: 'u1@x.com',
      evidenceType: 'other', evidenceImageUrls: [], status: 'pending', createdAt: serverTimestamp(),
    }));
  });
  test('✗ طلب استلام بحالة approved أو بانتحال مستخدم آخر', async () => {
    const base = { placeId: 'p1', placeName: 'م', userDisplayName: 'أ', userEmail: 'x@x.com', evidenceType: 'other', evidenceImageUrls: [], createdAt: serverTimestamp() };
    await assertFails(addDoc(collection(as('user1'), 'owner_claim_requests'), { ...base, userId: 'user1', status: 'approved' }));
    await assertFails(addDoc(collection(as('user1'), 'owner_claim_requests'), { ...base, userId: 'user2', status: 'pending' }));
  });
  test('✗ المستخدم لا يعتمد طلبه، ✓ الأدمن يعتمد', async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(doc(c.firestore(), 'owner_claim_requests/c1'), { userId: 'user1', placeId: 'p1', status: 'pending' });
    });
    await assertFails(updateDoc(doc(as('user1'), 'owner_claim_requests/c1'), { status: 'approved' }));
    await assertSucceeds(updateDoc(doc(as('admin1'), 'owner_claim_requests/c1'), { status: 'approved' }));
  });
  test('✓ المشرف يكتب moderation_logs بهويته، ✗ لا يعدّلها ولا يحذفها', async () => {
    const d = doc(as('mod1'), 'moderation_logs/l1');
    await assertSucceeds(setDoc(d, { actionKey: 'hide', actorId: 'mod1', createdAt: serverTimestamp() }));
    await assertFails(updateDoc(d, { actionKey: 'x' }));
    await assertFails(deleteDoc(d));
  });
  test('✗ مستخدم عادي لا يكتب moderation_logs ولا system_events', async () => {
    await assertFails(setDoc(doc(as('user1'), 'moderation_logs/l2'), { actorId: 'user1' }));
    await assertFails(setDoc(doc(as('user1'), 'system_events/e1'), { actorId: 'user1' }));
  });
  test('✓ rating_revisions: ينشئها صاحب التقييم فقط ولا تُعدَّل', async () => {
    await assertSucceeds(setDoc(doc(as('user1'), 'rating_revisions/v1'), { userId: 'user1', ratingId: 'r1' }));
    await assertFails(setDoc(doc(as('user2'), 'rating_revisions/v2'), { userId: 'user1', ratingId: 'r1' }));
    await assertFails(updateDoc(doc(as('user1'), 'rating_revisions/v1'), { ratingId: 'zz' }));
  });
  test('✓ audit_logs: المشرف يضيف ويؤرشف', async () => {
    const d = doc(as('mod1'), 'audit_logs/a1');
    await assertSucceeds(setDoc(d, { action: 'x', actorId: 'mod1', isArchived: false, isDeleted: false }));
    await assertSucceeds(updateDoc(d, { isArchived: true, archivedAt: serverTimestamp() }));
  });
  test('✗ audit_logs: لا حذف نهائي ولا تعديل محتوى، ولا انتحال actorId', async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(doc(c.firestore(), 'audit_logs/a2'), { action: 'x', actorId: 'admin1', isArchived: false });
    });
    await assertFails(deleteDoc(doc(as('admin1'), 'audit_logs/a2')));
    await assertFails(updateDoc(doc(as('mod1'), 'audit_logs/a2'), { action: 'مزوَّر' }));
    await assertFails(setDoc(doc(as('mod1'), 'audit_logs/a3'), { action: 'x', actorId: 'admin1' }));
  });
});

// ═══════════════ P0-د: الإشعارات + ratings + place_aggregates + التخزين ═══════════════
describe('P0-د إشعارات وتقييمات وتخزين', () => {
  test('✗ مستخدم عادي لا ينشئ إشعاراً لأي أحد، ✓ المشرف ينشئ', async () => {
    await assertFails(addDoc(collection(as('user1'), 'notifications'), { userId: 'user2', title: 't', body: 'b', type: 'x' }));
    await assertFails(addDoc(collection(as('user1'), 'notifications'), { userId: 'all', title: 't', body: 'b', type: 'x' }));
    await assertSucceeds(addDoc(collection(as('mod1'), 'notifications'), { userId: 'user2', title: 't', body: 'b', type: 'x' }));
  });
  test('✓ إنشاء تقييم بقيم ابتدائية صحيحة', async () => {
    await assertSucceeds(setDoc(doc(as('user2'), 'ratings/user2_p1'), {
      userId: 'user2', placeId: 'p1', status: 'PUBLISHED', overall: 5, helpfulCount: 0, reportCount: 0,
    }));
  });
  test('✗ إنشاء تقييم بعدّادات مضخّمة أو بتقييم خارج النطاق أو باسم غيره', async () => {
    const ok = { userId: 'user2', placeId: 'p1', status: 'PUBLISHED', overall: 5, helpfulCount: 0, reportCount: 0 };
    await assertFails(setDoc(doc(as('user2'), 'ratings/user2_p1'), { ...ok, helpfulCount: 100 }));
    await assertFails(setDoc(doc(as('user2'), 'ratings/user2_p1'), { ...ok, overall: 9 }));
    await assertFails(setDoc(doc(as('user2'), 'ratings/user2_p1'), { ...ok, userId: 'user1' }));
  });
  test('✓ التاجر مالك المكان يردّ على تقييم، ✗ لا يغيّر غير حقلي الردّ ولا يردّ على مكان غيره', async () => {
    await assertSucceeds(updateDoc(doc(as('merchant1'), 'ratings/r1'), { merchantReply: 'شكراً', merchantRepliedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('merchant1'), 'ratings/r1'), { overall: 1 }));
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(doc(c.firestore(), 'places/p9'), { ownerId: 'someoneelse', isApproved: true });
      await setDoc(doc(c.firestore(), 'ratings/r9'), { userId: 'user1', placeId: 'p9', status: 'PUBLISHED', overall: 3, helpfulCount: 0, reportCount: 0 });
    });
    await assertFails(updateDoc(doc(as('merchant1'), 'ratings/r9'), { merchantReply: 'x' }));
  });
  test('✗ تاجر لا ينشئ فرعاً معتمداً، ✓ ينشئه غير معتمد', async () => {
    await assertFails(setDoc(doc(as('merchant1'), 'places/b1'), { ownerId: 'merchant1', isApproved: true, averageRating: 0, reviewCount: 0 }));
    await assertSucceeds(setDoc(doc(as('merchant1'), 'places/b2'), { ownerId: 'merchant1', isApproved: false, averageRating: 0, reviewCount: 0 }));
  });
  test('✗ تاجر لا يبثّ إشعاراً للجميع', async () => {
    await assertFails(addDoc(collection(as('merchant1'), 'notifications'), { userId: 'all', title: 'عرض', body: 'x', type: 'newOffer' }));
  });
  test('✗ مالك المكان لا يقيّم مكانه عبر API مباشر', async () => {
    await assertFails(setDoc(doc(as('merchant1'), 'ratings/merchant1_p1'), {
      userId: 'merchant1', placeId: 'p1', status: 'PUBLISHED', overall: 5, helpfulCount: 0, reportCount: 0,
    }));
  });
  test('✗ تقييم بمعرّف عشوائي (تكرار لنفس المكان) يُرفض', async () => {
    await assertFails(setDoc(doc(as('user2'), 'ratings/random123'), {
      userId: 'user2', placeId: 'p1', status: 'PUBLISHED', overall: 5, helpfulCount: 0, reportCount: 0,
    }));
  });
  test('✗ نص تقييم ضخم يُرفض', async () => {
    await assertFails(setDoc(doc(as('user2'), 'ratings/user2_p1'), {
      userId: 'user2', placeId: 'p1', status: 'PUBLISHED', overall: 5, helpfulCount: 0, reportCount: 0, body: 'x'.repeat(5000),
    }));
  });
  test('✓ صاحب التقييم يعدّل تقييمه، ✗ لا يغيّر الحالة ولا يعدّل تقييم غيره', async () => {
    await assertSucceeds(updateDoc(doc(as('user1'), 'ratings/r1'), { overall: 5, body: 'محدّث' }));
    await assertFails(updateDoc(doc(as('user1'), 'ratings/r1'), { status: 'HIDDEN' }));
    await assertFails(updateDoc(doc(as('user2'), 'ratings/r1'), { overall: 1 }));
  });
  test('✗ place_aggregates: قفزة العدد أو متوسط خارج النطاق', async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(doc(c.firestore(), 'place_aggregates/p1'), { totalRatings: 3, averageOverall: 4 });
    });
    await assertFails(updateDoc(doc(as('user1'), 'place_aggregates/p1'), { totalRatings: 300 }));
    await assertFails(updateDoc(doc(as('user1'), 'place_aggregates/p1'), { averageOverall: 9 }));
    await assertSucceeds(updateDoc(doc(as('user1'), 'place_aggregates/p1'), { totalRatings: 4, averageOverall: 4.2 }));
  });
  // ── التخزين ──
  const img = () => new Uint8Array([1, 2, 3]);
  test('✗ مسجّل لا يكتب على صور مكان لا يملكه (إتلاف صور الغير)', async () => {
    const st = env.authenticatedContext('user1').storage();
    await assertFails(uploadBytes(ref(st, 'places/p1/cover.jpg'), img(), { contentType: 'image/jpeg' }));
  });
  test('✓ مالك المكان والأدمن يرفعان الصور', async () => {
    await assertSucceeds(uploadBytes(ref(env.authenticatedContext('merchant1').storage(), 'places/p1/a.jpg'), img(), { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(ref(env.authenticatedContext('admin1').storage(), 'places/p1/b.jpg'), img(), { contentType: 'image/jpeg' }));
  });
  test('✗ رفع غير صورة، ✗ حذف غير المالك', async () => {
    await assertFails(uploadBytes(ref(env.authenticatedContext('merchant1').storage(), 'places/p1/x.pdf'), img(), { contentType: 'application/pdf' }));
    await assertFails(deleteObject(ref(env.authenticatedContext('user1').storage(), 'places/p1/a.jpg')));
  });
  test('✓ صور المستخدم لصاحبها فقط', async () => {
    await assertSucceeds(uploadBytes(ref(env.authenticatedContext('user1').storage(), 'users/user1/me.jpg'), img(), { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(env.authenticatedContext('user2').storage(), 'users/user1/me.jpg'), img(), { contentType: 'image/jpeg' }));
  });
});

describe('رحلات المستخدم trip_plans', () => {
  test('✓ المستخدم يستعلم عن رحلاته (where userId) ✗ لا يستعلم بمعرّف غيره', async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(doc(c.firestore(), 'trip_plans/t1'), { userId: 'user1', status: 'draft', stops: [] });
    });
    const db = env.authenticatedContext('user1').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'trip_plans'), where('userId', '==', 'user1'))));
    await assertFails(getDocs(query(collection(db, 'trip_plans'), where('userId', '==', 'user2'))));
  });
  test('✗ تغيير userId عند التحديث، ✗ أكثر من 50 محطة', async () => {
    const db = env.authenticatedContext('user1').firestore();
    await assertFails(updateDoc(doc(db, 'trip_plans/t1'), { userId: 'user2', status: 'draft', stops: [] }));
    await assertFails(setDoc(doc(db, 'trip_plans/t2'), { userId: 'user1', status: 'draft', stops: Array(51).fill({}) }));
  });
});
