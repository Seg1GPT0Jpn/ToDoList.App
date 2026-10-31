// ホーム
import { state, saveMaterial, setCurrentMaterial } from '../core/store.js';
import * as db from '../core/db.js';
import { esc, fmtDate, uid, nowISO, toast } from '../core/util.js';
import { newMaterial, questionBlock } from '../domain/material.js';
import { kindLabel, currentMaterial } from './common.js';

export async function render(root) {
  const [hist, jobs, seen] = await Promise.all([db.all('history'), db.all('aiJobs'), db.kvGet('tutorialDone', false)]);
  const cur = await currentMaterial();
  const recentMaterials = state.materials.filter(m => m.status !== 'archived').slice(0, 6);
  const recentQs = [...state.user.values()].filter(q => !q.deleted).sort((a, b) => (b.updatedAt || '').localeCompare(a.updatedAt || '')).slice(0, 6);
  const pendingAI = state.questions.filter(q => q.origin === 'ai' && q.status !== 'approved');
  const needFix = state.questions.filter(q => q.status === 'needs_fix');
  const inReview = state.materials.filter(m => m.status === 'review');
  const activity = hist.filter(h => h.action !== 'エラー').sort((a, b) => b.at.localeCompare(a.at)).slice(0, 8);
  const counts = { all: state.questions.length, units: new Set(state.questions.map(q => (q.subj || '') + q.unit)).size };

  root.innerHTML = `
  <div class="page-head"><div class="grow"><h1>ホーム</h1><p>問題 ${counts.all.toLocaleString()} 問（${counts.units.toLocaleString()} 単元）・教材 ${state.materials.length} 件</p></div>
    <a class="btn primary" href="#/editor/new">＋ 新しい教材</a><a class="btn" href="#/exam">テストを作る</a></div>
  ${seen ? '' : `
  <section class="card tutorial" id="tutorial">
    <h2>はじめての方へ <span class="spacer"></span><button class="btn sm ghost" id="tut-close">閉じる</button></h2>
    <p>このアプリには<b>高校5教科（国語・数学・英語・理科・社会）の問題 3,840 問が最初から入っています</b>。データを用意しなくても、すぐにプリントを作れます。</p>
    <ol>
      <li><b>問題バンク</b>で教科・単元・難易度をしぼり、問題を「＋追加」する（「ランダムに追加」も使えます）</li>
      <li><b>教材制作</b>で見出しや文章を足し、用紙・解答欄・配点を設定する</li>
      <li>「印刷／PDF」で問題用紙・解答用紙・解答解説を出す</li>
    </ol>
    <div class="row mt"><button class="btn primary" id="sample">サンプルのプリントを作ってみる</button><span class="muted small">数学Ⅰ「二次関数」から基礎・標準・応用を選んだプリントを作ります</span></div>
    <p class="small muted mt">手持ちの問題データ（zip / json）があれば「設定・データ」から読み込めます。チーム共有や AI を使うにはクラウド接続が必要です（「設定・データ」に手順）。</p>
  </section>`}
  <div class="stats">
    <a class="stat" href="#/editor" style="text-decoration:none;color:inherit"><b>${cur ? cur.blocks.filter(b => b.type === 'question').length : 0}</b><span>作業中の教材の問題数${cur ? '（' + esc(cur.title) + '）' : ''}</span></a>
    <a class="stat" href="#/bank?status=pending" style="text-decoration:none;color:inherit"><b>${pendingAI.length}</b><span>承認待ちの AI 生成問題</span></a>
    <a class="stat" href="#/bank?status=needs_fix" style="text-decoration:none;color:inherit"><b>${needFix.length}</b><span>要修正の問題</span></a>
    <a class="stat" href="#/library" style="text-decoration:none;color:inherit"><b>${inReview.length}</b><span>レビュー待ちの教材</span></a>
  </div>
  <div class="grid2">
    <section class="card">
      <h2>最近の教材</h2>
      ${recentMaterials.length ? `<table class="list">${recentMaterials.map(m => `<tr><td><a href="#/editor/${esc(m.id)}">${esc(m.title)}</a>${cur && cur.id === m.id ? ' <span class="chip accent">作業中</span>' : ''}<div class="small muted">${esc(kindLabel(m.kind))}・問題 ${m.blocks.filter(b => b.type === 'question').length} 問</div></td><td class="small muted">${fmtDate(m.updatedAt, true)}</td></tr>`).join('')}</table>`
        : '<div class="empty">まだ教材がありません。<br><a class="btn primary" href="#/editor/new">教材を作る</a></div>'}
    </section>
    <section class="card">
      <h2>最近作成・編集した問題</h2>
      ${recentQs.length ? `<table class="list">${recentQs.map(q => `<tr><td><a href="#/bank?id=${encodeURIComponent(q.id)}">${esc((q.stem || '').slice(0, 50))}</a><div class="small muted">${esc([q.course || q.subj, q.unit].filter(Boolean).join('｜'))}</div></td><td class="small muted">${fmtDate(q.updatedAt, true)}</td></tr>`).join('')}</table>`
        : '<div class="empty">自作・編集した問題はまだありません。<br><a class="btn" href="#/bank?new=1">問題を作る</a></div>'}
    </section>
    <section class="card">
      <h2>AI の生成履歴</h2>
      ${jobs.length ? `<table class="list small">${jobs.sort((a, b) => b.at.localeCompare(a.at)).slice(0, 6).map(j => `<tr><td>${esc(j.label || j.action)}</td><td>${j.status === 'ok' ? '<span class="chip ok">完了</span>' : `<span class="chip danger">${esc(j.status)}</span>`}</td><td class="muted">${fmtDate(j.at, true)}</td></tr>`).join('')}</table>`
        : '<div class="empty">AI はまだ使っていません。<br><a class="btn" href="#/studio">AIスタジオへ</a></div>'}
    </section>
    <section class="card">
      <h2>最近の操作</h2>
      ${activity.length ? `<table class="list small">${activity.map(h => `<tr><td>${esc(h.action)}<div class="muted">${esc(h.detail || h.target)}</div></td><td class="muted" style="white-space:nowrap">${fmtDate(h.at, true)}</td></tr>`).join('')}</table>` : '<div class="empty">まだ操作の記録はありません。</div>'}
    </section>
  </div>
  <section class="card">
    <h2>よく使う機能</h2>
    <div class="row">
      <a class="btn" href="#/bank">問題をさがす</a><a class="btn" href="#/bank?new=1">問題を登録</a><a class="btn" href="#/editor/new">プリントを作る</a>
      <a class="btn" href="#/editor/new/wordtest">単語テストを作る</a><a class="btn" href="#/exam">テストを自動で作る</a><a class="btn" href="#/answers">解答・解説を整える</a>
      <a class="btn" href="#/settings">データの読み込み・バックアップ</a>
    </div>
  </section>`;

  const close = root.querySelector('#tut-close');
  if (close) close.addEventListener('click', async () => { await db.kvSet('tutorialDone', true); root.querySelector('#tutorial').remove(); });
  const sample = root.querySelector('#sample');
  if (sample) sample.addEventListener('click', async () => {
    const pool = state.questions.filter(q => q.src === '内蔵' && q.unit === '二次関数' && q.course === '数学Ⅰ');
    if (!pool.length) { toast('内蔵問題が読み込めていないため、サンプルを作れませんでした', 'error'); return; }
    const pick = (lv, n) => pool.filter(q => q.level === lv).slice(0, n);
    const m = newMaterial('quiz', { id: uid('M-'), now: nowISO() });
    m.title = '二次関数 確認テスト（サンプル）';
    m.blocks = [...pick('基礎', 3), ...pick('標準', 4), ...pick('応用', 2)].map(questionBlock);
    m.print.group = 'type';
    await saveMaterial(m);
    await setCurrentMaterial(m.id);
    await db.kvSet('tutorialDone', true);
    location.hash = '#/editor/' + m.id;
  });
}
