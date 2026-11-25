// اختبارات قواعد Storage — تتطلب تشغيل محاكيي Firestore وStorage معاً (للتحقق عبر firestore.get).
import { before, after, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, deleteObject } from 'firebase/storage';
import { createEnv, seed } from './helpers.mjs';

let env;
before(async () => { env = await createEnv(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await seed(env); });

const st = (id) => (id ? env.authenticatedContext(id).storage() : env.unauthenticatedContext().storage());
const bytes = (n = 10) => new Uint8Array(n);
const jpeg = { contentType: 'image/jpeg' };

describe('/places/{placeId}', () => {
  it('[ثغرة] مستخدم غريب لا يكتب صوراً في مكان غيره', async () => {
    await assertFails(uploadBytes(ref(st('user1'), 'places/p1/a.jpg'), bytes(), jpeg));
  });
  it('تاجر آخر لا يكتب فوق صور المالك', async () => {
    await assertFails(uploadBytes(ref(st('merchant2'), 'places/p1/a.jpg'), bytes(), jpeg));
  });
  it('المالك والأدمن يرفعان صوراً', async () => {
    await assertSucceeds(uploadBytes(ref(st('merchant1'), 'places/p1/a.jpg'), bytes(), jpeg));
    await assertSucceeds(uploadBytes(ref(st('admin1'), 'places/p1/b.jpg'), bytes(), jpeg));
  });
  it('المالك المحظور لا يرفع', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const { doc, updateDoc } = await import('firebase/firestore');
      await updateDoc(doc(ctx.firestore(), 'places', 'p1'), { ownerId: 'banned1' });
    });
    await assertFails(uploadBytes(ref(st('banned1'), 'places/p1/a.jpg'), bytes(), jpeg));
  });
  it('يُرفض SVG وكل ما ليس JPEG/PNG/WebP، ويُرفض ما فوق 5MB', async () => {
    await assertFails(uploadBytes(ref(st('merchant1'), 'places/p1/a.svg'), bytes(), { contentType: 'image/svg+xml' }));
    await assertFails(uploadBytes(ref(st('merchant1'), 'places/p1/a.jpg'), bytes(5 * 1024 * 1024 + 1), jpeg));
  });
  it('الزائر غير المسجّل لا يرفع، وغير المالك لا يحذف', async () => {
    await assertFails(uploadBytes(ref(st(null), 'places/p1/a.jpg'), bytes(), jpeg));
    await assertSucceeds(uploadBytes(ref(st('merchant1'), 'places/p1/d.jpg'), bytes(), jpeg));
    await assertFails(deleteObject(ref(st('user1'), 'places/p1/d.jpg')));
    await assertSucceeds(deleteObject(ref(st('merchant1'), 'places/p1/d.jpg')));
  });
});

describe('/users/{userId}', () => {
  it('المستخدم يكتب في مجلده فقط وبحجم ≤ 2MB', async () => {
    await assertSucceeds(uploadBytes(ref(st('user1'), 'users/user1/p.png'), bytes(), { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(st('user1'), 'users/user2/p.png'), bytes(), { contentType: 'image/png' }));
    await assertFails(uploadBytes(ref(st('user1'), 'users/user1/big.png'), bytes(2 * 1024 * 1024 + 1), { contentType: 'image/png' }));
  });
  it('أي مسار آخر مرفوض', async () => {
    await assertFails(uploadBytes(ref(st('admin1'), 'misc/x.jpg'), bytes(), jpeg));
  });
});
