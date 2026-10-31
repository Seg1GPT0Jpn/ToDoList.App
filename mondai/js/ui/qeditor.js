// 問題の登録・編集フォーム（モーダル）
import { state, saveQuestion } from '../core/store.js';
import * as db from '../core/db.js';
import { esc, clone, toast, debounce } from '../core/util.js';
import { QUESTION_TYPES, LEVELS, STATUSES, newQuestion, validateQuestion } from '../domain/question.js';
import { checkAnswer } from '../domain/mathcheck.js';
import { varyQuestion, validateVary } from '../domain/variant.js';
import { modal, renderMath, R } from './common.js';

const lines = (s) => String(s || '').split('\n').map(x => x.trim()).filter(Boolean);
const csv = (s) => String(s || '').split(/[,、，]/).map(x => x.trim()).filter(Boolean);

function datalist(id, key) {
  const vals = [...new Set(state.questions.map(q => q[key]).filter(Boolean))].sort((a, b) => String(a).localeCompare(String(b), 'ja')).slice(0, 400);
  return `<datalist id="${id}">${vals.map(v => `<option value="${esc(v)}">`).join('')}</datalist>`;
}

/**
 * 問題を編集する。保存したら保存後の問題、やめたら null を返す
 * @param {any} [original] 既存の問題（なければ新規）
 * @param {{title?:string, saveLabel?:string, onSave?:(q:any)=>Promise<any>}} [opt]
 */
export function editQuestion(original, opt = {}) {
  return new Promise(async (resolve) => {
    // 問題バンクにまだない問題（新規・複製・取り込み前）は新規として扱う
    const isNew = !original || !state.byId.has(original.id);
    if (isNew) original = undefined;
    const seed = arguments[0];
    const author = await db.kvGet('author', '');
    const q = seed ? clone(seed) : newQuestion({ author, subj: '', level: '標準', type: 'choice', choices: ['', '', '', ''], ai: [0] });
    if (isNew && !q.author) q.author = author;
    if (!q.choices) q.choices = [];
    if (!q.ai) q.ai = [];
    const typeOpts = Object.entries(QUESTION_TYPES).map(([k, d]) => `<option value="${k}">${esc(d.label)}</option>`).join('');
    const rating = original ? await db.get('ratings', original.id) : null;
    const usedIn = original ? state.materials.filter(m => m.blocks.some(b => b.type === 'question' && b.ref === original.id)) : [];

    const m = modal({
      title: opt.title || (isNew ? '問題を登録' : '問題を編集'),
      body: `
      <div class="grid2">
        <div>
          <div class="form-grid two">
            <label class="f">形式<select class="input" name="type">${typeOpts}</select></label>
            <label class="f">難易度<select class="input" name="level"><option value="">（なし）</option>${LEVELS.map(l => `<option>${l}</option>`).join('')}</select></label>
          </div>
          <label class="f">問題文（数式は $...$、下線は [[u:語句]]）<textarea class="input" name="stem" rows="4"></textarea></label>
          <label class="f">付属の文・資料（任意）<textarea class="input" name="sentence" rows="2"></textarea></label>
          <div class="f">図 <button class="btn sm" type="button" id="fig-draw">図を描く</button> <button class="btn sm danger" type="button" id="fig-clear" hidden>図をはずす</button>
            <input class="input" name="figCaption" placeholder="図の説明・キャプション（任意）" style="margin-top:4px"></div>
          <div id="ans-area"></div>
          <details class="mt"><summary>解説・採点基準</summary>
            <label class="f">解説<textarea class="input" name="expl" rows="3"></textarea></label>
            <label class="f">解き方の手順（1行に1つ）<textarea class="input" name="steps" rows="3"></textarea></label>
            <label class="f">初学者向けの解説<textarea class="input" name="explBasic" rows="2"></textarea></label>
            <label class="f">発展的な解説<textarea class="input" name="explAdvanced" rows="2"></textarea></label>
            <label class="f">よくある誤答（1行に1つ）<textarea class="input" name="mistakes" rows="2"></textarea></label>
            <label class="f">採点基準（1行に「基準｜点」）<textarea class="input" name="rubric" rows="3" placeholder="平方完成している｜2"></textarea></label>
          </details>
          <details class="mt"><summary>分類・属性</summary>
            <div class="form-grid two">
              <label class="f">段階<select class="input" name="stage"><option value=""></option><option>小学</option><option>中学</option><option>高校</option></select></label>
              <label class="f">教科<input class="input" name="subj" list="dl-subj"></label>
              <label class="f">科目<input class="input" name="course" list="dl-course"></label>
              <label class="f">学年<input class="input" name="grade" list="dl-grade" placeholder="高1"></label>
              <label class="f">分野<input class="input" name="field"></label>
              <label class="f">単元<input class="input" name="unit" list="dl-unit"></label>
              <label class="f">小単元<input class="input" name="subunit"></label>
              <label class="f">配点<input class="input" name="pts" type="number" min="0" step="1"></label>
              <label class="f">想定時間（分）<input class="input" name="timeMin" type="number" min="0" step="0.5"></label>
              <label class="f">出典<input class="input" name="src"></label>
            </div>
            <label class="f">必要な知識（読点区切り）<input class="input" name="knowledge"></label>
            <label class="f">出題意図<input class="input" name="intent"></label>
            <label class="f">タグ（読点区切り）<input class="input" name="tags" placeholder="頻出、計算"></label>
            <label class="f">検証状態<select class="input" name="status">${Object.entries(STATUSES).map(([k, l]) => `<option value="${k}">${esc(l)}</option>`).join('')}</select></label>
            <div class="form-grid two">
              <label class="f">検算用の式（任意）<input class="input mono" name="checkExpr" placeholder="(3+5)^2/4"></label>
              <label class="f">式の答え（空なら正答と比べる）<input class="input mono" name="checkExpect"></label>
            </div>
            <button class="btn sm" type="button" id="run-check">式で検算する</button> <span id="check-out" class="small"></span>
          </details>
          <details class="mt"><summary>数値替えのテンプレート（上級者向け）</summary>
            <p class="small muted">数値だけを変えた版を作るための設定です（JSON）。書き方：<code>{"vars":{"a":{"min":2,"max":9}},"stem":"… {{a}} …","ans":"{{=a*2}}","check":"a*2","expl":"…","original":{"a":3}}</code>。
              <code>{{a}}</code> に値、<code>{{=式}}</code> に計算結果が入ります（<code>|frac</code> 分数、<code>|sign</code> 符号つき、<code>|coef</code> 係数）。空欄なら、検算の式から自動で作ります。</p>
            <textarea class="input mono" name="varyJson" rows="6"></textarea>
            <button class="btn sm" type="button" id="try-vary">試しに作る</button>
            <div id="vary-out" class="small mt"></div>
          </details>
          ${datalist('dl-subj', 'subj')}${datalist('dl-course', 'course')}${datalist('dl-grade', 'grade')}${datalist('dl-unit', 'unit')}
        </div>
        <div>
          <div class="small muted">見本</div>
          <div class="preview-wrap" style="padding:10px"><div class="paper" style="min-height:0;width:auto;padding:14px;margin:0" id="qe-prev"></div></div>
          <ul class="err-list mt" id="qe-err"></ul>
          ${original ? `<div class="small muted mt">ID：${esc(original.id)}・版 ${original.rev || 1}・${original.updatedAt ? '更新 ' + new Date(original.updatedAt).toLocaleString('ja-JP') : ''}<br>使われている教材：${usedIn.length ? usedIn.map(x => esc(x.title)).join('、') : 'なし'}</div>` : ''}
          ${original ? `<div class="mt"><span class="small muted">この問題の評価：</span><span id="stars">${[1, 2, 3, 4, 5].map(n => `<button type="button" class="btn ghost sm" data-star="${n}">${rating && rating.stars >= n ? '★' : '☆'}</button>`).join('')}</span>
            <input class="input" id="rate-comment" placeholder="評価のメモ（任意）" value="${esc(rating ? rating.comment || '' : '')}"></div>` : ''}
        </div>
      </div>`,
      foot: `<span class="small muted" id="qe-ai-msg"></span><button class="btn" id="qe-ai-explain" title="AI が解説・別解・採点基準の案を作ります">AIで解説を作る</button><button class="btn" id="qe-ai-review" title="AI が問題を校閲します">AIで校閲</button>
        <span class="spacer"></span><button class="btn" data-close>やめる</button><button class="btn primary" id="qe-save">${esc(opt.saveLabel || '保存')}</button>`,
      onClose: () => resolve(null),
    });
    const form = m.el;
    const f = (name) => /** @type {any} */ (form.querySelector(`[name="${name}"]`));
    const set = (name, v) => { const el = f(name); if (el) el.value = v == null ? '' : v; };

    // 値を入れる
    ['type', 'level', 'stem', 'sentence', 'expl', 'explBasic', 'explAdvanced', 'stage', 'subj', 'course', 'grade', 'field', 'unit', 'subunit', 'pts', 'src', 'intent', 'status'].forEach(k => set(k, q[k]));
    set('steps', (q.steps || []).join('\n'));
    set('mistakes', (q.mistakes || []).join('\n'));
    set('rubric', (q.rubric || []).map(r => `${r.c}｜${r.p}`).join('\n'));
    set('knowledge', (q.knowledge || []).join('、'));
    set('tags', (q.tags || []).join('、'));
    set('timeMin', q.time ? +(q.time / 60).toFixed(1) : '');
    set('checkExpr', q.check ? q.check.expr : '');
    set('varyJson', q.vary ? JSON.stringify(q.vary, null, 1) : '');
    set('figCaption', q.fig && q.fig.caption ? q.fig.caption : '');
    const figButtons = () => {
      /** @type {any} */ (form.querySelector('#fig-draw')).textContent = q.fig ? (q.fig.model ? '図を編集' : '図を描き直す') : '図を描く';
      /** @type {any} */ (form.querySelector('#fig-clear')).hidden = !q.fig;
    };
    figButtons();
    set('checkExpect', q.check ? q.check.expect || '' : '');
    if (!q.status) set('status', 'unverified');

    // ---------- 答えの入力欄（形式で変わる） ----------
    const ansArea = /** @type {HTMLElement} */ (form.querySelector('#ans-area'));
    const renderAnswer = () => {
      const t = q.type;
      const def = QUESTION_TYPES[t] || {};
      if (def.hasChoices) {
        const isMulti = t === 'multi';
        const rows = q.choices.map((c, i) => `<div class="choice-edit">
          ${t === 'order' ? `<span class="small muted" style="width:2em">${i + 1}</span>` : `<input type="${isMulti ? 'checkbox' : 'radio'}" name="correct" value="${i}" ${q.ai.includes(i) ? 'checked' : ''} title="正解">`}
          <input class="input" data-choice="${i}" value="${esc(c)}" placeholder="選択肢 ${i + 1}">
          <button type="button" class="btn sm" data-up="${i}" title="上へ">↑</button><button type="button" class="btn sm danger" data-rm="${i}" title="削除">✕</button></div>`).join('');
        ansArea.innerHTML = `<div class="f">選択肢${t === 'order' ? '' : `（正解に${isMulti ? 'チェック' : '印'}）`}</div>${rows}
          <button type="button" class="btn sm" id="add-choice">＋ 選択肢を追加</button>
          ${t === 'order' ? `<label class="f mt">正しい順番（選択肢の番号を並べる。例：3,1,4,2）<input class="input" name="orderAns" value="${esc(q.ai.map(i => i + 1).join(','))}"></label>` : ''}`;
      } else if (t === 'tf') {
        ansArea.innerHTML = `<label class="f">正答<select class="input" name="ans"><option value="○（正しい）">○（正しい）</option><option value="×（誤り）">×（誤り）</option></select></label>`;
        set('ans', /^×/.test(q.ans || '') ? '×（誤り）' : '○（正しい）');
      } else if (t === 'steps') {
        ansArea.innerHTML = `<label class="f">小問（JSON。[{"stem":"(1) …","choices":["…"],"ai":[0]}]）<textarea class="input mono" name="subs" rows="6">${esc(JSON.stringify(q.subs || [], null, 1))}</textarea></label>`;
      } else {
        ansArea.innerHTML = `<label class="f">${t === 'written' ? '模範解答' : '正答'}<textarea class="input" name="ans" rows="${t === 'written' ? 4 : 2}">${esc(q.ans || '')}</textarea></label>
          <label class="f">別解・許容する答え（1行に1つ）<textarea class="input" name="alts" rows="2">${esc((q.alts || []).join('\n'))}</textarea></label>
          ${t === 'written' ? `<label class="f">解答欄の行数<input class="input" name="lines" type="number" min="1" max="30" value="${q.lines || 4}"></label>` : ''}`;
      }
    };
    renderAnswer();

    // フォームの値を q に戻す
    const collect = () => {
      const g = (k) => (f(k) ? f(k).value : undefined);
      q.type = g('type');
      ['level', 'stem', 'sentence', 'expl', 'explBasic', 'explAdvanced', 'stage', 'subj', 'course', 'grade', 'field', 'unit', 'subunit', 'src', 'intent', 'status'].forEach(k => { q[k] = (g(k) || '').trim(); });
      q.steps = lines(g('steps'));
      q.mistakes = lines(g('mistakes'));
      q.rubric = lines(g('rubric')).map(l => { const [c, p] = l.split(/[｜|]/); return { c: (c || '').trim(), p: Number(p) || 0 }; }).filter(r => r.c);
      q.knowledge = csv(g('knowledge'));
      q.tags = csv(g('tags'));
      q.pts = g('pts') === '' ? null : Number(g('pts'));
      q.time = g('timeMin') === '' ? null : Math.round(Number(g('timeMin')) * 60);
      if (q.fig) q.fig.caption = (g('figCaption') || '').trim();
      const vj = (g('varyJson') || '').trim();
      if (vj) { try { q.vary = JSON.parse(vj); q.__varyErr = validateVary(q.vary); } catch (e) { q.__varyErr = 'JSON として読めません：' + e.message; } }
      else { delete q.vary; delete q.__varyErr; }
      const ex = (g('checkExpr') || '').trim();
      q.check = ex ? { expr: ex, ...(g('checkExpect') ? { expect: g('checkExpect').trim() } : {}) } : undefined;
      const def = QUESTION_TYPES[q.type] || {};
      if (def.hasChoices) {
        form.querySelectorAll('[data-choice]').forEach(el => { q.choices[+el.getAttribute('data-choice')] = /** @type {any} */ (el).value; });
        if (q.type === 'order') q.ai = String(g('orderAns') || '').split(/[,、\s]+/).filter(Boolean).map(x => Number(x) - 1);
        else q.ai = [...form.querySelectorAll('input[name=correct]:checked')].map(el => Number(/** @type {any} */ (el).value));
        delete q.ans;
      } else if (q.type === 'steps') {
        try { q.subs = JSON.parse(g('subs') || '[]'); } catch (e) { q.subs = null; }
        q.choices = []; q.ai = [];
      } else {
        // 選択肢のない形式では、前の形式の選択肢・正解番号を残さない
        q.choices = []; q.ai = [];
        delete q.subs;
        q.ans = (g('ans') || '').trim();
        q.alts = lines(g('alts'));
        if (q.type === 'written') q.lines = Number(g('lines')) || 4;
      }
    };

    const prev = /** @type {HTMLElement} */ (form.querySelector('#qe-prev'));
    const showPreview = debounce(() => {
      collect();
      const v = validateQuestion(q);
      form.querySelector('#qe-err').innerHTML = [...v.errors.map(e => `<li>${esc(e.message)}</li>`), ...v.warnings.map(w => `<li style="color:var(--warn)">${esc(typeof w === 'string' ? w : w.message)}</li>`)].join('');
      try {
        const Rr = R();
        const views = Rr.prepare([q], { labels: 'auto', points: 'data' });
        views[0].label = '1';
        prev.innerHTML = Rr.questionHtml(views[0], { answer: 'inline', points: 'data' }) + `<div class="small" style="color:#1a7a44">答え：${Rr.text(views[0].ans)}</div>`;
        renderMath(prev);
      } catch (e) { prev.textContent = '（見本を表示できません：' + e.message + '）'; }
    }, 200);
    form.addEventListener('input', showPreview);
    form.addEventListener('change', (e) => {
      if (/** @type {any} */ (e.target).name === 'type') {
        collect();
        const def = QUESTION_TYPES[q.type] || {};
        if (def.hasChoices && q.choices.length < 2) q.choices = ['', '', '', ''];
        if (q.type === 'order') q.ai = q.choices.map((_, i) => i);
        renderAnswer();
      }
      showPreview();
    });
    const g2 = (k) => (f(k) ? f(k).value : '');
    form.addEventListener('click', async (e) => {
      const t = /** @type {HTMLElement} */ (e.target);
      if (t.id === 'add-choice') { collect(); q.choices.push(''); renderAnswer(); showPreview(); }
      if (t.dataset.rm != null) {
        collect();
        const i = +t.dataset.rm;
        q.choices.splice(i, 1);
        q.ai = q.ai.filter(x => x !== i).map(x => (x > i ? x - 1 : x));
        renderAnswer(); showPreview();
      }
      if (t.dataset.up != null && +t.dataset.up > 0) {
        collect();
        const i = +t.dataset.up;
        [q.choices[i - 1], q.choices[i]] = [q.choices[i], q.choices[i - 1]];
        q.ai = q.ai.map(x => (x === i ? i - 1 : x === i - 1 ? i : x));
        renderAnswer(); showPreview();
      }
      if (t.dataset.star) {
        const n = +t.dataset.star;
        db.put('ratings', { questionId: original.id, stars: n, comment: /** @type {any} */ (form.querySelector('#rate-comment')).value, at: new Date().toISOString() });
        form.querySelectorAll('[data-star]').forEach(b => { b.textContent = +(/** @type {any} */ (b).dataset.star) <= n ? '★' : '☆'; });
        toast('評価を保存しました');
      }
      if (t.id === 'fig-draw') {
        collect();
        if (q.fig && !q.fig.model && !confirm('この図は取り込んだ図なので、そのまま編集できません。新しく描き直しますか？')) return;
        const [{ openDrawing }, { toSvg }] = await Promise.all([import('./drawing.js'), import('../domain/figure.js')]);
        const fig = await openDrawing(q.fig && q.fig.model ? q.fig.model : undefined, { title: '問題の図' });
        if (!fig) return;
        q.fig = { svg: toSvg(fig), caption: (g2('figCaption') || '').trim(), model: fig };
        figButtons();
        showPreview();
      }
      if (t.id === 'fig-clear') { delete q.fig; figButtons(); showPreview(); }
      if (t.id === 'try-vary') {
        collect();
        const out = /** @type {HTMLElement} */ (form.querySelector('#vary-out'));
        if (q.__varyErr) { out.innerHTML = `<span style="color:var(--danger)">${esc(q.__varyErr)}</span>`; return; }
        const r = varyQuestion(q, Math.random());
        if (!r.ok) { out.innerHTML = `<span style="color:var(--danger)">作れません：${esc(r.reason)}</span>`; return; }
        const Rr = R();
        out.innerHTML = `<div class="notice ok">${r.auto ? '（検算の式から自動で作成）' : ''}${Rr.text(r.q.stem)}<br>答え：${Rr.text(Rr.prepare([r.q], { labels: 'auto', points: 'none' })[0].ans)}</div>`;
        renderMath(out);
      }
      if (t.id === 'run-check') {
        collect();
        const r = checkAnswer(q);
        const out = /** @type {HTMLElement} */ (form.querySelector('#check-out'));
        out.textContent = r.message || r.status;
        out.style.color = r.status === 'pass' ? 'var(--ok)' : r.status === 'fail' ? 'var(--danger)' : 'var(--muted)';
      }
    });
    const rc = form.querySelector('#rate-comment');
    if (rc) rc.addEventListener('change', async () => {
      const cur = (await db.get('ratings', original.id)) || { questionId: original.id, stars: 0 };
      await db.put('ratings', { ...cur, comment: /** @type {any} */ (rc).value, at: new Date().toISOString() });
    });
    showPreview();

    // ---------- AI（使えるときだけ） ----------
    const aiMsg = /** @type {HTMLElement} */ (form.querySelector('#qe-ai-msg'));
    import('../ai/client.js').then(async (ai) => {
      const av = await ai.availability();
      ['#qe-ai-explain', '#qe-ai-review'].forEach(sel => { const b = /** @type {any} */ (form.querySelector(sel)); b.disabled = !av.ok; if (!av.ok) b.title = av.reason; });
      form.querySelector('#qe-ai-explain').addEventListener('click', async () => {
        collect();
        aiMsg.textContent = 'AI が解説を作っています…';
        const r = await ai.callAI('explain', { question: q, detail: '標準' }, '解説の作成：' + (q.stem || '').slice(0, 30));
        aiMsg.textContent = '';
        if (!r.ok) { toast('作れませんでした：' + r.error.message, 'error'); return; }
        const d = r.data;
        if (d.expl) set('expl', d.expl);
        if (d.explBasic) set('explBasic', d.explBasic);
        if (d.explAdvanced) set('explAdvanced', d.explAdvanced);
        if (Array.isArray(d.steps)) set('steps', d.steps.join('\n'));
        if (Array.isArray(d.mistakes)) set('mistakes', d.mistakes.join('\n'));
        if (Array.isArray(d.rubric)) set('rubric', d.rubric.map(x => `${x.c}｜${x.p}`).join('\n'));
        if (Array.isArray(d.alts) && f('alts')) set('alts', d.alts.join('\n'));
        /** @type {any} */ (form.querySelector('details')).open = true;
        showPreview();
        toast('AI の案を入れました。内容を確かめてから保存してください', 'ok');
      });
      form.querySelector('#qe-ai-review').addEventListener('click', async () => {
        collect();
        aiMsg.textContent = 'AI が校閲しています…';
        const r = await ai.callAI('review', { question: q }, '校閲：' + (q.stem || '').slice(0, 30));
        aiMsg.textContent = '';
        if (!r.ok) { toast('校閲できませんでした：' + r.error.message, 'error'); return; }
        const issues = r.data.issues || [];
        const box = /** @type {HTMLElement} */ (form.querySelector('#qe-err'));
        box.innerHTML = (issues.length ? issues.map(i => `<li style="color:${i.severity === 'high' ? 'var(--danger)' : 'var(--warn)'}">AI校閲（${esc(i.field || '')}）：${esc(i.message)}</li>`).join('') : '<li style="color:var(--ok)">AI 校閲：指摘はありませんでした</li>')
          + (r.data.suggestedLevel && r.data.suggestedLevel !== q.level ? `<li>AI の難易度の見立て：${esc(r.data.suggestedLevel)}</li>` : '');
      });
    });

    form.querySelector('#qe-save').addEventListener('click', async () => {
      collect();
      const v = validateQuestion(q);
      if (!v.ok) { toast('入力を確認してください：' + v.errors[0].message, 'error'); return; }
      if (q.__varyErr) { toast('数値替えのテンプレート：' + q.__varyErr, 'error'); return; }
      delete q.__varyErr;
      // 問題文・答えが変わったら検証状態を戻す（人が承認済みでも再確認が必要）
      if (original && original.status === 'approved' && (original.stem !== q.stem || JSON.stringify(original.ai) !== JSON.stringify(q.ai) || original.ans !== q.ans) && q.status === 'approved') {
        q.status = 'verified';
        toast('問題文・答えを変えたので「人間承認済み」を「検証済み」に戻しました。確認後にもう一度承認してください');
      }
      const saved = opt.onSave ? await opt.onSave(q) : await saveQuestion(q);
      resolve(saved);
      m.close();
    });
  });
}
