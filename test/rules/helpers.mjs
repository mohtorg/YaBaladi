// مساعدات مشتركة لاختبارات القواعد — تهيئة البيئة وبذر المستخدمين والأماكن.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '../..');

export async function createEnv() {
  return initializeTestEnvironment({
    projectId: 'demo-yabaladi',
    firestore: { rules: readFileSync(resolve(root, 'firestore.rules'), 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: readFileSync(resolve(root, 'storage.rules'), 'utf8'), host: '127.0.0.1', port: 9199 },
  });
}

// بذر بيانات أساسية بتجاوز القواعد: أدوار + مكان واحد مملوك لتاجر.
export async function seed(env) {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const users = {
      admin1: { role: 'admin' },
      mod1: { role: 'moderator' },
      merchant1: { role: 'merchant' },
      merchant2: { role: 'merchant' },
      user1: { role: 'user', isBanned: false },
      user2: { role: 'user', isBanned: false },
      banned1: { role: 'user', isBanned: true },
    };
    for (const [id, data] of Object.entries(users)) {
      await setDoc(doc(db, 'users', id), { uid: id, ...data });
    }
    await setDoc(doc(db, 'places', 'p1'), {
      ownerId: 'merchant1', isApproved: true, averageRating: 4, reviewCount: 3, viewCount: 10, name: 'مكان',
    });
    await setDoc(doc(db, 'ratings', 'r1'), { userId: 'user1', placeId: 'p1', status: 'PUBLISHED', overall: 4, helpfulCount: 0, reportCount: 0 });
  });
}

export const as = (env, id) => (id ? env.authenticatedContext(id).firestore() : env.unauthenticatedContext().firestore());
