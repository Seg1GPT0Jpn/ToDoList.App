// ライブラリ：教材の一覧・検索・整理
import { state, saveMaterial, deleteMaterial, setCurrentMaterial, currentMaterialId, log } from '../core/store.js';
import { esc, uid, nowISO, toast, fmtDate, pickFiles, download, clone } from '../core/util.js';
import { KINDS, blockId } from '../domain/material.js';
import { renderMaterial, pageCss } from '../render/material.js';
import { kindLabel, renderMath, modal, fitPreview } from './common.js';

const STATUS_LABEL = { draft: '下書き', review: 'レビュー中', approved: '承認済み', published: '公開・配布', archived: 'アーカイブ' };
const mem = { q: '', kind: '', folder: '', tag: '', status: 'active', sort: 'updated' };

export async function render(root) {
  const cur = await currentMaterialId();
  root.innerHTML = `
  <div class="page-head"><div class="grow"><h1>ライブラリ</h1><p>作った教材の一覧。開く・複製・整理・書き出しができます。</p></div>
    <a class="btn primary" href="#/editor/new">＋ 新しい教材</a><button class="btn" id="import-m">教材を取り込む（JSON）</button></div>
  <div class="card">
    <div class="row">
      <input class="input grow" id="l-q" placeholder="タイトル・単元・タグで検索" style="margin:0">
      <select class="input" id="l-kind" style="width:auto"><option value="">すべての種類</option>${Object.entries(KINDS).map(([k, d]) => `<option value="${k}">${esc(d.label)}</option>`).join('')}</select>
      <select class="input" id="l-folder" style="width:auto"></select>
      <select class="input" id="l-tag" style="width:auto"></select>
      <select class="input" id="l-status" style="width:auto"><option value="active">アーカイブ以外</option><option value="">すべての状態</option>${Object.entries(STATUS_LABEL).map(([k, l]) => `<option value="${k}">${l}</option>`).join('')}</select>
      <select class="input" id="l-sort" style="width:auto"><option value="updated">更新が新しい順</option><option value="created">作成が新しい順</option><option value="title">タイトル順</option></select>
    </div>
  </div>
  <div id="l-list"></div>`;
  const $ = (id) => /** @type {any} */ (root.querySelector('#' + id));
  const folders = [...new Set(state.materials.map(m => m.folder).filter(Boolean))].sort();
  const tags = [...new Set(state.materials.flatMap(m => m.tags || []))].sort();
  $('l-folder').innerHTML = '<option value="">すべてのフォルダ</option>' + folders.map(f => `<option>${esc(f)}</option>`).join('');
  $('l-tag').innerHTML = '<option value="">すべてのタグ</option>' + tags.map(t => `<option>${esc(t)}</option>`).join('');
  for (const k of ['q', 'kind', 'folder', 'tag', 'status', 'sort']) $('l-' + k).value = mem[k];

  const units = (m) => [...new Set(m.blocks.filter(b => b.type === 'question').map(b => b.q.unit).filter(Boolean))];
  const list = () => {
    const q = mem.q.trim().toLowerCase();
    let ms = state.materials.filter(m => {
      if (mem.kind && m.kind !== mem.kind) return false;
      if (mem.folder && m.folder !== mem.folder) return false;
      if (mem.tag && !(m.tags || []).includes(mem.tag)) return false;
      if (mem.status === 'active' ? m.status === 'archived' : mem.status && m.status !== mem.status) return false;
      if (q && ![m.title, m.subtitle, m.folder, ...(m.tags || []), ...units(m)].join(' ').toLowerCase().includes(q)) return false;
      return true;
    });
    if (mem.sort === 'title') ms.sort((a, b) => a.title.localeCompare(b.title, 'ja'));
    else if (mem.sort === 'created') ms.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    return ms;
  };
  const renderList = () => {
    const ms = list();
    $('l-list').innerHTML = ms.length ? `<div class="card" style="padding:0;overflow-x:auto"><table class="list"><tr><th>タイトル</th><th>種類</th><th>問題</th><th>状態</th><th>フォルダ・タグ</th><th>更新</th><th></th></tr>
      ${ms.map(m => `<tr data-id="${esc(m.id)}"><td><a href="#/editor/${esc(m.id)}"><b>${esc(m.title)}</b></a>${m.id === cur ? ' <span class="chip accent">作業中</span>' : ''}<div class="small muted">${esc(units(m).slice(0, 4).join('・'))}</div></td>
        <td class="small">${esc(kindLabel(m.kind))}</td><td>${m.blocks.filter(b => b.type === 'question').length}</td>
        <td><span class="chip ${m.status === 'published' ? 'ok' : m.status === 'review' ? 'warn' : ''}">${STATUS_LABEL[m.status] || m.status}</span></td>
        <td class="small">${esc(m.folder || '')}${(m.tags || []).map(t => ` <span class="chip accent">#${esc(t)}</span>`).join('')}</td>
        <td class="small muted" style="white-space:nowrap">${fmtDate(m.updatedAt, true)}</td>
        <td style="white-space:nowrap"><a class="btn sm" href="#/editor/${esc(m.id)}">開く</a> <button class="btn sm" data-act="view">見本</button> <button class="btn sm" data-act="dup">複製</button>
          <button class="btn sm" data-act="${m.status === 'archived' ? 'unarchive' : 'archive'}">${m.status === 'archived' ? '戻す' : 'アーカイブ'}</button>
          <button class="btn sm" data-act="export">書き出し</button> <button class="btn sm danger" data-act="delete">削除</button></td></tr>`).join('')}</table></div>`
      : `<div class="card empty">${state.materials.length ? '条件に合う教材がありません。' : 'まだ教材がありません。'}<br><a class="btn primary" href="#/editor/new">新しい教材を作る</a></div>`;
  };
  renderList();
  for (const k of ['q', 'kind', 'folder', 'tag', 'status', 'sort']) $('l-' + k).addEventListener(k === 'q' ? 'input' : 'change', () => { mem[k] = $('l-' + k).value; renderList(); });

  $('l-list').addEventListener('click', async (e) => {
    const btn = e.target.closest('[data-act]');
    if (!btn) return;
    const m = state.materials.find(x => x.id === btn.closest('tr').dataset.id);
    if (!m) return;
    switch (btn.dataset.act) {
      case 'view': {
        const out = renderMaterial(m, state.stims);
        const md = modal({ title: m.title, body: `<div class="preview-wrap"><div class="preview">${out.html}</div></div>`, foot: `<a class="btn primary" href="#/editor/${esc(m.id)}" data-close>開いて編集</a>` });
        renderMath(md.el);
        fitPreview(/** @type {any} */ (md.el.querySelector('.preview')));
        break;
      }
      case 'dup': {
        const c = clone(m);
        Object.assign(c, { id: uid('M-'), title: m.title + '（コピー）', status: 'draft', rev: 1, createdAt: nowISO() });
        c.blocks = c.blocks.map(b => ({ ...b, id: blockId() }));
        await saveMaterial(c);
        toast('複製しました', 'ok');
        renderList();
        break;
      }
      case 'archive': case 'unarchive':
        await saveMaterial({ ...m, status: btn.dataset.act === 'archive' ? 'archived' : 'draft' }, { snapshot: true, note: btn.dataset.act === 'archive' ? 'アーカイブ' : 'アーカイブから戻す' });
        renderList();
        break;
      case 'export':
        download(`${m.title}.json`, JSON.stringify({ format: 'mondai-material', version: 1, material: m }, null, 1));
        break;
      case 'delete':
        if (!confirm(`「${m.title}」を削除しますか？（元に戻せません。残したい場合はアーカイブを使ってください）`)) return;
        await deleteMaterial(m.id);
        if (m.id === cur) await setCurrentMaterial(null);
        renderList();
        break;
    }
  });

  $('import-m').addEventListener('click', async () => {
    const files = await pickFiles('.json,application/json', true);
    let n = 0;
    for (const f of files) {
      try {
        const d = JSON.parse(await f.text());
        const ms = d.format === 'mondai-material' ? [d.material] : Array.isArray(d.materials) ? d.materials : [];
        for (const m of ms) {
          if (!m || !Array.isArray(m.blocks) || !m.page || !m.print) throw new Error('教材の形ではありません');
          const ex = state.materials.find(x => x.id === m.id);
          await saveMaterial({ ...m, id: ex ? uid('M-') : m.id || uid('M-'), title: ex ? m.title + '（取り込み）' : m.title });
          n++;
        }
      } catch (err) { toast(`${f.name}：取り込めませんでした（${err.message}）`, 'error'); }
    }
    if (n) { await log('教材を取り込み', `${n}件`); toast(`${n} 件の教材を取り込みました`, 'ok'); renderList(); }
  });
  void pageCss;
}
