// 画面の動き（データ読み込み・問題えらび・単語テスト・プリント）
(() => {
  const $ = (id) => document.getElementById(id);
  const state = {
    datasets: [],
    questions: [],
    byId: new Map(),
    stims: {},
    lists: [],
    filtered: [],
    units: new Set(),  // えらんだ単元（複数可）
    page: 0,
    cart: [],       // { ref: 問題ID } または { q: 単語テストなどで作った問題 }
    settings: null,
  };
  const PAGE_SIZE = 40;
  const LS_CART = 'mondai.cart', LS_SETTINGS = 'mondai.settings', LS_SAVED = 'mondai.saved';
  const DEFAULT_SETTINGS = {
    title: '確認テスト', subtitle: '', notes: '', labels: 'auto', cols: '1', answer: 'inline', key: 'expl',
    font: '13.5', points: 'data', group: 'none', shuffle: false, name: true, date: false, meta: false, seed: 1,
  };

  function load(key, def) { try { const v = localStorage.getItem(key); return v ? JSON.parse(v) : def; } catch (e) { return def; } }
  function save(key, v) { try { localStorage.setItem(key, JSON.stringify(v)); } catch (e) { toast('保存できませんでした（ブラウザの容量がいっぱいかもしれません）'); } }

  let toastTimer;
  function toast(msg) {
    const t = $('toast');
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.classList.remove('show'), 2200);
  }

  // ---------- タブ ----------
  function showTab(name) {
    document.querySelectorAll('.tab').forEach(t => { t.hidden = t.id !== 'tab-' + name; });
    document.querySelectorAll('#tabs button').forEach(b => b.classList.toggle('active', b.dataset.tab === name));
    if (name === 'pick') renderList();
    if (name === 'print') { renderCart(); renderPreview(); renderSaved(); }
    if (name === 'words') renderWordInfo();
    try { sessionStorage.setItem('mondai.tab', name); } catch (e) { /* なくても動く */ }
  }

  // ---------- データ ----------
  function rebuild() {
    state.questions = [];
    state.byId = new Map();
    state.stims = {};
    state.lists = [];
    for (const ds of state.datasets) {
      for (const q of ds.questions || []) {
        if (q.ucode) {
          const name = unitName(q.ucode);
          if (name) {
            const grp = typeof UNIT_GROUP !== 'undefined' && (UNIT_GROUP[q.ucode] || UNIT_GROUP[q.ucode.split('.').slice(0, 4).join('.')]);
            q.unit = grp || bigUnit(name, q.ucode);
            q.subunit = name !== q.unit ? name : '';
          }
        } else if (q.src === '予想問題' && !q.subunit) {
          // 予想問題は大問ごとではなく、科目ごとの1単元にまとめる（大問名は小単元として残す）
          q.subunit = q.unit;
          q.unit = q.set;
        } else if (q.src === 'かながわ' && typeof KANAGAWA_ALIAS !== 'undefined' && KANAGAWA_ALIAS[q.unit] && !q.subunit) {
          q.subunit = q.unit;
          q.unit = KANAGAWA_ALIAS[q.unit];
        }
        state.questions.push(q);
        state.byId.set(q.id, q);
      }
      Object.assign(state.stims, ds.stims || {});
      state.lists.push(...(ds.lists || []));
    }
    renderDatasets();
    // 単元コードを持たない古い取り込みデータがあれば、読み込み直しを案内する
    $('reimport').hidden = !state.questions.some(q => q.src === 'つづり' && !q.ucode);
    buildFilters();
    buildWordLists();
    updateCartCount();
  }

  // つづりクエストの単元コードを日本語名にする（高校は先頭4区切りで引く）
  function unitName(code) {
    if (typeof UNIT_NAMES === 'undefined') return '';
    return UNIT_NAMES[code] || UNIT_NAMES[code.split('.').slice(0, 4).join('.')] || '';
  }

  // 細かい単元名を、教科書の単元の大きさにまとめる
  //   不定詞（3用法）→ 不定詞、文法：不定詞 → 不定詞（高校英語）、2次関数：グラフ → 2次関数
  const UNIT_ALIAS = {
    未来: '未来表現', '2次関数': '二次関数', 論理: '集合と命題', 微分積分: '微分法・積分法', '指数・対数': '指数関数・対数関数',
    微分法: '微分法とその応用', 積分法: '積分法とその応用', 統計: '統計的な推測', 平面上の曲線: '平面上の曲線と複素数平面',
    '式：複素数': '複素数と方程式', '式：二項定理・等式不等式の証明': '式と証明',
  };
  function bigUnit(name, code) {
    if (UNIT_ALIAS[name]) return UNIT_ALIAS[name];
    let u = name;
    const m = /^([^：]+)：(.+)$/.exec(u);
    if (m) u = code.startsWith('english.') ? m[2] : m[1];
    u = u.replace(/（[^（）]*）$/, '').trim() || name;
    return UNIT_ALIAS[u] || u;
  }

  function renderDatasets() {
    const el = $('dataset-list');
    if (!state.datasets.length) { el.innerHTML = '<p class="muted">まだありません。</p>'; return; }
    el.innerHTML = '<table class="dslist"><tr><th>データ</th><th>中身</th><th>読み込んだ日</th><th></th></tr>' +
      state.datasets.map(ds => `<tr><td>${Render.esc(ds.name)}</td><td>${ds.questions ? ds.questions.length.toLocaleString() + ' 問' : ds.lists.length + ' 冊（' + ds.lists.reduce((a, l) => a + l.items.length, 0).toLocaleString() + ' 語）'}</td>` +
        (ds.builtin ? '<td>アプリに内蔵</td><td></td></tr>' : `<td>${new Date(ds.importedAt).toLocaleDateString('ja-JP')}</td><td><button class="ghost small danger" data-del="${ds.id}">削除</button></td></tr>`)).join('') +
      '</table>' + `<p class="muted small">合計 ${state.questions.length.toLocaleString()} 問・単語帳など ${state.lists.length} 冊</p>`;
  }

  async function handleFiles(files) {
    if (!files.length) return;
    if (!window.JSZip) { $('import-status').textContent = 'zip を開く部品が読み込めていません。インターネットにつないでページを開き直してください。'; return; }
    const status = $('import-status');
    try {
      const result = await Importer.importFiles(Array.from(files), msg => { status.textContent = msg; });
      if (!result.length) { status.textContent = '問題データが見つかりませんでした。もらった zip をそのまま選んでください。'; return; }
      for (const ds of result) {
        // 同じ種類のデータが既にあれば足し合わせる（同じIDは新しいほうで上書き）
        const old = state.datasets.find(d => d.id === ds.id);
        if (old && ds.questions) {
          const m = new Map(old.questions.map(q => [q.id, q]));
          ds.questions.forEach(q => m.set(q.id, q));
          ds.questions = Array.from(m.values());
          ds.stims = Object.assign({}, old.stims, ds.stims);
        }
        if (old && ds.lists) {
          const m = new Map(old.lists.map(l => [l.id, l]));
          ds.lists.forEach(l => m.set(l.id, l));
          ds.lists = Array.from(m.values());
        }
        status.textContent = `保存中：${ds.name}…`;
        await DB.putDataset(ds);
        state.datasets = state.datasets.filter(d => d.id !== ds.id).concat(ds);
      }
      rebuild();
      status.textContent = '読み込みました：' + result.map(d => `${d.name}（${d.questions ? d.questions.length.toLocaleString() + '問' : d.lists.length + '冊'}）`).join('、');
    } catch (e) {
      console.error(e);
      status.textContent = '読み込みに失敗しました：' + e.message;
    }
  }

  // ---------- しぼりこみ ----------
  const FILTERS = [
    ['f-src', 'src', '出典'], ['f-stage', 'stage', '段階'], ['f-subj', 'subj', '教科'], ['f-course', 'course', '科目'],
    ['f-grade', 'grade', '学年'], ['f-unit', 'unit', '単元'], ['f-cat', 'cat', '区分'], ['f-type', 'type', '形式'], ['f-level', 'level', '難易度'],
  ];
  const ORDER = {
    stage: ['小学', '中学', '高校'],
    grade: ['小1', '小2', '小3', '小4', '小5', '小6', '小3-4', '中1', '中2', '中3', '中1-2', '中1-3', '高1', '高2', '高3'],
    level: ['基礎', '標準', '応用'],
    subj: ['国語', '数学', '英語', '理科', '社会', '情報', '音楽', '教科横断'],
  };

  // 単元はチェックボックスで複数えらべる（state.units）。ほかはプルダウンで1つ
  function currentFilter(except) {
    const f = {};
    for (const [id, key] of FILTERS) {
      if (key === except) continue;
      if (key === 'unit') { if (state.units.size) f.unit = state.units; }
      else if ($(id).value) f[key] = $(id).value;
    }
    return f;
  }
  function matches(q, f, kw) {
    for (const k in f) {
      if (k === 'unit') { if (!f.unit.has(q.unit || q.set)) return false; }
      else if ((q[k] || '') !== f[k]) return false;
    }
    if (kw) {
      if (!q._kw) q._kw = [q.stem, q.sentence, q.unit, q.subunit, q.set, q.course, (q.choices || []).join(' ')].join(' ').toLowerCase();
      for (const w of kw) if (!q._kw.includes(w)) return false;
    }
    return true;
  }
  function keywords() { return $('f-q').value.trim().toLowerCase().split(/[\s　]+/).filter(Boolean); }

  function buildFilters() {
    const kw = keywords();
    for (const [id, key, label] of FILTERS) {
      const sel = $(id);
      const cur = key === 'unit' ? '' : sel.value;
      const f = currentFilter(key);
      // 単元は上の条件で決まる側なので、ほかの欄の選択肢は単元の選択でしぼらない
      if (key !== 'unit') delete f.unit;
      const counts = new Map(), uord = new Map();
      for (const q of state.questions) {
        if (!matches(q, f, kw)) continue;
        const v = key === 'unit' ? (q.unit || q.set) : q[key];
        if (!v) continue;
        counts.set(v, (counts.get(v) || 0) + 1);
        if (key === 'unit' && q.uord && (!uord.has(v) || q.uord < uord.get(v))) uord.set(v, q.uord);
      }
      let vals = Array.from(counts.keys());
      const ord = ORDER[key];
      vals.sort((a, b) => {
        if (key === 'unit') {
          // 単元は教科書の順（データの単元コード順）に並べる
          const oa = uord.get(a) || '~' + a, ob = uord.get(b) || '~' + b;
          if (oa !== ob) return oa < ob ? -1 : 1;
        }
        if (ord) { const ia = ord.indexOf(a), ib = ord.indexOf(b); if (ia !== ib) return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib); }
        return a.localeCompare(b, 'ja', { numeric: true });
      });
      if (key === 'unit' && vals.length > 800) vals = vals.slice(0, 800);
      if (key === 'unit') { renderUnitChecks(vals, counts); continue; }
      const show = v => key === 'type' ? (Render.TYPE_LABEL[v] || v) : v;
      sel.innerHTML = `<option value="">すべての${label}</option>` + vals.map(v => `<option value="${Render.esc(v)}">${Render.esc(show(v))}（${counts.get(v)}）</option>`).join('');
      sel.value = counts.has(cur) ? cur : '';
    }
  }

  function renderUnitChecks(vals, counts) {
    // 選んでいた単元が条件変更で消えたら、選択からもはずす
    for (const u of Array.from(state.units)) if (!counts.has(u)) state.units.delete(u);
    const n = state.units.size;
    $('f-unit-sum').textContent = n ? `${n}個えらび中` : 'すべての単元';
    $('f-unit-clear').hidden = !n;
    const box = $('f-unit'), top = box.scrollTop;
    box.innerHTML = vals.length
      ? vals.map(v => `<label class="uc${state.units.has(v) ? ' on' : ''}"><input type="checkbox" value="${Render.esc(v)}"${state.units.has(v) ? ' checked' : ''}><span>${Render.esc(v)}</span><span class="n">${counts.get(v)}</span></label>`).join('')
      : '<p class="muted small">（該当する単元がありません）</p>';
    box.scrollTop = top;
  }

  function applyFilter() {
    const f = currentFilter(), kw = keywords();
    state.filtered = state.questions.filter(q => matches(q, f, kw));
    state.page = 0;
    renderList();
  }

  const inCart = () => new Set(state.cart.filter(c => c.ref).map(c => c.ref));

  function renderList() {
    $('nodata').hidden = state.questions.length > 0;
    if (!state.questions.length) {
      $('result-count').textContent = '';
      $('f-count').textContent = '';
      $('qlist').innerHTML = '';
      $('pager').innerHTML = '';
      return;
    }
    if (!state.filtered.length && !$('f-q').value && !Object.keys(currentFilter()).length) state.filtered = state.questions;
    const sel = inCart();
    const total = state.filtered.length;
    const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
    state.page = Math.min(state.page, pages - 1);
    const start = state.page * PAGE_SIZE;
    const rows = state.filtered.slice(start, start + PAGE_SIZE);
    $('result-count').textContent = `${total.toLocaleString()} 問が見つかりました`;
    $('f-count').textContent = `${total.toLocaleString()} 問`;
    $('f-show').textContent = `↓ ${total.toLocaleString()} 問を見る`;
    $('qlist').innerHTML = rows.map(q => {
      const on = sel.has(q.id);
      const tags = [q.src, q.stage, q.course || q.subj, q.grade, Render.TYPE_LABEL[q.type], q.level].filter(Boolean).map(t => `<span class="tag">${Render.esc(t)}</span>`).join('');
      return `<li class="qrow${on ? ' on' : ''}" data-id="${Render.esc(q.id)}">
        <button class="add ${on ? 'added' : ''}" data-add="${Render.esc(q.id)}">${on ? '✓ 追加済み' : '＋ 追加'}</button>
        <div class="qmain">
          <div class="tags">${tags}<span class="unit">${Render.esc([q.unit || q.set, q.subunit].filter(Boolean).join(' › '))}</span></div>
          <div class="qstem${Render.isTex(q) ? ' tex' : ''}">${Render.text(q.stem)}</div>
          <details><summary>選択肢・答えを見る</summary><div class="${Render.isTex(q) ? 'tex' : ''}">${detailHtml(q)}</div></details>
        </div></li>`;
    }).join('') || '<li class="empty">条件に合う問題がありません。</li>';
    Render.math($('qlist'));
    let p = '';
    if (pages > 1) {
      p += `<button ${state.page === 0 ? 'disabled' : ''} data-page="${state.page - 1}">← 前</button>`;
      p += `<span>${state.page + 1} / ${pages} ページ</span>`;
      p += `<button ${state.page >= pages - 1 ? 'disabled' : ''} data-page="${state.page + 1}">次 →</button>`;
    }
    $('pager').innerHTML = p;
  }

  function detailHtml(q) {
    const v = Render.prepare([q], { ...state.settings, shuffle: false, points: 'none' })[0];
    let h = '';
    if (q.sid && state.stims[q.sid]) h += `<div class="small muted">［共通の本文：${Render.esc(state.stims[q.sid].title || 'あり')}］</div>`;
    if (q.sentence) h += `<div class="pq-sentence">${Render.text(q.sentence)}</div>`;
    h += Render.table(q.table) + Render.figure(q.fig);
    if (q.choices) h += Render.choicesHtml(q.choices, v.perm, v.labels);
    if (v.subs) h += v.subs.map(x => `<div>${Render.text(x.sq.stem)}</div>` + Render.choicesHtml(x.sq.choices, x.perm, x.labels)).join('');
    h += `<div class="answer">答え：${Render.text(v.ans)}</div>`;
    if (q.expl) h += `<div class="expl">${Render.text(q.expl)}</div>`;
    return h;
  }

  // ---------- カート ----------
  function resolve(c) { return c.q || state.byId.get(c.ref); }
  function cartQuestions() { return state.cart.map(resolve).filter(Boolean); }
  function saveCart() { save(LS_CART, state.cart); updateCartCount(); }
  function updateCartCount() {
    const n = cartQuestions().length;
    $('cart-count').textContent = n;
    $('cart-count2').textContent = `（${n}問）`;
  }
  function addRefs(ids) {
    const have = inCart();
    let added = 0;
    for (const id of ids) if (!have.has(id)) { state.cart.push({ ref: id }); have.add(id); added++; }
    saveCart();
    return added;
  }
  function toggle(id) {
    const i = state.cart.findIndex(c => c.ref === id);
    if (i >= 0) state.cart.splice(i, 1); else state.cart.push({ ref: id });
    saveCart();
  }

  function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
    return a;
  }

  function randomAdd() {
    const have = inCart();
    const pool = shuffle(state.filtered.filter(q => !have.has(q.id)));
    const want = { 基礎: +$('r-basic').value || 0, 標準: +$('r-standard').value || 0, 応用: +$('r-advanced').value || 0 };
    let any = +$('r-any').value || 0;
    const picked = [];
    const used = new Set();
    for (const lv of ['基礎', '標準', '応用']) {
      for (const q of pool) {
        if (want[lv] <= 0) break;
        if (q.level === lv && !used.has(q.id)) { picked.push(q); used.add(q.id); want[lv]--; }
      }
    }
    for (const q of pool) { if (any <= 0) break; if (!used.has(q.id)) { picked.push(q); used.add(q.id); any--; } }
    // 難易度順（基礎→標準→応用）に並べる
    const rank = { 基礎: 0, 標準: 1, 応用: 2 };
    picked.sort((a, b) => (rank[a.level] ?? 1) - (rank[b.level] ?? 1));
    const n = addRefs(picked.map(q => q.id));
    const short = Object.values(want).reduce((a, b) => a + b, 0) + any;
    toast(`${n} 問追加しました` + (short > 0 ? `（条件に合う問題が足りず ${short} 問少なめ）` : ''));
    renderList();
  }

  function renderCart() {
    const el = $('cart');
    const qs = state.cart.map(resolve);
    el.innerHTML = qs.map((q, i) => q ? `<li><span class="c-no">${i + 1}</span><span class="c-text${Render.isTex(q) ? ' tex' : ''}">${Render.esc(Render.plain(q.stem).slice(0, 60))}${Render.plain(q.stem).length > 60 ? '…' : ''}</span>
      <span class="c-btns"><button data-up="${i}" title="上へ">↑</button><button data-down="${i}" title="下へ">↓</button><button data-rm="${i}" title="はずす">✕</button></span></li>`
      : `<li class="muted"><span class="c-no">${i + 1}</span>（データが見つからない問題）<span class="c-btns"><button data-rm="${i}">✕</button></span></li>`).join('') ||
      '<li class="empty">「② 問題をえらぶ」か「③ 単語・用語テスト」で問題を追加してください。</li>';
    Render.math(el);
    updateCartCount();
  }

  // ---------- 設定 ----------
  const SETTING_FIELDS = { title: 's-title', subtitle: 's-subtitle', notes: 's-notes', labels: 's-labels', cols: 's-cols', answer: 's-answer', key: 's-key', font: 's-font', points: 's-points', group: 's-group', shuffle: 's-shuffle', name: 's-name', date: 's-date', meta: 's-meta' };
  function settingsToForm() {
    for (const [k, id] of Object.entries(SETTING_FIELDS)) {
      const el = $(id);
      if (el.type === 'checkbox') el.checked = !!state.settings[k]; else el.value = state.settings[k];
    }
  }
  function formToSettings() {
    for (const [k, id] of Object.entries(SETTING_FIELDS)) {
      const el = $(id);
      state.settings[k] = el.type === 'checkbox' ? el.checked : el.value;
    }
    save(LS_SETTINGS, state.settings);
  }

  let previewTimer;
  function renderPreview() {
    clearTimeout(previewTimer);
    previewTimer = setTimeout(() => {
      const qs = cartQuestions();
      const el = $('preview');
      if (!qs.length) { el.innerHTML = '<div class="paper empty-paper">ここにプリントの見本が出ます。</div>'; return; }
      const views = Render.prepare(qs, state.settings);
      el.innerHTML = Render.sheet(views, { ...state.settings }, state.stims);
      Render.math(el);
    }, 80);
  }

  // ---------- 保存したプリント ----------
  function renderSaved() {
    const list = load(LS_SAVED, []);
    $('saved').innerHTML = list.map((s, i) => `<li><button class="link" data-open="${i}">${Render.esc(s.name)}</button><span class="muted small">${s.cart.length}問・${new Date(s.at).toLocaleDateString('ja-JP')}</span><button class="ghost small danger" data-delsaved="${i}">削除</button></li>`).join('') || '<li class="muted small">まだありません。</li>';
  }
  function saveCurrent() {
    const name = $('save-name').value.trim() || state.settings.title || 'プリント';
    const list = load(LS_SAVED, []);
    list.unshift({ name, at: Date.now(), cart: state.cart, settings: state.settings });
    save(LS_SAVED, list);
    $('save-name').value = '';
    renderSaved();
    toast('保存しました');
  }

  // ---------- 単語・用語テスト ----------
  function buildWordLists() {
    const groups = {};
    state.lists.forEach((l, i) => { (groups[l.group] = groups[l.group] || []).push({ l, i }); });
    $('w-list').innerHTML = Object.entries(groups).map(([g, arr]) => `<optgroup label="${Render.esc(g)}">${arr.map(({ l, i }) => `<option value="${i}">${Render.esc(l.title)}（${l.items.length}）</option>`).join('')}</optgroup>`).join('') ||
      '<option value="">（単語帳データがありません）</option>';
    renderWordInfo(true);
  }
  function currentList() { return state.lists[+$('w-list').value]; }

  function renderWordInfo(resetRange) {
    const l = currentList();
    if (!l) { $('w-info').textContent = '単語帳・用語カードのデータを「① データ」で読み込むと使えます。'; $('w-preview').innerHTML = ''; return; }
    const first = l.items[0].n, last = l.items[l.items.length - 1].n;
    if (resetRange) { $('w-from').value = first; $('w-to').value = Math.min(last, first + 49); }
    $('w-info').textContent = `番号 ${first}〜${last}（${l.items.length}語）`;
    $('w-preview').innerHTML = '<table class="dtable">' + l.items.slice(0, 5).map(w => `<tr><td>${w.n}</td><td>${Render.esc(w.term)}</td><td>${Render.esc(w.meaning)}</td></tr>`).join('') + '</table>';
  }

  function blankOut(w) {
    if (!w.ex) return null;
    let s = w.ex, ok = false;
    const words = (w.blanks && w.blanks.length) ? w.blanks : [w.term.replace(/[～~].*$/, '').replace(/\s*\(.*?\)\s*/g, ' ').trim()];
    for (const b of words) {
      if (!b) continue;
      const re = new RegExp('\\b' + b.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+') + '\\w*', 'i');
      if (re.test(s)) { s = s.replace(re, m => '（' + '　'.repeat(Math.min(6, Math.max(3, Math.ceil(m.length / 2)))) + '）'); ok = true; }
    }
    if (!ok) return null;
    return { stem: (w.exJa ? w.exJa + '\n' : '') + s, ans: words.join(' … ') };
  }

  function makeWordTest() {
    const l = currentList();
    if (!l) return;
    const from = +$('w-from').value || 1, to = +$('w-to').value || Infinity;
    const count = +$('w-count').value || 20, mode = $('w-mode').value;
    let pool = l.items.filter(w => w.n >= from && w.n <= to);
    if (mode === 'cloze') pool = pool.filter(w => blankOut(w));
    if (!pool.length) { toast(mode === 'cloze' ? 'この範囲には例文のある語がありません' : 'この範囲に語がありません'); return; }
    let picked = $('w-order').value === 'random' ? shuffle(pool.slice()).slice(0, count) : pool.slice(0, count);
    if ($('w-order').value === 'random') picked.sort((a, b) => a.n - b.n);
    const isTerm = l.group === '用語カード';
    const subj = isTerm ? '' : '英語';
    const items = picked.map(w => {
      const base = { id: `w:${l.id}:${w.n}:${mode}`, src: '単語帳', subj, unit: l.title, set: l.title, level: '', expl: w.ex ? w.ex + (w.exJa ? '（' + w.exJa + '）' : '') : (w.sec || '') };
      const others = shuffle(l.items.filter(x => x !== w && x.meaning !== w.meaning)).slice(0, 3);
      if (mode === 'meaning') return { ...base, type: 'short', compact: true, stem: w.term, ans: w.meaning };
      if (mode === 'term') return { ...base, type: 'short', compact: !isTerm, stem: w.meaning, ans: w.term };
      if (mode === 'cloze') { const b = blankOut(w); return { ...base, type: 'short', stem: '（　）に入る語句を書きなさい。\n' + b.stem, ans: b.ans }; }
      const opts = shuffle([w, ...others]);
      const rev = mode === 'mcr';
      return {
        ...base, type: 'choice',
        stem: rev ? w.meaning : w.term,
        choices: opts.map(o => rev ? o.term : o.meaning),
        ai: [opts.indexOf(w)],
      };
    });
    state.cart.push(...items.map(q => ({ q })));
    saveCart();
    if (state.settings.title === DEFAULT_SETTINGS.title) { state.settings.title = l.title + ' テスト'; settingsToForm(); save(LS_SETTINGS, state.settings); }
    toast(`${items.length} 問をプリントに追加しました`);
  }

  // ---------- イベント ----------
  function bind() {
    $('tabs').addEventListener('click', e => { const b = e.target.closest('button[data-tab]'); if (b) showTab(b.dataset.tab); });

    const fi = $('file-input');
    fi.addEventListener('change', () => { handleFiles(fi.files); fi.value = ''; });
    const drop = $('drop');
    ['dragenter', 'dragover'].forEach(ev => drop.addEventListener(ev, e => { e.preventDefault(); drop.classList.add('over'); }));
    ['dragleave', 'drop'].forEach(ev => drop.addEventListener(ev, e => { e.preventDefault(); drop.classList.remove('over'); }));
    drop.addEventListener('drop', e => handleFiles(e.dataTransfer.files));
    $('dataset-list').addEventListener('click', async e => {
      const id = e.target.dataset.del;
      if (!id || !confirm('このデータを削除しますか？（もう一度読み込めば戻せます）')) return;
      await DB.remove(id);
      state.datasets = state.datasets.filter(d => d.id !== id);
      rebuild();
      applyFilter();
    });

    let kwTimer;
    $('f-q').addEventListener('input', () => { clearTimeout(kwTimer); kwTimer = setTimeout(() => { buildFilters(); applyFilter(); }, 250); });
    for (const [id, key] of FILTERS) {
      if (key === 'unit') continue;
      $(id).addEventListener('change', () => { buildFilters(); applyFilter(); });
    }
    $('f-unit').addEventListener('change', e => {
      const v = e.target.value;
      if (e.target.checked) state.units.add(v); else state.units.delete(v);
      buildFilters(); applyFilter();
    });
    $('f-unit-clear').addEventListener('click', () => { state.units.clear(); buildFilters(); applyFilter(); });
    $('f-show').addEventListener('click', () => $('results').scrollIntoView({ behavior: 'smooth' }));
    document.addEventListener('click', e => { const g = e.target.closest('[data-goto]'); if (g) { showTab(g.dataset.goto); window.scrollTo(0, 0); } });
    $('f-reset').addEventListener('click', () => { $('f-q').value = ''; FILTERS.forEach(([id, key]) => { if (key !== 'unit') $(id).value = ''; }); state.units.clear(); buildFilters(); applyFilter(); });
    $('r-add').addEventListener('click', randomAdd);
    $('add-page').addEventListener('click', () => {
      const ids = state.filtered.slice(state.page * PAGE_SIZE, (state.page + 1) * PAGE_SIZE).map(q => q.id);
      toast(`${addRefs(ids)} 問追加しました`);
      renderList();
    });
    $('qlist').addEventListener('click', e => {
      const id = e.target.dataset.add;
      if (!id) return;
      toggle(id);
      const on = inCart().has(id);
      e.target.textContent = on ? '✓ 追加済み' : '＋ 追加';
      e.target.classList.toggle('added', on);
      e.target.closest('.qrow').classList.toggle('on', on);
    });
    $('pager').addEventListener('click', e => {
      const p = e.target.dataset.page;
      if (p == null) return;
      state.page = +p;
      renderList();
      window.scrollTo(0, 0);
    });

    $('w-list').addEventListener('change', () => renderWordInfo(true));
    $('w-add').addEventListener('click', makeWordTest);

    Object.values(SETTING_FIELDS).forEach(id => $(id).addEventListener('input', () => { formToSettings(); renderPreview(); }));
    $('reshuffle').addEventListener('click', () => { state.settings.seed = Math.floor(Math.random() * 1e9) + 1; state.settings.shuffle = true; settingsToForm(); formToSettings(); renderPreview(); });
    $('do-print').addEventListener('click', () => {
      if (!cartQuestions().length) { toast('問題が入っていません'); return; }
      window.print();
    });

    $('cart').addEventListener('click', e => {
      const d = e.target.dataset;
      const c = state.cart;
      if (d.rm != null) c.splice(+d.rm, 1);
      else if (d.up != null && +d.up > 0) [c[+d.up - 1], c[+d.up]] = [c[+d.up], c[+d.up - 1]];
      else if (d.down != null && +d.down < c.length - 1) [c[+d.down + 1], c[+d.down]] = [c[+d.down], c[+d.down + 1]];
      else return;
      saveCart(); renderCart(); renderPreview();
    });
    $('cart-clear').addEventListener('click', () => {
      if (!state.cart.length || !confirm('入っている問題を全部はずしますか？')) return;
      state.cart = []; saveCart(); renderCart(); renderPreview();
    });
    $('cart-shuffle').addEventListener('click', () => { shuffle(state.cart); saveCart(); renderCart(); renderPreview(); });
    $('cart-group').addEventListener('click', () => {
      // 同じ本文（長文・資料）を使う問題を、最初に出てくる位置にまとめる
      const groups = new Map();
      state.cart.forEach((c, i) => { const q = resolve(c); const k = (q && q.sid) || ('#' + i); if (!groups.has(k)) groups.set(k, []); groups.get(k).push(c); });
      state.cart = Array.from(groups.values()).flat();
      saveCart(); renderCart(); renderPreview();
    });

    $('save-btn').addEventListener('click', saveCurrent);
    $('saved').addEventListener('click', e => {
      const list = load(LS_SAVED, []);
      if (e.target.dataset.open != null) {
        const s = list[+e.target.dataset.open];
        state.cart = s.cart.slice();
        state.settings = { ...DEFAULT_SETTINGS, ...s.settings };
        settingsToForm(); save(LS_SETTINGS, state.settings); saveCart(); renderCart(); renderPreview();
        toast(`「${s.name}」を開きました`);
      } else if (e.target.dataset.delsaved != null) {
        if (!confirm('この保存を削除しますか？')) return;
        list.splice(+e.target.dataset.delsaved, 1);
        save(LS_SAVED, list); renderSaved();
      }
    });

    window.addEventListener('beforeprint', () => { if ($('tab-print').hidden) showTab('print'); });
  }

  // アプリに内蔵している問題（このリポジトリで作ったオリジナル問題）。zip なしで使える
  async function loadBuiltin() {
    try {
      const res = await fetch('builtin/hs.json');
      if (!res.ok) return null;
      const d = await res.json();
      return { id: 'builtin', name: '内蔵問題（高校5教科・オリジナル）', builtin: true, questions: d.questions, stims: {}, importedAt: null };
    } catch (e) {
      return null;
    }
  }

  async function init() {
    state.settings = { ...DEFAULT_SETTINGS, ...load(LS_SETTINGS, {}) };
    state.cart = load(LS_CART, []);
    settingsToForm();
    bind();
    const builtin = await loadBuiltin();
    try { state.datasets = await DB.getAll(); } catch (e) { console.error(e); $('import-status').textContent = 'このブラウザではデータを保存できません（プライベートモードでは使えないことがあります）。'; }
    if (builtin) state.datasets.unshift(builtin);
    rebuild();
    state.filtered = state.questions;
    let tab = null;
    try { tab = sessionStorage.getItem('mondai.tab'); } catch (e) { /* なくても動く */ }
    showTab(tab || (state.questions.length ? 'pick' : 'data'));
  }

  init();
})();
