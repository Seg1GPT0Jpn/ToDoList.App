// AI スタジオ：依頼文 → 条件 → 既存問題の検索 → 不足分を AI で作成 → 検証 → 人が承認
import { state, saveQuestion, saveQuestions, saveMaterial, setCurrentMaterial, log } from '../core/store.js';
import * as db from '../core/db.js';
import { esc, toast, uid, nowISO, shuffle, fmtDate } from '../core/util.js';
import { newQuestion, normalizeQuestion, newId, LEVELS } from '../domain/question.js';
import { newMaterial, questionBlock, blockId } from '../domain/material.js';
import { availability, callAI, verifyQuestion } from '../ai/client.js';
import { renderMath, texClass, questionDetail, addToCurrentMaterial, R, TYPE_LABEL } from './common.js';
import { editQuestion } from './qeditor.js';

const mem = {
  text: '', cond: { subj: '', course: '', grade: '', units: '', level: '', count: 10, types: [], timeMin: '', totalPts: '', exclude: '', explanation: 'detailed', notes: '' },
  items: [], // {q, from:'bank'|'ai', state, notes}
};
const STATE_LABEL = { bank: '既存', verifying: '検証中', verified: '検証済み', needs_fix: '要修正', approved: '人間承認済み', discarded: '破棄' };

export async function render(root) {
  const av = await availability();
  root.innerHTML = `
  <div class="page-head"><div class="grow"><h1>AIスタジオ</h1><p>依頼文から条件を読み取り、問題バンクを先に探して、足りない分だけ AI が作ります。AI が作った問題は検証し、<b>人が承認するまで正式な問題にはなりません</b>。</p></div></div>
  ${av.ok ? '<div class="notice ok">AI を使える状態です（Claude）。</div>' : `<div class="notice warn"><b>AI は使えません：</b>${esc(av.reason)}<br>AI を使わなくても、下の条件を手で入れて既存の問題を探し、教材に追加できます。</div>`}
  <div class="grid2">
    <section class="card">
      <h2>1. 依頼文</h2>
      <textarea class="input" id="s-text" rows="4" placeholder="例：高校1年生向けに数学Ⅰの二次関数の最大・最小を扱う標準問題を10問作成してください。計算問題だけでなく、文章題も含めてください。"></textarea>
      <div class="row mt"><button class="btn primary" id="s-parse" ${av.ok ? '' : 'disabled'}>条件を読み取る（AI）</button><span class="small muted">読み取った条件は右で直せます</span></div>
      <h2 class="mt">AI の道具</h2>
      <div class="row"><button class="btn" id="s-plan" ${av.ok ? '' : 'disabled'}>依頼文から教材の構成案を作る</button></div>
      <p class="small muted">問題ごとの解説づくり・校閲は、問題の編集画面の「AI」ボタンからも使えます。</p>
    </section>
    <section class="card">
      <h2>2. 条件</h2>
      <div class="form-grid two">
        <label class="f">教科<input class="input" data-c="subj" list="st-subj"></label>
        <label class="f">科目<input class="input" data-c="course" list="st-course"></label>
        <label class="f">学年<input class="input" data-c="grade"></label>
        <label class="f">単元（読点区切り）<input class="input" data-c="units" list="st-unit"></label>
        <label class="f">難易度<select class="input" data-c="level"><option value="">指定なし</option>${LEVELS.map(l => `<option>${l}</option>`).join('')}</select></label>
        <label class="f">問題数<input class="input" type="number" min="1" max="50" data-c="count"></label>
        <label class="f">想定時間（分）<input class="input" type="number" data-c="timeMin"></label>
        <label class="f">配点の合計<input class="input" type="number" data-c="totalPts"></label>
        <label class="f">除外する内容<input class="input" data-c="exclude"></label>
        <label class="f">解説の詳しさ<select class="input" data-c="explanation"><option value="brief">簡単</option><option value="detailed">詳しく</option><option value="none">なし</option></select></label>
      </div>
      <div class="f">問題形式 ${Object.entries(TYPE_LABEL).filter(([k]) => k !== 'steps').map(([k, l]) => `<label class="check" style="display:inline-flex;margin-right:10px"><input type="checkbox" data-type="${k}"> ${l}</label>`).join('')}</div>
      <label class="f">その他の条件<input class="input" data-c="notes" placeholder="例：文章題を含める"></label>
      <div class="row"><button class="btn primary" id="s-search">既存の問題を探す</button><button class="btn" id="s-gen" ${av.ok ? '' : 'disabled'}>不足分を AI で作る</button></div>
      <p class="small muted" id="s-found"></p>
      <datalist id="st-subj">${[...new Set(state.questions.map(q => q.subj).filter(Boolean))].map(v => `<option value="${esc(v)}">`).join('')}</datalist>
      <datalist id="st-course">${[...new Set(state.questions.map(q => q.course).filter(Boolean))].map(v => `<option value="${esc(v)}">`).join('')}</datalist>
      <datalist id="st-unit">${[...new Set(state.questions.map(q => q.unit).filter(Boolean))].slice(0, 500).map(v => `<option value="${esc(v)}">`).join('')}</datalist>
    </section>
  </div>
  <section class="card">
    <div class="row"><h2 style="margin:0">3. 結果</h2><span class="spacer"></span>
      <button class="btn" id="s-approve-all">検証済みをすべて承認</button><button class="btn primary" id="s-add">承認済み・既存の問題を教材に追加</button><button class="btn ghost" id="s-clear">結果を消す</button></div>
    <p class="small muted" id="s-progress" role="status"></p>
    <ol class="qlist" id="s-items"></ol>
  </section>
  <section class="card">
    <h2>AI の利用履歴</h2>
    <div id="s-jobs"></div>
  </section>`;
  const $ = (id) => /** @type {any} */ (root.querySelector('#' + id));
  $('s-text').value = mem.text;

  const fill = () => {
    root.querySelectorAll('[data-c]').forEach(el => { el.value = mem.cond[el.dataset.c] ?? ''; });
    root.querySelectorAll('[data-type]').forEach(el => { el.checked = mem.cond.types.includes(el.dataset.type); });
  };
  fill();
  root.querySelectorAll('[data-c]').forEach(el => el.addEventListener('change', () => { mem.cond[el.dataset.c] = el.type === 'number' ? Number(el.value) || '' : el.value; }));
  root.querySelectorAll('[data-type]').forEach(el => el.addEventListener('change', () => { mem.cond.types = [...root.querySelectorAll('[data-type]:checked')].map(x => /** @type {any} */ (x).dataset.type); }));
  $('s-text').addEventListener('input', () => { mem.text = $('s-text').value; });
  const units = () => String(mem.cond.units || '').split(/[,、，]/).map(s => s.trim()).filter(Boolean);
  const progress = (t) => { $('s-progress').textContent = t; };

  // ---------- 1. 依頼文 → 条件 ----------
  $('s-parse').addEventListener('click', async () => {
    if (!mem.text.trim()) { toast('依頼文を入れてください', 'error'); return; }
    progress('条件を読み取っています…');
    const r = await callAI('parse_request', { text: mem.text }, '条件の読み取り');
    progress('');
    if (!r.ok) { toast('読み取れませんでした：' + r.error.message, 'error'); return; }
    const d = r.data;
    Object.assign(mem.cond, {
      subj: d.subj || '', course: d.course || '', grade: d.grade || '', units: (d.units || []).join('、'), level: d.level || '',
      count: d.count || 10, types: d.types || [], timeMin: d.timeMin || '', totalPts: d.totalPts || '',
      exclude: [...((d.exclude || {}).units || []), ...((d.exclude || {}).keywords || [])].join('、'), explanation: d.explanation || 'detailed', notes: d.notes || '',
    });
    fill();
    toast('条件を読み取りました。確認して「既存の問題を探す」を押してください', 'ok');
  });

  // ---------- 2. 既存の問題を先に探す ----------
  const matchBank = () => {
    const us = units(), ex = String(mem.cond.exclude || '').split(/[,、，]/).map(s => s.trim()).filter(Boolean);
    return state.questions.filter(q => {
      if (q.origin === 'ai' && q.status !== 'approved') return false;
      if (q.compact) return false;
      if (mem.cond.subj && q.subj !== mem.cond.subj) return false;
      if (mem.cond.course && q.course !== mem.cond.course) return false;
      if (mem.cond.grade && q.grade && q.grade !== mem.cond.grade) return false;
      if (us.length && !us.some(u => (q.unit || '').includes(u) || (q.subunit || '').includes(u))) return false;
      if (mem.cond.level && q.level !== mem.cond.level) return false;
      if (mem.cond.types.length && !mem.cond.types.includes(q.type)) return false;
      if (ex.some(w => (q.stem + (q.unit || '') + (q.subunit || '')).includes(w))) return false;
      return true;
    });
  };
  $('s-search').addEventListener('click', () => {
    const found = matchBank();
    const n = Number(mem.cond.count) || 10;
    const picked = shuffle(found.slice()).slice(0, n);
    mem.items = mem.items.filter(it => it.from === 'ai');
    picked.forEach(q => mem.items.push({ q, from: 'bank', state: 'bank', notes: [] }));
    $('s-found').textContent = `問題バンクで条件に合う問題：${found.length} 問。${picked.length} 問を選びました${picked.length < n ? `（あと ${n - picked.length} 問足りません。「不足分を AI で作る」で作れます）` : '。'}`;
    renderItems();
  });

  // ---------- 不足分を AI で作る ----------
  $('s-gen').addEventListener('click', async () => {
    const n = Number(mem.cond.count) || 10;
    const have = mem.items.filter(it => it.state !== 'discarded').length;
    let need = Math.max(0, n - have);
    if (!need) { if (!confirm('条件の問題数はそろっています。さらに作りますか？')) return; need = Math.min(5, n); }
    const existing = matchBank().slice(0, 40).map(q => '・' + (q.stem || '').slice(0, 80)).join('\n');
    const bank = state.questions.filter(q => !mem.cond.subj || q.subj === mem.cond.subj);
    $('s-gen').disabled = true;
    try {
      // 1回に作る数を5問までに分ける（時間切れを防ぐ）
      for (let made = 0; made < need;) {
        const k = Math.min(5, need - made);
        progress(`AI が問題を作っています…（${made + 1}〜${made + k} 問目 / ${need} 問）`);
        const r = await callAI('generate', { conditions: { ...mem.cond, units: units(), request: mem.text }, existing, count: k }, `問題作成 ${k}問：${(mem.cond.course || mem.cond.subj || '')} ${units().join('・')}`);
        if (!r.ok) { toast('作成できませんでした：' + r.error.message, 'error'); break; }
        const author = await db.kvGet('author', '');
        for (const raw of r.data.questions) {
          const q = normalizeQuestion({
            ...newQuestion({}), ...raw, id: undefined, origin: 'ai', src: 'AI', status: 'verifying', author: author || 'AI',
            subj: raw.subj || mem.cond.subj, course: raw.course || mem.cond.course, grade: raw.grade || mem.cond.grade, unit: raw.unit || units()[0] || '',
          });
          q.id = newId('AI');
          const saved = await saveQuestion(q, 'AI 生成');
          const item = { q: saved, from: 'ai', state: 'verifying', notes: [] };
          mem.items.push(item);
          renderItems();
          const res = await verifyQuestion(saved, bank, (t) => progress(`検証中：${(saved.stem || '').slice(0, 20)}… ${t}`));
          item.notes = res.notes;
          item.fixed = res.fixed;
          item.state = res.status;
          item.q = await saveQuestion({ ...saved, status: res.status }, `AI 検証：${res.status === 'verified' ? '検証済み' : '要修正'}`);
          renderItems();
        }
        made += k;
      }
      progress('完了しました。内容を確認して「承認」してください。');
      await log('AI で問題を作成', `${mem.cond.course || mem.cond.subj}`, units().join('・'));
    } finally {
      $('s-gen').disabled = false;
    }
  });

  // ---------- 結果 ----------
  const renderItems = () => {
    $('s-items').innerHTML = mem.items.map((it, i) => it.state === 'discarded' ? '' : `<li class="qrow" data-i="${i}">
      <div class="qmain">
        <div class="tags"><span class="chip ${it.from === 'bank' ? '' : 'accent'}">${it.from === 'bank' ? '既存（問題バンク）' : '新規（AI生成）'}</span>
          ${it.from === 'ai' ? `<span class="chip ${{ verified: 'accent', needs_fix: 'danger', approved: 'ok', verifying: 'warn' }[it.state] || ''}">${STATE_LABEL[it.state]}</span>` : ''}
          <span class="tag">${esc(it.q.level || '')}</span><span class="tag">${esc(TYPE_LABEL[it.q.type] || '')}</span><span class="unit">${esc(it.q.unit || '')}</span></div>
        <div class="qstem ${texClass(it.q)}">${R().text(it.q.stem)}</div>
        <details${it.from === 'ai' ? ' open' : ''}><summary>選択肢・答え・解説${it.notes.length ? '・検証結果' : ''}</summary><div class="${texClass(it.q)}">${questionDetail(it.q)}</div>
          ${it.notes.length ? `<ul class="small" style="margin:6px 0 0">${it.notes.map(n => `<li>${esc(n)}</li>`).join('')}</ul>` : ''}</details>
      </div>
      <div class="qactions">
        ${it.from === 'ai' && it.state !== 'approved' && it.state !== 'verifying' ? '<button class="btn sm primary" data-act="approve">承認</button>' : ''}
        ${it.fixed && it.state === 'needs_fix' ? '<button class="btn sm" data-act="fixed">校閲の修正案を使う</button>' : ''}
        <button class="btn sm" data-act="edit">編集</button>
        ${it.from === 'ai' && it.state !== 'verifying' ? '<button class="btn sm" data-act="reverify">再検証</button>' : ''}
        <button class="btn sm danger" data-act="discard">${it.from === 'ai' ? '破棄' : 'はずす'}</button>
      </div></li>`).join('') || '<li class="empty">まだ結果はありません。条件を決めて「既存の問題を探す」を押してください。</li>';
    renderMath($('s-items'));
  };
  renderItems();

  $('s-items').addEventListener('click', async (e) => {
    const act = e.target.dataset.act;
    if (!act) return;
    const it = mem.items[+e.target.closest('[data-i]').dataset.i];
    if (act === 'approve') {
      if (it.state === 'needs_fix' && !confirm('この問題は「要修正」です。内容を直したうえで承認しますか？')) return;
      it.q = await saveQuestion({ ...it.q, status: 'approved' }, '人が承認');
      it.state = 'approved';
      toast('承認しました。問題バンクの通常の検索にも出ます', 'ok');
    }
    if (act === 'fixed') {
      const saved = await editQuestion({ ...it.q, ...it.fixed, id: it.q.id, origin: 'ai', status: 'verified' }, { title: '校閲の修正案を確認' });
      if (saved) { it.q = saved; it.state = saved.status; it.fixed = null; }
    }
    if (act === 'edit') {
      const saved = await editQuestion(it.q);
      if (saved) { it.q = saved; if (it.from === 'ai') it.state = saved.status; }
    }
    if (act === 'reverify') {
      it.state = 'verifying'; renderItems();
      const res = await verifyQuestion(it.q, state.questions.filter(q => q.subj === it.q.subj && q.id !== it.q.id), (t) => progress(t));
      it.notes = res.notes; it.fixed = res.fixed; it.state = res.status;
      it.q = await saveQuestion({ ...it.q, status: res.status }, 'AI 再検証');
      progress('');
    }
    if (act === 'discard') {
      if (it.from === 'ai' && !confirm('この AI 生成問題を破棄しますか？（問題バンクからも消えます）')) return;
      if (it.from === 'ai') { const { deleteQuestions } = await import('../core/store.js'); await deleteQuestions([it.q.id]); }
      it.state = 'discarded';
    }
    renderItems();
  });
  $('s-approve-all').addEventListener('click', async () => {
    const list = mem.items.filter(it => it.from === 'ai' && it.state === 'verified');
    if (!list.length) { toast('検証済みの問題がありません'); return; }
    if (!confirm(`検証済みの ${list.length} 問を承認します。内容を確認しましたか？`)) return;
    const saved = await saveQuestions(list.map(it => ({ ...it.q, status: 'approved' })), '人が一括承認');
    list.forEach((it, i) => { it.q = saved[i]; it.state = 'approved'; });
    renderItems();
    toast(`${list.length} 問を承認しました`, 'ok');
  });
  $('s-add').addEventListener('click', async () => {
    const list = mem.items.filter(it => it.state === 'bank' || it.state === 'approved').map(it => it.q);
    const pending = mem.items.filter(it => it.from === 'ai' && ['verified', 'needs_fix'].includes(it.state)).length;
    if (!list.length) { toast(pending ? '承認済みの問題がありません。先に内容を確認して承認してください' : '追加できる問題がありません', 'error'); return; }
    const r = await addToCurrentMaterial(list);
    toast(`${r.added} 問を作業中の教材に追加しました${pending ? `（未承認の ${pending} 問は追加していません）` : ''}`, 'ok');
  });
  $('s-clear').addEventListener('click', () => { mem.items = []; renderItems(); $('s-found').textContent = ''; });

  // ---------- 教材の構成案 ----------
  $('s-plan').addEventListener('click', async () => {
    const purpose = mem.text.trim() || [mem.cond.course || mem.cond.subj, units().join('・'), mem.cond.notes].filter(Boolean).join(' ');
    if (!purpose) { toast('依頼文か条件を入れてください', 'error'); return; }
    progress('教材の構成案を作っています…');
    const r = await callAI('plan_material', { purpose }, '教材の構成案');
    progress('');
    if (!r.ok) { toast('作れませんでした：' + r.error.message, 'error'); return; }
    const d = r.data;
    const m = newMaterial(d.kind || 'worksheet', { id: uid('M-'), now: nowISO() });
    m.title = d.title || m.title; m.subtitle = d.subtitle || '';
    if (d.page) { m.page.size = d.page.size || m.page.size; m.page.orientation = d.page.orientation || m.page.orientation; m.page.cols = String(d.page.cols || m.page.cols); }
    const pool = matchBank();
    const used = new Set();
    m.blocks = [];
    for (const b of d.blocks || []) {
      if (b.type === 'question') {
        // 構成案の「必要な問題」は、まず問題バンクから探す。なければ空欄の案内を置く
        const want = String(b.want || '');
        const hit = pool.find(q => !used.has(q.id) && (!want || [q.unit, q.subunit, q.stem].join(' ').includes(want.slice(0, 6))));
        if (hit) { used.add(hit.id); m.blocks.push(questionBlock(hit)); }
        else m.blocks.push({ id: blockId(), type: 'text', text: `【ここに問題：${want}】` });
      } else if (['heading', 'text', 'section', 'pagebreak', 'table', 'space'].includes(b.type)) {
        m.blocks.push({ ...b, id: blockId() });
      }
    }
    await saveMaterial(m);
    await setCurrentMaterial(m.id);
    toast('構成案から教材を作りました。内容を確認して直してください', 'ok');
    location.hash = '#/editor/' + m.id;
  });

  // ---------- 利用履歴 ----------
  const jobs = (await db.all('aiJobs')).sort((a, b) => b.at.localeCompare(a.at)).slice(0, 30);
  $('s-jobs').innerHTML = jobs.length ? `<table class="list small">${jobs.map(j => `<tr><td>${fmtDate(j.at, true)}</td><td>${esc(j.label)}</td><td>${j.status === 'ok' ? '<span class="chip ok">完了</span>' : `<span class="chip danger">${esc(j.status)}</span> ${esc(j.error || '')}`}</td><td>${j.tokens ? j.tokens.toLocaleString() + ' トークン' : ''}</td><td>${esc(j.model || '')}</td></tr>`).join('')}</table>` : '<p class="empty">まだ AI を使っていません。</p>';
}
