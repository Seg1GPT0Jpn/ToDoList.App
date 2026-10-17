import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteField, serverTimestamp, Timestamp, increment, collection, getDocs, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';

const env = await initializeTestEnvironment({
  projectId: 'demo-tsuzuri',
  firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8181 },
});
let pass = 0, fail = 0;
async function check(name, p) {
  try { await p; pass++; console.log('ok  ', name); }
  catch (e) { fail++; console.log('FAIL', name, e.message.split('\n')[0]); }
}
const db = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const later = (d) => Timestamp.fromMillis(Date.now() + d * 86400000);
const base = (uid, extra = {}) => ({
  code: '123456', name: '1年英語', ownerId: uid, ownerName: 'あ', members: { [uid]: 'あ' },
  tasks: [], closed: false, createdAt: serverTimestamp(), expiresAt: later(180), ...extra,
});

const A = db('alice'), B = db('bob'), C = db('carol'), N = db(null);
// 作成
await check('ログインなしでは作れない', assertFails(setDoc(doc(N, 'classrooms/123456'), base('x'))));
await check('他人をオーナーにして作れない', assertFails(setDoc(doc(A, 'classrooms/123456'), base('bob'))));
await check('コードが6ケタでないと作れない', assertFails(setDoc(doc(A, 'classrooms/012345'), { ...base('alice'), code: '012345' })));
await check('期限が長すぎると作れない', assertFails(setDoc(doc(A, 'classrooms/123456'), base('alice', { expiresAt: later(400) }))));
await check('他人をメンバーに入れて作れない', assertFails(setDoc(doc(A, 'classrooms/123456'), base('alice', { members: { alice: 'あ', bob: 'い' } }))));
await check('作れる', assertSucceeds(setDoc(doc(A, 'classrooms/123456'), base('alice'))));
// 読む
await check('コードを知っていれば読める', assertSucceeds(getDoc(doc(B, 'classrooms/123456'))));
await check('ログインなしでは読めない', assertFails(getDoc(doc(N, 'classrooms/123456'))));
await check('一覧は出せない', assertFails(getDocs(collection(B, 'classrooms'))));
// 入る
await check('他人を入れられない', assertFails(updateDoc(doc(B, 'classrooms/123456'), { 'members.carol': 'う' })));
await check('名前が長すぎると入れない', assertFails(updateDoc(doc(B, 'classrooms/123456'), { 'members.bob': 'あ'.repeat(21) })));
await check('入れる', assertSucceeds(updateDoc(doc(B, 'classrooms/123456'), { 'members.bob': 'い' })));
await check('メンバーは範囲を変えられない', assertFails(updateDoc(doc(B, 'classrooms/123456'), { tasks: [{ id: 'x' }] })));
await check('メンバーは他人を外せない', assertFails(updateDoc(doc(B, 'classrooms/123456'), { 'members.alice': deleteField() })));
await check('ニックネームを変えられる', assertSucceeds(updateDoc(doc(B, 'classrooms/123456'), { 'members.bob': 'いい' })));
// 作った人
await check('作った人は範囲を保存できる', assertSucceeds(updateDoc(doc(A, 'classrooms/123456'), { tasks: [{ id: 't1', from: 1, to: 100 }] })));
await check('作った人は自分を外せない', assertFails(updateDoc(doc(A, 'classrooms/123456'), { 'members.alice': deleteField() })));
await check('作った人はオーナーを変えられない', assertFails(updateDoc(doc(A, 'classrooms/123456'), { ownerId: 'bob' })));
// ボス
await check('メンバーでない人はボスを読めない', assertFails(getDocs(collection(C, 'classrooms/123456/boss'))));
await check('メンバーはボスに正解数を足せる（新規）', assertSucceeds(setDoc(doc(B, 'classrooms/123456/boss/t1'), { dealt: increment(80) }, { merge: true })));
await check('メンバーはボスに正解数を足せる（追加）', assertSucceeds(setDoc(doc(A, 'classrooms/123456/boss/t1'), { dealt: increment(100) }, { merge: true })));
await check('1回に100より多くは足せない', assertFails(setDoc(doc(A, 'classrooms/123456/boss/t1'), { dealt: increment(101) }, { merge: true })));
await check('減らせない', assertFails(setDoc(doc(A, 'classrooms/123456/boss/t1'), { dealt: increment(-5) }, { merge: true })));
await check('メンバーでない人は足せない', assertFails(setDoc(doc(C, 'classrooms/123456/boss/t1'), { dealt: increment(1) }, { merge: true })));
await check('メンバーはボスを読める', assertSucceeds(getDocs(collection(B, 'classrooms/123456/boss'))));
// 抜ける・閉じる
await check('抜けられる', assertSucceeds(updateDoc(doc(B, 'classrooms/123456'), { 'members.bob': deleteField() })));
await check('抜けたらボスに足せない', assertFails(setDoc(doc(B, 'classrooms/123456/boss/t1'), { dealt: increment(1) }, { merge: true })));
await check('作った人は閉じられる', assertSucceeds(updateDoc(doc(A, 'classrooms/123456'), { closed: true })));
await check('閉じたクラスには入れない', assertFails(updateDoc(doc(C, 'classrooms/123456'), { 'members.carol': 'う' })));
await check('消せない', assertFails(deleteDoc(doc(A, 'classrooms/123456'))));
// 期限切れ
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'classrooms/654321'), { ...base('alice'), code: '654321', createdAt: Timestamp.now(), expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
});
await check('期限切れのクラスには入れない', assertFails(updateDoc(doc(C, 'classrooms/654321'), { 'members.carol': 'う' })));
// コードの作り直し：自分だけで作ってから、メンバーを移す
await check('作り直し：自分だけで新しいコードを作れる', assertSucceeds(setDoc(doc(A, 'classrooms/222222'), { ...base('alice'), code: '222222' })));
await check('作り直し：作った人はメンバーを移せる', assertSucceeds(updateDoc(doc(A, 'classrooms/222222'), { members: { alice: 'あ', bob: 'い', carol: 'う' } })));
await check('作り直し：メンバーは移されたあと読める・足せる', assertSucceeds(setDoc(doc(C, 'classrooms/222222/boss/t1'), { dealt: increment(3) }, { merge: true })));
// 単語チャレンジ
const duel = (uid, extra = {}) => ({
  ownerId: uid, ownerName: 'あ', source: 'book', sourceId: 'leap', title: 'LEAP 1〜100',
  numbers: [3, 5, 8], seed: 7, results: { [uid]: { name: 'あ', correct: 8, score: 1100 } },
  createdAt: serverTimestamp(), expiresAt: later(7), ...extra,
});
await check('チャレンジ：ログインなしでは作れない', assertFails(setDoc(doc(N, 'duels/abcd2345'), duel('x'))));
await check('チャレンジ：他人の結果を入れて作れない', assertFails(setDoc(doc(A, 'duels/abcd2345'), duel('alice', { results: { bob: { name: 'い', correct: 1, score: 1 } } }))));
await check('チャレンジ：単語の中身などよけいな項目は置けない', assertFails(setDoc(doc(A, 'duels/abcd2345'), duel('alice', { words: ['apple'] }))));
await check('チャレンジ：IDが8文字でないと作れない', assertFails(setDoc(doc(A, 'duels/ABC'), duel('alice'))));
await check('チャレンジ：期限が長すぎると作れない', assertFails(setDoc(doc(A, 'duels/abcd2345'), duel('alice', { expiresAt: later(30) }))));
await check('チャレンジ：作れる', assertSucceeds(setDoc(doc(A, 'duels/abcd2345'), duel('alice'))));
await check('チャレンジ：IDを知っていれば読める', assertSucceeds(getDoc(doc(B, 'duels/abcd2345'))));
await check('チャレンジ：一覧は出せない', assertFails(getDocs(collection(B, 'duels'))));
await check('チャレンジ：他人の結果は入れられない', assertFails(updateDoc(doc(B, 'duels/abcd2345'), { 'results.carol': { name: 'う', correct: 1, score: 100 } })));
await check('チャレンジ：点数が大きすぎると入れられない', assertFails(updateDoc(doc(B, 'duels/abcd2345'), { 'results.bob': { name: 'い', correct: 1, score: 99999 } })));
await check('チャレンジ：自分の結果を入れられる', assertSucceeds(updateDoc(doc(B, 'duels/abcd2345'), { 'results.bob': { name: 'い', correct: 9, score: 1200 } })));
await check('チャレンジ：2回目は入れられない（上書き不可）', assertFails(updateDoc(doc(B, 'duels/abcd2345'), { 'results.bob': { name: 'い', correct: 10, score: 1500 } })));
await check('チャレンジ：作った人も結果を書き直せない', assertFails(updateDoc(doc(A, 'duels/abcd2345'), { 'results.alice': { name: 'あ', correct: 10, score: 1500 } })));
await check('チャレンジ：問題は変えられない', assertFails(updateDoc(doc(A, 'duels/abcd2345'), { numbers: [1] })));
await check('チャレンジ：消せない', assertFails(deleteDoc(doc(A, 'duels/abcd2345'))));
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'duels/zzzz2345'), { ...duel('alice'), createdAt: Timestamp.now(), expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
});
await check('チャレンジ：期限切れには入れられない', assertFails(updateDoc(doc(C, 'duels/zzzz2345'), { 'results.carol': { name: 'う', correct: 1, score: 100 } })));
// 使った機能の回数
await check('回数：ログインなしでも1足せる（新規）', assertSucceeds(setDoc(doc(N, 'usage/2026-10-17'), { vocab: increment(1) }, { merge: true })));
await check('回数：1足せる（追加）', assertSucceeds(setDoc(doc(A, 'usage/2026-10-17'), { vocab: increment(1) }, { merge: true })));
await check('回数：別の機能も足せる', assertSucceeds(setDoc(doc(N, 'usage/2026-10-17'), { duel: increment(1) }, { merge: true })));
await check('回数：2以上は足せない', assertFails(setDoc(doc(N, 'usage/2026-10-17'), { vocab: increment(5) }, { merge: true })));
await check('回数：減らせない', assertFails(setDoc(doc(N, 'usage/2026-10-17'), { vocab: increment(-1) }, { merge: true })));
await check('回数：2つ同時には足せない', assertFails(setDoc(doc(N, 'usage/2026-10-17'), { vocab: increment(1), duel: increment(1) }, { merge: true })));
await check('回数：知らない項目（名前など）は置けない', assertFails(setDoc(doc(N, 'usage/2026-10-17'), { name: 'あ' }, { merge: true })));
await check('回数：日付でない文書には書けない', assertFails(setDoc(doc(N, 'usage/hello'), { vocab: increment(1) }, { merge: true })));
await check('回数：アプリからは読めない', assertFails(getDoc(doc(A, 'usage/2026-10-17'))));
// ランダム対戦の待ち合わせ
const q = (extra = {}) => ({ name: 'あ', since: Timestamp.now(), ping: Timestamp.now(), room: null, by: null, ...extra });
await check('待ち合わせ：ログインなしでは入れない', assertFails(setDoc(doc(N, 'match_queue/x'), q())));
await check('待ち合わせ：他人の名前では入れない', assertFails(setDoc(doc(A, 'match_queue/bob'), q())));
await check('待ち合わせ：よけいな項目は置けない', assertFails(setDoc(doc(A, 'match_queue/alice'), q({ email: 'a@b' }))));
await check('待ち合わせ：入れる', assertSucceeds(setDoc(doc(A, 'match_queue/alice'), q())));
await check('待ち合わせ：一覧を読める', assertSucceeds(getDocs(collection(B, 'match_queue'))));
await check('待ち合わせ：他人の名前は変えられない', assertFails(updateDoc(doc(B, 'match_queue/alice'), { name: 'ばか' })));
await check('待ち合わせ：他人のbyに別人を入れられない', assertFails(updateDoc(doc(B, 'match_queue/alice'), { room: '1234', by: 'carol' })));
await check('待ち合わせ：部屋を知らせられる', assertSucceeds(updateDoc(doc(B, 'match_queue/alice'), { room: '1234', by: 'bob' })));
await check('待ち合わせ：決まった部屋は横取りできない', assertFails(updateDoc(doc(C, 'match_queue/alice'), { room: '5678', by: 'carol' })));
await check('待ち合わせ：他人は消せない', assertFails(deleteDoc(doc(B, 'match_queue/alice'))));
await check('待ち合わせ：自分は消せる', assertSucceeds(deleteDoc(doc(A, 'match_queue/alice'))));
// ゴースト
const g = (uid, extra = {}) => ({ uid, name: 'あ', setIds: ['s1'], seed: 3, rounds: 10, answers: [1200, -1, -2002], r: 0.5, at: serverTimestamp(), ...extra });
await check('ゴースト：作れる', assertSucceeds(setDoc(doc(A, 'ghosts/g1'), g('alice'))));
await check('ゴースト：他人の名義では作れない', assertFails(setDoc(doc(A, 'ghosts/g2'), g('bob'))));
await check('ゴースト：よけいな項目は置けない', assertFails(setDoc(doc(A, 'ghosts/g3'), g('alice', { email: 'x' }))));
await check('ゴースト：読める', assertSucceeds(getDocs(collection(B, 'ghosts'))));
await check('ゴースト：変えられない', assertFails(updateDoc(doc(A, 'ghosts/g1'), { name: 'い' })));
// 報告
const rep = (extra = {}) => ({ from: 'alice', about: 'bob', reason: 'name', at: serverTimestamp(), ...extra });
await check('報告：送れる', assertSucceeds(setDoc(doc(A, 'player_reports/r1'), rep())));
await check('報告：他人のふりはできない', assertFails(setDoc(doc(A, 'player_reports/r2'), rep({ from: 'carol' }))));
await check('報告：理由は決まったものだけ', assertFails(setDoc(doc(A, 'player_reports/r3'), rep({ reason: 'free text' }))));
await check('報告：読めない', assertFails(getDoc(doc(A, 'player_reports/r1'))));
// 既存のルールが壊れていない
await check('自分の進行状況は書ける（既存）', assertSucceeds(setDoc(doc(A, 'users/alice/rpg_progress/main'), { level: 1 })));
await check('他人の進行状況は読めない（既存）', assertFails(getDoc(doc(B, 'users/alice/rpg_progress/main'))));
console.log(`\n${pass} ok / ${fail} fail`);
await env.cleanup();
process.exit(fail ? 1 : 0);
