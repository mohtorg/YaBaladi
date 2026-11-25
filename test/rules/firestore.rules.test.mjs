// اختبارات قواعد Firestore — كل اختبار يمثل سيناريو تلاعب موثّقاً في تقرير الفحص.
// الاختبارات المسمّاة «[ثغرة]» كانت تنجح للمهاجم على القواعد الأصلية (v6.1) وتُرفض الآن.
import { before, after, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, increment } from 'firebase/firestore';
import { createEnv, seed, as } from './helpers.mjs';

let env;
before(async () => { env = await createEnv(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await seed(env); });

describe('places', () => {
  it('[ثغرة] مستخدم عادي لا يُنشئ مكاناً معتمداً', async () => {
    await assertFails(setDoc(doc(as(env, 'user1'), 'places', 'x1'), { ownerId: 'user1', isApproved: true }));
  });
  it('[ثغرة] لا يُنشئ مكاناً بتقييم مصنوع', async () => {
    await assertFails(setDoc(doc(as(env, 'user1'), 'places', 'x2'), { ownerId: 'user1', isApproved: false, reviewCount: 50, averageRating: 5 }));
  });
  it('يُنشئ مكاناً غير معتمد بهويته', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'user1'), 'places', 'x3'), { ownerId: 'user1', isApproved: false, averageRating: 0, reviewCount: 0 }));
  });
  it('المحظور لا يُنشئ مكاناً', async () => {
    await assertFails(setDoc(doc(as(env, 'banned1'), 'places', 'x4'), { ownerId: 'banned1', isApproved: false }));
  });
  it('الأدمن يُنشئ مكاناً معتمداً', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'admin1'), 'places', 'x5'), { ownerId: 'merchant1', isApproved: true }));
  });
  it('الزائر يزيد viewCount بمقدار 1', async () => {
    await assertSucceeds(updateDoc(doc(as(env, null), 'places', 'p1'), { viewCount: increment(1) }));
  });
  it('[ثغرة] الزائر لا يضبط viewCount على قيمة اعتباطية', async () => {
    await assertFails(updateDoc(doc(as(env, null), 'places', 'p1'), { viewCount: 999999 }));
  });
  it('الزائر لا يغيّر averageRating', async () => {
    await assertFails(updateDoc(doc(as(env, null), 'places', 'p1'), { averageRating: 5 }));
  });
  it('مزامنة النظام القديم ضمن النطاق والخطوة تنجح', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 'user1'), 'places', 'p1'), { averageRating: 4.2, reviewCount: 4 }));
  });
  it('[ثغرة] لا يُقفز بـ reviewCount أو يخرج التقييم عن 0–5', async () => {
    await assertFails(updateDoc(doc(as(env, 'user1'), 'places', 'p1'), { reviewCount: 999 }));
    await assertFails(updateDoc(doc(as(env, 'user1'), 'places', 'p1'), { averageRating: 9 }));
  });
  it('المحظور لا يزامن التقييم', async () => {
    await assertFails(updateDoc(doc(as(env, 'banned1'), 'places', 'p1'), { averageRating: 4.1, reviewCount: 4 }));
  });
  it('المالك يعدّل بياناته لكن لا يضبط isRankable ولا subscriptionTier', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 'merchant1'), 'places', 'p1'), { name: 'اسم جديد' }));
    await assertFails(updateDoc(doc(as(env, 'merchant1'), 'places', 'p1'), { isRankable: true }));
    await assertFails(updateDoc(doc(as(env, 'merchant1'), 'places', 'p1'), { subscriptionTier: 'pro' }));
  });
  it('تاجر آخر لا يعدّل مكان غيره', async () => {
    await assertFails(updateDoc(doc(as(env, 'merchant2'), 'places', 'p1'), { name: 'تشويه' }));
  });
});

describe('users', () => {
  it('[ثغرة] لا يُنشئ المستخدم مستنداً بدور أدمن', async () => {
    await assertFails(setDoc(doc(as(env, 'new1'), 'users', 'new1'), { uid: 'new1', role: 'admin' }));
  });
  it('[ثغرة] لا يُنشئ مستنداً بثقة أو عدّاد مرفوع مسبقاً', async () => {
    await assertFails(setDoc(doc(as(env, 'new2'), 'users', 'new2'), { uid: 'new2', role: 'user', trustScore: 5 }));
    await assertFails(setDoc(doc(as(env, 'new2'), 'users', 'new2'), { uid: 'new2', role: 'user', isBanned: true }));
  });
  it('يُنشئ مستنداً بالقيم الابتدائية الصحيحة (كما يفعل AuthController)', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'new3'), 'users', 'new3'), {
      uid: 'new3', email: 'a@b.c', name: 'م', role: 'user', isBanned: false,
      publishedRatingsCount: 0, trustScore: 0.0, hasConfirmedReports: false,
    }));
  });
  it('[ثغرة] المحظور لا يحذف مستنده ليعيد إنشاءه', async () => {
    await assertFails(deleteDoc(doc(as(env, 'banned1'), 'users', 'banned1')));
  });
  it('المستخدم العادي يحذف حسابه (متطلب Play)', async () => {
    await assertSucceeds(deleteDoc(doc(as(env, 'user2'), 'users', 'user2')));
  });
  it('لا يرفع المستخدم confirmedReportsCount ولا merchantVerified', async () => {
    await assertFails(updateDoc(doc(as(env, 'user1'), 'users', 'user1'), { confirmedReportsCount: 9 }));
    await assertFails(updateDoc(doc(as(env, 'user1'), 'users', 'user1'), { merchantVerified: true }));
    await assertFails(updateDoc(doc(as(env, 'user1'), 'users', 'user1'), { role: 'admin' }));
    await assertFails(updateDoc(doc(as(env, 'banned1'), 'users', 'banned1'), { isBanned: false }));
  });
  it('يحدّث fcmToken وتُحفظ رموزه في fcm_tokens (كانت ممنوعة)', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 'user1'), 'users', 'user1'), { fcmToken: 't1' }));
    await assertSucceeds(setDoc(doc(as(env, 'user1'), 'users', 'user1', 'fcm_tokens', 't1'), { token: 't1' }));
    await assertFails(setDoc(doc(as(env, 'user2'), 'users', 'user1', 'fcm_tokens', 't2'), { token: 't2' }));
  });
  it('لا يقرأ مستخدم بيانات غيره', async () => {
    await assertFails(getDoc(doc(as(env, 'user2'), 'users', 'user1')));
  });
});

describe('ratings / visits / reports وفرض الحظر', () => {
  const rating = (uid, extra = {}) => ({ userId: uid, placeId: 'p1', status: 'PUBLISHED', overall: 4, helpfulCount: 0, reportCount: 0, ...extra });
  it('مستخدم عادي يُنشئ تقييماً سليماً', async () => {
    await assertSucceeds(addDoc(collection(as(env, 'user2'), 'ratings'), rating('user2')));
  });
  it('[ثغرة] المحظور لا يُنشئ تقييماً ولا زيارة ولا بلاغاً', async () => {
    await assertFails(addDoc(collection(as(env, 'banned1'), 'ratings'), rating('banned1')));
    await assertFails(addDoc(collection(as(env, 'banned1'), 'visits'), { userId: 'banned1', placeId: 'p1' }));
    await assertFails(addDoc(collection(as(env, 'banned1'), 'reports'), { reporterId: 'banned1', ratingId: 'r1' }));
  });
  it('[ثغرة] لا يُنشئ تقييماً بدرجة خارج 1–5 أو بعدّادات مرفوعة', async () => {
    await assertFails(addDoc(collection(as(env, 'user2'), 'ratings'), rating('user2', { overall: 99 })));
    await assertFails(addDoc(collection(as(env, 'user2'), 'ratings'), rating('user2', { helpfulCount: 500 })));
  });
  it('لا يُنشئ تقييماً باسم غيره', async () => {
    await assertFails(addDoc(collection(as(env, 'user2'), 'ratings'), rating('user1')));
  });
  it('helpful +1 فقط', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 'user2'), 'ratings', 'r1'), { helpfulCount: increment(1) }));
    await assertFails(updateDoc(doc(as(env, 'user2'), 'ratings', 'r1'), { helpfulCount: 50 }));
  });
  it('المشرف يخفي التقييم', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 'mod1'), 'ratings', 'r1'), { status: 'HIDDEN' }));
  });
});

describe('المجموعات التي كانت بلا قواعد', () => {
  it('moderation_logs: المشرف بهويته فقط، ولا تعديل ولا حذف', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'mod1'), 'moderation_logs', 'm1'), { actorId: 'mod1', actionKey: 'hide' }));
    await assertFails(setDoc(doc(as(env, 'mod1'), 'moderation_logs', 'm2'), { actorId: 'admin1', actionKey: 'hide' }));
    await assertFails(setDoc(doc(as(env, 'user1'), 'moderation_logs', 'm3'), { actorId: 'user1' }));
    await assertFails(updateDoc(doc(as(env, 'mod1'), 'moderation_logs', 'm1'), { actionKey: 'x' }));
    await assertFails(deleteDoc(doc(as(env, 'admin1'), 'moderation_logs', 'm1')));
  });
  it('owner_claim_requests: طلب معلّق لنفسه فقط، والأدمن وحده يحسم', async () => {
    const claim = { userId: 'user1', placeId: 'p1', status: 'pending' };
    await assertSucceeds(setDoc(doc(as(env, 'user1'), 'owner_claim_requests', 'c1'), claim));
    await assertFails(setDoc(doc(as(env, 'user1'), 'owner_claim_requests', 'c2'), { ...claim, status: 'approved' }));
    await assertFails(setDoc(doc(as(env, 'user2'), 'owner_claim_requests', 'c3'), claim));
    await assertFails(updateDoc(doc(as(env, 'user1'), 'owner_claim_requests', 'c1'), { status: 'approved' }));
    await assertSucceeds(updateDoc(doc(as(env, 'admin1'), 'owner_claim_requests', 'c1'), { status: 'approved' }));
    await assertFails(getDoc(doc(as(env, 'user2'), 'owner_claim_requests', 'c1')));
  });
  it('rating_revisions: صاحب التقييم يؤرشف، ولا تعديل ولا حذف، والقراءة للإدارة', async () => {
    await assertSucceeds(addDoc(collection(as(env, 'user1'), 'rating_revisions'), { ratingId: 'r1', userId: 'user1', placeId: 'p1' }));
    await assertFails(addDoc(collection(as(env, 'user2'), 'rating_revisions'), { ratingId: 'r1', userId: 'user2', placeId: 'p1' }));
    await assertFails(getDoc(doc(as(env, 'user1'), 'rating_revisions', 'any')));
  });
  it('system_events: إضافة فقط بهوية المشرف/الأدمن', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'admin1'), 'system_events', 'e1'), { actorId: 'admin1', action: 'x' }));
    await assertFails(setDoc(doc(as(env, 'user1'), 'system_events', 'e2'), { actorId: 'user1', action: 'x' }));
    await assertFails(deleteDoc(doc(as(env, 'admin1'), 'system_events', 'e1')));
  });
});

describe('audit_logs: إضافة فقط', () => {
  it('المشرف يُضيف بهويته، ولا أحد يحذف نهائياً', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'mod1'), 'audit_logs', 'a1'), { actorId: 'mod1', action: 'x', isDeleted: false, isArchived: false }));
    await assertFails(setDoc(doc(as(env, 'mod1'), 'audit_logs', 'a2'), { actorId: 'admin1', action: 'تزوير' }));
    await assertFails(deleteDoc(doc(as(env, 'mod1'), 'audit_logs', 'a1')));
    await assertFails(deleteDoc(doc(as(env, 'admin1'), 'audit_logs', 'a1')));
  });
  it('[ثغرة] المشرف لا يعدّل سجلاً ولا يخفيه؛ الأدمن يؤرشف فقط ولا يغيّر المحتوى', async () => {
    await assertSucceeds(setDoc(doc(as(env, 'mod1'), 'audit_logs', 'a3'), { actorId: 'mod1', action: 'x' }));
    await assertFails(updateDoc(doc(as(env, 'mod1'), 'audit_logs', 'a3'), { isDeleted: true }));
    await assertSucceeds(updateDoc(doc(as(env, 'admin1'), 'audit_logs', 'a3'), { isArchived: true }));
    await assertFails(updateDoc(doc(as(env, 'admin1'), 'audit_logs', 'a3'), { action: 'محرَّف' }));
  });
});

describe('notifications وplace_aggregates', () => {
  const n = (extra = {}) => ({ userId: 'user2', title: 'عنوان', body: 'نص', type: 'x', ...extra });
  it('[ثغرة] المستخدم لا يبثّ إشعاراً للجميع', async () => {
    await assertFails(addDoc(collection(as(env, 'user1'), 'notifications'), n({ userId: 'all' })));
  });
  it('الأدمن يبثّ للجميع، والمستخدم يُرسل لمستخدم محدد بحدود طول', async () => {
    await assertSucceeds(addDoc(collection(as(env, 'admin1'), 'notifications'), n({ userId: 'all' })));
    await assertSucceeds(addDoc(collection(as(env, 'user1'), 'notifications'), n()));
    await assertFails(addDoc(collection(as(env, 'user1'), 'notifications'), n({ title: '' })));
    await assertFails(addDoc(collection(as(env, 'user1'), 'notifications'), n({ body: 'ا'.repeat(501) })));
    await assertFails(addDoc(collection(as(env, 'banned1'), 'notifications'), n()));
  });
  it('place_aggregates: لا كتابة لمكان غير موجود ولا للمحظور', async () => {
    await assertFails(setDoc(doc(as(env, 'user1'), 'place_aggregates', 'ghost'), { total: 1 }));
    await assertFails(setDoc(doc(as(env, 'banned1'), 'place_aggregates', 'p1'), { total: 1 }));
    await assertSucceeds(setDoc(doc(as(env, 'user1'), 'place_aggregates', 'p1'), { total: 1 }));
  });
});
