// RLS（行単位セキュリティ）の検証。PGlite（WASM 版 Postgres）に本番と同じマイグレーションを流して確認する。
import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const MIGRATION = readFileSync(
  fileURLToPath(new URL('../../supabase/migrations/0001_init.sql', import.meta.url)), 'utf8');

// Supabase が用意している auth スキーマ・ロールの最小スタブ
const AUTH_STUB = `
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users (
  id uuid primary key,
  email text unique,
  raw_user_meta_data jsonb default '{}'::jsonb
);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create function auth.jwt() returns jsonb language sql stable as $$
  select jsonb_build_object('sub', current_setting('request.jwt.claim.sub', true))
$$;
grant usage on schema auth to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;
`;

const U = {
  alice: '00000000-0000-0000-0000-00000000000a', // team owner
  bob: '00000000-0000-0000-0000-00000000000b',   // admin
  ed: '00000000-0000-0000-0000-00000000000e',    // editor
  rita: '00000000-0000-0000-0000-00000000000f',  // reviewer
  vic: '00000000-0000-0000-0000-000000000001',   // viewer
  mal: '00000000-0000-0000-0000-000000000002',   // outsider
  nina: '00000000-0000-0000-0000-000000000003',  // invited later
};

/** @type {PGlite} */
let db;
let teamWs;
/** @type {Record<string,string>} */
const personal = {};

/** Run fn inside a transaction as the given user (role authenticated). Commits on success. */
async function as(uid, fn) {
  await db.exec(`begin; set local role authenticated; set local request.jwt.claim.sub = '${uid}';`);
  try {
    const r = await fn((sql, params) => db.query(sql, params));
    await db.exec('commit');
    return r;
  } catch (e) {
    await db.exec('rollback');
    throw e;
  }
}
/** Single query as a user. */
const q = (uid, sql, params) => as(uid, (run) => run(sql, params));
/** Rows visible to a user. */
const rows = async (uid, sql, params) => (await q(uid, sql, params)).rows;

beforeAll(async () => {
  db = new PGlite();
  await db.exec(AUTH_STUB);
  await db.exec(MIGRATION);
  for (const [name, id] of Object.entries(U)) {
    await db.query('insert into auth.users(id, email) values ($1, $2)', [id, `${name}@example.com`]);
  }
  for (const [name, id] of Object.entries(U)) {
    const r = await db.query('select id from public.workspaces where owner_id = $1 and personal', [id]);
    personal[name] = /** @type {any} */ (r.rows[0]).id;
  }
  teamWs = (await rows(U.alice, `select public.create_workspace('チームA') as id`))[0].id;
  // owner がメンバーを追加
  await as(U.alice, async (run) => {
    await run(`insert into public.workspace_members(workspace_id, user_id, role) values
      ($1, $2, 'admin'), ($1, $3, 'editor'), ($1, $4, 'reviewer'), ($1, $5, 'viewer')`,
    [teamWs, U.bob, U.ed, U.rita, U.vic]);
  });
}, 60000);

describe('signup trigger', () => {
  it('creates a profile and a personal workspace with the user as sole owner', async () => {
    const p = await rows(U.alice, 'select * from public.profiles where id = $1', [U.alice]);
    expect(p[0].display_name).toBe('alice');
    const m = await rows(U.alice, 'select * from public.workspace_members where workspace_id = $1', [personal.alice]);
    expect(m).toHaveLength(1);
    expect(m[0]).toMatchObject({ user_id: U.alice, role: 'owner' });
  });
});

describe('personal workspace isolation', () => {
  beforeAll(async () => {
    await q(U.alice, `insert into public.questions(workspace_id, local_id, data) values ($1, 'U-1', '{"stem":"秘密"}')`, [personal.alice]);
    await q(U.alice, `insert into public.materials(workspace_id, local_id, data, status) values ($1, 'M-1', '{"title":"個人教材"}', 'draft')`, [personal.alice]);
  });
  it('other users cannot see the workspace, its questions or materials', async () => {
    expect(await rows(U.mal, 'select * from public.workspaces where id = $1', [personal.alice])).toHaveLength(0);
    expect(await rows(U.mal, 'select * from public.questions where workspace_id = $1', [personal.alice])).toHaveLength(0);
    expect(await rows(U.mal, 'select * from public.materials where workspace_id = $1', [personal.alice])).toHaveLength(0);
    // チームメンバーでも他人の個人WSは見えない
    expect(await rows(U.bob, 'select * from public.questions where workspace_id = $1', [personal.alice])).toHaveLength(0);
  });
  it('the owner sees their own data', async () => {
    expect(await rows(U.alice, 'select * from public.questions where workspace_id = $1', [personal.alice])).toHaveLength(1);
  });
  it('outsiders cannot write into someone else\'s personal workspace', async () => {
    await expect(q(U.mal, `insert into public.questions(workspace_id, local_id, data) values ($1, 'X', '{}')`, [personal.alice])).rejects.toThrow(/row-level security/);
  });
  it('members cannot be added to a personal workspace', async () => {
    await expect(q(U.alice, `insert into public.workspace_members(workspace_id, user_id, role) values ($1, $2, 'viewer')`, [personal.alice, U.mal])).rejects.toThrow(/row-level security/);
  });
  it('profiles: visible to co-members only; only self can update', async () => {
    expect(await rows(U.vic, 'select id from public.profiles where id = $1', [U.alice])).toHaveLength(1);
    expect(await rows(U.mal, 'select id from public.profiles where id = $1', [U.alice])).toHaveLength(0);
    const r = await q(U.bob, `update public.profiles set display_name = 'x' where id = $1`, [U.alice]);
    expect(r.affectedRows).toBe(0);
    const r2 = await q(U.alice, `update public.profiles set display_name = 'アリス' where id = $1`, [U.alice]);
    expect(r2.affectedRows).toBe(1);
  });
});

describe('questions', () => {
  it('viewer cannot insert or update', async () => {
    await expect(q(U.vic, `insert into public.questions(workspace_id, local_id, data) values ($1, 'V-1', '{}')`, [teamWs])).rejects.toThrow(/row-level security/);
    await q(U.ed, `insert into public.questions(workspace_id, local_id, data) values ($1, 'Q-viewer', '{"stem":"a"}')`, [teamWs]);
    const r = await q(U.vic, `update public.questions set data = '{"stem":"hack"}' where local_id = 'Q-viewer'`);
    expect(r.affectedRows).toBe(0);
    expect(await rows(U.vic, `select * from public.questions where local_id = 'Q-viewer'`)).toHaveLength(1);
  });
  it('reviewer cannot insert questions', async () => {
    await expect(q(U.rita, `insert into public.questions(workspace_id, local_id, data) values ($1, 'R-1', '{}')`, [teamWs])).rejects.toThrow(/row-level security/);
  });
  it('editor can insert and update', async () => {
    await q(U.ed, `insert into public.questions(workspace_id, local_id, data) values ($1, 'Q-ed', '{"stem":"1+1"}')`, [teamWs]);
    const r = await q(U.ed, `update public.questions set data = '{"stem":"1+2"}' where local_id = 'Q-ed'`);
    expect(r.affectedRows).toBe(1);
  });
  it('update stores the previous version and bumps rev', async () => {
    await q(U.ed, `insert into public.questions(workspace_id, local_id, data) values ($1, 'Q-ver', '{"stem":"v1"}')`, [teamWs]);
    await q(U.ed, `update public.questions set data = '{"stem":"v2"}' where local_id = 'Q-ver'`);
    await q(U.ed, `update public.questions set data = '{"stem":"v3"}' where local_id = 'Q-ver'`);
    const [cur] = await rows(U.vic, `select id, rev, data from public.questions where local_id = 'Q-ver'`);
    expect(cur.rev).toBe(3);
    expect(cur.data.stem).toBe('v3');
    const vers = await rows(U.vic, 'select rev, data from public.question_versions where question_id = $1 order by rev', [cur.id]);
    expect(vers.map((v) => [v.rev, v.data.stem])).toEqual([[1, 'v1'], [2, 'v2']]);
    // 状態だけの更新では版を作らない
    await q(U.ed, `update public.questions set status = 'verified' where local_id = 'Q-ver'`);
    expect((await rows(U.vic, `select rev from public.questions where local_id = 'Q-ver'`))[0].rev).toBe(3);
  });
  it('clients cannot write question_versions directly', async () => {
    const [cur] = await rows(U.ed, `select id from public.questions where local_id = 'Q-ver'`);
    await expect(q(U.ed, `insert into public.question_versions(question_id, workspace_id, rev, data) values ($1, $2, 99, '{}')`, [cur.id, teamWs])).rejects.toThrow(/permission denied/);
  });
});

describe('materials', () => {
  beforeAll(async () => {
    await q(U.ed, `insert into public.materials(workspace_id, local_id, data, status) values
      ($1, 'draft-1', '{"title":"下書き"}', 'draft'), ($1, 'pub-1', '{"title":"公開"}', 'draft')`, [teamWs]);
    // 公開は承認済みからのみ：owner が承認 → editor が公開
    await q(U.alice, `update public.materials set status = 'approved' where local_id = 'pub-1'`);
    await q(U.ed, `update public.materials set status = 'published' where local_id = 'pub-1'`);
  });
  it('viewer sees only published materials', async () => {
    const r = await rows(U.vic, `select local_id from public.materials where workspace_id = $1 order by local_id`, [teamWs]);
    expect(r.map((x) => x.local_id)).toEqual(['pub-1']);
  });
  it('reviewer and editor see drafts too', async () => {
    expect(await rows(U.rita, `select 1 from public.materials where local_id = 'draft-1'`)).toHaveLength(1);
    expect(await rows(U.ed, `select 1 from public.materials where local_id = 'draft-1'`)).toHaveLength(1);
  });
  it('viewer cannot create materials', async () => {
    await expect(q(U.vic, `insert into public.materials(workspace_id, data) values ($1, '{}')`, [teamWs])).rejects.toThrow(/row-level security/);
  });
});

describe('share_material_to_workspace', () => {
  let srcId;
  beforeAll(async () => {
    srcId = (await rows(U.ed, `insert into public.materials(workspace_id, local_id, data) values ($1, 'mine', '{"title":"自分の教材"}') returning id`, [personal.ed]))[0].id;
  });
  it('copies the material into the team workspace with a new id', async () => {
    const newId = (await rows(U.ed, 'select public.share_material_to_workspace($1, $2) as id', [srcId, teamWs]))[0].id;
    expect(newId).not.toBe(srcId);
    const [copy] = await rows(U.rita, 'select * from public.materials where id = $1', [newId]);
    expect(copy).toMatchObject({ workspace_id: teamWs, shared_from: srcId, status: 'draft', created_by: U.ed });
    expect(copy.data.title).toBe('自分の教材');
    // 元の教材は個人のまま・他人から見えない
    expect(await rows(U.rita, 'select * from public.materials where id = $1', [srcId])).toHaveLength(0);
    const [orig] = await rows(U.ed, 'select workspace_id from public.materials where id = $1', [srcId]);
    expect(orig.workspace_id).toBe(personal.ed);
    // コピーを編集しても元は変わらない
    await q(U.ed, `update public.materials set data = '{"title":"チーム版"}' where id = $1`, [newId]);
    expect((await rows(U.ed, 'select data from public.materials where id = $1', [srcId]))[0].data.title).toBe('自分の教材');
  });
  it('requires editor+ in the target workspace', async () => {
    const vicSrc = (await rows(U.vic, `insert into public.materials(workspace_id, data) values ($1, '{}') returning id`, [personal.vic]))[0].id;
    await expect(q(U.vic, 'select public.share_material_to_workspace($1, $2)', [vicSrc, teamWs])).rejects.toThrow(/forbidden/);
  });
  it('requires read access to the source', async () => {
    await expect(q(U.mal, 'select public.share_material_to_workspace($1, $2)', [srcId, personal.mal])).rejects.toThrow(/material_not_found/);
  });
});

describe('reviews', () => {
  let reviewId;
  beforeAll(async () => {
    const [qq] = await rows(U.ed, `select id from public.questions where local_id = 'Q-ed'`);
    reviewId = (await rows(U.ed, `insert into public.reviews(workspace_id, target_type, target_id) values ($1, 'question', $2) returning id`, [teamWs, qq.id]))[0].id;
  });
  it('editor can request but cannot approve', async () => {
    const r = await q(U.ed, `update public.reviews set state = 'approved' where id = $1`, [reviewId]);
    expect(r.affectedRows).toBe(0);
    await expect(q(U.ed, `insert into public.reviews(workspace_id, target_type, target_id, state) values ($1, 'question', gen_random_uuid(), 'approved')`, [teamWs])).rejects.toThrow(/row-level security/);
    expect((await rows(U.ed, 'select state from public.reviews where id = $1', [reviewId]))[0].state).toBe('pending');
  });
  it('viewer cannot approve', async () => {
    const r = await q(U.vic, `update public.reviews set state = 'approved' where id = $1`, [reviewId]);
    expect(r.affectedRows).toBe(0);
  });
  it('reviewer can approve and is recorded as reviewer', async () => {
    const r = await q(U.rita, `update public.reviews set state = 'approved', comment = 'OK' where id = $1`, [reviewId]);
    expect(r.affectedRows).toBe(1);
    const [rv] = await rows(U.vic, 'select * from public.reviews where id = $1', [reviewId]);
    expect(rv).toMatchObject({ state: 'approved', reviewer_id: U.rita, comment: 'OK' });
    expect(rv.reviewed_at).toBeTruthy();
  });
  it('reviewer can reject', async () => {
    const r = await q(U.rita, `update public.reviews set state = 'rejected' where id = $1`, [reviewId]);
    expect(r.affectedRows).toBe(1);
  });
});

describe('workspace members', () => {
  it('admin can add/change/remove members', async () => {
    await q(U.bob, `insert into public.workspace_members(workspace_id, user_id, role) values ($1, $2, 'viewer')`, [teamWs, U.mal]);
    expect((await q(U.bob, `update public.workspace_members set role = 'editor' where workspace_id = $1 and user_id = $2`, [teamWs, U.mal])).affectedRows).toBe(1);
    expect((await q(U.bob, 'delete from public.workspace_members where workspace_id = $1 and user_id = $2', [teamWs, U.mal])).affectedRows).toBe(1);
  });
  it('editor cannot add, change or remove members', async () => {
    await expect(q(U.ed, `insert into public.workspace_members(workspace_id, user_id, role) values ($1, $2, 'viewer')`, [teamWs, U.mal])).rejects.toThrow(/row-level security/);
    expect((await q(U.ed, `update public.workspace_members set role = 'admin' where workspace_id = $1 and user_id = $2`, [teamWs, U.ed])).affectedRows).toBe(0);
    expect((await q(U.ed, 'delete from public.workspace_members where workspace_id = $1 and user_id = $2', [teamWs, U.vic])).affectedRows).toBe(0);
    expect((await rows(U.ed, 'select role from public.workspace_members where workspace_id = $1 and user_id = $2', [teamWs, U.ed]))[0].role).toBe('editor');
  });
  it('admin cannot grant owner or touch the owner', async () => {
    await expect(q(U.bob, `insert into public.workspace_members(workspace_id, user_id, role) values ($1, $2, 'owner')`, [teamWs, U.mal])).rejects.toThrow(/row-level security/);
    expect((await q(U.bob, `update public.workspace_members set role = 'viewer' where workspace_id = $1 and user_id = $2`, [teamWs, U.alice])).affectedRows).toBe(0);
    expect((await q(U.bob, 'delete from public.workspace_members where workspace_id = $1 and user_id = $2', [teamWs, U.alice])).affectedRows).toBe(0);
  });
  it('members can see the member list; outsiders cannot', async () => {
    expect((await rows(U.vic, 'select * from public.workspace_members where workspace_id = $1', [teamWs])).length).toBe(5);
    expect(await rows(U.mal, 'select * from public.workspace_members where workspace_id = $1', [teamWs])).toHaveLength(0);
  });
  it('only owner/admin can rename the workspace', async () => {
    expect((await q(U.ed, `update public.workspaces set name = 'x' where id = $1`, [teamWs])).affectedRows).toBe(0);
    expect((await q(U.bob, `update public.workspaces set name = 'チームA改' where id = $1`, [teamWs])).affectedRows).toBe(1);
  });
});

describe('invitations', () => {
  let token;
  it('editor cannot create or read invitations; admin can', async () => {
    await expect(q(U.ed, `insert into public.invitations(workspace_id, email, role) values ($1, 'nina@example.com', 'editor')`, [teamWs])).rejects.toThrow(/row-level security/);
    token = (await rows(U.bob, `insert into public.invitations(workspace_id, email, role) values ($1, 'Nina@Example.com', 'editor') returning token`, [teamWs]))[0].token;
    expect(token).toMatch(/^[0-9a-f]{64}$/);
    expect(await rows(U.ed, 'select * from public.invitations')).toHaveLength(0);
  });
  it('accept_invitation rejects a non-matching email', async () => {
    await expect(q(U.mal, 'select public.accept_invitation($1)', [token])).rejects.toThrow(/invitation_email_mismatch/);
    expect(await rows(U.mal, 'select * from public.workspaces where id = $1', [teamWs])).toHaveLength(0);
  });
  it('accept_invitation adds the matching user with the invited role, once', async () => {
    const ws = (await rows(U.nina, 'select public.accept_invitation($1) as ws', [token]))[0].ws;
    expect(ws).toBe(teamWs);
    expect((await rows(U.nina, 'select role from public.workspace_members where workspace_id = $1 and user_id = $2', [teamWs, U.nina]))[0].role).toBe('editor');
    await expect(q(U.nina, 'select public.accept_invitation($1)', [token])).rejects.toThrow(/invitation_already_used/);
  });
  it('unknown token fails', async () => {
    await expect(q(U.mal, 'select public.accept_invitation($1)', ['nope'])).rejects.toThrow(/invitation_not_found/);
  });
});

describe('comments', () => {
  let cid;
  it('members create; only the author deletes', async () => {
    cid = (await rows(U.vic, `insert into public.comments(workspace_id, target_type, target_id, body) values ($1, 'material', gen_random_uuid(), 'いいね') returning id`, [teamWs]))[0].id;
    await expect(q(U.mal, `insert into public.comments(workspace_id, target_type, target_id, body) values ($1, 'material', gen_random_uuid(), 'x')`, [teamWs])).rejects.toThrow(/row-level security/);
    await expect(q(U.ed, `insert into public.comments(workspace_id, target_type, target_id, body, author_id) values ($1, 'material', gen_random_uuid(), 'なりすまし', $2)`, [teamWs, U.vic])).rejects.toThrow(/row-level security/);
    expect((await q(U.alice, 'delete from public.comments where id = $1', [cid])).affectedRows).toBe(0);
    expect((await q(U.vic, 'delete from public.comments where id = $1', [cid])).affectedRows).toBe(1);
  });
});

describe('history', () => {
  it('members can insert and read, but never update or delete', async () => {
    await q(U.vic, `insert into public.history(workspace_id, action, target) values ($1, 'view', 'm1')`, [teamWs]);
    expect((await rows(U.ed, `select * from public.history where workspace_id = $1 and action = 'view'`, [teamWs]))).toHaveLength(1);
    await expect(q(U.alice, `update public.history set action = 'x' where workspace_id = $1`, [teamWs])).rejects.toThrow(/permission denied/);
    await expect(q(U.alice, 'delete from public.history where workspace_id = $1', [teamWs])).rejects.toThrow(/permission denied/);
    await expect(q(U.mal, `insert into public.history(workspace_id, action) values ($1, 'x')`, [teamWs])).rejects.toThrow(/row-level security/);
    expect(await rows(U.mal, 'select * from public.history where workspace_id = $1', [teamWs])).toHaveLength(0);
  });
});

describe('ai_jobs', () => {
  beforeAll(async () => {
    // service role（Edge Function）として記録
    await db.exec(`begin; set local role service_role;`);
    await db.query(`insert into public.ai_jobs(user_id, workspace_id, action, model, tokens) values ($1, $2, 'generate', 'm', 100), ($3, $2, 'generate', 'm', 50)`, [U.ed, teamWs, U.rita]);
    await db.exec('commit');
  });
  it('clients cannot insert', async () => {
    await expect(q(U.ed, `insert into public.ai_jobs(user_id, workspace_id, action) values ($1, $2, 'generate')`, [U.ed, teamWs])).rejects.toThrow(/permission denied/);
  });
  it('users see their own jobs; owner/admin see the workspace\'s', async () => {
    expect(await rows(U.ed, 'select * from public.ai_jobs')).toHaveLength(1);
    expect(await rows(U.vic, 'select * from public.ai_jobs')).toHaveLength(0);
    expect(await rows(U.alice, 'select * from public.ai_jobs')).toHaveLength(2);
    expect(await rows(U.bob, 'select * from public.ai_jobs')).toHaveLength(2);
  });
});

describe('learning_results', () => {
  it('editor+ inserts, viewer cannot, members read', async () => {
    await q(U.ed, `insert into public.learning_results(workspace_id, question_id, learner, score) values ($1, 'Q-ed', '生徒1', 1)`, [teamWs]);
    await expect(q(U.vic, `insert into public.learning_results(workspace_id, learner, score) values ($1, 'x', 0)`, [teamWs])).rejects.toThrow(/row-level security/);
    expect(await rows(U.vic, 'select * from public.learning_results where workspace_id = $1', [teamWs])).toHaveLength(1);
    expect(await rows(U.mal, 'select * from public.learning_results')).toHaveLength(0);
  });
});

describe('anon', () => {
  it('anon sees nothing', async () => {
    await db.exec('begin; set local role anon;');
    await expect(db.query('select * from public.questions')).rejects.toThrow(/permission denied/);
    await db.exec('rollback');
  });
  it('every public table has RLS enabled', async () => {
    const r = await db.query(`select relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity`);
    expect(r.rows).toEqual([]);
  });
});

describe('client upsert path (as used by pushQuestion / pushMaterial)', () => {
  it('editor upserts by (workspace_id, local_id); second push updates and versions', async () => {
    const up = `insert into public.questions(workspace_id, local_id, data, status) values ($1, 'U-up', $2, 'unverified')
      on conflict (workspace_id, local_id) do update set data = excluded.data, status = excluded.status returning rev`;
    expect((await rows(U.ed, up, [teamWs, { stem: 'a' }]))[0].rev).toBe(1);
    expect((await rows(U.ed, up, [teamWs, { stem: 'b' }]))[0].rev).toBe(2);
    const mup = `insert into public.materials(workspace_id, local_id, data, status) values ($1, 'M-up', $2, 'draft')
      on conflict (workspace_id, local_id) do update set data = excluded.data, status = excluded.status returning rev`;
    expect((await rows(U.ed, mup, [teamWs, { title: 'a' }]))[0].rev).toBe(1);
    expect((await rows(U.ed, mup, [teamWs, { title: 'b' }]))[0].rev).toBe(2);
  });
  it('viewer upsert is rejected', async () => {
    await expect(q(U.vic, `insert into public.questions(workspace_id, local_id, data) values ($1, 'U-up', '{}')
      on conflict (workspace_id, local_id) do update set data = excluded.data`, [teamWs])).rejects.toThrow(/row-level security/);
  });
});

describe('approval flow', () => {
  /** editor creates a material and requests review; returns {matId, reviewId} */
  async function requested(localId) {
    const matId = (await rows(U.ed, `insert into public.materials(workspace_id, local_id, data) values ($1, $2, '{"title":"t"}') returning id`, [teamWs, localId]))[0].id;
    const reviewId = (await rows(U.ed, `insert into public.reviews(workspace_id, target_type, target_id) values ($1, 'material', $2) returning id`, [teamWs, matId]))[0].id;
    return { matId, reviewId };
  }
  const matStatus = async (id) => (await rows(U.ed, 'select status, rev from public.materials where id = $1', [id]))[0];

  it('requesting a review sets material → review', async () => {
    const { matId } = await requested('af-1');
    expect((await matStatus(matId)).status).toBe('review');
  });
  it('reviewer approves → material approved (no rev bump)', async () => {
    const { matId, reviewId } = await requested('af-2');
    await q(U.rita, `update public.reviews set state = 'approved' where id = $1`, [reviewId]);
    expect(await matStatus(matId)).toMatchObject({ status: 'approved', rev: 1 });
  });
  it('editor cannot approve (neither via review nor directly)', async () => {
    const { matId, reviewId } = await requested('af-3');
    expect((await q(U.ed, `update public.reviews set state = 'approved' where id = $1`, [reviewId])).affectedRows).toBe(0);
    await expect(q(U.ed, `update public.materials set status = 'approved' where id = $1`, [matId])).rejects.toThrow(/承認はレビュー担当者/);
    expect((await matStatus(matId)).status).toBe('review');
  });
  it('reviewer rejects → material draft', async () => {
    const { matId, reviewId } = await requested('af-4');
    await q(U.rita, `update public.reviews set state = 'rejected', comment = '要修正' where id = $1`, [reviewId]);
    expect((await matStatus(matId)).status).toBe('draft');
  });
  it('question review: verifying → approved / needs_fix', async () => {
    const qid = (await rows(U.ed, `insert into public.questions(workspace_id, local_id, data) values ($1, 'af-q', '{"stem":"x"}') returning id`, [teamWs]))[0].id;
    const rid = (await rows(U.ed, `insert into public.reviews(workspace_id, target_type, target_id) values ($1, 'question', $2) returning id`, [teamWs, qid]))[0].id;
    const st = async () => (await rows(U.ed, 'select status, rev from public.questions where id = $1', [qid]))[0];
    expect((await st()).status).toBe('verifying');
    await q(U.rita, `update public.reviews set state = 'rejected' where id = $1`, [rid]);
    expect((await st()).status).toBe('needs_fix');
    await q(U.rita, `update public.reviews set state = 'approved' where id = $1`, [rid]);
    expect(await st()).toMatchObject({ status: 'approved', rev: 1 });
  });
  it('a review cannot change targets in another workspace', async () => {
    const mine = (await rows(U.mal, `insert into public.materials(workspace_id, data) values ($1, '{}') returning id`, [personal.mal]))[0].id;
    await q(U.rita, `insert into public.reviews(workspace_id, target_type, target_id) values ($1, 'material', $2)`, [teamWs, mine]);
    expect((await rows(U.mal, 'select status from public.materials where id = $1', [mine]))[0].status).toBe('draft');
  });
  it('publish only from approved', async () => {
    const { matId, reviewId } = await requested('af-5');
    await expect(q(U.ed, `update public.materials set status = 'published' where id = $1`, [matId])).rejects.toThrow(/承認済み（approved）の教材だけを公開できます/);
    await expect(q(U.ed, `insert into public.materials(workspace_id, data, status) values ($1, '{}', 'published')`, [teamWs])).rejects.toThrow(/承認済み/);
    await q(U.rita, `update public.reviews set state = 'approved' where id = $1`, [reviewId]);
    await q(U.ed, `update public.materials set status = 'published' where id = $1`, [matId]);
    expect((await matStatus(matId)).status).toBe('published');
    expect(await rows(U.vic, 'select 1 from public.materials where id = $1', [matId])).toHaveLength(1);
  });
  it('viewer and reviewer cannot publish', async () => {
    const { matId, reviewId } = await requested('af-6');
    await q(U.rita, `update public.reviews set state = 'approved' where id = $1`, [reviewId]);
    expect((await q(U.vic, `update public.materials set status = 'published' where id = $1`, [matId])).affectedRows).toBe(0);
    expect((await q(U.rita, `update public.materials set status = 'published' where id = $1`, [matId])).affectedRows).toBe(0);
    expect((await matStatus(matId)).status).toBe('approved');
  });
  it('users update their own display_name only', async () => {
    expect((await q(U.vic, `update public.profiles set display_name = 'ビック' where id = $1`, [U.vic])).affectedRows).toBe(1);
    expect((await rows(U.ed, 'select display_name from public.profiles where id = $1', [U.vic]))[0].display_name).toBe('ビック');
    expect((await q(U.ed, `update public.profiles set display_name = 'x' where id = $1`, [U.vic])).affectedRows).toBe(0);
    await expect(q(U.vic, `update public.profiles set id = $2 where id = $1`, [U.vic, U.mal])).rejects.toThrow(/permission denied/);
  });
});
