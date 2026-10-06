/*
 * Firestore Security Rules の権限テスト（Firebase エミュレータで実行）
 *   npm run test:rules
 *
 * テストデータはすべて架空です（@example.com）。
 */
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where
} from 'firebase/firestore';

const PROJECT_ID = 'demo-kco-rules';
let env: RulesTestEnvironment;

// ---- 登場人物 ----
const USERS = {
  memberA: { uid: 'uid-a', email: 'member.a@example.com', memberId: 'm-a' },
  memberB: { uid: 'uid-b', email: 'member.b@example.com', memberId: 'm-b' },
  paused: { uid: 'uid-p', email: 'paused@example.com', memberId: 'm-p' },
  left: { uid: 'uid-l', email: 'left@example.com', memberId: 'm-l' },
  admin: { uid: 'uid-admin', email: 'admin@example.com', memberId: null },
  staff: { uid: 'uid-staff', email: 'staff@example.com', memberId: 'm-s' },
  applicant: { uid: 'uid-ap', email: 'applicant@example.com', memberId: null },
  stranger: { uid: 'uid-x', email: 'stranger@example.com', memberId: null }
};

type UserKey = keyof typeof USERS;

function as(key: UserKey, opts: { verified?: boolean; emailOverride?: string } = {}) {
  const u = USERS[key];
  return env
    .authenticatedContext(u.uid, {
      email: opts.emailOverride ?? u.email,
      email_verified: opts.verified ?? true
    })
    .firestore();
}

function anon() {
  return env.unauthenticatedContext().firestore();
}

const past = Timestamp.fromDate(new Date(Date.now() - 86400000));

function rehearsalData(extra: Record<string, unknown> = {}) {
  return {
    title: '合奏練習',
    date: '',
    startTime: '',
    endTime: '',
    venue: '',
    content: '',
    notes: '',
    target: '',
    scoreNote: '',
    attendanceDeadline: null,
    published: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra
  };
}

function announcementData(extra: Record<string, unknown> = {}) {
  return {
    title: 'お知らせ',
    body: '本文',
    important: false,
    category: 'general',
    audience: { type: 'all', values: [] },
    published: true,
    publishedAt: serverTimestamp(),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra
  };
}

function concertData(extra: Record<string, unknown> = {}) {
  return {
    title: '第1回演奏会',
    date: '',
    venue: '',
    openTime: '',
    startTime: '',
    program: [{ label: 'メインプログラム', composer: 'ドヴォルザーク', work: '交響曲第7番 ニ短調 作品70' }],
    performers: '',
    notes: '',
    daySchedule: '',
    order: 1,
    published: true,
    updatedAt: serverTimestamp(),
    ...extra
  };
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8085
    }
  });
});

afterAll(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    const access = (email: string, status: string, role: string, memberId: string | null) =>
      setDoc(doc(db, 'memberAccess', email), { email, status, role, memberId, source: 'sheet' });

    await access(USERS.memberA.email, 'active', 'member', 'm-a');
    await access(USERS.memberB.email, 'active', 'member', 'm-b');
    await access(USERS.paused.email, 'paused', 'member', 'm-p');
    await access(USERS.left.email, 'inactive', 'member', 'm-l');
    await access(USERS.admin.email, 'active', 'admin', null);
    await access(USERS.staff.email, 'active', 'staff', 'm-s');
    // 参加希望者（applicant）と部外者（stranger）には memberAccess が無い

    const member = (id: string, name: string, instrument: string, status = 'active') =>
      setDoc(doc(db, 'members', id), {
        displayName: name,
        instrument,
        instrumentLabel: instrument,
        part: instrument,
        section: 'strings',
        status,
        bio: '',
        roleLabel: ''
      });

    await member('m-a', 'えー', 'Va');
    await member('m-b', 'びー', 'Vc');
    await member('m-p', 'ぴー', 'Fl', 'paused');
    await member('m-l', 'える', 'Ob', 'inactive');
    await member('m-s', 'えす', 'Hr');

    await setDoc(doc(db, 'stats', 'summary'), { memberCount: 3, targetMembers: 80 });
    await setDoc(doc(db, 'adminStats', 'summary'), { applicantCount: 9 });

    await setDoc(doc(db, 'rehearsals', 'r-open'), { ...rehearsalData(), createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
    await setDoc(doc(db, 'rehearsals', 'r-closed'), { ...rehearsalData({ attendanceDeadline: past }), createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
    await setDoc(doc(db, 'rehearsals', 'r-draft'), { ...rehearsalData({ published: false }), createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
    await setDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-b'), { status: 'absent', comment: '', updatedAt: Timestamp.now() });

    await setDoc(doc(db, 'announcements', 'a-pub'), { ...announcementData(), publishedAt: Timestamp.now(), createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
    await setDoc(doc(db, 'announcements', 'a-draft'), { ...announcementData({ published: false }), publishedAt: null, createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
    await setDoc(doc(db, 'concerts', 'c-1'), { ...concertData(), updatedAt: Timestamp.now() });

    await setDoc(doc(db, 'secret', 'x'), { a: 1 });
  });
});

// ---------------------------------------------------------------
describe('未ログイン', () => {
  it('団員情報・予定・お知らせ・演奏会・統計を読めない', async () => {
    const db = anon();
    await assertFails(getDoc(doc(db, 'members', 'm-a')));
    await assertFails(getDoc(doc(db, 'stats', 'summary')));
    await assertFails(getDoc(doc(db, 'rehearsals', 'r-open')));
    await assertFails(getDoc(doc(db, 'announcements', 'a-pub')));
    await assertFails(getDoc(doc(db, 'concerts', 'c-1')));
    await assertFails(getDoc(doc(db, 'memberAccess', USERS.memberA.email)));
  });

  it('何も書き込めない', async () => {
    const db = anon();
    await assertFails(setDoc(doc(db, 'memberAccess', 'x@example.com'), { status: 'active', role: 'admin' }));
    await assertFails(setDoc(doc(db, 'rehearsals', 'new'), rehearsalData()));
  });
});

describe('存在しないユーザー（ログインはできたが団員ではない）', () => {
  it('自分のアクセス情報（無し）は確認できるが、団員情報は読めない', async () => {
    const db = as('stranger');
    await assertSucceeds(getDoc(doc(db, 'memberAccess', USERS.stranger.email)));
    await assertFails(getDoc(doc(db, 'members', 'm-a')));
    await assertFails(getDocs(collection(db, 'members')));
    await assertFails(getDoc(doc(db, 'stats', 'summary')));
  });

  it('他人のアクセス情報は読めない', async () => {
    await assertFails(getDoc(doc(as('stranger'), 'memberAccess', USERS.memberA.email)));
  });

  it('自分を団員として登録できない', async () => {
    const db = as('stranger');
    await assertFails(setDoc(doc(db, 'memberAccess', USERS.stranger.email), { status: 'active', role: 'member', memberId: 'm-x' }));
    await assertFails(setDoc(doc(db, 'members', 'm-x'), { displayName: 'x' }));
  });
});

describe('加入確定前ユーザー（応募しただけ）', () => {
  it('団員専用情報を一切読めない', async () => {
    const db = as('applicant');
    await assertFails(getDoc(doc(db, 'members', 'm-a')));
    await assertFails(getDoc(doc(db, 'rehearsals', 'r-open')));
    await assertFails(getDocs(query(collection(db, 'announcements'), where('published', '==', true))));
    await assertFails(getDoc(doc(db, 'concerts', 'c-1')));
    await assertFails(getDoc(doc(db, 'stats', 'summary')));
  });
});

describe('退団ユーザー', () => {
  it('自分の状態は確認できるが、団員情報は読めない', async () => {
    const db = as('left');
    await assertSucceeds(getDoc(doc(db, 'memberAccess', USERS.left.email)));
    await assertFails(getDoc(doc(db, 'members', 'm-a')));
    await assertFails(getDoc(doc(db, 'rehearsals', 'r-open')));
    await assertFails(getDoc(doc(db, 'stats', 'summary')));
  });

  it('出欠もプロフィールも書けない', async () => {
    const db = as('left');
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-l'), { status: 'present', comment: '', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'members', 'm-l'), { displayName: 'x', updatedAt: serverTimestamp() }));
  });
});

describe('メール未確認のアカウント', () => {
  it('memberAccess があっても読めない', async () => {
    const db = as('memberA', { verified: false });
    await assertFails(getDoc(doc(db, 'members', 'm-a')));
    await assertFails(getDoc(doc(db, 'memberAccess', USERS.memberA.email)));
  });
});

describe('一般団員', () => {
  it('メールアドレスの大文字・小文字が違ってもログインできる', async () => {
    const db = as('memberA', { emailOverride: 'Member.A@Example.com' });
    await assertSucceeds(getDoc(doc(db, 'members', 'm-a')));
  });

  it('団員情報・統計・公開中の予定・お知らせ・演奏会を読める', async () => {
    const db = as('memberA');
    await assertSucceeds(getDoc(doc(db, 'memberAccess', USERS.memberA.email)));
    await assertSucceeds(getDocs(collection(db, 'members')));
    await assertSucceeds(getDoc(doc(db, 'stats', 'summary')));
    await assertSucceeds(getDoc(doc(db, 'rehearsals', 'r-open')));
    await assertSucceeds(getDocs(query(collection(db, 'rehearsals'), where('published', '==', true), orderBy('date'))));
    await assertSucceeds(getDocs(query(collection(db, 'announcements'), where('published', '==', true), orderBy('publishedAt', 'desc'))));
    await assertSucceeds(getDocs(query(collection(db, 'concerts'), where('published', '==', true), orderBy('order'))));
  });

  it('非公開（下書き）の予定・お知らせは読めない', async () => {
    const db = as('memberA');
    await assertFails(getDoc(doc(db, 'rehearsals', 'r-draft')));
    await assertFails(getDoc(doc(db, 'announcements', 'a-draft')));
    await assertFails(getDocs(collection(db, 'announcements')));
  });

  it('運営専用の集計（参加希望者数）は読めない', async () => {
    await assertFails(getDoc(doc(as('memberA'), 'adminStats', 'summary')));
  });

  it('他人のアクセス情報（メールアドレス）は読めない', async () => {
    const db = as('memberA');
    await assertFails(getDoc(doc(db, 'memberAccess', USERS.memberB.email)));
    await assertFails(getDocs(collection(db, 'memberAccess')));
  });

  it('自分や他人を管理者にできない', async () => {
    const db = as('memberA');
    await assertFails(updateDoc(doc(db, 'memberAccess', USERS.memberA.email), { role: 'admin' }));
    await assertFails(setDoc(doc(db, 'memberAccess', USERS.memberB.email), { status: 'inactive' }));
  });

  it('自分の表示名・自己紹介は変更できる', async () => {
    await assertSucceeds(updateDoc(doc(as('memberA'), 'members', 'm-a'), {
      displayName: 'えーさん', bio: 'ヴィオラ担当です', updatedAt: serverTimestamp()
    }));
  });

  it('自分の楽器・状態は変更できない', async () => {
    const db = as('memberA');
    await assertFails(updateDoc(doc(db, 'members', 'm-a'), { instrument: 'Vn', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'members', 'm-a'), { status: 'active', roleLabel: 'コンマス', updatedAt: serverTimestamp() }));
  });

  it('長すぎる表示名・空の表示名は拒否', async () => {
    const db = as('memberA');
    await assertFails(updateDoc(doc(db, 'members', 'm-a'), { displayName: 'x'.repeat(31), updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'members', 'm-a'), { displayName: '', updatedAt: serverTimestamp() }));
  });

  it('他人のプロフィールは変更できない', async () => {
    await assertFails(updateDoc(doc(as('memberA'), 'members', 'm-b'), { displayName: 'いたずら', updatedAt: serverTimestamp() }));
  });

  it('自分の出欠を登録・変更できる', async () => {
    const db = as('memberA');
    const ref = doc(db, 'rehearsals', 'r-open', 'attendance', 'm-a');
    await assertSucceeds(setDoc(ref, { status: 'present', comment: '', updatedAt: serverTimestamp() }));
    await assertSucceeds(setDoc(ref, { status: 'late', comment: '30分ほど遅れます', updatedAt: serverTimestamp() }));
    await assertSucceeds(getDoc(ref));
  });

  it('他人の出欠は登録も閲覧もできない', async () => {
    const db = as('memberA');
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-b'), { status: 'present', comment: '', updatedAt: serverTimestamp() }));
    await assertFails(getDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-b')));
    await assertFails(getDocs(collection(db, 'rehearsals', 'r-open', 'attendance')));
  });

  it('締切後・下書きの練習・不正な値の出欠は拒否', async () => {
    const db = as('memberA');
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-closed', 'attendance', 'm-a'), { status: 'present', comment: '', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-draft', 'attendance', 'm-a'), { status: 'present', comment: '', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-a'), { status: 'maybe', comment: '', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-a'), { status: 'present', comment: 'x'.repeat(201), updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-a'), { status: 'present', comment: '', email: 'x', updatedAt: serverTimestamp() }));
  });

  it('予定・お知らせ・演奏会を作成・削除できない', async () => {
    const db = as('memberA');
    await assertFails(setDoc(doc(db, 'rehearsals', 'new'), rehearsalData()));
    await assertFails(setDoc(doc(db, 'announcements', 'new'), announcementData()));
    await assertFails(setDoc(doc(db, 'concerts', 'new'), concertData()));
    await assertFails(deleteDoc(doc(db, 'rehearsals', 'r-open')));
  });

  it('ルールに無いコレクションは読み書きできない', async () => {
    const db = as('memberA');
    await assertFails(getDoc(doc(db, 'secret', 'x')));
    await assertFails(setDoc(doc(db, 'anything', 'x'), { a: 1 }));
  });
});

describe('活動休止中の団員', () => {
  it('閲覧はできる', async () => {
    const db = as('paused');
    await assertSucceeds(getDoc(doc(db, 'members', 'm-a')));
    await assertSucceeds(getDoc(doc(db, 'rehearsals', 'r-open')));
  });

  it('出欠・プロフィールは書けない', async () => {
    const db = as('paused');
    await assertFails(setDoc(doc(db, 'rehearsals', 'r-open', 'attendance', 'm-p'), { status: 'present', comment: '', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'members', 'm-p'), { displayName: 'x', updatedAt: serverTimestamp() }));
  });
});

describe('運営補助（staff）', () => {
  it('練習予定・お知らせを作成・更新・削除できる', async () => {
    const db = as('staff');
    await assertSucceeds(setDoc(doc(db, 'rehearsals', 'new'), rehearsalData({ date: '2026-12-05', startTime: '13:00', endTime: '16:00' })));
    await assertSucceeds(setDoc(doc(db, 'announcements', 'new'), announcementData({ important: true })));
    await assertSucceeds(deleteDoc(doc(db, 'announcements', 'new')));
  });

  it('全員の出欠を見られる', async () => {
    await assertSucceeds(getDocs(collection(as('staff'), 'rehearsals', 'r-open', 'attendance')));
  });

  it('下書きも読める', async () => {
    await assertSucceeds(getDoc(doc(as('staff'), 'rehearsals', 'r-draft')));
  });

  it('演奏会情報・運営専用集計は扱えない', async () => {
    const db = as('staff');
    await assertFails(setDoc(doc(db, 'concerts', 'c-2'), concertData()));
    await assertFails(getDoc(doc(db, 'adminStats', 'summary')));
  });
});

describe('管理者', () => {
  it('運営専用集計・全員のアクセス情報を読める', async () => {
    const db = as('admin');
    await assertSucceeds(getDoc(doc(db, 'adminStats', 'summary')));
    await assertSucceeds(getDoc(doc(db, 'memberAccess', USERS.memberA.email)));
  });

  it('演奏会情報を作成・更新できる（未定の項目は空欄のまま）', async () => {
    const db = as('admin');
    await assertSucceeds(setDoc(doc(db, 'concerts', 'c-2'), concertData({ order: 2 })));
    await assertSucceeds(setDoc(doc(db, 'concerts', 'c-1'), concertData({ venue: '' })));
  });

  it('不正な形式のデータは管理者でも拒否', async () => {
    const db = as('admin');
    await assertFails(setDoc(doc(db, 'rehearsals', 'bad1'), rehearsalData({ date: '12月5日' })));
    await assertFails(setDoc(doc(db, 'rehearsals', 'bad2'), rehearsalData({ password: 'x' })));
    await assertFails(setDoc(doc(db, 'announcements', 'bad3'), announcementData({ category: 'spam' })));
    await assertFails(setDoc(doc(db, 'announcements', 'bad4'), announcementData({ audience: { type: 'all', values: [], extra: 1 } })));
    await assertFails(setDoc(doc(db, 'concerts', 'bad5'), concertData({ order: '1' })));
  });

  it('アクセス情報（権限）はアプリから変更できない（スプレッドシートで管理）', async () => {
    const db = as('admin');
    await assertFails(updateDoc(doc(db, 'memberAccess', USERS.memberA.email), { role: 'admin' }));
    await assertFails(setDoc(doc(db, 'memberAccess', 'new@example.com'), { status: 'active', role: 'member', memberId: 'm-new' }));
  });

  it('団員の楽器・状態は変更できないが、表示名・役職表示は直せる', async () => {
    const db = as('admin');
    await assertFails(updateDoc(doc(db, 'members', 'm-a'), { instrument: 'Vn', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db, 'members', 'm-a'), { roleLabel: 'パートリーダー', updatedAt: serverTimestamp() }));
  });

  it('団員IDが無い管理者は出欠を登録できない', async () => {
    await assertFails(setDoc(doc(as('admin'), 'rehearsals', 'r-open', 'attendance', 'null'), { status: 'present', comment: '', updatedAt: serverTimestamp() }));
  });
});
