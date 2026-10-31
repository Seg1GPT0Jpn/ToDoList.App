// Supabase クライアント（ブラウザ用 ES モジュール）。
// 未設定のときは supabase-js を読み込まず、すべての関数が code: 'not_configured' の誤りを返す／投げる。
// 権限はサーバー側（RLS）で強制される。ここでの確認は表示用の補助にすぎない。

/** supabase-js の配布 URL（設定済みのときだけ動的に読み込む） */
const SUPABASE_ESM = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/+esm';
/** 接続設定の保存キー */
const STORAGE_KEY = 'mondai.cloud';

/** @typedef {'owner'|'admin'|'editor'|'reviewer'|'viewer'} Role */
/** @typedef {'question'|'material'} ReviewTarget */
/** @typedef {'pending'|'approved'|'rejected'} ReviewState */
/** @typedef {{url: string, anonKey: string}} CloudConfig */
/** @typedef {{code: string, message: string, [k: string]: any}} CloudErrorInfo */
/** @typedef {{ok: true, data: any, job?: any} | {ok: false, error: CloudErrorInfo}} AIResult */
/** @typedef {{id: string, name: string, owner_id: string, personal: boolean, role: Role|null, created_at: string, updated_at: string}} Workspace */
/** @typedef {{workspace_id: string, user_id: string, role: Role, created_at: string, display_name: string}} Member */

const ROLES = ['owner', 'admin', 'editor', 'reviewer', 'viewer'];
const QUESTION_STATUSES = ['unverified', 'verifying', 'verified', 'approved', 'needs_fix'];
const MATERIAL_STATUSES = ['draft', 'review', 'approved', 'published', 'archived'];

/** クラウド機能の誤り。code で種類を判別できる */
export class CloudError extends Error {
  /**
   * @param {string} code  not_configured / unauthorized / forbidden / bad_request / network / db_error など
   * @param {string} message
   * @param {any} [cause]
   */
  constructor(code, message, cause) {
    super(message);
    this.name = 'CloudError';
    this.code = code;
    this.cause = cause;
  }
}

/** @type {CloudConfig|null} */
let config = loadConfig();
/** @type {Promise<any>|null} */
let clientPromise = null;

/** @returns {CloudConfig|null} */
function loadConfig() {
  try {
    const raw = globalThis.localStorage?.getItem(STORAGE_KEY);
    if (!raw) return null;
    const c = JSON.parse(raw);
    return c && typeof c.url === 'string' && typeof c.anonKey === 'string' && c.url && c.anonKey ? c : null;
  } catch {
    return null;
  }
}

function notConfigured() {
  return new CloudError('not_configured', 'クラウド（Supabase）が未設定です。設定画面で Project URL と anon key を入力してください。');
}

/** Supabase の誤りを CloudError に変換して投げる */
function raise(error, fallback = 'db_error') {
  if (!error) return;
  if (error instanceof CloudError) throw error;
  const msg = String(error.message || error);
  let code = fallback;
  if (error.code === '42501' || /row-level security|permission denied|forbidden/i.test(msg)) code = 'forbidden';
  else if (error.code === 'PGRST301' || /JWT|not_authenticated/i.test(msg)) code = 'unauthorized';
  throw new CloudError(code, msg, error);
}

/** @param {string} v @param {string[]} allowed @param {string} name */
function check(v, allowed, name) {
  if (!allowed.includes(v)) throw new CloudError('bad_request', `${name} が不正です: ${v}`);
}

// ---- 設定・接続 ---------------------------------------------------------

/** クラウドの接続設定があるか @returns {boolean} */
export function isConfigured() {
  return !!config;
}

/**
 * 接続設定を保存する（localStorage 'mondai.cloud'）。null を渡すと解除。
 * anon key は公開しても安全（権限は RLS で守られる）。service role key は絶対に入れないこと。
 * @param {CloudConfig|null} c
 */
export function configure(c) {
  if (c == null) {
    config = null;
    clientPromise = null;
    try { globalThis.localStorage?.removeItem(STORAGE_KEY); } catch { /* 保存できなくても続行 */ }
    return;
  }
  const url = String(c.url || '').trim().replace(/\/+$/, '');
  const anonKey = String(c.anonKey || '').trim();
  if (!/^https:\/\/[^/\s]+$/.test(url)) throw new CloudError('bad_request', 'Project URL は https://xxxx.supabase.co の形式で入力してください');
  if (!anonKey) throw new CloudError('bad_request', 'anon key を入力してください');
  if (looksLikeServiceRole(anonKey)) {
    throw new CloudError('bad_request', 'これは service role key です。ブラウザには anon（public）key を入力してください');
  }
  config = { url, anonKey };
  clientPromise = null;
  try { globalThis.localStorage?.setItem(STORAGE_KEY, JSON.stringify(config)); } catch { /* 保存できなくても続行 */ }
}

/** JWT の role クレームが service_role なら true @param {string} key */
function looksLikeServiceRole(key) {
  if (key.startsWith('sb_secret_')) return true;
  try {
    const part = key.split('.')[1];
    if (!part) return false;
    const payload = JSON.parse(atob(part.replace(/-/g, '+').replace(/_/g, '/')));
    return payload && payload.role === 'service_role';
  } catch {
    return false;
  }
}

/**
 * supabase-js クライアントを返す（初回に CDN から読み込む）。
 * @returns {Promise<any>}
 */
export async function getClient() {
  if (!config) throw notConfigured();
  if (!clientPromise) {
    const { url, anonKey } = config;
    clientPromise = (async () => {
      /** @type {string} */
      const src = SUPABASE_ESM;
      let mod;
      try {
        mod = await import(/* @vite-ignore */ src);
      } catch (e) {
        throw new CloudError('network', 'Supabase のライブラリを読み込めません（ネットワークを確認してください）', e);
      }
      return mod.createClient(url, anonKey, {
        auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, storageKey: 'mondai.cloud.auth' },
      });
    })();
    clientPromise.catch(() => { clientPromise = null; });
  }
  return clientPromise;
}

// ---- 認証 ---------------------------------------------------------------

/**
 * メールのログインリンク（マジックリンク）を送る。リンクを開くと現在のページに戻る。
 * @param {string} email
 * @returns {Promise<void>}
 */
export async function signIn(email) {
  const sb = await getClient();
  const addr = String(email || '').trim();
  if (!/^[^@\s]+@[^@\s]+$/.test(addr)) throw new CloudError('bad_request', 'メールアドレスが正しくありません');
  const redirect = globalThis.location ? globalThis.location.href.split('#')[0] : undefined;
  const { error } = await sb.auth.signInWithOtp({ email: addr, options: { emailRedirectTo: redirect } });
  raise(error, 'auth_error');
}

/** ログアウト @returns {Promise<void>} */
export async function signOut() {
  const sb = await getClient();
  const { error } = await sb.auth.signOut();
  raise(error, 'auth_error');
}

/**
 * ログイン中のユーザー（未ログインなら null）
 * @returns {Promise<{id: string, email: string}|null>}
 */
export async function currentUser() {
  const sb = await getClient();
  const { data } = await sb.auth.getSession();
  const u = data?.session?.user;
  return u ? { id: u.id, email: u.email } : null;
}

/** @returns {Promise<string>} ログイン中のユーザー ID（未ログインなら unauthorized） */
async function requireUserId() {
  const u = await currentUser();
  if (!u) throw new CloudError('unauthorized', 'ログインしてください');
  return u.id;
}

/**
 * ログイン状態の変化を通知する。
 * @param {(user: {id: string, email: string}|null, event: string) => void} cb
 * @returns {Promise<() => void>} 購読解除関数
 */
export async function onAuthChange(cb) {
  const sb = await getClient();
  const { data } = sb.auth.onAuthStateChange((event, session) => {
    const u = session?.user;
    cb(u ? { id: u.id, email: u.email } : null, event);
  });
  return () => data?.subscription?.unsubscribe();
}

/**
 * 自分のプロフィール（表示名）を更新する
 * @param {{display_name: string}} p
 * @returns {Promise<{id: string, display_name: string}>}
 */
export async function updateProfile(p) {
  const name = String(p?.display_name ?? '').trim();
  if (!name || name.length > 100) throw new CloudError('bad_request', '表示名は 1〜100 文字で入力してください');
  const sb = await getClient();
  const uid = await requireUserId();
  const { data, error } = await sb.from('profiles').update({ display_name: name }).eq('id', uid).select('id, display_name');
  raise(error);
  if (data && data.length) return data[0];
  // プロフィール行が無い場合（トリガー導入前の利用者など）は作成する
  const ins = await sb.from('profiles').insert({ id: uid, display_name: name }).select('id, display_name').single();
  raise(ins.error);
  return ins.data;
}

// ---- ワークスペース・メンバー -------------------------------------------

/**
 * 自分が所属するワークスペース（自分の役割つき）
 * @returns {Promise<Workspace[]>}
 */
export async function listWorkspaces() {
  const sb = await getClient();
  const uid = await requireUserId();
  const { data, error } = await sb
    .from('workspaces')
    .select('*, workspace_members!inner(role, user_id)')
    .eq('workspace_members.user_id', uid)
    .order('personal', { ascending: false })
    .order('created_at');
  raise(error);
  return (data || []).map((w) => {
    const { workspace_members: m, ...rest } = w;
    return { ...rest, role: m?.[0]?.role ?? null };
  });
}

/**
 * チームのワークスペースを作る（作成者が owner）
 * @param {string} name
 * @returns {Promise<string>} 新しいワークスペース ID
 */
export async function createWorkspace(name) {
  const sb = await getClient();
  const { data, error } = await sb.rpc('create_workspace', { name: String(name || '').trim() });
  raise(error);
  return data;
}

/**
 * メンバー一覧（表示名つき）
 * @param {string} wsId
 * @returns {Promise<Member[]>}
 */
export async function listMembers(wsId) {
  const sb = await getClient();
  const { data, error } = await sb.from('workspace_members').select('*').eq('workspace_id', wsId).order('created_at');
  raise(error);
  const ids = (data || []).map((m) => m.user_id);
  /** @type {Record<string,string>} */
  const names = {};
  if (ids.length) {
    const { data: profs, error: e2 } = await sb.from('profiles').select('id, display_name').in('id', ids);
    raise(e2);
    for (const p of profs || []) names[p.id] = p.display_name;
  }
  return (data || []).map((m) => ({ ...m, display_name: names[m.user_id] ?? '' }));
}

/**
 * 招待を作る（owner/admin のみ）。メールは送信されないので、返したリンクを相手に伝える。
 * @param {string} wsId
 * @param {string} email
 * @param {Exclude<Role,'owner'>} role
 * @returns {Promise<{id: string, token: string, link: string, expires_at: string}>}
 */
export async function invite(wsId, email, role) {
  check(role, ROLES.slice(1), 'role');
  const sb = await getClient();
  const { data, error } = await sb
    .from('invitations')
    .insert({ workspace_id: wsId, email: String(email || '').trim(), role })
    .select('id, token, expires_at')
    .single();
  raise(error);
  const base = globalThis.location ? globalThis.location.href.split('#')[0] : '';
  return { ...data, link: `${base}#invite=${data.token}` };
}

/**
 * 招待を受ける（ログイン中のメールアドレスが招待先と一致する必要がある）
 * @param {string} token
 * @returns {Promise<string>} 参加したワークスペース ID
 */
export async function acceptInvitation(token) {
  const sb = await getClient();
  const { data, error } = await sb.rpc('accept_invitation', { token });
  if (error) {
    const m = String(error.message || '');
    if (m.includes('invitation_email_mismatch')) throw new CloudError('forbidden', '招待されたメールアドレスでログインしてください', error);
    if (m.includes('invitation_not_found')) throw new CloudError('not_found', '招待が見つかりません', error);
    if (m.includes('invitation_expired')) throw new CloudError('expired', '招待の有効期限が切れています', error);
    if (m.includes('invitation_already_used')) throw new CloudError('already_used', 'この招待はすでに使われています', error);
    raise(error);
  }
  return data;
}

/**
 * メンバーの役割を変える（owner/admin のみ。owner 権限の付与は owner のみ）
 * @param {string} wsId @param {string} userId @param {Role} role
 * @returns {Promise<void>}
 */
export async function setMemberRole(wsId, userId, role) {
  check(role, ROLES, 'role');
  const sb = await getClient();
  const { data, error } = await sb
    .from('workspace_members')
    .update({ role })
    .eq('workspace_id', wsId)
    .eq('user_id', userId)
    .select('user_id');
  raise(error);
  if (!data || data.length === 0) throw new CloudError('forbidden', 'この役割を変更する権限がありません');
}

/**
 * メンバーを外す（owner/admin。本人は自分で脱退できる）
 * @param {string} wsId @param {string} userId
 * @returns {Promise<void>}
 */
export async function removeMember(wsId, userId) {
  const sb = await getClient();
  const { data, error } = await sb
    .from('workspace_members')
    .delete()
    .eq('workspace_id', wsId)
    .eq('user_id', userId)
    .select('user_id');
  raise(error);
  if (!data || data.length === 0) throw new CloudError('forbidden', 'このメンバーを外す権限がありません');
}

// ---- 問題・教材 ---------------------------------------------------------

/**
 * 問題を保存（同じ ID があれば更新。更新のたびにサーバーで旧版が保存され rev が上がる）
 * @param {string} wsId
 * @param {{id: string, status?: string, [k: string]: any}} q 共通問題形式
 * @returns {Promise<{id: string, local_id: string, rev: number, status: string, updated_at: string}>}
 */
export async function pushQuestion(wsId, q) {
  if (!q || !q.id) throw new CloudError('bad_request', '問題に id がありません');
  const sb = await getClient();
  const status = QUESTION_STATUSES.includes(q.status) ? q.status : 'unverified';
  const { data, error } = await sb
    .from('questions')
    .upsert({ workspace_id: wsId, local_id: String(q.id), data: q, status }, { onConflict: 'workspace_id,local_id' })
    .select('id, local_id, rev, status, updated_at')
    .single();
  raise(error);
  return data;
}

/**
 * ワークスペースの問題を取得（data に rev・serverId を補って返す）
 * @param {string} wsId
 * @returns {Promise<any[]>}
 */
export async function pullQuestions(wsId) {
  const sb = await getClient();
  const { data, error } = await sb.from('questions').select('*').eq('workspace_id', wsId).order('updated_at', { ascending: false });
  raise(error);
  return (data || []).map((r) => ({ ...r.data, id: r.local_id, rev: r.rev, status: r.status, updatedAt: r.updated_at, serverId: r.id }));
}

/**
 * 教材を保存（同じ ID があれば更新）
 * @param {string} wsId
 * @param {{id: string, status?: string, [k: string]: any}} m 教材
 * @returns {Promise<{id: string, local_id: string, rev: number, status: string, updated_at: string}>}
 */
export async function pushMaterial(wsId, m) {
  if (!m || !m.id) throw new CloudError('bad_request', '教材に id がありません');
  const sb = await getClient();
  // approved / published はサーバー側のレビュー・公開手続きでのみ変わるので送らない（サーバーの状態を優先）
  /** @type {Record<string, any>} */
  const row = { workspace_id: wsId, local_id: String(m.id), data: m };
  if (['draft', 'review', 'archived'].includes(m.status)) row.status = m.status;
  const { data, error } = await sb
    .from('materials')
    .upsert(row, { onConflict: 'workspace_id,local_id' })
    .select('id, local_id, rev, status, updated_at')
    .single();
  raise(error);
  return data;
}

/**
 * ワークスペースの教材を取得（viewer には published のみ返る）
 * @param {string} wsId
 * @returns {Promise<any[]>}
 */
export async function pullMaterials(wsId) {
  const sb = await getClient();
  const { data, error } = await sb.from('materials').select('*').eq('workspace_id', wsId).order('updated_at', { ascending: false });
  raise(error);
  return (data || []).map((r) => ({
    ...r.data,
    id: r.local_id ?? r.id,
    rev: r.rev,
    status: r.status,
    updatedAt: r.updated_at,
    serverId: r.id,
    sharedFrom: r.shared_from,
  }));
}

/**
 * 教材をチームのワークスペースへコピーして共有（元の教材は非公開のまま）
 * @param {string} materialId サーバー側の教材 ID（serverId）
 * @param {string} targetWs
 * @returns {Promise<string>} コピーの ID
 */
export async function shareMaterial(materialId, targetWs) {
  const sb = await getClient();
  const { data, error } = await sb.rpc('share_material_to_workspace', { material_id: materialId, target_ws: targetWs });
  raise(error);
  return data;
}

/**
 * 教材の状態を変える。published にできるのは owner/admin/editor で、approved の教材だけ（サーバーで強制）。
 * @param {string} materialId サーバー側の教材 ID（serverId）
 * @param {'draft'|'review'|'approved'|'published'|'archived'} status
 * @returns {Promise<any>}
 */
export async function setMaterialStatus(materialId, status) {
  check(status, MATERIAL_STATUSES, 'status');
  const sb = await getClient();
  const { data, error } = await sb.from('materials').update({ status }).eq('id', materialId).select('id, status, rev, updated_at');
  raise(error);
  if (!data || data.length === 0) throw new CloudError('forbidden', 'この教材の状態を変更する権限がありません');
  return data[0];
}

// ---- レビュー・コメント・履歴 -------------------------------------------

/**
 * レビューを依頼（editor 以上）
 * @param {string} wsId @param {ReviewTarget} targetType @param {string} targetId サーバー側 ID
 * @returns {Promise<any>}
 */
export async function requestReview(wsId, targetType, targetId) {
  check(targetType, ['question', 'material'], 'targetType');
  const sb = await getClient();
  const { data, error } = await sb
    .from('reviews')
    .insert({ workspace_id: wsId, target_type: targetType, target_id: targetId })
    .select('*')
    .single();
  raise(error);
  return data;
}

/**
 * レビューの承認・差し戻し（reviewer / admin / owner のみ）
 * @param {string} reviewId @param {ReviewState} state @param {string} [comment]
 * @returns {Promise<any>}
 */
export async function setReviewState(reviewId, state, comment) {
  check(state, ['pending', 'approved', 'rejected'], 'state');
  const sb = await getClient();
  /** @type {Record<string, any>} */
  const patch = { state };
  if (comment != null) patch.comment = String(comment);
  const { data, error } = await sb.from('reviews').update(patch).eq('id', reviewId).select('*');
  raise(error);
  if (!data || data.length === 0) throw new CloudError('forbidden', '承認・差し戻しはレビュー担当者以上の権限が必要です');
  return data[0];
}

/**
 * レビュー一覧（新しい順）
 * @param {string} wsId
 * @returns {Promise<any[]>}
 */
export async function listReviews(wsId) {
  const sb = await getClient();
  const { data, error } = await sb.from('reviews').select('*').eq('workspace_id', wsId).order('created_at', { ascending: false });
  raise(error);
  return data || [];
}

/**
 * コメントを書く（メンバー）
 * @param {string} wsId @param {'question'|'material'|'review'} targetType @param {string} targetId @param {string} body
 * @returns {Promise<any>}
 */
export async function addComment(wsId, targetType, targetId, body) {
  check(targetType, ['question', 'material', 'review'], 'targetType');
  const sb = await getClient();
  const { data, error } = await sb
    .from('comments')
    .insert({ workspace_id: wsId, target_type: targetType, target_id: targetId, body: String(body || '') })
    .select('*')
    .single();
  raise(error);
  return data;
}

/**
 * 対象へのコメント一覧（古い順）
 * @param {string} wsId @param {'question'|'material'|'review'} targetType @param {string} targetId
 * @returns {Promise<any[]>}
 */
export async function listComments(wsId, targetType, targetId) {
  const sb = await getClient();
  const { data, error } = await sb
    .from('comments')
    .select('*')
    .eq('workspace_id', wsId)
    .eq('target_type', targetType)
    .eq('target_id', targetId)
    .order('created_at');
  raise(error);
  return data || [];
}

/**
 * 操作履歴（新しい順、最大 200 件）
 * @param {string} wsId
 * @returns {Promise<any[]>}
 */
export async function listHistory(wsId) {
  const sb = await getClient();
  const { data, error } = await sb.from('history').select('*').eq('workspace_id', wsId).order('at', { ascending: false }).limit(200);
  raise(error);
  return data || [];
}

// ---- AI -----------------------------------------------------------------

/**
 * Edge Function `ai` を呼ぶ。例外は投げず、結果オブジェクトで返す。
 * @param {'parse_request'|'generate'|'solve'|'explain'|'review'|'plan_material'|'suggest_review'} action
 * @param {Record<string, any>} payload
 * @param {string} [wsId] 省略時は個人ワークスペース
 * @returns {Promise<AIResult>}
 */
export async function callAI(action, payload, wsId) {
  if (!config) {
    const e = notConfigured();
    return { ok: false, error: { code: e.code, message: e.message } };
  }
  try {
    const sb = await getClient();
    const { data } = await sb.auth.getSession();
    const token = data?.session?.access_token;
    if (!token) return { ok: false, error: { code: 'unauthorized', message: 'AI を使うにはログインしてください' } };
    const res = await fetch(`${config.url}/functions/v1/ai`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        apikey: config.anonKey,
      },
      body: JSON.stringify({ action, payload: payload || {}, workspace_id: wsId || null }),
    });
    let body = null;
    try { body = await res.json(); } catch { /* 下で処理 */ }
    if (body && typeof body.ok === 'boolean') return body;
    if (res.status === 404) {
      return { ok: false, error: { code: 'not_configured', message: 'AI のサーバー関数（ai）がデプロイされていません' } };
    }
    return { ok: false, error: { code: 'provider_error', message: `AI サーバーの応答が不正です（HTTP ${res.status}）` } };
  } catch (e) {
    if (e instanceof CloudError) return { ok: false, error: { code: e.code, message: e.message } };
    return { ok: false, error: { code: 'network', message: `AI サーバーに接続できません: ${e?.message || e}` } };
  }
}
