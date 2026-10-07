/*
 * 楽譜ファイル（Cloud Storage）の権限テスト（Firestore と Storage のエミュレータで実行）
 * テストデータはすべて架空です（@example.com）。
 */
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, doc, setDoc } from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

// Storage のルールから Firestore を参照するため、両方のエミュレータで同じプロジェクトIDを使う
const PROJECT_ID = 'demo-kco';
let env: RulesTestEnvironment;

const USERS = {
  va: { uid: 'uid-va', email: 'va@example.com' },
  vc: { uid: 'uid-vc', email: 'vc@example.com' },
  left: { uid: 'uid-l', email: 'left@example.com' },
  staff: { uid: 'uid-staff', email: 'staff@example.com' },
  applicant: { uid: 'uid-ap', email: 'applicant@example.com' }
};
type UserKey = keyof typeof USERS;

const storageAs = (k: UserKey) => env.authenticatedContext(USERS[k].uid, { email: USERS[k].email, email_verified: true }).storage();
const pdf = new Uint8Array([0x25, 0x50, 0x44, 0x46]);

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8085 },
    storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 9199 }
  });
});

afterAll(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    const now = Timestamp.now();
    const access = (k: UserKey, status: string, role: string, part: string) =>
      setDoc(doc(db, 'memberAccess', USERS[k].email), { email: USERS[k].email, status, role, memberId: 'm-' + k, part, source: 'sheet' });
    await access('va', 'active', 'member', 'Va');
    await access('vc', 'active', 'member', 'Vc');
    await access('left', 'inactive', 'member', 'Va');
    await access('staff', 'active', 'staff', 'Hr');
    const score = (id: string, parts: string[], published = true) =>
      setDoc(doc(db, 'scores', id), { title: 't', parts, kind: 'file', storagePath: `scores/${id}/a.pdf`, published, createdAt: now, updatedAt: now });
    await score('va', ['Va']);
    await score('all', ['all']);
    await score('draft', ['all'], false);
    const storage = ctx.storage();
    for (const id of ['va', 'all', 'draft', 'orphan']) {
      await uploadBytes(ref(storage, `scores/${id}/a.pdf`), pdf, { contentType: 'application/pdf' });
    }
  });
});

describe('楽譜ファイル', () => {
  it('対象パート・全員向けの公開中の楽譜だけ取得できる', async () => {
    await assertSucceeds(getBytes(ref(storageAs('va'), 'scores/va/a.pdf')));
    await assertSucceeds(getBytes(ref(storageAs('vc'), 'scores/all/a.pdf')));
    await assertFails(getBytes(ref(storageAs('vc'), 'scores/va/a.pdf')));
    await assertFails(getBytes(ref(storageAs('va'), 'scores/draft/a.pdf')));
    await assertFails(getBytes(ref(storageAs('va'), 'scores/orphan/a.pdf'))); // 楽譜の登録が無いファイル
    await assertFails(getBytes(ref(storageAs('left'), 'scores/all/a.pdf')));
    await assertFails(getBytes(ref(storageAs('applicant'), 'scores/all/a.pdf')));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), 'scores/all/a.pdf')));
    await assertSucceeds(getBytes(ref(storageAs('staff'), 'scores/draft/a.pdf')));
  });

  it('アップロード・削除は運営だけ（PDF・画像のみ）', async () => {
    await assertFails(uploadBytes(ref(storageAs('va'), 'scores/new/a.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertSucceeds(uploadBytes(ref(storageAs('staff'), 'scores/new/a.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(storageAs('staff'), 'scores/new/a.html'), pdf, { contentType: 'text/html' }));
    await assertFails(uploadBytes(ref(storageAs('staff'), 'other/a.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertFails(deleteObject(ref(storageAs('va'), 'scores/va/a.pdf')));
    await assertSucceeds(deleteObject(ref(storageAs('staff'), 'scores/va/a.pdf')));
  });
});
