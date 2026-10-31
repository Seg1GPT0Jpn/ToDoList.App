import { describe, it, expect } from 'vitest';
import {
  newFigure, newShape, toSvg, normalizeShape, normalizeFigure, normalizeExpr, checkExpr, sampleGraph, graphSegments,
  bounds, hitTest, moveShape, cloneFigure, handles, applyHandle,
  presetTriangle, presetCircleWithCenter, presetAxesWithGraph, presetNumberLine,
} from '../../js/domain/figure.js';

/** 簡単な XML の形の検査：タグの対応・属性の引用符・禁止物がないこと */
function checkXml(svg) {
  expect(svg.startsWith('<svg xmlns="http://www.w3.org/2000/svg"')).toBe(true);
  expect(svg.endsWith('</svg>')).toBe(true);
  expect(svg).not.toMatch(/<script|<foreignObject|<iframe|<image|<use|javascript:|<!ENTITY|<!DOCTYPE/i);
  const stack = [];
  const re = /<(\/?)([A-Za-z][\w:-]*)((?:\s+[\w:-]+="[^"<]*")*)\s*(\/?)>|([<>])/g;
  let m, last = 0;
  while ((m = re.exec(svg))) {
    expect(m[5], `stray ${m[5]} at ${m.index}: ${svg.slice(m.index - 30, m.index + 30)}`).toBeUndefined();
    // タグの外の文字に生の < > & がないこと
    const between = svg.slice(last, m.index);
    expect(between).not.toMatch(/[<>]|&(?!amp;|lt;|gt;|quot;|#39;)/);
    last = re.lastIndex;
    // 属性名にイベント・リンクがないこと
    for (const a of (m[3] || '').matchAll(/([\w:-]+)="/g)) expect(a[1]).not.toMatch(/^on|href|^style$/i);
    if (m[1]) expect(stack.pop()).toBe(m[2]);
    else if (!m[4]) stack.push(m[2]);
  }
  expect(stack).toEqual([]);
  return svg;
}
const figOf = (...shapes) => ({ ...newFigure(), shapes });
const numAttrs = (svg) => [...svg.matchAll(/\s(?:x|y|x1|y1|x2|y2|cx|cy|r|rx|ry|width|height)="([^"]*)"/g)].map(m => m[1]);

describe('toSvg: each shape type', () => {
  it('empty figure', () => {
    const svg = checkXml(toSvg(newFigure()));
    expect(svg).toContain('viewBox="0 0 400 300"');
    expect(svg).toContain('width="400" height="300"');
    expect(svg).toMatch(/font-family="[^"]*serif"/);
  });
  it('scale changes px size but not viewBox', () => {
    const svg = toSvg(newFigure(200, 100), { scale: 2 });
    expect(svg).toContain('viewBox="0 0 200 100"');
    expect(svg).toContain('width="400" height="200"');
  });
  it('line with arrows uses markers with unique ids per call', () => {
    const fig = figOf(newShape('line', { x1: 10, y1: 20, x2: 110, y2: 20, arrow: 'both', dash: 'dashed', width: 2 }));
    const a = checkXml(toSvg(fig)), b = toSvg(fig);
    expect(a).toMatch(/<line x1="10" y1="20" x2="110" y2="20"/);
    expect(a).toContain('stroke-dasharray');
    expect(a).toMatch(/marker-end="url\(#([^)]+)\)"/);
    expect(a).toMatch(/marker-start="url\(#([^)]+)\)"/);
    const ids = (s) => [...s.matchAll(/<marker id="([^"]+)"/g)].map(m => m[1]);
    expect(ids(a)).toHaveLength(2);
    expect(ids(a).filter(x => ids(b).includes(x))).toEqual([]);
    for (const id of ids(a)) expect(a).toContain(`url(#${id})`);
  });
  it('line without arrow has no markers', () => {
    expect(toSvg(figOf(newShape('line', {})))).not.toContain('<marker');
  });
  it('rect / ellipse / polygon / polyline', () => {
    const svg = checkXml(toSvg(figOf(
      newShape('rect', { x: 10, y: 10, w: -50, h: 30, fill: '#dddddd' }),
      newShape('ellipse', { cx: 100, cy: 100, rx: 40, ry: 20 }),
      newShape('polygon', { points: [[0, 0], [10, 0], [5, 8]], closed: true, dash: 'dotted' }),
      newShape('polygon', { points: [[0, 0], [10, 10]], closed: false }),
    )));
    expect(svg).toContain('<rect x="-40" y="10" width="50" height="30" fill="#dddddd"');
    expect(svg).toContain('<ellipse cx="100" cy="100" rx="40" ry="20" fill="none"');
    expect(svg).toContain('<polygon points="0,0 10,0 5,8"');
    expect(svg).toContain('<polyline points="0,0 10,10"');
  });
  it('text: escaped, serif, anchor, italic, multi-line', () => {
    const svg = checkXml(toSvg(figOf(newShape('text', { x: 5, y: 20, text: 'AB = 3 cm\n2行目', size: 18, anchor: 'middle', italic: true }))));
    expect(svg).toContain('font-size="18" text-anchor="middle"');
    expect(svg).toContain('font-style="italic"');
    expect(svg).toContain('AB = 3 cm');
    expect(svg).toContain('<tspan x="5" dy="22.5">2行目</tspan>');
  });
  it('point with label, hollow point', () => {
    const svg = checkXml(toSvg(figOf(newShape('point', { x: 50, y: 50, label: 'P' }), newShape('point', { x: 60, y: 50, fill: 'none' }))));
    expect(svg).toContain('<circle cx="50" cy="50" r="2.5" fill="#000000"');
    expect(svg).toContain('>P</text>');
    expect(svg).toContain('<circle cx="60" cy="50" r="2.5" fill="#ffffff"');
  });
  it('angle: arc (math orientation) and right-angle square', () => {
    const arc = checkXml(toSvg(figOf(newShape('angle', { cx: 100, cy: 100, r: 20, start: 0, end: 90, label: '90°' }))));
    // 0° は右 (120,100)、90° は上 (100,80)：y が上向きに変換されている
    expect(arc).toContain('M120,100 A20,20 0 0 0 100,80');
    expect(arc).toContain('>90°</text>');
    const big = toSvg(figOf(newShape('angle', { cx: 0, cy: 0, r: 10, start: 0, end: 270 })));
    expect(big).toContain(' 0 1 0 ');
    const right = checkXml(toSvg(figOf(newShape('angle', { cx: 100, cy: 100, r: 20, start: 0, end: 90, right: true }))));
    expect(right).toContain('M115,100 L115,85 L100,85');
    expect(right).not.toContain(' A');
  });
  it('axes: lines with arrows, ticks, labels, origin O, grid', () => {
    const svg = checkXml(toSvg(figOf(newShape('axes', { ox: 200, oy: 150, unit: 20, xmin: -3, xmax: 3, ymin: -2, ymax: 2, grid: true }))));
    expect(svg).toContain('<line x1="140" y1="150"');
    expect(svg).toContain('marker-end');
    expect(svg).toContain('>−3</text>');
    expect(svg).toContain('>2</text>');
    expect(svg).toContain('>O</text>');
    expect(svg).toMatch(/>x<\/text>/);
    expect(svg).toMatch(/>y<\/text>/);
    expect(svg).toContain('stroke="#b5b5b5"');
    const plain = toSvg(figOf(newShape('axes', { labels: false, ticks: false, grid: false })));
    expect(plain).not.toContain('>O</text>');
    expect(plain).not.toContain('#b5b5b5');
  });
  it('graph: plotted through its axes and clipped', () => {
    const ax = newShape('axes', { ox: 200, oy: 150, unit: 20, xmin: -5, xmax: 5, ymin: -5, ymax: 5 });
    const svg = checkXml(toSvg(figOf(ax, newShape('graph', { expr: 'x^2', axesId: ax.id }))));
    expect(svg).toMatch(/<clipPath id="[^"]+"><rect x="100" y="50" width="200" height="200"\/><\/clipPath>/);
    const d = /<path d="(M[^"]+)" fill="none" clip-path/.exec(svg)[1];
    expect(d).toContain('200,150'); // 原点を通る
    expect(d.split('M')).toHaveLength(2); // 1 本につながる
  });
  it('graph with bad expression draws nothing', () => {
    const ax = newShape('axes', {});
    const svg = checkXml(toSvg(figOf(ax, newShape('graph', { expr: 'alert(1)', axesId: ax.id }))));
    expect(svg).not.toContain('clip-path');
    expect(svg).not.toContain('alert');
  });
});

describe('sanitizing', () => {
  it('escapes malicious text', () => {
    const svg = checkXml(toSvg(figOf(
      newShape('text', { text: '<script>alert(1)</script>' }),
      newShape('text', { text: '" onload="alert(1)' }),
      newShape('point', { label: '</text><script>x</script>' }),
      newShape('angle', { label: '&<>' }),
      newShape('axes', { xlabel: '<b onmouseover=1>', ylabel: "'" }),
    )));
    expect(svg).not.toContain('<script');
    expect(svg).toContain('&lt;script&gt;');
    expect(svg).toContain('&quot; onload=&quot;');
    expect(svg).toContain('&amp;&lt;&gt;');
  });
  it('drops control characters and lone surrogates', () => {
    const svg = toSvg(figOf(newShape('text', { text: 'a\u0000b\u0007c\uD800d' })));
    expect(svg).toContain('>abcd</text>');
  });
  it('coerces non-numeric coordinates', () => {
    const svg = checkXml(toSvg(figOf(
      { type: 'line', id: 'a', x1: 'abc', y1: '10" onclick="x', x2: NaN, y2: Infinity },
      { type: 'rect', id: 'b', x: { a: 1 }, y: [1], w: '20', h: null },
      { type: 'polygon', id: 'c', points: [['x', 1], null, { x: '3', y: 'q' }, 'zz'] },
      { type: 'ellipse', id: 'd', cx: 1e30, cy: -1e30, rx: -5, ry: 5 },
    )));
    for (const v of numAttrs(svg)) expect(v).toMatch(/^-?\d+(\.\d+)?$/);
    expect(svg).not.toContain('onclick');
    expect(svg).toContain('<line x1="50" y1="150" x2="150" y2="150"'); // 既定値
    expect(svg).toContain('width="20"');
    expect(svg).toContain('points="0,1 0,0 3,0 0,0"');
    expect(svg).toContain('rx="5"');
  });
  it('whitelists colors, fills and enums', () => {
    const s = normalizeShape({ type: 'line', stroke: 'url(javascript:alert(1))', fill: 'red;x', dash: 'evil', arrow: '"><script>', width: 'wide' });
    expect(s).toMatchObject({ stroke: '#000000', fill: 'none', dash: 'solid', arrow: 'none', width: 1.5 });
    expect(normalizeShape({ type: 'rect', stroke: '#D32F2F', fill: '#DDD' })).toMatchObject({ stroke: '#d32f2f', fill: '#dddddd' });
    expect(normalizeShape({ type: 'text', anchor: 'x', size: 9999 })).toMatchObject({ anchor: 'start', size: 120 });
    const svg = checkXml(toSvg(figOf({ type: 'text', id: 'a', text: 'x', stroke: '" onload="x', anchor: '"/><script>' })));
    expect(svg).not.toMatch(/onload|<script/);
  });
  it('drops unknown shapes and bad ids, clamps figure size', () => {
    const fig = normalizeFigure({ w: 'x', h: 99999, shapes: [{ type: 'script' }, null, 'x', { type: 'image', href: 'http://x' }, { type: 'point', id: '"><x' }, { type: 'point', id: 'p1' }, { type: 'point', id: 'p1' }] });
    expect(fig.w).toBe(400);
    expect(fig.h).toBe(2000);
    expect(fig.shapes.map(s => s.type)).toEqual(['point', 'point', 'point']);
    expect(fig.shapes[0].id).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(new Set(fig.shapes.map(s => s.id)).size).toBe(3);
    expect(normalizeFigure(null).shapes).toEqual([]);
    expect(checkXml(toSvg(/** @type {any} */ ('<svg onload=alert(1)>')))).not.toContain('onload');
  });
  it('never emits href or event attributes even with prototype tricks', () => {
    const evil = JSON.parse('{"type":"text","id":"a","text":"x","__proto__":{"onload":"x"},"href":"javascript:x","xlink:href":"http://x"}');
    const svg = checkXml(toSvg(figOf(evil)));
    expect(svg).not.toMatch(/href|onload/);
  });
});

describe('expressions and graph sampling', () => {
  it('normalizeExpr adds implicit multiplication', () => {
    expect(normalizeExpr('x^2-2x')).toBe('x^2-2*x');
    expect(normalizeExpr('y = 2(x+1)')).toBe('2*(x+1)');
    expect(normalizeExpr('(x+1)(x-1)')).toBe('(x+1)*(x-1)');
    expect(normalizeExpr('x(x+1)')).toBe('x*(x+1)');
    expect(normalizeExpr('2sin(x)')).toBe('2*sin(x)');
    expect(normalizeExpr('1.5e2x')).toBe('1.5e2*x');
    expect(normalizeExpr('３ｘ²＋１')).toBe('3*x^2+1');
    expect(normalizeExpr('2πx')).toBe('2*pi*x');
    expect(normalizeExpr('xx')).toBe('x*x');
  });
  it('checkExpr reports errors without eval', () => {
    expect(checkExpr('x^2-2x')).toMatchObject({ ok: true, expr: 'x^2-2*x' });
    expect(checkExpr('alert(1)').ok).toBe(false);
    expect(checkExpr('constructor').ok).toBe(false);
    expect(checkExpr('').ok).toBe(false);
  });
  it('samples ≥ 200 finite points for a polynomial', () => {
    const segs = sampleGraph('x^2-2x', -3, 5, -5, 20, 50);
    expect(segs).toHaveLength(1);
    expect(segs[0].length).toBeGreaterThanOrEqual(200);
    expect(segs[0].every(([x, y]) => Number.isFinite(x) && Number.isFinite(y))).toBe(true);
    const [x, y] = segs[0].find(p => Math.abs(p[0] - 1) < 1e-9);
    expect(y).toBeCloseTo(-1);
  });
  it('breaks at the asymptote of 1/x', () => {
    for (const [a, b] of [[-5, 5], [-5.13, 4.97]]) {
      const segs = sampleGraph('1/x', a, b, -5, 5);
      expect(segs).toHaveLength(2);
      expect(segs[0].every(p => p[0] < 0)).toBe(true);
      expect(segs[1].every(p => p[0] > 0)).toBe(true);
      expect(segs.flat().every(([, y]) => Number.isFinite(y) && Math.abs(y) <= 15)).toBe(true);
    }
  });
  it('breaks at tan asymptotes and where sqrt is undefined', () => {
    expect(sampleGraph('tan(x)', -4, 4, -5, 5).length).toBe(3);
    const s = sampleGraph('sqrt(x)', -2, 4, -1, 3);
    expect(s).toHaveLength(1);
    expect(s[0][0][0]).toBeGreaterThanOrEqual(0);
  });
  it('bad expression or range gives nothing', () => {
    expect(sampleGraph('foo(x)', -1, 1, -1, 1)).toEqual([]);
    expect(sampleGraph('x', 1, -1, -1, 1)).toEqual([]);
  });
  it('graphSegments uses the referenced axes transform', () => {
    const a1 = newShape('axes', { ox: 100, oy: 100, unit: 10, xmin: -2, xmax: 2, ymin: -2, ymax: 2 });
    const a2 = newShape('axes', { ox: 300, oy: 200, unit: 20, xmin: -2, xmax: 2, ymin: -2, ymax: 2 });
    const g = newShape('graph', { expr: 'x', axesId: a2.id });
    const seg = graphSegments(figOf(a1, a2, g), g)[0];
    expect(seg[0]).toEqual([260, 240]);
    expect(seg[seg.length - 1]).toEqual([340, 160]);
  });
});

describe('hitTest / bounds / move / handles', () => {
  const line = newShape('line', { id: 'L', x1: 0, y1: 0, x2: 100, y2: 0 });
  const rect = newShape('rect', { id: 'R', x: 50, y: -20, w: 40, h: 40, fill: '#ffffff' });
  const circ = newShape('ellipse', { id: 'C', cx: 200, cy: 100, rx: 30, ry: 30 });
  const fig = figOf(line, rect, circ);
  it('returns the topmost shape', () => {
    expect(hitTest(fig, 60, 0, 3)).toBe('R'); // 塗りのある四角が線の上
    expect(hitTest(fig, 20, 2, 3)).toBe('L');
    expect(hitTest(fig, 230, 100, 3)).toBe('C');
    expect(hitTest(fig, 200, 100, 3)).toBe('C'); // 中心
    expect(hitTest(fig, 215, 100, 3)).toBeNull(); // 塗りのない円の内側
    expect(hitTest(fig, 300, 300, 3)).toBeNull();
  });
  it('hits text, points, angles, axes and graphs', () => {
    const ax = newShape('axes', { id: 'A', ox: 200, oy: 150, unit: 20, xmin: -5, xmax: 5, ymin: -5, ymax: 5 });
    const f2 = figOf(ax, newShape('graph', { id: 'G', expr: 'x', axesId: 'A' }), newShape('text', { id: 'T', x: 10, y: 30, text: 'ABC', size: 20 }), newShape('point', { id: 'P', x: 350, y: 20 }));
    expect(hitTest(f2, 240, 110, 3)).toBe('G'); // x=2, y=2
    expect(hitTest(f2, 290, 150, 3)).toBe('A');
    expect(hitTest(f2, 20, 25, 3)).toBe('T');
    expect(hitTest(f2, 351, 21, 3)).toBe('P');
  });
  it('bounds and moveShape', () => {
    expect(bounds(line)).toEqual({ x: 0, y: 0, w: 100, h: 0 });
    expect(bounds(circ)).toEqual({ x: 170, y: 70, w: 60, h: 60 });
    const moved = moveShape(line, 5, 7);
    expect(moved).toMatchObject({ x1: 5, y1: 7, x2: 105, y2: 7 });
    expect(line.x1).toBe(0); // 元は変わらない
    const poly = moveShape(newShape('polygon', { points: [[0, 0], [1, 1]] }), 1, 1);
    expect(poly.points).toEqual([[1, 1], [2, 2]]);
    expect(moveShape(newShape('axes', { ox: 1, oy: 2 }), 1, 1)).toMatchObject({ ox: 2, oy: 3 });
  });
  it('handles resize lines, rects, ellipses, text, points', () => {
    expect(handles(line).map(h => h.key)).toEqual(['p1', 'p2']);
    expect(applyHandle(line, 'p2', 50, 50)).toMatchObject({ x2: 50, y2: 50 });
    expect(applyHandle(rect, 'se', 100, 40)).toMatchObject({ x: 50, y: -20, w: 50, h: 60 });
    expect(applyHandle(rect, 'nw', 60, 0)).toMatchObject({ x: 60, y: 0, w: 30, h: 20 });
    expect(applyHandle(circ, 'se', 250, 150)).toMatchObject({ cx: 210, cy: 110, rx: 40, ry: 40 });
    const t = newShape('text', { x: 0, y: 20, size: 20 });
    expect(applyHandle(t, 'size', 0, 3 + 30).size).toBe(30);
    expect(applyHandle(newShape('point', { x: 0, y: 0 }), 'r', 10, 0).r).toBe(4);
  });
  it('cloneFigure is deep', () => {
    const c = cloneFigure(fig);
    c.shapes[0].x1 = 999;
    expect(fig.shapes[0].x1).toBe(0);
    expect(c.shapes).toHaveLength(3);
  });
});

describe('presets', () => {
  for (const [name, fn] of [['triangle', presetTriangle], ['circle', presetCircleWithCenter], ['axes+graph', () => presetAxesWithGraph('x^2-2x')], ['number line', presetNumberLine]]) {
    it(`${name} produces valid SVG inside the canvas`, () => {
      const shapes = fn();
      expect(shapes.length).toBeGreaterThan(0);
      const fig = figOf(...shapes);
      const svg = checkXml(toSvg(fig));
      for (const s of shapes) {
        const b = bounds(s, fig);
        expect(b.x).toBeGreaterThanOrEqual(0);
        expect(b.y).toBeGreaterThanOrEqual(0);
        expect(b.x + b.w).toBeLessThanOrEqual(400);
        expect(b.y + b.h).toBeLessThanOrEqual(300);
      }
      expect(svg.length).toBeGreaterThan(100);
    });
  }
  it('axes+graph links the graph to its axes and normalizes the expression', () => {
    const [ax, g] = presetAxesWithGraph('x^2-2x');
    expect(g.axesId).toBe(ax.id);
    expect(g.expr).toBe('x^2-2*x');
    expect(toSvg(figOf(ax, g))).toContain('clip-path');
  });
});
