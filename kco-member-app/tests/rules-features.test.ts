/*
 * 追加機能（アンケート・提案・楽譜・通知・団員募集）の権限テスト
 *   npm run test:rules
 * テストデータはすべて架空です（@example.com）。
 */
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch
} from 'firebase/firestore';

const PROJECT_ID = 'demo-kco-features';
let env: RulesTestEnvironment;

const USERS = {
  va: { uid: 'uid-va', email: 'va@example.com', memberId: 'm-va', part: 'Va' },
  vc: { uid: 'uid-vc', email: 'vc@example.com', memberId: 'm-vc', part: 'Vc' },
  paused: { uid: 'uid-p', email: 'paused@example.com', memberId: 'm-p', part: 'Va' },
  left: { uid: 'uid-l', email: 'left@example.com', memberId: 'm-l', part: 'Va' },
  admin: { uid: 'uid-admin', email: 'admin@example.com', memberId: null, part: '' },
  staff: { uid: 'uid-staff', email: 'staff@example.com', memberId: 'm-s', part: 'Hr' },
  applicant: { uid: 'uid-ap', email: 'applicant@example.com', memberId: null, part: '' },
  // 応募しただけの参加希望者（stage = applicant）
  hopeful: { uid: 'uid-h', email: 'hopeful@example.com', memberId: 'ap-1', part: 'Va' }
};
type UserKey = keyof typeof USERS;

function as(key: UserKey) {
  const u = USERS[key];
  return env.authenticatedContext(u.uid, { email: u.email, email_verified: true }).firestore();
}
const anon = () => env.unauthenticatedContext().firestore();
const past = Timestamp.fromDate(new Date(Date.now() - 86400000));

function surveyData(extra: Record<string, unknown> = {}) {
  return {
    title: '練習日アンケート',
    description: '',
    questions: [{ id: 'q1', type: 'single', label: '曜日', options: ['土', '日'], required: true }],
    anonymous: false,
    deadline: null,
    published: true,
    closed: false,
    results: null,
    resultsPublished: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra
  };
}

function proposalData(extra: Record<string, unknown> = {}) {
  return {
    title: 'ドヴォルザークをやりたい',
    body: '',
    category: 'music',
    visibility: 'members',
    authorId: 'm-va',
    authorName: 'ゔぃおら',
    status: 'open',
    staffReply: '',
    supportCount: 0,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra
  };
}

function scoreData(extra: Record<string, unknown> = {}) {
  return {
    title: '交響曲 第1楽章',
    composer: '',
    note: '',
    parts: ['Va'],
    kind: 'link',
    url: 'https://example.com/score.pdf',
    fileName: '',
    published: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra
  };
}

function campaignData(extra: Record<string, unknown> = {}) {
  return {
    active: true,
    headline: '団員募集',
    message: '',
    parts: [{ part: 'Ob', label: 'オーボエ', level: 'urgent' }],
    formUrl: 'https://forms.gle/example',
    hashtags: '',
    deadlineText: '',
    showMemberCount: false,
    memberCount: 0,
    targetMembers: 80,
    updatedAt: serverTimestamp(),
    ...extra
  };
}

function notificationData(uid: string, extra: Record<string, unknown> = {}) {
  return {
    title: '明日は練習です',
    body: '',
    url: '/schedule',
    audience: { type: 'all', values: [] },
    status: 'pending',
    source: 'manual',
    createdAt: serverTimestamp(),
    createdBy: uid,
    ...extra
  };
}

const now0 = () => Timestamp.now();

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8085 }
  });
});

afterAll(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    const access = (k: UserKey, status: string, role: string) => {
      const u = USERS[k];
      return setDoc(doc(db, 'memberAccess', u.email), { email: u.email, status, role, memberId: u.memberId, part: u.part, source: 'sheet' });
    };
    await access('va', 'active', 'member');
    await access('vc', 'active', 'member');
    await access('paused', 'paused', 'member');
    await access('left', 'inactive', 'member');
    await access('admin', 'active', 'admin');
    await access('staff', 'active', 'staff');
    await setDoc(doc(db, 'memberAccess', USERS.hopeful.email), { email: USERS.hopeful.email, status: 'active', role: 'member', memberId: 'ap-1', part: 'Va', stage: 'applicant', source: 'sheet' });
    await setDoc(doc(db, 'applicants', 'ap-1'), { displayName: 'きぼう', instrument: 'Va', instrumentLabel: 'ヴィオラ', part: 'Va', section: 'strings', status: 'active', bio: '' });
    await setDoc(doc(db, 'applicants', 'ap-2'), { displayName: 'べつのひと', instrument: 'Fl', instrumentLabel: 'フルート', part: 'Fl', section: 'woodwind', status: 'active', bio: '' });
    await setDoc(doc(db, 'stats', 'summary'), { memberCount: 3, targetMembers: 80, applicantCount: 2 });
    await setDoc(doc(db, 'rehearsals', 'r1'), { title: '合奏', date: '', startTime: '', endTime: '', venue: '', content: '', notes: '', target: '', scoreNote: '', attendanceDeadline: null, published: true, createdAt: now0(), updatedAt: now0() });
    const news = (id: string, forApplicants: boolean | undefined) => setDoc(doc(db, 'announcements', id), {
      title: id, body: '', important: false, category: 'general', audience: { type: 'all', values: [] }, published: true, publishedAt: now0(), createdAt: now0(), updatedAt: now0(),
      ...(forApplicants === undefined ? {} : { forApplicants })
    });
    await news('a-members', undefined);
    await news('a-both', true);
    const member = (id: string, name: string, part: string) =>
      setDoc(doc(db, 'members', id), { displayName: name, instrument: part, instrumentLabel: part, part, section: 'strings', status: 'active', bio: '', roleLabel: '' });
    await member('m-va', 'ゔぃおら', 'Va');
    await member('m-vc', 'ちぇろ', 'Vc');
    await member('m-p', 'きゅうし', 'Va');
    await member('m-s', 'ほるん', 'Hr');

    const now = Timestamp.now();
    await setDoc(doc(db, 'surveys', 's-open'), { ...surveyData(), createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'surveys', 's-closed'), { ...surveyData({ closed: true }), createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'surveys', 's-late'), { ...surveyData({ deadline: past }), createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'surveys', 's-draft'), { ...surveyData({ published: false }), createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'surveys', 's-open', 'responses', 'm-vc'), { answers: { q1: 1 }, updatedAt: now });

    await setDoc(doc(db, 'proposals', 'p-shared'), { ...proposalData({ authorId: 'm-vc', authorName: 'ちぇろ' }), createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'proposals', 'p-private'), { ...proposalData({ authorId: 'm-vc', authorName: 'ちぇろ', visibility: 'staff' }), createdAt: now, updatedAt: now });

    await setDoc(doc(db, 'scores', 'sc-va'), { ...scoreData(), createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'scores', 'sc-all'), { ...scoreData({ parts: ['all'] }), createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'scores', 'sc-draft'), { ...scoreData({ parts: ['all'], published: false }), createdAt: now, updatedAt: now });

    await setDoc(doc(db, 'pushTokens', 'token-vc'), { uid: 'uid-vc', accessKey: 'vc@example.com', token: 'token-vc', platform: 'Android', updatedAt: now });
    await setDoc(doc(db, 'notifications', 'n1'), { ...notificationData('uid-admin'), createdAt: now });
    await setDoc(doc(db, 'publicCampaign', 'current'), { ...campaignData(), updatedAt: now });
    await setDoc(doc(db, 'appConfig', 'public'), { vapidKey: 'x'.repeat(87), updatedAt: now });
  });
});

// ---------------------------------------------------------------------
describe('アンケート', () => {
  it('団員は公開中のアンケートを読めるが、下書きは読めない', async () => {
    await assertSucceeds(getDocs(query(collection(as('va'), 'surveys'), where('published', '==', true), orderBy('createdAt', 'desc'))));
    await assertFails(getDoc(doc(as('va'), 'surveys', 's-draft')));
    await assertSucceeds(getDoc(doc(as('staff'), 'surveys', 's-draft')));
  });

  it('参加希望者・未ログイン・退団者は読めない', async () => {
    await assertFails(getDoc(doc(as('applicant'), 'surveys', 's-open')));
    await assertFails(getDoc(doc(anon(), 'surveys', 's-open')));
    await assertFails(getDoc(doc(as('left'), 'surveys', 's-open')));
  });

  it('回答は本人の分だけ・受付中だけ書ける', async () => {
    const answer = { answers: { q1: 0 }, updatedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as('va'), 'surveys', 's-open', 'responses', 'm-va'), answer));
    await assertSucceeds(setDoc(doc(as('va'), 'surveys', 's-open', 'responses', 'm-va'), answer)); // 修正
    await assertFails(setDoc(doc(as('va'), 'surveys', 's-open', 'responses', 'm-vc'), answer)); // なりすまし
    await assertFails(setDoc(doc(as('va'), 'surveys', 's-closed', 'responses', 'm-va'), answer));
    await assertFails(setDoc(doc(as('va'), 'surveys', 's-late', 'responses', 'm-va'), answer));
    await assertFails(setDoc(doc(as('va'), 'surveys', 's-draft', 'responses', 'm-va'), answer));
    await assertFails(setDoc(doc(as('paused'), 'surveys', 's-open', 'responses', 'm-p'), answer)); // 活動休止中
    await assertFails(setDoc(doc(as('va'), 'surveys', 's-open', 'responses', 'm-va'), { answers: { q1: 0 }, name: '本名', updatedAt: serverTimestamp() }));
  });

  it('他の団員の回答は読めない（運営は読める）', async () => {
    await assertFails(getDoc(doc(as('va'), 'surveys', 's-open', 'responses', 'm-vc')));
    await assertFails(getDocs(collection(as('va'), 'surveys', 's-open', 'responses')));
    await assertSucceeds(getDoc(doc(as('vc'), 'surveys', 's-open', 'responses', 'm-vc')));
    await assertSucceeds(getDocs(collection(as('staff'), 'surveys', 's-open', 'responses')));
  });

  it('作成・結果の公開は運営だけ', async () => {
    await assertFails(addDoc(collection(as('va'), 'surveys'), surveyData()));
    await assertSucceeds(addDoc(collection(as('staff'), 'surveys'), surveyData()));
    await assertSucceeds(updateDoc(doc(as('staff'), 'surveys', 's-open'), { results: { respondents: 1, counts: { q1: [0, 1] } }, resultsPublished: true, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('va'), 'surveys', 's-open'), { resultsPublished: true, updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(as('staff'), 'surveys', 's-open')));
    await assertSucceeds(deleteDoc(doc(as('admin'), 'surveys', 's-open')));
  });
});

// ---------------------------------------------------------------------
describe('提案', () => {
  it('自分の名前で投稿できる（他人の名前・他人のIDは不可）', async () => {
    await assertSucceeds(addDoc(collection(as('va'), 'proposals'), proposalData()));
    await assertFails(addDoc(collection(as('va'), 'proposals'), proposalData({ authorName: 'ちぇろ' })));
    await assertFails(addDoc(collection(as('va'), 'proposals'), proposalData({ authorId: 'm-vc' })));
    await assertFails(addDoc(collection(as('va'), 'proposals'), proposalData({ status: 'adopted' })));
    await assertFails(addDoc(collection(as('va'), 'proposals'), proposalData({ supportCount: 99 })));
    await assertFails(addDoc(collection(as('paused'), 'proposals'), proposalData({ authorId: 'm-p', authorName: 'きゅうし' })));
    await assertFails(addDoc(collection(as('applicant'), 'proposals'), proposalData({ authorId: 'x' })));
  });

  it('「運営だけに送る」提案は、本人と運営しか読めない', async () => {
    await assertSucceeds(getDoc(doc(as('va'), 'proposals', 'p-shared')));
    await assertFails(getDoc(doc(as('va'), 'proposals', 'p-private')));
    await assertSucceeds(getDoc(doc(as('vc'), 'proposals', 'p-private')));
    await assertSucceeds(getDoc(doc(as('staff'), 'proposals', 'p-private')));
    // 一覧の問い合わせ
    await assertSucceeds(getDocs(query(collection(as('va'), 'proposals'), where('visibility', '==', 'members'), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDocs(query(collection(as('vc'), 'proposals'), where('authorId', '==', 'm-vc'))));
    await assertFails(getDocs(query(collection(as('va'), 'proposals'), where('authorId', '==', 'm-vc'))));
    await assertFails(getDocs(collection(as('va'), 'proposals')));
  });

  it('投稿者は受付中のあいだ内容を直せる。対応状況・返信は運営だけ', async () => {
    await assertSucceeds(updateDoc(doc(as('vc'), 'proposals', 'p-shared'), { body: '追記', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('va'), 'proposals', 'p-shared'), { body: '改ざん', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('vc'), 'proposals', 'p-shared'), { status: 'adopted', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(as('staff'), 'proposals', 'p-shared'), { status: 'considering', staffReply: '検討します', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('staff'), 'proposals', 'p-shared'), { title: '書き換え', updatedAt: serverTimestamp() }));
    // 運営が対応を始めたら投稿者は編集できない
    await assertFails(updateDoc(doc(as('vc'), 'proposals', 'p-shared'), { body: '再編集', updatedAt: serverTimestamp() }));
  });

  it('賛成は1人1回。数だけ増やすことはできない', async () => {
    const vote = (key: UserKey, memberId: string, delta: 1 | -1) => {
      const db = as(key);
      const b = writeBatch(db);
      const ref = doc(db, 'proposals', 'p-shared', 'supports', memberId);
      if (delta > 0) b.set(ref, { createdAt: serverTimestamp() });
      else b.delete(ref);
      b.update(doc(db, 'proposals', 'p-shared'), { supportCount: increment(delta) });
      return b.commit();
    };
    await assertSucceeds(vote('va', 'm-va', 1));
    await assertFails(vote('va', 'm-va', 1)); // 2回目
    await assertFails(vote('va', 'm-vc', 1)); // 他人の分
    await assertFails(updateDoc(doc(as('va'), 'proposals', 'p-shared'), { supportCount: increment(10) }));
    await assertFails(updateDoc(doc(as('vc'), 'proposals', 'p-shared'), { supportCount: increment(1) }));
    await assertSucceeds(vote('va', 'm-va', -1)); // 取り消し
    await assertFails(vote('va', 'm-va', -1));
    let count: unknown;
    await env.withSecurityRulesDisabled(async ctx => {
      count = (await getDoc(doc(ctx.firestore(), 'proposals', 'p-shared'))).data()?.supportCount;
    });
    expect(count).toBe(0);
  });

  it('削除は投稿者（受付中のみ）と管理者', async () => {
    await assertFails(deleteDoc(doc(as('va'), 'proposals', 'p-shared')));
    await assertSucceeds(deleteDoc(doc(as('vc'), 'proposals', 'p-private')));
    await assertSucceeds(deleteDoc(doc(as('admin'), 'proposals', 'p-shared')));
  });
});

// ---------------------------------------------------------------------
describe('楽譜', () => {
  it('自分のパート・全員向けの公開中の楽譜だけ読める', async () => {
    await assertSucceeds(getDoc(doc(as('va'), 'scores', 'sc-va')));
    await assertSucceeds(getDoc(doc(as('vc'), 'scores', 'sc-all')));
    await assertFails(getDoc(doc(as('vc'), 'scores', 'sc-va')));
    await assertFails(getDoc(doc(as('va'), 'scores', 'sc-draft')));
    await assertSucceeds(getDoc(doc(as('paused'), 'scores', 'sc-va'))); // 活動休止中も閲覧は可
    await assertFails(getDoc(doc(as('left'), 'scores', 'sc-all')));
    await assertFails(getDoc(doc(as('applicant'), 'scores', 'sc-all')));
    await assertFails(getDoc(doc(anon(), 'scores', 'sc-all')));
    await assertSucceeds(getDoc(doc(as('staff'), 'scores', 'sc-draft')));
  });

  it('一覧は「全員向け」「自分のパート」の問い合わせだけ通る', async () => {
    const ref = collection(as('vc'), 'scores');
    await assertSucceeds(getDocs(query(ref, where('published', '==', true), where('parts', 'array-contains', 'all'))));
    await assertSucceeds(getDocs(query(ref, where('published', '==', true), where('parts', 'array-contains', 'Vc'))));
    await assertFails(getDocs(query(ref, where('published', '==', true), where('parts', 'array-contains', 'Va'))));
    await assertFails(getDocs(query(ref, where('published', '==', true))));
  });

  it('登録は運営だけ。リンクは https のみ', async () => {
    await assertFails(addDoc(collection(as('va'), 'scores'), scoreData()));
    await assertSucceeds(addDoc(collection(as('staff'), 'scores'), scoreData()));
    await assertFails(addDoc(collection(as('staff'), 'scores'), scoreData({ url: 'javascript:alert(1)' })));
    await assertFails(addDoc(collection(as('staff'), 'scores'), scoreData({ kind: 'file', storagePath: '../../etc' })));
    const { url: _url, ...fileScore } = scoreData({ kind: 'file', storagePath: 'scores/abc/1-score.pdf' });
    await assertSucceeds(addDoc(collection(as('staff'), 'scores'), fileScore));
  });
});

// ---------------------------------------------------------------------
describe('プッシュ通知', () => {
  const token = (uid: string, accessKey: string, t: string) => ({ uid, accessKey, token: t, platform: 'iOS', updatedAt: serverTimestamp() });

  it('団員は自分の端末だけ登録・削除できる', async () => {
    await assertSucceeds(setDoc(doc(as('va'), 'pushTokens', 'token-va'), token('uid-va', 'va@example.com', 'token-va')));
    await assertSucceeds(setDoc(doc(as('paused'), 'pushTokens', 'token-p'), token('uid-p', 'paused@example.com', 'token-p')));
    await assertFails(setDoc(doc(as('va'), 'pushTokens', 'token-x'), token('uid-vc', 'vc@example.com', 'token-x'))); // 他人として登録
    await assertFails(setDoc(doc(as('va'), 'pushTokens', 'token-y'), token('uid-va', 'va@example.com', 'other'))); // IDと不一致
    await assertFails(setDoc(doc(as('va'), 'pushTokens', 'token-vc'), token('uid-va', 'va@example.com', 'token-vc'))); // 他人の端末を乗っ取り
    await assertFails(setDoc(doc(as('applicant'), 'pushTokens', 'token-ap'), token('uid-ap', 'applicant@example.com', 'token-ap')));
    await assertFails(setDoc(doc(as('left'), 'pushTokens', 'token-l'), token('uid-l', 'left@example.com', 'token-l')));
    await assertFails(getDoc(doc(as('va'), 'pushTokens', 'token-vc')));
    await assertFails(deleteDoc(doc(as('va'), 'pushTokens', 'token-vc')));
    await assertSucceeds(deleteDoc(doc(as('vc'), 'pushTokens', 'token-vc')));
    await assertFails(getDocs(collection(as('admin'), 'pushTokens')));
  });

  it('通知の予約は運営だけ。送信結果はアプリから書き換えられない', async () => {
    await assertFails(addDoc(collection(as('va'), 'notifications'), notificationData('uid-va')));
    await assertSucceeds(addDoc(collection(as('staff'), 'notifications'), notificationData('uid-staff')));
    await assertFails(addDoc(collection(as('staff'), 'notifications'), notificationData('uid-admin'))); // 作成者の偽装
    await assertFails(addDoc(collection(as('staff'), 'notifications'), notificationData('uid-staff', { status: 'sent' })));
    await assertFails(addDoc(collection(as('staff'), 'notifications'), notificationData('uid-staff', { url: 'https://evil.example.com' })));
    await assertFails(updateDoc(doc(as('admin'), 'notifications', 'n1'), { status: 'sent' }));
    await assertFails(getDocs(collection(as('va'), 'notifications')));
    await assertSucceeds(getDocs(query(collection(as('staff'), 'notifications'), orderBy('createdAt', 'desc'))));
  });

  it('通知の公開鍵は団員が読め、管理者だけが変更できる', async () => {
    await assertSucceeds(getDoc(doc(as('va'), 'appConfig', 'public')));
    await assertFails(getDoc(doc(as('applicant'), 'appConfig', 'public')));
    await assertFails(setDoc(doc(as('staff'), 'appConfig', 'public'), { vapidKey: 'y', updatedAt: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(as('admin'), 'appConfig', 'public'), { vapidKey: 'y', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as('admin'), 'appConfig', 'public'), { vapidKey: 'y', privateKey: 'z', updatedAt: serverTimestamp() }));
  });
});

// ---------------------------------------------------------------------
describe('団員募集キャンペーン', () => {
  it('誰でも（未ログインでも）読める', async () => {
    await assertSucceeds(getDoc(doc(anon(), 'publicCampaign', 'current')));
    await assertSucceeds(getDoc(doc(as('applicant'), 'publicCampaign', 'current')));
  });

  it('変更できるのは運営だけ。決められた項目以外は保存できない', async () => {
    await assertFails(setDoc(doc(anon(), 'publicCampaign', 'current'), campaignData()));
    await assertFails(setDoc(doc(as('va'), 'publicCampaign', 'current'), campaignData()));
    await assertSucceeds(setDoc(doc(as('staff'), 'publicCampaign', 'current'), campaignData()));
    await assertFails(setDoc(doc(as('staff'), 'publicCampaign', 'other'), campaignData()));
    await assertFails(setDoc(doc(as('admin'), 'publicCampaign', 'current'), campaignData({ contactEmail: 'a@example.com' })));
    await assertFails(setDoc(doc(as('admin'), 'publicCampaign', 'current'), campaignData({ formUrl: 'javascript:alert(1)' })));
    await assertFails(setDoc(doc(as('admin'), 'publicCampaign', 'current'), campaignData({ parts: [{ part: 'Ob', label: 'オーボエ', level: 'urgent' }, { part: 'Fl', label: 'x', level: 'urgent', email: 'a@example.com' }] })));
  });
});

// ---------------------------------------------------------------------
describe('参加希望者（応募しただけの人）', () => {
  it('練習予定・演奏会・団員数は読め、自分の出欠を登録できる', async () => {
    const db = as('hopeful');
    await assertSucceeds(getDocs(query(collection(db, 'rehearsals'), where('published', '==', true), orderBy('date'))));
    await assertSucceeds(getDoc(doc(db, 'stats', 'summary')));
    await assertSucceeds(setDoc(doc(db, 'rehearsals', 'r1', 'attendance', 'ap-1'), { status: 'present', comment: '見学します', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'rehearsals', 'r1', 'attendance', 'm-va'), { status: 'present', comment: '', updatedAt: serverTimestamp() }));
  });

  it('団員一覧・楽譜・アンケート・提案は読めない', async () => {
    const db = as('hopeful');
    await assertFails(getDocs(collection(db, 'members')));
    await assertFails(getDoc(doc(db, 'members', 'm-va')));
    await assertFails(getDoc(doc(db, 'scores', 'sc-all')));
    await assertFails(getDoc(doc(db, 'scores', 'sc-va')));
    await assertFails(getDocs(query(collection(db, 'scores'), where('published', '==', true), where('parts', 'array-contains', 'all'))));
    await assertFails(getDoc(doc(db, 'surveys', 's-open')));
    await assertFails(setDoc(doc(db, 'surveys', 's-open', 'responses', 'ap-1'), { answers: { q1: 0 }, updatedAt: serverTimestamp() }));
    await assertFails(getDoc(doc(db, 'proposals', 'p-shared')));
    await assertFails(getDocs(query(collection(db, 'proposals'), where('visibility', '==', 'members'), orderBy('createdAt', 'desc'))));
    await assertFails(addDoc(collection(db, 'proposals'), proposalData({ authorId: 'ap-1', authorName: 'きぼう' })));
  });

  it('お知らせは「参加希望者にも表示」のものだけ', async () => {
    const db = as('hopeful');
    await assertSucceeds(getDoc(doc(db, 'announcements', 'a-both')));
    await assertFails(getDoc(doc(db, 'announcements', 'a-members')));
    await assertSucceeds(getDocs(query(collection(db, 'announcements'), where('published', '==', true), where('forApplicants', '==', true), orderBy('publishedAt', 'desc'))));
    await assertFails(getDocs(query(collection(db, 'announcements'), where('published', '==', true), orderBy('publishedAt', 'desc'))));
    // 団員はどちらも読める（stage が無い既存の許可も団員として扱う）
    await assertSucceeds(getDoc(doc(as('va'), 'announcements', 'a-members')));
    await assertSucceeds(getDocs(query(collection(as('va'), 'announcements'), where('published', '==', true), orderBy('publishedAt', 'desc'))));
  });

  it('参加希望者のプロフィールは本人と運営だけ（団員にも見えない）', async () => {
    await assertSucceeds(getDoc(doc(as('hopeful'), 'applicants', 'ap-1')));
    await assertFails(getDoc(doc(as('hopeful'), 'applicants', 'ap-2')));
    await assertFails(getDocs(collection(as('hopeful'), 'applicants')));
    await assertFails(getDoc(doc(as('va'), 'applicants', 'ap-1')));
    await assertSucceeds(getDocs(collection(as('staff'), 'applicants')));
    await assertFails(setDoc(doc(as('admin'), 'applicants', 'ap-1'), { displayName: 'x' }));
  });

  it('通知の登録はできる。お知らせの「参加希望者にも表示」は運営だけが付けられる', async () => {
    await assertSucceeds(setDoc(doc(as('hopeful'), 'pushTokens', 'tok-h'), { uid: 'uid-h', accessKey: 'hopeful@example.com', token: 'tok-h', platform: 'iOS', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('hopeful'), 'announcements', 'a-members'), { forApplicants: true, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(as('staff'), 'announcements', 'a-members'), { forApplicants: true, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('staff'), 'announcements', 'a-members'), { forApplicants: 'yes', updatedAt: serverTimestamp() }));
  });

  it('正式加入確認フォームの URL はアプリから変更できない（同期のみ）', async () => {
    await env.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), 'appConfig', 'public'), { vapidKey: 'k', joinFormUrl: 'https://forms.example.com/a', updatedAt: Timestamp.now() });
    });
    await assertSucceeds(getDoc(doc(as('hopeful'), 'appConfig', 'public')));
    await assertSucceeds(setDoc(doc(as('admin'), 'appConfig', 'public'), { vapidKey: 'k2', updatedAt: serverTimestamp() }, { merge: true }));
    await assertFails(setDoc(doc(as('admin'), 'appConfig', 'public'), { joinFormUrl: 'https://evil.example.com', updatedAt: serverTimestamp() }, { merge: true }));
  });
});
