// チーム：ログイン・ワークスペース・メンバーと権限・共有・レビュー・コメント・履歴（Supabase）
import { state, saveMaterial, saveQuestions, setCurrentMaterial, log } from '../core/store.js';
import { esc, toast, fmtDate, uid, nowISO, clone } from '../core/util.js';
import { blockId } from '../domain/material.js';
import { modal, kindLabel } from './common.js';

const ROLE_LABEL = { owner: 'オーナー', admin: '管理者', editor: '編集者', reviewer: 'レビュアー', viewer: '閲覧者' };
const REVIEW_LABEL = { pending: '確認待ち', approved: '承認', rejected: '差し戻し' };
const STATUS_LABEL = { draft: '下書き', review: 'レビュー中', approved: '承認済み', published: '公開・配布', archived: 'アーカイブ' };
const canEdit = (r) => ['owner', 'admin', 'editor'].includes(r);
const canReview = (r) => ['owner', 'admin', 'reviewer'].includes(r);
const canManage = (r) => ['owner', 'admin'].includes(r);
let selectedWs = null;

export async function render(root) {
  let cloud;
  try { cloud = await import('../cloud/supabase.js'); } catch (e) { cloud = null; }
  const head = '<div class="page-head"><div class="grow"><h1>チーム</h1><p>教材や問題をチームで共有し、レビュー・承認して配布します。個人の教材は共有するまで公開されません。</p></div></div>';
  if (!cloud || !cloud.isConfigured()) {
    root.innerHTML = head + `<div class="card"><h2>クラウドに接続していません</h2>
      <p>チーム機能には、無料で使える Supabase の設定が必要です（一度だけ）。</p>
      <ol><li>Supabase で無料のプロジェクトを作る</li><li>付属の SQL を実行してデータベースを用意する</li><li>「設定・データ」に Project URL と anon key を入れる</li></ol>
      <p>詳しい手順：<a href="https://github.com/Seg1GPT0Jpn/ToDoList.App/blob/main/mondai/supabase/README.md" target="_blank" rel="noopener">supabase/README.md</a></p>
      <a class="btn primary" href="#/settings">設定・データへ</a>
      <p class="small muted mt">接続しなくても、このアプリのほかの機能（問題バンク・教材制作・テスト制作など）はこの端末の中ですべて使えます。</p></div>`;
    return;
  }
  let user = null;
  try { user = await cloud.currentUser(); } catch (e) { /* 未ログイン */ }
  if (!user) {
    root.innerHTML = head + `<div class="card" style="max-width:520px"><h2>ログイン</h2>
      <p>メールアドレスにログイン用のリンクを送ります。パスワードはいりません。</p>
      <label class="f">メールアドレス<input class="input" type="email" id="t-email" autocomplete="email"></label>
      <button class="btn primary" id="t-login">ログインリンクを送る</button>
      ${sessionStorage.getItem('mondai.invite') ? '<div class="notice info mt">招待を受け取っています。ログインすると参加できます。</div>' : ''}</div>`;
    root.querySelector('#t-login').addEventListener('click', async () => {
      const email = /** @type {any} */ (root.querySelector('#t-email')).value.trim();
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { toast('メールアドレスを正しく入れてください', 'error'); return; }
      try { await cloud.signIn(email); toast('ログイン用のリンクを送りました。メールを開いてください', 'ok'); }
      catch (e) { toast('送れませんでした：' + e.message, 'error'); }
    });
    return;
  }

  // 招待リンクから来たとき
  const token = sessionStorage.getItem('mondai.invite');
  if (token) {
    sessionStorage.removeItem('mondai.invite');
    try { selectedWs = await cloud.acceptInvitation(token); toast('チームに参加しました', 'ok'); await log('チームに参加', selectedWs); }
    catch (e) { toast('招待を受けられませんでした：' + e.message, 'error'); }
  }

  let workspaces = [];
  try { workspaces = await cloud.listWorkspaces(); } catch (e) { root.innerHTML = head + `<div class="notice error">ワークスペースを読み込めませんでした：${esc(e.message)}</div>`; return; }
  if (!selectedWs || !workspaces.some(w => w.id === selectedWs)) selectedWs = (workspaces.find(w => !w.personal) || workspaces[0] || {}).id || null;

  root.innerHTML = head + `
  <div class="side-layout">
    <aside class="card">
      <h2>アカウント</h2>
      <p class="small">${esc(user.email)}</p>
      <label class="f">表示名<input class="input" id="t-name" placeholder="チームの人に見える名前"></label>
      <button class="btn sm" id="t-logout">ログアウト</button>
      <h2 class="mt">ワークスペース</h2>
      <div id="t-wslist">${workspaces.map(w => `<button class="btn ${w.id === selectedWs ? 'primary' : ''}" style="width:100%;justify-content:flex-start;margin-bottom:6px" data-ws="${esc(w.id)}">${w.personal ? '個人' : esc(w.name)}<span class="spacer"></span><span class="small">${esc(ROLE_LABEL[w.role] || w.role || '')}</span></button>`).join('')}</div>
      <div class="row"><input class="input grow" id="t-newname" placeholder="新しいチームの名前" style="margin:0"><button class="btn sm" id="t-create">作る</button></div>
    </aside>
    <div id="t-main"></div>
  </div>`;
  const $ = (id) => /** @type {any} */ (root.querySelector('#' + id));
  $('t-logout').addEventListener('click', async () => { await cloud.signOut(); toast('ログアウトしました'); render(root); });
  if (cloud.updateProfile) {
    $('t-name').addEventListener('change', async () => { try { await cloud.updateProfile({ display_name: $('t-name').value.trim() }); toast('表示名を保存しました', 'ok'); } catch (e) { toast(e.message, 'error'); } });
  } else $('t-name').closest('label').hidden = true;
  $('t-wslist').addEventListener('click', (e) => { const b = e.target.closest('[data-ws]'); if (b) { selectedWs = b.dataset.ws; render(root); } });
  $('t-create').addEventListener('click', async () => {
    const name = $('t-newname').value.trim();
    if (!name) { toast('チームの名前を入れてください', 'error'); return; }
    try { selectedWs = await cloud.createWorkspace(name); await log('チームを作成', name); render(root); }
    catch (e) { toast('作れませんでした：' + e.message, 'error'); }
  });

  const ws = workspaces.find(w => w.id === selectedWs);
  const main = $('t-main');
  if (!ws) { main.innerHTML = '<div class="card empty">ワークスペースがありません。左でチームを作ってください。</div>'; return; }
  const role = ws.role;
  main.innerHTML = `
    <div class="card"><h2>${ws.personal ? '個人ワークスペース' : esc(ws.name)} <span class="chip accent">あなた：${esc(ROLE_LABEL[role] || role)}</span></h2>
      <p class="small muted">${ws.personal ? '自分だけが見られる場所です。端末をまたいで教材を持ち運べます。' : '権限：オーナー・管理者＝メンバー管理／編集者＝問題・教材の作成と共有／レビュアー＝承認・差し戻し／閲覧者＝公開された教材の閲覧。権限はサーバー側でも確認されます。'}</p></div>
    ${ws.personal ? '' : `<div class="card" id="t-members"><h2>メンバー</h2><div id="t-mlist" class="small muted">読み込み中…</div>
      ${canManage(role) ? `<h3>招待する</h3><div class="row"><input class="input grow" id="t-inv-email" type="email" placeholder="相手のメールアドレス" style="margin:0">
        <select class="input" id="t-inv-role" style="width:auto;margin:0">${['admin', 'editor', 'reviewer', 'viewer'].map(r => `<option value="${r}"${r === 'editor' ? ' selected' : ''}>${ROLE_LABEL[r]}</option>`).join('')}</select>
        <button class="btn" id="t-invite">招待リンクを作る</button></div><p class="small muted">メールは自動で送られません。できたリンクを相手に送ってください（14日間有効）。</p><div id="t-invlink"></div>` : ''}</div>`}
    <div class="card"><div class="row"><h2 style="margin:0">共有された教材</h2><span class="spacer"></span>
      ${canEdit(role) ? '<select class="input" id="t-share-sel" style="width:auto;max-width:260px;margin:0"></select><button class="btn primary" id="t-share">この教材を共有</button>' : ''}</div>
      <div id="t-mats" class="small muted mt">読み込み中…</div></div>
    <div class="card"><div class="row"><h2 style="margin:0">共有された問題</h2><span class="spacer"></span>
      ${canEdit(role) ? '<button class="btn" id="t-share-q">自作・編集した問題を共有</button>' : ''}<button class="btn" id="t-pull-q">共有された問題を取り込む</button></div>
      <p class="small muted" id="t-qinfo"></p></div>
    <div class="card"><h2>レビュー</h2><div id="t-reviews" class="small muted">読み込み中…</div></div>
    <div class="card"><h2>チームの活動</h2><div id="t-hist" class="small muted">読み込み中…</div></div>`;

  // ---------- メンバー ----------
  const loadMembers = async () => {
    if (ws.personal) return;
    try {
      const ms = await cloud.listMembers(ws.id);
      $('t-mlist').innerHTML = `<table class="list">${ms.map(mm => `<tr><td>${esc(mm.display_name || mm.user_id.slice(0, 8))}${mm.user_id === user.id ? '（あなた）' : ''}</td>
        <td>${canManage(role) && mm.role !== 'owner' && mm.user_id !== user.id ? `<select class="input" data-role="${esc(mm.user_id)}" style="width:auto;margin:0">${['admin', 'editor', 'reviewer', 'viewer'].map(r => `<option value="${r}"${r === mm.role ? ' selected' : ''}>${ROLE_LABEL[r]}</option>`).join('')}</select>` : esc(ROLE_LABEL[mm.role] || mm.role)}</td>
        <td>${(canManage(role) && mm.role !== 'owner' && mm.user_id !== user.id) ? `<button class="btn sm danger" data-rm="${esc(mm.user_id)}">はずす</button>` : mm.user_id === user.id && mm.role !== 'owner' ? `<button class="btn sm" data-rm="${esc(mm.user_id)}">抜ける</button>` : ''}</td></tr>`).join('')}</table>`;
    } catch (e) { $('t-mlist').textContent = '読み込めませんでした：' + e.message; }
  };
  loadMembers();
  if (!ws.personal) {
    main.querySelector('#t-members').addEventListener('change', async (e) => {
      const uidv = e.target.dataset.role;
      if (!uidv) return;
      try { await cloud.setMemberRole(ws.id, uidv, e.target.value); toast('権限を変えました', 'ok'); await log('権限を変更', ws.name, e.target.value); }
      catch (err) { toast('変えられませんでした：' + err.message, 'error'); loadMembers(); }
    });
    main.querySelector('#t-members').addEventListener('click', async (e) => {
      const rm = e.target.dataset.rm;
      if (rm) {
        if (!confirm(rm === user.id ? 'このチームから抜けますか？' : 'このメンバーをはずしますか？')) return;
        try { await cloud.removeMember(ws.id, rm); toast('はずしました'); if (rm === user.id) { selectedWs = null; render(root); return; } loadMembers(); }
        catch (err) { toast('できませんでした：' + err.message, 'error'); }
      }
      if (e.target.id === 't-invite') {
        const email = $('t-inv-email').value.trim();
        if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { toast('メールアドレスを正しく入れてください', 'error'); return; }
        try {
          const inv = await cloud.invite(ws.id, email, $('t-inv-role').value);
          $('t-invlink').innerHTML = `<div class="notice ok">招待リンク（${esc(email)} さん用）：<br><input class="input mono" readonly value="${esc(inv.link)}"><button class="btn sm mt" id="t-copy">コピー</button></div>`;
          $('t-invlink').querySelector('#t-copy').addEventListener('click', () => { navigator.clipboard.writeText(inv.link).then(() => toast('コピーしました')); });
          await log('メンバーを招待', ws.name, email);
        } catch (err) { toast('招待できませんでした：' + err.message, 'error'); }
      }
    });
  }

  // ---------- 教材の共有 ----------
  let shared = [];
  const loadMats = async () => {
    try { shared = await cloud.pullMaterials(ws.id); } catch (e) { $('t-mats').textContent = '読み込めませんでした：' + e.message; return; }
    $('t-mats').innerHTML = shared.length ? `<table class="list">${shared.map(sm => `<tr data-sid="${esc(sm.serverId)}"><td><b>${esc(sm.title)}</b><div class="muted">${esc(kindLabel(sm.kind))}・問題 ${(sm.blocks || []).filter(b => b.type === 'question').length} 問・更新 ${fmtDate(sm.updatedAt, true)}</div></td>
      <td><span class="chip ${sm.status === 'published' ? 'ok' : sm.status === 'review' ? 'warn' : sm.status === 'approved' ? 'accent' : ''}">${STATUS_LABEL[sm.status] || sm.status}</span></td>
      <td style="white-space:nowrap"><button class="btn sm" data-m="copy">自分の教材にコピー</button> <button class="btn sm" data-m="comments">コメント</button>
        ${canEdit(role) && ['draft', 'approved'].includes(sm.status) ? `<button class="btn sm" data-m="${sm.status === 'draft' ? 'review' : 'publish'}">${sm.status === 'draft' ? 'レビュー依頼' : '公開・配布'}</button>` : ''}</td></tr>`).join('')}</table>`
      : '<p class="empty">まだ共有された教材はありません。</p>';
  };
  loadMats();
  if (canEdit(role)) {
    $('t-share-sel').innerHTML = state.materials.filter(m => m.status !== 'archived').map(m => `<option value="${esc(m.id)}">${esc(m.title)}</option>`).join('') || '<option value="">（教材がありません）</option>';
    $('t-share').addEventListener('click', async () => {
      const m = state.materials.find(x => x.id === $('t-share-sel').value);
      if (!m) return;
      // 元の個人教材とは分けるため、共有用のコピーを作って送る
      const copy = { ...clone(m), id: uid('M-'), sharedFrom: m.id, status: 'draft', rev: 1, createdAt: nowISO() };
      try { await cloud.pushMaterial(ws.id, copy); toast('共有しました（元の教材はあなたの端末に残ります）', 'ok'); await log('教材を共有', ws.name, m.title); loadMats(); }
      catch (e) { toast('共有できませんでした：' + e.message, 'error'); }
    });
  }
  $('t-mats').addEventListener('click', async (e) => {
    const act = e.target.dataset.m;
    if (!act) return;
    const sm = shared.find(x => x.serverId === e.target.closest('tr').dataset.sid);
    if (act === 'copy') {
      const c = { ...clone(sm), id: uid('M-'), title: sm.title, status: 'draft', rev: 1, createdAt: nowISO(), blocks: sm.blocks.map(b => ({ ...b, id: blockId() })) };
      delete c.serverId;
      await saveMaterial(c);
      await setCurrentMaterial(c.id);
      toast('自分の教材にコピーしました', 'ok');
      location.hash = '#/editor/' + c.id;
    }
    if (act === 'review') {
      try { await cloud.requestReview(ws.id, 'material', sm.serverId); toast('レビューを依頼しました', 'ok'); loadMats(); loadReviews(); }
      catch (err) { toast('依頼できませんでした：' + err.message, 'error'); }
    }
    if (act === 'publish') {
      if (!confirm('この教材を「公開・配布」にします。チームの閲覧者も見られるようになります。よろしいですか？')) return;
      try { await cloud.setMaterialStatus(sm.serverId, 'published'); toast('公開しました', 'ok'); await log('教材を公開', ws.name, sm.title); loadMats(); }
      catch (err) { toast('公開できませんでした：' + err.message, 'error'); }
    }
    if (act === 'comments') commentsDialog('material', sm.serverId, sm.title);
  });

  const commentsDialog = async (type, targetId, title) => {
    const md = modal({ title: 'コメント：' + title, narrow: true, body: '<div id="c-list" class="small muted">読み込み中…</div><textarea class="input mt" id="c-body" rows="3" placeholder="コメント・修正の提案"></textarea>', foot: '<button class="btn" data-close>閉じる</button><button class="btn primary" id="c-send">送る</button>' });
    const list = /** @type {HTMLElement} */ (md.el.querySelector('#c-list'));
    const load = async () => {
      try {
        const cs = await cloud.listComments(ws.id, type, targetId);
        list.innerHTML = cs.length ? cs.map(c => `<div class="notice"><div class="muted">${fmtDate(c.created_at, true)}</div>${esc(c.body)}</div>`).join('') : '<p>まだコメントはありません。</p>';
      } catch (e) { list.textContent = '読み込めませんでした：' + e.message; }
    };
    load();
    md.el.querySelector('#c-send').addEventListener('click', async () => {
      const body = /** @type {any} */ (md.el.querySelector('#c-body')).value.trim();
      if (!body) return;
      try { await cloud.addComment(ws.id, type, targetId, body); /** @type {any} */ (md.el.querySelector('#c-body')).value = ''; load(); }
      catch (e) { toast('送れませんでした：' + e.message, 'error'); }
    });
  };

  // ---------- 問題の共有 ----------
  if (canEdit(role)) $('t-share-q').addEventListener('click', async () => {
    const mine = [...state.user.values()].filter(q => !q.deleted && (q.origin === 'user' || (q.origin === 'ai' && q.status === 'approved') || state.base.has(q.id)));
    if (!mine.length) { toast('共有できる問題（自作・編集・承認済み AI 問題）がありません'); return; }
    if (!confirm(`${mine.length} 問をこのワークスペースに共有します。よろしいですか？`)) return;
    let n = 0;
    for (const q of mine) { try { await cloud.pushQuestion(ws.id, q); n++; } catch (e) { toast('一部共有できませんでした：' + e.message, 'error'); break; } }
    $('t-qinfo').textContent = `${n} 問を共有しました。`;
    await log('問題を共有', ws.name, `${n}問`);
  });
  $('t-pull-q').addEventListener('click', async () => {
    try {
      const qs = await cloud.pullQuestions(ws.id);
      if (!qs.length) { $('t-qinfo').textContent = '共有された問題はありません。'; return; }
      const list = qs.map(q => { const c = { ...q }; delete c.serverId; c.src = c.src || ('チーム：' + (ws.name || '個人')); return c; });
      await saveQuestions(list, `チーム「${ws.name || '個人'}」から取り込み`);
      $('t-qinfo').textContent = `${list.length} 問を問題バンクに取り込みました（同じ問題は旧版を残して更新）。`;
    } catch (e) { toast('取り込めませんでした：' + e.message, 'error'); }
  });

  // ---------- レビュー ----------
  const loadReviews = async () => {
    try {
      const rs = await cloud.listReviews(ws.id);
      const title = (r) => { const sm = shared.find(x => x.serverId === r.target_id); return sm ? sm.title : (r.target_type === 'material' ? '教材' : '問題') + ' ' + String(r.target_id).slice(0, 8); };
      $('t-reviews').innerHTML = rs.length ? `<table class="list">${rs.map(r => `<tr data-rid="${esc(r.id)}"><td>${esc(title(r))}<div class="muted">${fmtDate(r.created_at, true)}${r.comment ? '・' + esc(r.comment) : ''}</div></td>
        <td><span class="chip ${r.state === 'approved' ? 'ok' : r.state === 'rejected' ? 'danger' : 'warn'}">${REVIEW_LABEL[r.state] || r.state}</span></td>
        <td>${canReview(role) && r.state === 'pending' ? '<button class="btn sm primary" data-r="approved">承認</button> <button class="btn sm danger" data-r="rejected">差し戻し</button>' : ''}</td></tr>`).join('')}</table>` : '<p class="empty">レビューの依頼はありません。</p>';
    } catch (e) { $('t-reviews').textContent = '読み込めませんでした：' + e.message; }
  };
  loadReviews();
  $('t-reviews').addEventListener('click', async (e) => {
    const st = e.target.dataset.r;
    if (!st) return;
    const comment = prompt(st === 'approved' ? '承認のコメント（任意）' : '差し戻しの理由', '') ?? null;
    if (comment === null) return;
    try { await cloud.setReviewState(e.target.closest('tr').dataset.rid, st, comment); toast(st === 'approved' ? '承認しました' : '差し戻しました', 'ok'); loadReviews(); loadMats(); }
    catch (err) { toast('できませんでした：' + err.message, 'error'); }
  });

  // ---------- 履歴 ----------
  try {
    const hs = await cloud.listHistory(ws.id);
    $('t-hist').innerHTML = hs.length ? `<table class="list">${hs.slice(0, 50).map(h => `<tr><td style="white-space:nowrap">${fmtDate(h.created_at || h.at, true)}</td><td>${esc(h.action)}</td><td>${esc(h.target || '')}</td></tr>`).join('')}</table>` : '<p class="empty">まだ活動の記録はありません。</p>';
  } catch (e) { $('t-hist').textContent = '読み込めませんでした：' + e.message; }
}
