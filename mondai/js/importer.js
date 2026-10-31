// 問題データ（zip / json）を読み込んで、アプリ共通の形にそろえる
//
// 共通の問題の形:
// { id, src, stage, subj, course, grade, unit, set, cat, type, stem, sentence,
//   choices:[文字列], cl:[元のラベル]|null, ai:[正解の選択肢番号], ans:文字列,
//   expl, steps:[], fig, table, sid（共通の本文）, level, lines, grid, pts, rubric, subs }
// type: choice（選択）/ multi（複数選択）/ order（並べかえ）/ tf（正誤）/ short（答えのみ）/ written（記述）/ steps（小問つき）

const Importer = (() => {
  const SUBJECT = { japanese: '国語', math: '数学', english: '英語', science: '理科', social: '社会', information: '情報', integrated: '教科横断', music: '音楽' };
  const GRADE = { JH1: '中1', JH2: '中2', JH3: '中3', HS1: '高1', HS2: '高2', HS3: '高3' };
  const LEVEL = { basic: '基礎', standard: '標準', advanced: '応用', challenge: '応用' };
  const TRACK = {
    pilot: 'パイロット', junior_high: '単元プリント', tokushoku: '特色検査対策', mock_exam: '模試',
    high_school: '単元プリント', common_test: '共通テスト対策', second_stage: '二次試験対策', hs_pack: '授業・演習プリント', jh_pack: '授業・演習プリント',
  };
  const PRINT_TYPE = { lesson: '授業プリント', exercise: '問題プリント', worksheet: '単元プリント' };
  // つづりクエストの unit の2番目の区切り → 科目名
  const TSUZURI_COURSE = {
    eng: '英語', info: '情報Ⅰ', gendai: '現代文', kanbun: '漢文', kobun: '古文',
    m1: '数学Ⅰ', m2: '数学Ⅱ', m3: '数学Ⅲ', ma: '数学A', mb: '数学B', mc: '数学C', theory: '音楽理論',
    biology: '生物', chemistry: '化学', earth: '地学', physics: '物理',
    eth: '倫理', geo: '地理', jhist: '日本史', pol: '公共・政治経済', whist: '世界史', civ: '公民', hist: '歴史',
  };
  const YOSOU_SUBJECT = {
    bio: ['理科', '生物基礎'], chem: ['理科', '化学基礎'], ec: ['英語', '英語コミュニケーションⅠ'], le: ['英語', '論理・表現Ⅰ'],
    gendai: ['国語', '現代の国語'], gengo: ['国語', '言語文化'], joho: ['情報', '情報Ⅰ'], kokyo: ['社会', '公共'],
    math1: ['数学', '数学Ⅰ'], mathA: ['数学', '数学A'],
  };

  // ---------- かながわ形式 ----------
  function curriculumLabels(map) {
    const units = {}, courses = {};
    if (!map) return { units, courses };
    const walk = (o) => {
      if (Array.isArray(o)) { o.forEach(walk); return; }
      if (!o || typeof o !== 'object') return;
      if (o.unit_id && o.title) units[o.unit_id] = o.title;
      if (o.course && o.label && o.units) courses[o.course] = o.label;
      Object.values(o).forEach(walk);
    };
    walk(map.stages);
    walk(map.exam_tracks);
    return { units, courses };
  }

  function kStim(s) {
    if (!s) return null;
    return {
      title: s.title || '',
      content: s.content || '',
      table: s.table || null,
      fig: s.figure ? { svg: s.figure.svg, alt: s.figure.alt, caption: s.figure.caption } : null,
      glossary: s.glossary || null,
      source: s.source && s.source !== 'オリジナル' ? s.source : '',
    };
  }

  function convertKanagawa(set, labels, out) {
    const subj = SUBJECT[set.subject] || set.subject;
    const course = labels.courses[set.course] || '';
    const cat = PRINT_TYPE[set.print_type] || TRACK[set.track] || '';
    const stage = set.stage === 'high_school' ? '高校' : '中学';
    const stimById = {};
    (set.stimuli || []).forEach(s => { stimById[s.id] = s; });

    for (const q of set.questions || []) {
      const labelsOrig = (q.choices || []).map(c => c.label);
      const idx = (l) => labelsOrig.indexOf(l);
      const value = q.answer ? q.answer.value : '';
      const n = {
        id: q.id, src: 'かながわ', stage, subj, course,
        grade: GRADE[q.grade || set.grade] || '',
        unit: labels.units[q.unit_id] || set.title || '',
        uord: q.unit_id || '',
        set: set.title + (set.subtitle ? '｜' + set.subtitle : ''),
        cat,
        stem: q.stem || '',
        level: q.difficulty ? (LEVEL[q.difficulty.level] || '') : '',
        pts: q.scoring ? q.scoring.points : null,
        expl: q.explanation || '',
      };
      if (q.explanation_detail && Array.isArray(q.explanation_detail.steps)) n.steps = q.explanation_detail.steps;
      if (q.scoring && Array.isArray(q.scoring.rubric)) n.rubric = q.scoring.rubric.map(r => ({ c: r.criterion, p: r.points }));
      else if (q.explanation_detail && Array.isArray(q.explanation_detail.partial_credit)) n.rubric = q.explanation_detail.partial_credit.map(r => ({ c: r.point, p: r.points }));

      switch (q.question_type) {
        case 'multiple_choice':
        case 'true_false':
          n.type = 'choice';
          n.choices = q.choices.map(c => c.text);
          n.cl = labelsOrig;
          n.ai = [idx(value)];
          break;
        case 'multiple_select':
          n.type = 'multi';
          n.choices = q.choices.map(c => c.text);
          n.cl = labelsOrig;
          n.ai = (Array.isArray(value) ? value : [value]).map(idx);
          break;
        case 'ordering':
          n.type = 'order';
          n.choices = q.choices.map(c => c.text);
          n.cl = labelsOrig;
          n.ai = (Array.isArray(value) ? value : [value]).map(idx);
          break;
        case 'descriptive':
        case 'proof':
          n.type = 'written';
          n.ans = String(value);
          break;
        default: // numeric / short_answer など
          n.type = 'short';
          n.ans = (q.answer && q.answer.display) || (String(value) + (q.answer && q.answer.unit ? ' ' + q.answer.unit : ''));
          if (q.answer && Array.isArray(q.answer.accepted) && q.answer.accepted.length) n.ans += '（' + q.answer.accepted.join('、') + ' も可）';
      }
      if ((n.ai || []).some(i => i < 0)) { n.type = 'short'; n.ans = Array.isArray(value) ? value.join(' → ') : String(value); }
      if (q.answer_space) {
        if (q.answer_space.lines) n.lines = q.answer_space.lines;
        if (q.answer_space.char_grid) n.grid = q.answer_space.char_grid;
      }
      if (n.type === 'written' && !n.lines && !n.grid) n.lines = 4;
      if (q.figure) n.fig = { svg: q.figure.svg, alt: q.figure.alt, caption: q.figure.caption };
      if (q.table) n.table = q.table;
      const st = q.stimulus || (q.stimulus_ref && stimById[q.stimulus_ref]);
      if (st) {
        n.sid = set.set_id + '/' + (st.id || q.stimulus_ref);
        if (!out.stims[n.sid]) out.stims[n.sid] = kStim(st);
      }
      out.questions.push(n);
    }
  }

  // ---------- つづりクエスト形式 ----------
  function seededShuffle(arr, seedStr) {
    let h = 2166136261;
    for (const ch of seedStr) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619); }
    const rand = () => { h ^= h << 13; h ^= h >>> 17; h ^= h << 5; return ((h >>> 0) % 10000) / 10000; };
    const order = arr.map((_, i) => i);
    for (let i = order.length - 1; i > 0; i--) { const j = Math.floor(rand() * (i + 1)); [order[i], order[j]] = [order[j], order[i]]; }
    if (order.every((v, i) => v === i) && order.length > 1) order.reverse();
    return order;
  }

  // 「ウ 〜」のように記号つきで入っている選択肢は、記号をはずして記号の順に並べ直す
  const LABEL_SEQS = ['アイウエオカキクケコ', '123456789', 'ABCDEFGH'];
  function labeledChoices(choices, answerIndex) {
    const m = choices.map(c => /^([ア-ン1-9A-H])[\s　](.+)$/s.exec(c));
    if (m.every(Boolean)) {
      const labels = m.map(x => x[1]);
      const seq = LABEL_SEQS.find(s => s.includes(labels[0]));
      const want = seq ? seq.slice(0, labels.length).split('') : [];
      if (seq && labels.slice().sort((a, b) => seq.indexOf(a) - seq.indexOf(b)).join('') === want.join('')) {
        const order = want.map(l => labels.indexOf(l));
        return { choices: order.map(i => m[i][2]), cl: want, ai: [order.indexOf(answerIndex)] };
      }
    }
    return { choices, ai: [answerIndex] };
  }

  function tsuzuriFig(f) {
    if (!f) return null;
    if (f.yosou) return { note: '図・資料（原本参照）' };
    if (f.chart && f.labels) return { chart: f.chart, labels: f.labels, series: f.series || [{ name: '', values: f.values || [] }], unit: f.unit || '' };
    return null;
  }

  function passageStim(p) {
    const parts = (p.paragraphs || []).map(t => (typeof t === 'string' && t.startsWith('@')) ? '［図・資料：原本参照］' : t);
    return { title: p.title || '', content: parts.join('\n\n'), table: null, fig: null };
  }

  function convertTsuzuri(set, path, out, opts) {
    const isJunior = /(^|\/)junior\//.test(path);
    const passages = {};
    (set.passages || []).forEach(p => { passages[p.id] = p; });
    for (const q of set.questions || []) {
      const u = (q.unit || '').split('.');
      let grade = '';
      let stage = isJunior ? '中学' : '高校';
      if (isJunior) {
        const g = /^([ej])(\d)$/.exec(u[1] || '');
        if (g) { stage = g[1] === 'e' ? '小学' : '中学'; grade = (g[1] === 'e' ? '小' : '中') + g[2]; }
        else if (q.targetGrade) { grade = q.targetGrade; if (/^小/.test(grade)) stage = '小学'; }
      } else if (q.targetGrade) grade = '高' + q.targetGrade;
      const n = {
        id: q.id, src: opts.src, stage,
        subj: opts.subj || SUBJECT[u[0]] || SUBJECT[set.worldId] || u[0] || '',
        course: opts.course || (isJunior && /^[ej]\d$/.test(u[1] || '') ? '' : (TSUZURI_COURSE[u[1]] || '')),
        grade: opts.grade || grade,
        unit: opts.unitOf ? opts.unitOf(q) : u.slice(2).join(' / '),
        ucode: q.unit || '',
        uord: opts.unitOf ? (q.passageId || '') : (q.unit || ''),
        set: opts.setName || set.setId,
        cat: opts.cat || '',
        stem: q.prompt || '',
        level: LEVEL[q.difficulty] || '',
        expl: q.explanation || '',
      };
      const pt = (q.tags || []).map(t => /^pt:(\d+)/.exec(t)).find(Boolean);
      if (pt) n.pts = Number(pt[1]);
      if (q.sentence) n.sentence = q.sentence;
      switch (q.format) {
        case 'trueFalse':
          n.type = 'tf';
          n.ans = q.truth ? '○（正しい）' : '×（誤り）';
          break;
        case 'multiSelect':
          n.type = 'multi';
          n.choices = q.multiSelect.options;
          n.ai = q.multiSelect.correct;
          break;
        case 'order': {
          const items = q.order.items;
          const ord = seededShuffle(items, q.id);
          n.type = 'order';
          n.choices = ord.map(i => items[i]);
          n.ai = items.map((_, i) => ord.indexOf(i));
          break;
        }
        case 'written':
          n.type = 'written';
          n.ans = q.written.modelAnswer || '';
          if (q.written.rubric) n.rubric = q.written.rubric.map(r => ({ c: r.point, p: r.score }));
          n.lines = 4;
          break;
        case 'numeric':
          n.type = 'short';
          n.ans = q.numeric.value + (q.numeric.unit ? ' ' + q.numeric.unit : '');
          break;
        case 'cloze':
          n.type = 'short';
          n.sentence = q.cloze.text.replace(/\[(\d+)\]/g, '（ $1 ）');
          n.ans = q.cloze.blanks.map((b, i) => `(${i + 1}) ${b[0]}`).join('　');
          break;
        case 'multiStep':
          n.type = 'steps';
          n.subs = q.subQuestions.map(s => ({ stem: s.prompt, choices: s.choices, ai: [s.answerIndex] }));
          break;
        default:
          if (Array.isArray(q.choices) && q.choices.some(c => /^（書いて答える問題）$/.test(c)) && typeof q.answerIndex === 'number') {
            // アプリ用に選択式にしてあるが、元は書いて答える問題
            n.type = 'short';
            n.ans = q.choices[q.answerIndex];
            if (Array.isArray(q.accepted) && q.accepted.length) n.ans += '（' + q.accepted.join('、') + ' も可）';
          } else if (Array.isArray(q.choices) && q.choices.length && typeof q.answerIndex === 'number') {
            n.type = 'choice';
            Object.assign(n, labeledChoices(q.choices, q.answerIndex));
          } else {
            n.type = 'short';
            n.ans = (q.accepted && q.accepted[0]) || '';
          }
      }
      if (Array.isArray(q.accepted) && q.accepted.length && n.type === 'short' && !n.ans) n.ans = q.accepted.join('／');
      const fig = tsuzuriFig(q.figure);
      if (fig) n.fig = fig;
      if (q.passageId && passages[q.passageId]) {
        n.sid = (set.setId || '') + '/' + q.passageId;
        if (!out.stims[n.sid]) out.stims[n.sid] = passageStim(passages[q.passageId]);
      }
      out.questions.push(n);
    }
  }

  // ---------- 単語帳・用語カード ----------
  function convertWords(d, path) {
    const group = /junior\//.test(path) ? '英単語（小中）' : '英単語・熟語';
    return {
      id: d.listId, title: d.title || d.listId, group,
      items: (d.words || []).map(w => ({ n: w.number, term: w.term, meaning: w.meaning, ex: w.example || '', exJa: w.exampleJa || '' })),
    };
  }
  function convertTerms(d) {
    const items = [];
    let n = 0;
    for (const s of d.sections || []) for (const c of s.cards || []) items.push({ n: ++n, term: c.t, meaning: c.m, sec: s.name });
    return { id: 'terms_' + d.id, title: d.title || d.id, group: '用語カード', items };
  }
  function convertIdioms(arr) {
    return {
      id: 'scramble_idioms', title: 'Scramble イディオム', group: '英単語・熟語',
      items: arr.map(w => ({ n: w.no, term: w.idiom, meaning: w.meaning, ex: w.example_en || '', exJa: w.example_ja || '', blanks: w.blank_answer || [] })),
    };
  }

  // ---------- zip / json の読み込み ----------
  async function readEntries(file, progress) {
    const entries = [];
    if (/\.zip$/i.test(file.name)) {
      const zip = await JSZip.loadAsync(file);
      const files = Object.values(zip.files).filter(f => !f.dir && /\.json$/i.test(f.name) && !/__MACOSX|\/\._/.test(f.name));
      let i = 0;
      for (const f of files) {
        entries.push({ path: f.name, text: await f.async('string') });
        if (++i % 40 === 0) progress(`${file.name}：ファイルを展開中 ${i}/${files.length}`);
      }
    } else if (/\.json$/i.test(file.name)) {
      entries.push({ path: file.webkitRelativePath || file.name, text: await file.text() });
    }
    return entries;
  }

  async function importFiles(fileList, progress) {
    const all = [];
    for (const f of fileList) all.push(...await readEntries(f, progress));
    progress(`${all.length} 個のデータファイルを読み取り中…`);

    const parsed = [];
    let map = null;
    for (const e of all) {
      let d;
      try { d = JSON.parse(e.text.replace(/^\uFEFF/, '')); } catch (err) { continue; }
      if (/curriculum_map\.json$/.test(e.path)) { map = d; continue; }
      parsed.push({ path: e.path, d });
    }
    const labels = curriculumLabels(map);
    const families = {
      kanagawa: { id: 'kanagawa', name: 'かながわ教材（中学・高校・入試）', questions: [], stims: {} },
      tsuzuri: { id: 'tsuzuri', name: 'つづりクエスト 問題セット', questions: [], stims: {} },
      yosou: { id: 'yosou', name: '後期中間 予想問題', questions: [], stims: {} },
      words: { id: 'words', name: '単語帳・用語カード', lists: [] },
    };
    let i = 0;
    for (const { path, d } of parsed) {
      if (++i % 50 === 0) { progress(`変換中 ${i}/${parsed.length}`); await new Promise(r => setTimeout(r)); }
      if (d && d.schema_version && Array.isArray(d.questions) && d.set_id) {
        convertKanagawa(d, labels, families.kanagawa);
      } else if (d && d.setId && Array.isArray(d.questions)) {
        const y = /^yosou_(.+)$/.exec(d.setId);
        if (y) {
          const [subj, course] = YOSOU_SUBJECT[y[1]] || ['', y[1]];
          const passTitle = {};
          (d.passages || []).forEach(p => { passTitle[p.id] = p.title; });
          convertTsuzuri(d, path, families.yosou, {
            src: '予想問題', subj, course, grade: '高1', setName: course + ' 後期中間 予想問題', cat: '予想問題',
            unitOf: q => passTitle[q.passageId] || '',
          });
        } else {
          convertTsuzuri(d, path, families.tsuzuri, { src: 'つづり' });
        }
      } else if (d && d.listId && Array.isArray(d.words)) {
        families.words.lists.push(convertWords(d, path));
      } else if (d && Array.isArray(d.sections) && d.sections.some(s => Array.isArray(s.cards))) {
        families.words.lists.push(convertTerms(d));
      } else if (Array.isArray(d) && d.length && d[0].idiom) {
        families.words.lists.push(convertIdioms(d));
      }
    }
    const result = [];
    for (const f of Object.values(families)) {
      if ((f.questions && f.questions.length) || (f.lists && f.lists.length)) {
        f.importedAt = new Date().toISOString();
        result.push(f);
      }
    }
    return result;
  }

  return { importFiles };
})();

window.Importer = Importer;
