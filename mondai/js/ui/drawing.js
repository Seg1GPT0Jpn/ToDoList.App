// 図をかく画面（モーダル）。図のデータは domain/figure.js、表示は toSvg をそのまま使う。
import { modal } from './common.js';
import { esc } from '../core/util.js';
import * as F from '../domain/figure.js';

/** @typedef {import('../domain/figure.js').Figure} Figure */
/** @typedef {import('../domain/figure.js').Shape} Shape */

const TOOLS = [
  ['select', '選択', '↖', 'クリックで選ぶ・ドラッグで動かす・つまみで大きさを変える'],
  ['line', '線', '／', 'ドラッグして線を引きます'],
  ['arrow', '矢印', '→', 'ドラッグして矢印を引きます'],
  ['rect', '四角', '□', 'ドラッグして四角をかきます'],
  ['ellipse', '円', '○', '中心からドラッグして円をかきます（Shift で だ円）'],
  ['polygon', '多角形', '△', 'クリックで頂点を置きます。最初の点をクリック・ダブルクリック・Enter で完成'],
  ['text', '文字', 'A', 'クリックした所に文字を置きます'],
  ['point', '点', '•', 'クリックで点を置きます（名前は A, B, C… の順）'],
  ['angle', '角の印', '∠', '①頂点 ②一方の辺の上 ③もう一方の辺の上 の順にクリック'],
  ['axes', '座標軸', '┼', '原点にしたい所をクリックします'],
  ['graph', '関数のグラフ', 'y=', '式を入れて「追加」を押します'],
];
const PRESETS = [['triangle', '三角形'], ['circle', '円'], ['graph', '座標とグラフ'], ['numberline', '数直線']];
const COLOR_LABEL = { '#000000': '黒', '#555555': 'こい灰', '#888888': '灰', '#ffffff': '白', '#d32f2f': '赤', '#1e5bc6': '青' };
const FILL_LABEL = { none: 'なし', '#ffffff': '白', '#dddddd': 'うすい灰', '#888888': '灰', '#000000': '黒' };
const DASH_LABEL = { solid: '実線', dashed: '破線', dotted: '点線' };
const ARROW_LABEL = { none: 'なし', end: '終点', start: '始点', both: '両方' };
const ANCHOR_LABEL = { start: '左そろえ', middle: '中央', end: '右そろえ' };
const POS_LABEL = { ne: '右上', nw: '左上', se: '右下', sw: '左下', n: '上', s: '下', e: '右', w: '左' };
const TYPE_LABEL = { line: '線', rect: '四角', ellipse: '円', polygon: '多角形', text: '文字', point: '点', angle: '角の印', axes: '座標軸', graph: 'グラフ' };
const GRID = 10;
const ACCENT = '#2459d6';

/**
 * 図をかくモーダルを開く。「保存」で図、「やめる」・Esc で null。
 * @param {Figure} [initial]
 * @param {{ title?: string }} [opts]
 * @returns {Promise<Figure|null>}
 */
export function openDrawing(initial, { title = '図をかく' } = {}) {
  return new Promise(resolve => {
    /** @type {Figure} */
    let fig = initial ? F.cloneFigure(initial) : F.newFigure();
    /** @type {string|null} */
    let sel = null;
    let tool = 'select';
    let snap = true;
    /** @type {string[]} */
    let past = [];
    /** @type {string[]} */
    let future = [];
    /** @type {any} */
    let drag = null;
    /** @type {number[][]} 作りかけの多角形・角の印の点 */
    let clicks = [];
    /** @type {number[]|null} */
    let hover = null;
    let lastDown = { t: 0, x: 0, y: 0 };
    /** @type {EventTarget|null} */
    let propSession = null;
    /** @type {Figure|null} */
    let result = null;

    const toolBtns = TOOLS.map(([k, label, ico, hint]) => `<button type="button" class="btn sm dr-tool" data-tool="${k}" title="${esc(hint)}"><span class="dr-ico" aria-hidden="true">${esc(ico)}</span>${esc(label)}</button>`).join('');
    const presetBtns = PRESETS.map(([k, label]) => `<button type="button" class="btn sm" data-preset="${k}">${esc(label)}</button>`).join('');
    const m = modal({
      title,
      body: `<div class="dr-wrap">
        <div class="dr-toolbar" role="toolbar" aria-label="作図の道具">${toolBtns}</div>
        <div class="dr-toolbar dr-sub"><span class="small muted">ひな形</span>${presetBtns}
          <span class="spacer"></span>
          <button type="button" class="btn sm" data-act="undo" title="元に戻す（Ctrl+Z）">↶ 元に戻す</button>
          <button type="button" class="btn sm" data-act="redo" title="やり直す（Ctrl+Y）">↷ やり直す</button>
          <button type="button" class="btn sm danger" data-act="clear">全部消す</button>
        </div>
        <div class="dr-main">
          <div class="dr-center">
            <form class="dr-exprbar" hidden>
              <label class="dr-inline">y = <input class="input mono" name="expr" placeholder="例：x^2-2x、1/x、sin(x)" autocomplete="off" spellcheck="false"></label>
              <label class="dr-inline">x の範囲 <input class="input dr-num" name="xmin" type="number" step="any" placeholder="左端"> ～ <input class="input dr-num" name="xmax" type="number" step="any" placeholder="右端"></label>
              <button class="btn sm primary" type="submit">追加</button>
              <button class="btn sm" type="button" data-act="expr-cancel">やめる</button>
              <span class="dr-err small" aria-live="polite"></span>
            </form>
            <div class="dr-hint small muted" aria-live="polite"></div>
            <div class="dr-stage-box">
              <div class="dr-stage" tabindex="0" aria-label="作図の画面">
                <div class="dr-layer dr-gridlayer"></div>
                <div class="dr-layer dr-fig"></div>
                <svg class="dr-layer dr-over" xmlns="http://www.w3.org/2000/svg"></svg>
              </div>
            </div>
            <div class="dr-stagebar">
              <label class="dr-inline">幅 <input class="input dr-num" data-size="w" type="number" min="50" max="1200" step="10"></label>
              <label class="dr-inline">高さ <input class="input dr-num" data-size="h" type="number" min="50" max="1200" step="10"></label>
              <label class="check dr-inline"><input type="checkbox" data-snap checked> 方眼に合わせる（${GRID}）</label>
              <span class="small muted">Delete：消す　矢印キー：少し動かす　Ctrl+Z：元に戻す</span>
            </div>
          </div>
          <aside class="dr-props" aria-label="図形の設定"></aside>
        </div>
      </div>`,
      foot: `<button type="button" class="btn" data-act="cancel">やめる</button><button type="button" class="btn primary" data-act="save">保存</button>`,
      onClose: () => {
        window.removeEventListener('keydown', onKey, true);
        window.removeEventListener('resize', onResize);
        resolve(result);
      },
    });
    const root = m.el;
    root.classList.add('dr-modal');
    const back = /** @type {HTMLElement} */ (root.parentElement);
    const $ = (/** @type {string} */ q) => /** @type {HTMLElement} */ (root.querySelector(q));
    const stage = $('.dr-stage'), gridLayer = $('.dr-gridlayer'), figLayer = $('.dr-fig'), over = $('.dr-over');
    const props = $('.dr-props'), hint = $('.dr-hint');
    const exprBar = /** @type {HTMLFormElement} */ ($('.dr-exprbar'));
    const sizeW = /** @type {HTMLInputElement} */ ($('[data-size="w"]')), sizeH = /** @type {HTMLInputElement} */ ($('[data-size="h"]'));

    // 外側をクリックしても閉じない（かきかけの図が消えないように）
    back.addEventListener('click', e => { if (e.target === back) e.stopImmediatePropagation(); }, true);

    // ---------- 履歴 ----------
    const snapshot = () => JSON.stringify(fig);
    /** @param {string} before */
    const pushPast = (before) => { past.push(before); if (past.length > 200) past.shift(); future = []; };
    /** @param {() => void} fn */
    function change(fn) {
      const before = snapshot();
      fn();
      if (snapshot() !== before) pushPast(before);
      propSession = null;
      render();
    }
    function undo() {
      if (!past.length) return;
      future.push(snapshot());
      fig = JSON.parse(/** @type {string} */ (past.pop()));
      afterHistory();
    }
    function redo() {
      if (!future.length) return;
      past.push(snapshot());
      fig = JSON.parse(/** @type {string} */ (future.pop()));
      afterHistory();
    }
    function afterHistory() {
      if (sel && !getShape(sel)) sel = null;
      propSession = null;
      render();
      renderProps();
    }

    // ---------- 図形の出し入れ ----------
    const getShape = (/** @type {string|null} */ id) => fig.shapes.find(s => s.id === id) || null;
    /** @param {string} id @param {Shape} ns */
    const replaceShape = (id, ns) => { fig.shapes = fig.shapes.map(s => (s.id === id ? (F.normalizeShape(ns) || s) : s)); };
    /** @param {Shape} s */
    const addShape = (s) => { fig.shapes.push(s); return s; };
    /** @param {string|null} id */
    function select(id) {
      sel = id;
      propSession = null;
      render();
      renderProps();
    }
    function deleteSelected() {
      if (!sel) return;
      const s = getShape(sel);
      change(() => {
        fig.shapes = fig.shapes.filter(x => x.id !== sel && !(s && s.type === 'axes' && x.type === 'graph' && x.axesId === s.id));
      });
      select(null);
    }

    // ---------- 座標 ----------
    const scaleK = () => { const r = stage.getBoundingClientRect(); return r.width ? fig.w / r.width : 1; };
    /** @param {PointerEvent} e */
    function toLogical(e) {
      const r = stage.getBoundingClientRect();
      return [(e.clientX - r.left) * fig.w / r.width, (e.clientY - r.top) * fig.h / r.height];
    }
    /** 点を頂点か方眼にくっつける @param {number[]} p @param {string} [exceptId] */
    function snapPt(p, exceptId) {
      const tol = 8 * scaleK();
      let best = null, bd = tol;
      for (const q of F.snapPoints(fig, exceptId)) {
        const d = Math.hypot(q[0] - p[0], q[1] - p[1]);
        if (d <= bd) { bd = d; best = q; }
      }
      if (best) return [best[0], best[1]];
      return snap ? [Math.round(p[0] / GRID) * GRID, Math.round(p[1] / GRID) * GRID] : [Math.round(p[0] * 10) / 10, Math.round(p[1] * 10) / 10];
    }
    const snapD = (/** @type {number} */ d) => (snap ? Math.round(d / GRID) * GRID : Math.round(d * 10) / 10);

    // ---------- 描画 ----------
    function gridSvg() {
      let minor = '', major = '';
      for (let x = GRID; x < fig.w; x += GRID) (x % 50 ? (minor += `M${x},0V${fig.h}`) : (major += `M${x},0V${fig.h}`));
      for (let y = GRID; y < fig.h; y += GRID) (y % 50 ? (minor += `M0,${y}H${fig.w}`) : (major += `M0,${y}H${fig.w}`));
      return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${fig.w} ${fig.h}" preserveAspectRatio="none"><path d="${minor}" stroke="#edf0f5" stroke-width="1" vector-effect="non-scaling-stroke" fill="none"/><path d="${major}" stroke="#d8dee8" stroke-width="1" vector-effect="non-scaling-stroke" fill="none"/></svg>`;
    }
    let gridKey = '';
    function render() {
      stage.style.aspectRatio = `${fig.w} / ${fig.h}`;
      stage.style.width = `min(100%, ${Math.round(fig.w * 1.6)}px, calc((100vh - 330px) * ${fig.w / fig.h}))`;
      const gk = fig.w + 'x' + fig.h;
      if (gk !== gridKey) { gridLayer.innerHTML = gridSvg(); gridKey = gk; }
      figLayer.innerHTML = F.toSvg(fig);
      if (document.activeElement !== sizeW) sizeW.value = String(fig.w);
      if (document.activeElement !== sizeH) sizeH.value = String(fig.h);
      renderOverlay();
      updateButtons();
    }
    function renderOverlay() {
      const k = scaleK(), hs = 5 * k;
      over.setAttribute('viewBox', `0 0 ${fig.w} ${fig.h}`);
      over.setAttribute('preserveAspectRatio', 'none');
      let h = '';
      const s = getShape(sel);
      if (s) {
        const b = F.bounds(s, fig);
        const pad = 4 * k;
        h += `<rect x="${b.x - pad}" y="${b.y - pad}" width="${b.w + pad * 2}" height="${b.h + pad * 2}" fill="none" stroke="${ACCENT}" stroke-width="1" stroke-dasharray="4 3" vector-effect="non-scaling-stroke"/>`;
        for (const hd of F.handles(s)) h += `<rect x="${hd.x - hs}" y="${hd.y - hs}" width="${hs * 2}" height="${hs * 2}" fill="#fff" stroke="${ACCENT}" stroke-width="1.5" vector-effect="non-scaling-stroke"/>`;
      }
      if (clicks.length) {
        const pts = hover ? [...clicks, hover] : clicks;
        const d = pts.map((p, i) => (i ? 'L' : 'M') + p[0] + ',' + p[1]).join('');
        h += `<path d="${d}" fill="none" stroke="${ACCENT}" stroke-width="1.5" stroke-dasharray="5 4" vector-effect="non-scaling-stroke"/>`;
        for (const p of clicks) h += `<circle cx="${p[0]}" cy="${p[1]}" r="${3.5 * k}" fill="${ACCENT}"/>`;
      }
      if (hover && tool !== 'select') h += `<circle cx="${hover[0]}" cy="${hover[1]}" r="${3 * k}" fill="none" stroke="${ACCENT}" stroke-width="1" vector-effect="non-scaling-stroke"/>`;
      over.innerHTML = h;
    }
    function updateButtons() {
      root.querySelectorAll('.dr-tool[data-tool]').forEach(b => b.classList.toggle('on', /** @type {HTMLElement} */ (b).dataset.tool === tool));
      /** @type {HTMLButtonElement} */ ($('[data-act="undo"]')).disabled = !past.length;
      /** @type {HTMLButtonElement} */ ($('[data-act="redo"]')).disabled = !future.length;
      const t = TOOLS.find(x => x[0] === tool);
      let msg = t ? t[3] : '';
      if (tool === 'polygon' && clicks.length) msg = `頂点 ${clicks.length} 個。最初の点をクリック・ダブルクリック・Enter で完成、Esc でやめる`;
      if (tool === 'angle' && clicks.length) msg = clicks.length === 1 ? '② 一方の辺の上をクリック' : '③ もう一方の辺の上をクリック';
      hint.innerHTML = esc(msg) + (tool === 'polygon' && clicks.length >= 2 ? ' <button type="button" class="btn sm" data-act="poly-done">完成</button>' : '');
      stage.dataset.mode = tool;
    }

    // ---------- 道具 ----------
    /** @param {string} t */
    function setTool(t) {
      if (t === 'graph') { openExprBar(); return; }
      tool = t;
      clicks = [];
      hover = null;
      exprBar.hidden = true;
      render();
    }
    function nextLabel() {
      const used = new Set(fig.shapes.filter(s => s.type === 'point' || s.type === 'text').map(s => (s.type === 'point' ? s.label : s.text)));
      for (const c of 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') if (!used.has(c)) return c;
      return '';
    }
    function finishPolygon() {
      const pts = clicks.filter((p, i) => i === 0 || Math.hypot(p[0] - clicks[i - 1][0], p[1] - clicks[i - 1][1]) > 0.5);
      clicks = [];
      hover = null;
      if (pts.length < 2) { render(); return; }
      /** @type {any} */ let s;
      change(() => { s = addShape(F.newShape('polygon', { points: pts, closed: pts.length >= 3 })); });
      select(s.id);
    }
    /** 原点の位置から、図に収まる座標軸を作る @param {number} ox @param {number} oy */
    function makeAxes(ox, oy, unit = 20) {
      const xmin = -Math.max(0, Math.floor((ox - 12) / unit)), xmax = Math.max(1, Math.floor((fig.w - ox - 24) / unit));
      const ymin = -Math.max(0, Math.floor((fig.h - oy - 12) / unit)), ymax = Math.max(1, Math.floor((oy - 24) / unit));
      return F.newShape('axes', { ox, oy, unit, xmin, xmax, ymin, ymax, grid: false });
    }
    /** @param {string} k */
    function addPreset(k) {
      const list = k === 'triangle' ? F.presetTriangle() : k === 'circle' ? F.presetCircleWithCenter() : k === 'graph' ? F.presetAxesWithGraph('x^2-2x') : F.presetNumberLine();
      const dx = Math.round((fig.w - 400) / 2), dy = Math.round((fig.h - 300) / 2);
      change(() => { list.forEach(s => addShape(F.moveShape(s, dx, dy))); });
      tool = 'select';
      select(list[list.length - 1].id);
    }

    // ---------- 関数の式の入力 ----------
    function openExprBar() {
      exprBar.hidden = false;
      const s = getShape(sel);
      const ei = /** @type {HTMLInputElement} */ (exprBar.elements.namedItem('expr'));
      if (!ei.value) ei.value = s && s.type === 'graph' ? s.expr : '';
      /** @type {HTMLElement} */ ($('.dr-err')).textContent = '';
      ei.focus();
      ei.select();
    }
    exprBar.addEventListener('submit', e => {
      e.preventDefault();
      const fd = new FormData(exprBar);
      const chk = F.checkExpr(fd.get('expr'));
      const err = /** @type {HTMLElement} */ ($('.dr-err'));
      if (!chk.ok) { err.textContent = '式が読めません：' + chk.error; return; }
      err.textContent = '';
      const cur = getShape(sel);
      let ax = cur && cur.type === 'axes' ? cur : cur && cur.type === 'graph' ? F.axesFor(fig, cur) : fig.shapes.find(s => s.type === 'axes');
      /** @type {any} */ let g;
      change(() => {
        if (!ax || ax.id === 'auto') ax = addShape(makeAxes(Math.round(fig.w / 2 / GRID) * GRID, Math.round(fig.h / 2 / GRID) * GRID));
        const n = (/** @type {*} */ v) => (v === '' || v == null ? null : Number(v));
        g = addShape(F.newShape('graph', { expr: chk.expr, axesId: ax.id, xmin: n(fd.get('xmin')), xmax: n(fd.get('xmax')) }));
      });
      exprBar.hidden = true;
      exprBar.reset();
      tool = 'select';
      select(g.id);
    });

    // ---------- 画面の操作（マウス・タッチ・ペン） ----------
    stage.addEventListener('pointerdown', e => {
      if (e.button !== 0 && e.pointerType === 'mouse') return;
      e.preventDefault();
      stage.focus({ preventScroll: true });
      const raw = toLogical(e);
      const k = scaleK();
      const now = Date.now();
      const dbl = now - lastDown.t < 350 && Math.hypot(raw[0] - lastDown.x, raw[1] - lastDown.y) < 6 * k;
      lastDown = { t: now, x: raw[0], y: raw[1] };

      if (tool === 'select') {
        const cur = getShape(sel);
        if (cur) {
          const hd = F.handles(cur).find(h => Math.abs(h.x - raw[0]) <= 8 * k && Math.abs(h.y - raw[1]) <= 8 * k);
          if (hd) { startDrag(e, { mode: 'handle', id: cur.id, key: hd.key }); return; }
        }
        const id = F.hitTest(fig, raw[0], raw[1], 6 * k);
        if (id !== sel) select(id);
        if (!id) return;
        const s = getShape(id);
        if (dbl && s.type === 'text') { focusProp('text'); return; }
        // グラフは座標軸ごと動かす
        const target = s.type === 'graph' ? F.axesFor(fig, s) : s;
        if (target.id === 'auto') return;
        startDrag(e, { mode: 'move', id: target.id, start: raw, orig: target });
        return;
      }
      const p = snapPt(raw);
      if (tool === 'line' || tool === 'arrow' || tool === 'rect' || tool === 'ellipse') {
        const init = tool === 'rect' ? { x: p[0], y: p[1], w: 0, h: 0 }
          : tool === 'ellipse' ? { cx: p[0], cy: p[1], rx: 0, ry: 0 }
            : { x1: p[0], y1: p[1], x2: p[0], y2: p[1], arrow: tool === 'arrow' ? 'end' : 'none' };
        const s = F.newShape(tool === 'arrow' ? 'line' : tool, init);
        startDrag(e, { mode: 'create', id: s.id, p0: p, before: snapshot() });
        addShape(s);
        sel = s.id;
        render();
        return;
      }
      if (tool === 'polygon') {
        if (dbl && clicks.length >= 2) { finishPolygon(); return; }
        if (clicks.length >= 3 && Math.hypot(p[0] - clicks[0][0], p[1] - clicks[0][1]) <= 8 * k) { finishPolygon(); return; }
        clicks.push(p);
        render();
        return;
      }
      if (tool === 'angle') {
        clicks.push(p);
        if (clicks.length === 3) {
          const [v, a, b] = clicks;
          clicks = [];
          hover = null;
          let s1 = Math.atan2(-(a[1] - v[1]), a[0] - v[0]) * 180 / Math.PI, s2 = Math.atan2(-(b[1] - v[1]), b[0] - v[0]) * 180 / Math.PI;
          let sweep = ((s2 - s1) % 360 + 360) % 360;
          if (sweep > 180) { [s1, s2] = [s2, s1]; sweep = 360 - sweep; }
          /** @type {any} */ let s;
          change(() => { s = addShape(F.newShape('angle', { cx: v[0], cy: v[1], r: 18, start: Math.round(s1 * 10) / 10, end: Math.round(s2 * 10) / 10, right: Math.abs(sweep - 90) < 1.5 })); });
          select(s.id);
          return;
        }
        render();
        return;
      }
      /** @type {any} */ let s = null;
      change(() => {
        if (tool === 'text') s = addShape(F.newShape('text', { x: p[0], y: p[1], text: '文字', size: 16 }));
        else if (tool === 'point') s = addShape(F.newShape('point', { x: p[0], y: p[1], label: nextLabel() }));
        else if (tool === 'axes') s = addShape(makeAxes(p[0], p[1]));
      });
      if (!s) return;
      if (tool === 'text' || tool === 'axes') tool = 'select';
      select(s.id);
      if (s.type === 'text') focusProp('text');
    });

    /** @param {PointerEvent} e @param {any} d */
    function startDrag(e, d) {
      drag = { ...d, pointerId: e.pointerId, before: d.before || snapshot(), moved: false };
      try { stage.setPointerCapture(e.pointerId); } catch { /* 古いブラウザ */ }
    }
    stage.addEventListener('pointermove', e => {
      const raw = toLogical(e);
      if (!drag) {
        if (tool !== 'select') { hover = tool === 'polygon' || tool === 'angle' || tool === 'point' ? snapPt(raw) : null; renderOverlay(); }
        return;
      }
      if (e.pointerId !== drag.pointerId) return;
      drag.moved = true;
      const s = getShape(drag.id);
      if (!s) return;
      if (drag.mode === 'move') {
        replaceShape(drag.id, F.moveShape(drag.orig, snapD(raw[0] - drag.start[0]), snapD(raw[1] - drag.start[1])));
      } else if (drag.mode === 'handle') {
        const p = s.type === 'text' || s.type === 'point' || s.type === 'angle' || s.type === 'axes' ? raw : snapPt(raw, s.id);
        replaceShape(drag.id, F.applyHandle(s, drag.key, p[0], p[1]));
      } else if (drag.mode === 'create') {
        const p = snapPt(raw, s.id), p0 = drag.p0;
        if (s.type === 'line') replaceShape(s.id, { ...s, x2: p[0], y2: p[1] });
        else if (s.type === 'rect') replaceShape(s.id, { ...s, x: Math.min(p0[0], p[0]), y: Math.min(p0[1], p[1]), w: Math.abs(p[0] - p0[0]), h: Math.abs(p[1] - p0[1]) });
        else if (s.type === 'ellipse') {
          const r = Math.round(Math.hypot(p[0] - p0[0], p[1] - p0[1]) * 10) / 10;
          replaceShape(s.id, e.shiftKey ? { ...s, rx: Math.abs(p[0] - p0[0]), ry: Math.abs(p[1] - p0[1]) } : { ...s, rx: r, ry: r });
        }
      }
      render();
    });
    /** @param {PointerEvent} e */
    function endDrag(e) {
      if (!drag || e.pointerId !== drag.pointerId) return;
      const d = drag;
      drag = null;
      if (d.mode === 'create') {
        const s = getShape(d.id);
        if (s) {
          const b = F.bounds(s);
          if (Math.max(b.w, b.h) < 3) {
            // クリックだけのときは決まった大きさで置く
            if (s.type === 'line') replaceShape(s.id, { ...s, x2: s.x1 + 80 });
            else if (s.type === 'rect') replaceShape(s.id, { ...s, w: 80, h: 50 });
            else if (s.type === 'ellipse') replaceShape(s.id, { ...s, rx: 40, ry: 40 });
          }
        }
      }
      if (snapshot() !== d.before) pushPast(d.before);
      propSession = null;
      render();
      renderProps();
    }
    stage.addEventListener('pointerup', endDrag);
    stage.addEventListener('pointercancel', endDrag);
    stage.addEventListener('pointerleave', () => { if (!drag && hover) { hover = null; renderOverlay(); } });

    // ---------- キーボード ----------
    /** @param {KeyboardEvent} e */
    function onKey(e) {
      if (!document.body.contains(root)) return;
      const t = /** @type {HTMLElement} */ (e.target);
      const typing = !!(t && t.closest && t.closest('input, textarea, select'));
      if (e.key === 'Escape') {
        if (clicks.length || drag || !exprBar.hidden) {
          e.preventDefault();
          e.stopPropagation();
          if (drag) { fig = JSON.parse(drag.before); drag = null; }
          clicks = []; hover = null; exprBar.hidden = true;
          render();
          renderProps();
        }
        return; // それ以外の Esc はモーダルを閉じる（＝やめる）
      }
      if (typing) return;
      const mod = e.ctrlKey || e.metaKey;
      const key = e.key.toLowerCase();
      if (mod && key === 'z') { e.preventDefault(); e.shiftKey ? redo() : undo(); return; }
      if (mod && key === 'y') { e.preventDefault(); redo(); return; }
      if (mod) return;
      if (e.key === 'Enter' && tool === 'polygon' && clicks.length) { e.preventDefault(); finishPolygon(); return; }
      if ((e.key === 'Delete' || e.key === 'Backspace') && sel) { e.preventDefault(); deleteSelected(); return; }
      const arrows = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] };
      if (arrows[e.key] && sel) {
        e.preventDefault();
        const s = getShape(sel);
        const target = s.type === 'graph' ? F.axesFor(fig, s) : s;
        if (target.id === 'auto') return;
        const step = e.shiftKey ? 10 : 1;
        const before = snapshot();
        replaceShape(target.id, F.moveShape(target, arrows[e.key][0] * step, arrows[e.key][1] * step));
        // 続けて押したときは 1 回の操作にまとめる
        if (propSession !== stage) { pushPast(before); propSession = stage; }
        render();
      }
    }
    window.addEventListener('keydown', onKey, true);
    const onResize = () => renderOverlay();
    window.addEventListener('resize', onResize);

    // ---------- 設定の欄 ----------
    /** @param {Record<string, string>} labels @param {*} v */
    const opts = (labels, v) => Object.entries(labels).map(([k, l]) => `<option value="${esc(k)}"${String(v) === k ? ' selected' : ''}>${esc(l)}</option>`).join('');
    const sel_ = (/** @type {string} */ k, /** @type {string} */ label, /** @type {Record<string,string>} */ labels, /** @type {*} */ v) => `<label class="f">${esc(label)}<select data-k="${k}">${opts(labels, v)}</select></label>`;
    const numF = (/** @type {string} */ k, /** @type {string} */ label, /** @type {*} */ v, /** @type {number|string} */ step = 1, extra = "") => `<label class="f">${esc(label)}<input type="number" step="${step}" data-k="${k}" data-num value="${v == null ? '' : esc(v)}"${extra}></label>`;
    const txtF = (/** @type {string} */ k, /** @type {string} */ label, /** @type {*} */ v, extra = '') => `<label class="f">${esc(label)}<input type="text" data-k="${k}" value="${esc(v ?? '')}"${extra}></label>`;
    const chkF = (/** @type {string} */ k, /** @type {string} */ label, /** @type {*} */ v) => `<label class="check"><input type="checkbox" data-k="${k}"${v ? ' checked' : ''}> ${esc(label)}</label>`;
    const WIDTHS = { '0.75': '細い（0.75）', '1': '1', '1.5': 'ふつう（1.5）', '2': '2', '3': '太い（3）' };

    function renderProps() {
      const s = getShape(sel);
      if (!s) {
        props.innerHTML = `<div class="dr-props-empty small muted">
          <p><b>使い方</b></p>
          <p>上の道具を選んで、白い画面にかきます。図形をクリックすると、ここで線の太さ・種類・塗りなどを変えられます。</p>
          <p>図形は ${fig.shapes.length} 個あります。</p></div>`;
        return;
      }
      const widths = { ...WIDTHS };
      if (!(String(s.width) in widths)) widths[String(s.width)] = String(s.width);
      let h = `<div class="dr-props-head"><b>${esc(TYPE_LABEL[s.type] || s.type)}</b></div>`;
      const style = (fill = true) => sel_('stroke', '色', COLOR_LABEL, s.stroke) + sel_('width', '線の太さ', widths, s.width) + sel_('dash', '線の種類', DASH_LABEL, s.dash) + (fill ? sel_('fill', '塗り', FILL_LABEL, s.fill) : '');
      switch (s.type) {
        case 'line': h += style(false) + sel_('arrow', '矢印', ARROW_LABEL, s.arrow); break;
        case 'rect': h += style() + `<div class="dr-pair">${numF('w', '横', s.w)}${numF('h', 'たて', s.h)}</div>`; break;
        case 'ellipse': h += style() + `<div class="dr-pair">${numF('rx', '横の半径', s.rx)}${numF('ry', 'たての半径', s.ry)}</div>`; break;
        case 'polygon': h += style() + chkF('closed', '閉じる（最後の点と最初の点を結ぶ）', s.closed); break;
        case 'text':
          h += `<label class="f">文字<textarea data-k="text" rows="2">${esc(s.text)}</textarea></label>`
            + `<div class="dr-pair">${numF('size', '大きさ', s.size, 1, ' min="6" max="120"')}${sel_('anchor', 'そろえ方', ANCHOR_LABEL, s.anchor)}</div>`
            + sel_('stroke', '色', COLOR_LABEL, s.stroke) + chkF('italic', '斜体（x や y などの文字に）', s.italic);
          break;
        case 'point':
          h += `<div class="dr-pair">${txtF('label', '名前', s.label)}${sel_('labelPos', '名前の位置', POS_LABEL, s.labelPos)}</div>`
            + `<div class="dr-pair">${numF('r', '点の大きさ', s.r, 0.5, ' min="0.5" max="20"')}${sel_('fill', '塗り', { '#000000': '黒（●）', none: '白抜き（○）', '#888888': '灰' }, s.fill)}</div>`
            + sel_('stroke', '色', COLOR_LABEL, s.stroke);
          break;
        case 'angle':
          h += txtF('label', '印の文字（例：60°、x、●）', s.label)
            + chkF('right', '直角の印（□）', s.right)
            + `<div class="dr-pair">${numF('r', '半径', s.r, 1, ' min="2"')}${sel_('arcs', '弧の数', { 1: '1本', 2: '2本', 3: '3本' }, s.arcs)}</div>`
            + `<div class="dr-pair">${numF('start', '始めの向き（度）', s.start, 1)}${numF('end', '終わりの向き（度）', s.end, 1)}</div>`
            + style();
          break;
        case 'axes':
          h += `<div class="dr-pair">${numF('xmin', 'x の最小', s.xmin)}${numF('xmax', 'x の最大', s.xmax)}</div>`
            + `<div class="dr-pair">${numF('ymin', 'y の最小', s.ymin)}${numF('ymax', 'y の最大', s.ymax)}</div>`
            + `<div class="dr-pair">${numF('unit', '1 目もりの長さ', s.unit, 1, ' min="2"')}${numF('step', '数字の間隔（0 は自動）', s.step, 1, ' min="0"')}</div>`
            + chkF('grid', '方眼', s.grid) + chkF('ticks', '目もり', s.ticks) + chkF('labels', '数字', s.labels)
            + `<div class="dr-pair">${txtF('xlabel', '横軸の名前', s.xlabel)}${txtF('ylabel', 'たて軸の名前', s.ylabel)}</div>`
            + sel_('stroke', '色', COLOR_LABEL, s.stroke) + sel_('width', '線の太さ', widths, s.width)
            + `<button type="button" class="btn sm" data-act="add-graph">この軸にグラフを追加</button>`;
          break;
        case 'graph': {
          const chk = F.checkExpr(s.expr);
          const axes = fig.shapes.filter(x => x.type === 'axes');
          h += `<label class="f">y =<input type="text" class="mono" data-k="expr" value="${esc(s.expr)}" spellcheck="false" autocomplete="off"></label>`
            + `<div class="dr-err small" data-expr-err>${chk.ok ? '' : esc('式が読めません：' + chk.error)}</div>`
            + `<div class="dr-pair">${numF('xmin', 'x の左端（空は軸に合わせる）', s.xmin, 'any')}${numF('xmax', 'x の右端', s.xmax, 'any')}</div>`
            + (axes.length > 1 ? sel_('axesId', '使う座標軸', Object.fromEntries(axes.map((a, i) => [a.id, `座標軸 ${i + 1}`])), F.axesFor(fig, s).id) : '')
            + style(false);
          break;
        }
      }
      h += `<div class="dr-props-actions">
        <button type="button" class="btn sm" data-act="dup">複製</button>
        <button type="button" class="btn sm" data-act="front">前へ</button>
        <button type="button" class="btn sm" data-act="back">後ろへ</button>
        <button type="button" class="btn sm danger" data-act="del">削除</button></div>`;
      props.innerHTML = h;
    }
    /** @param {string} k */
    function focusProp(k) {
      const el = /** @type {HTMLInputElement|null} */ (props.querySelector(`[data-k="${k}"]`));
      if (el) { el.focus(); el.select(); }
    }
    /** @param {Event} e */
    function onPropInput(e) {
      const el = /** @type {HTMLInputElement} */ (e.target);
      const k = el.dataset && el.dataset.k;
      const s = getShape(sel);
      if (!k || !s) return;
      /** @type {*} */
      let v = el.type === 'checkbox' ? el.checked : el.value;
      if (el.dataset.num !== undefined) {
        if (v === '') { if (s.type !== 'graph') return; v = null; } else { v = Number(v); if (!Number.isFinite(v)) return; }
      }
      if (k === 'width' || k === 'arcs') v = Number(v);
      if (k === 'expr') {
        const chk = F.checkExpr(v);
        const err = /** @type {HTMLElement|null} */ (props.querySelector('[data-expr-err]'));
        if (err) err.textContent = chk.ok ? '' : '式が読めません：' + chk.error;
        if (!chk.ok) return;
        v = chk.expr;
      }
      const before = snapshot();
      replaceShape(s.id, { ...s, [k]: v });
      if (snapshot() === before) return;
      if (propSession !== el) { pushPast(before); propSession = el; }
      render();
      if (el.tagName === 'SELECT' || el.type === 'checkbox') renderPropsKeepFocus(k);
    }
    /** @param {string} k */
    function renderPropsKeepFocus(k) {
      renderProps();
      const el = /** @type {HTMLElement|null} */ (props.querySelector(`[data-k="${k}"]`));
      if (el) el.focus();
    }
    props.addEventListener('input', onPropInput);
    props.addEventListener('change', onPropInput);
    props.addEventListener('focusout', () => { propSession = null; });

    // ---------- ボタン ----------
    root.addEventListener('click', e => {
      const t = /** @type {HTMLElement} */ (e.target);
      const toolBtn = /** @type {HTMLElement|null} */ (t.closest('.dr-tool[data-tool]'));
      if (toolBtn) { setTool(/** @type {string} */ (toolBtn.dataset.tool)); return; }
      const pre = /** @type {HTMLElement|null} */ (t.closest('[data-preset]'));
      if (pre) { addPreset(/** @type {string} */ (pre.dataset.preset)); return; }
      const act = /** @type {HTMLElement|null} */ (t.closest('[data-act]'));
      if (!act) return;
      const s = getShape(sel);
      switch (act.dataset.act) {
        case 'save': result = F.normalizeFigure(fig); m.close(); break;
        case 'cancel': result = null; m.close(); break;
        case 'undo': undo(); break;
        case 'redo': redo(); break;
        case 'clear': if (fig.shapes.length && window.confirm('かいた図形を全部消しますか？')) { change(() => { fig.shapes = []; }); select(null); } break;
        case 'poly-done': finishPolygon(); break;
        case 'expr-cancel': exprBar.hidden = true; break;
        case 'add-graph': openExprBar(); break;
        case 'del': deleteSelected(); break;
        case 'dup': if (s) {
          /** @type {any} */ let c;
          change(() => { c = addShape(F.newShape(s.type, { ...F.moveShape(s, GRID, GRID), id: undefined })); });
          select(c.id);
        } break;
        case 'front': if (s) change(() => { fig.shapes = [...fig.shapes.filter(x => x !== s), s]; }); break;
        case 'back': if (s) change(() => { fig.shapes = [s, ...fig.shapes.filter(x => x !== s)]; }); break;
      }
    });
    root.querySelector('[data-snap]').addEventListener('change', e => { snap = /** @type {HTMLInputElement} */ (e.target).checked; });
    for (const inp of [sizeW, sizeH]) {
      inp.addEventListener('change', () => {
        const v = Math.round(Number(inp.value));
        if (!Number.isFinite(v) || v < 50 || v > 1200) { inp.value = String(inp === sizeW ? fig.w : fig.h); return; }
        change(() => { if (inp === sizeW) fig.w = v; else fig.h = v; });
      });
    }

    render();
    renderProps();
    /** @type {HTMLElement} */ (root.querySelector('[data-tool="select"]')).focus();
    // モーダルが表示されてから大きさが決まるので、もう一度つまみを描く
    requestAnimationFrame(() => renderOverlay());
  });
}
