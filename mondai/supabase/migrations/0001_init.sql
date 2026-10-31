-- =====================================================================
-- mondai 初期スキーマ（DATABASE_DESIGN §5）
--   テーブル・行単位セキュリティ（RLS）・トリガー・RPC 関数
--   Supabase の SQL Editor にそのまま貼り付けて実行できる。
--
-- 役割（role）と権限
--   owner    : すべて（メンバー管理・ワークスペース更新/削除）
--   admin    : owner 以外のメンバー管理・ワークスペース更新
--   editor   : 問題・教材・学習結果の作成/更新、レビュー依頼
--   reviewer : 閲覧（下書き含む）、レビューの承認/差し戻し
--   viewer   : 閲覧のみ（教材は published のみ）
--   ※「editor 以上」= owner/admin/editor、「reviewer 以上」= owner/admin/reviewer
-- =====================================================================

-- ---------------------------------------------------------------------
-- テーブル
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table if not exists public.workspaces (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (length(name) between 1 and 200),
  owner_id   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  personal   boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- 個人ワークスペースはユーザーごとに 1 つ
create unique index if not exists workspaces_one_personal
  on public.workspaces(owner_id) where personal;

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         text not null check (role in ('owner','admin','editor','reviewer','viewer')),
  created_at   timestamptz not null default now(),
  primary key (workspace_id, user_id)
);
create index if not exists workspace_members_user on public.workspace_members(user_id);

create table if not exists public.invitations (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  email        text not null check (position('@' in email) > 1),
  role         text not null default 'viewer' check (role in ('admin','editor','reviewer','viewer')),
  token        text not null unique default (replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '')),
  invited_by   uuid default auth.uid() references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default (now() + interval '14 days'),
  accepted_at  timestamptz,
  accepted_by  uuid references auth.users(id) on delete set null
);
create index if not exists invitations_ws on public.invitations(workspace_id);

-- 問題：id はサーバー側の UUID、local_id はアプリ内の問題 ID（U-xxxx / AI-xxxx など）
create table if not exists public.questions (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  local_id     text not null,
  data         jsonb not null default '{}'::jsonb,
  rev          integer not null default 1,
  status       text not null default 'unverified'
               check (status in ('unverified','verifying','verified','approved','needs_fix')),
  created_by   uuid default auth.uid() references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (workspace_id, local_id)
);

create table if not exists public.question_versions (
  id           bigint generated always as identity primary key,
  question_id  uuid not null references public.questions(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  rev          integer not null,
  data         jsonb not null,
  status       text,
  saved_by     uuid references auth.users(id) on delete set null,
  saved_at     timestamptz not null default now(),
  unique (question_id, rev)
);

create table if not exists public.materials (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  local_id     text,
  data         jsonb not null default '{}'::jsonb,
  rev          integer not null default 1,
  status       text not null default 'draft'
               check (status in ('draft','review','approved','published','archived')),
  shared_from  uuid references public.materials(id) on delete set null,
  created_by   uuid default auth.uid() references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  -- local_id が null（共有コピーなど）の行は重複可（Postgres では NULL 同士は一意制約に掛からない）
  unique (workspace_id, local_id)
);

create table if not exists public.reviews (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  target_type  text not null check (target_type in ('question','material')),
  target_id    uuid not null,
  state        text not null default 'pending' check (state in ('pending','approved','rejected')),
  requested_by uuid default auth.uid() references auth.users(id) on delete set null,
  reviewer_id  uuid references auth.users(id) on delete set null,
  comment      text not null default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  reviewed_at  timestamptz
);
create index if not exists reviews_ws on public.reviews(workspace_id, state);

create table if not exists public.comments (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  target_type  text not null check (target_type in ('question','material','review')),
  target_id    uuid not null,
  body         text not null check (length(body) between 1 and 10000),
  author_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at   timestamptz not null default now()
);
create index if not exists comments_target on public.comments(workspace_id, target_type, target_id);

create table if not exists public.history (
  id           bigint generated always as identity primary key,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  actor_id     uuid default auth.uid() references auth.users(id) on delete set null,
  action       text not null,
  target       text,
  detail       jsonb,
  at           timestamptz not null default now()
);
create index if not exists history_ws on public.history(workspace_id, at desc);

create table if not exists public.ai_jobs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  workspace_id uuid references public.workspaces(id) on delete set null,
  action       text not null,
  model        text,
  tokens       integer not null default 0,
  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  status       text not null default 'ok' check (status in ('ok','error')),
  error_code   text,
  input        jsonb,
  output       jsonb,
  created_at   timestamptz not null default now()
);
create index if not exists ai_jobs_user_day on public.ai_jobs(user_id, created_at);

create table if not exists public.learning_results (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  material_id  uuid references public.materials(id) on delete set null,
  question_id  text,
  learner      text not null default '',
  score        numeric,
  time_sec     integer,
  at           timestamptz not null default now(),
  created_by   uuid default auth.uid() references auth.users(id) on delete set null
);
create index if not exists learning_results_ws on public.learning_results(workspace_id);

-- ---------------------------------------------------------------------
-- 権限判定の補助関数（SECURITY DEFINER：RLS を通さず判定し、ポリシーの再帰を防ぐ）
-- ---------------------------------------------------------------------
create or replace function public.ws_role(ws uuid)
returns text
language sql stable security definer set search_path = public
as $$
  select m.role from public.workspace_members m
  where m.workspace_id = ws and m.user_id = auth.uid()
$$;

create or replace function public.is_member(ws uuid)
returns boolean
language sql stable security definer set search_path = public
as $$ select public.ws_role(ws) is not null $$;

create or replace function public.can_edit(ws uuid)
returns boolean
language sql stable security definer set search_path = public
as $$ select coalesce(public.ws_role(ws) in ('owner','admin','editor'), false) $$;

create or replace function public.can_review(ws uuid)
returns boolean
language sql stable security definer set search_path = public
as $$ select coalesce(public.ws_role(ws) in ('owner','admin','reviewer'), false) $$;

create or replace function public.is_ws_admin(ws uuid)
returns boolean
language sql stable security definer set search_path = public
as $$ select coalesce(public.ws_role(ws) in ('owner','admin'), false) $$;

create or replace function public.ws_is_personal(ws uuid)
returns boolean
language sql stable security definer set search_path = public
as $$ select coalesce((select w.personal from public.workspaces w where w.id = ws), false) $$;

create or replace function public.ws_owner(ws uuid)
returns uuid
language sql stable security definer set search_path = public
as $$ select w.owner_id from public.workspaces w where w.id = ws $$;

-- 呼び出し者と other が同じワークスペースに所属しているか
create or replace function public.shares_workspace(other uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.workspace_members a
    join public.workspace_members b on a.workspace_id = b.workspace_id
    where a.user_id = auth.uid() and b.user_id = other
  )
$$;

-- 呼び出し者が教材を閲覧できるか（materials の SELECT ポリシーと同じ条件）
create or replace function public.can_read_material(mat_ws uuid, mat_status text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select public.is_member(mat_ws)
     and (mat_status = 'published' or public.ws_role(mat_ws) <> 'viewer')
$$;

-- ---------------------------------------------------------------------
-- トリガー
-- ---------------------------------------------------------------------
-- updated_at を自動更新
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists set_updated_at on public.profiles;
create trigger set_updated_at before update on public.profiles
  for each row execute function public.tg_set_updated_at();
drop trigger if exists set_updated_at on public.workspaces;
create trigger set_updated_at before update on public.workspaces
  for each row execute function public.tg_set_updated_at();
drop trigger if exists set_updated_at on public.questions;
create trigger set_updated_at before update on public.questions
  for each row execute function public.tg_set_updated_at();
drop trigger if exists set_updated_at on public.materials;
create trigger set_updated_at before update on public.materials
  for each row execute function public.tg_set_updated_at();
drop trigger if exists set_updated_at on public.reviews;
create trigger set_updated_at before update on public.reviews
  for each row execute function public.tg_set_updated_at();

-- ワークスペース作成時、作成者を owner としてメンバー登録
create or replace function public.tg_workspace_add_owner()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.workspace_members(workspace_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (workspace_id, user_id) do update set role = 'owner';
  return new;
end $$;

drop trigger if exists workspace_add_owner on public.workspaces;
create trigger workspace_add_owner after insert on public.workspaces
  for each row execute function public.tg_workspace_add_owner();

-- 新規ユーザー登録時、プロフィールと個人ワークスペースを作成
create or replace function public.tg_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  dname text;
begin
  dname := coalesce(
    nullif(new.raw_user_meta_data ->> 'display_name', ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'ユーザー');
  insert into public.profiles(id, display_name) values (new.id, dname)
  on conflict (id) do nothing;
  insert into public.workspaces(name, owner_id, personal)
  values ('個人', new.id, true)
  on conflict do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.tg_handle_new_user();

-- 問題の更新時、旧版を question_versions に退避して rev を上げる
create or replace function public.tg_question_version()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.data is distinct from old.data then
    insert into public.question_versions(question_id, workspace_id, rev, data, status, saved_by)
    values (old.id, old.workspace_id, old.rev, old.data, old.status, auth.uid())
    on conflict (question_id, rev) do nothing;
    new.rev := old.rev + 1;
  else
    new.rev := old.rev;  -- データが変わらない更新（状態変更など）で rev を直接書き換えさせない
  end if;
  new.id := old.id;
  new.workspace_id := old.workspace_id;
  new.created_by := old.created_by;
  new.created_at := old.created_at;
  return new;
end $$;

drop trigger if exists question_version on public.questions;
create trigger question_version before update on public.questions
  for each row execute function public.tg_question_version();

-- 教材の更新時、rev を上げ、移動・作成者の書き換えを防ぐ
create or replace function public.tg_material_update()
returns trigger language plpgsql as $$
begin
  if new.data is distinct from old.data then
    new.rev := old.rev + 1;
  else
    new.rev := old.rev;
  end if;
  new.id := old.id;
  new.workspace_id := old.workspace_id;
  new.created_by := old.created_by;
  new.created_at := old.created_at;
  return new;
end $$;

drop trigger if exists material_update on public.materials;
create trigger material_update before update on public.materials
  for each row execute function public.tg_material_update();

-- レビューの状態が変わったら reviewer_id / reviewed_at を記録
create or replace function public.tg_review_state()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    new.reviewer_id := null;
    new.reviewed_at := null;
    if new.state <> 'pending' then
      new.reviewer_id := auth.uid();
      new.reviewed_at := now();
    end if;
  elsif new.state is distinct from old.state then
    new.reviewer_id := auth.uid();
    new.reviewed_at := case when new.state = 'pending' then null else now() end;
  else
    new.reviewer_id := old.reviewer_id;
    new.reviewed_at := old.reviewed_at;
  end if;
  if tg_op = 'UPDATE' then
    new.workspace_id := old.workspace_id;
    new.target_type := old.target_type;
    new.target_id := old.target_id;
    new.requested_by := old.requested_by;
  end if;
  return new;
end $$;

drop trigger if exists review_state on public.reviews;
create trigger review_state before insert or update on public.reviews
  for each row execute function public.tg_review_state();

-- 教材の状態遷移の制限（クライアントからの変更のみ。auth.uid() が無い service role・SQL Editor は対象外）
--   published にできるのは owner/admin/editor で、現在 approved の教材だけ
--   approved にできるのは owner/admin/reviewer（通常はレビューの承認で自動的に変わる）
create or replace function public.tg_material_status()
returns trigger language plpgsql as $$
declare
  prev text := case when tg_op = 'UPDATE' then old.status else null end;
begin
  if auth.uid() is null or new.status is not distinct from prev then
    return new;
  end if;
  if new.status = 'published' then
    if not public.can_edit(new.workspace_id) then
      raise exception '教材を公開できるのは所有者・管理者・編集者だけです' using errcode = '42501';
    end if;
    if prev is distinct from 'approved' then
      raise exception '承認済み（approved）の教材だけを公開できます。先にレビューで承認を受けてください（現在の状態：%）',
        coalesce(prev, '新規') using errcode = '42501';
    end if;
  elsif new.status = 'approved' then
    if not public.can_review(new.workspace_id) then
      raise exception '教材の承認はレビュー担当者・管理者・所有者だけができます。レビューを依頼してください' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists material_status on public.materials;
create trigger material_status before insert or update of status on public.materials
  for each row execute function public.tg_material_status();

-- レビューの依頼・承認・差し戻しに合わせて対象の状態を変える
--   依頼(pending) → 教材 review / 問題 verifying
--   承認(approved) → 教材 approved / 問題 approved
--   差し戻し(rejected) → 教材 draft / 問題 needs_fix
-- 対象は同じワークスペース内のものに限る
create or replace function public.tg_review_apply()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and new.state is not distinct from old.state then
    return null;
  end if;
  if new.target_type = 'material' then
    update public.materials
       set status = case new.state when 'approved' then 'approved'
                                   when 'rejected' then 'draft'
                                   else 'review' end
     where id = new.target_id and workspace_id = new.workspace_id;
  elsif new.target_type = 'question' then
    update public.questions
       set status = case new.state when 'approved' then 'approved'
                                   when 'rejected' then 'needs_fix'
                                   else 'verifying' end
     where id = new.target_id and workspace_id = new.workspace_id;
  end if;
  return null;
end $$;

drop trigger if exists review_apply on public.reviews;
create trigger review_apply after insert or update of state on public.reviews
  for each row execute function public.tg_review_apply();

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.profiles          enable row level security;
alter table public.workspaces        enable row level security;
alter table public.workspace_members enable row level security;
alter table public.invitations       enable row level security;
alter table public.questions         enable row level security;
alter table public.question_versions enable row level security;
alter table public.materials         enable row level security;
alter table public.reviews           enable row level security;
alter table public.comments          enable row level security;
alter table public.history           enable row level security;
alter table public.ai_jobs           enable row level security;
alter table public.learning_results  enable row level security;

-- profiles：本人と同じワークスペースのメンバーが閲覧、本人のみ更新
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.shares_workspace(id));
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to authenticated
  with check (id = auth.uid());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- workspaces：メンバーのみ閲覧、owner/admin のみ更新、owner のみ削除（個人WSは削除不可）
drop policy if exists workspaces_select on public.workspaces;
create policy workspaces_select on public.workspaces for select to authenticated
  using (public.is_member(id));
drop policy if exists workspaces_insert on public.workspaces;
create policy workspaces_insert on public.workspaces for insert to authenticated
  with check (owner_id = auth.uid() and personal = false);
drop policy if exists workspaces_update on public.workspaces;
create policy workspaces_update on public.workspaces for update to authenticated
  using (public.is_ws_admin(id)) with check (public.is_ws_admin(id));
drop policy if exists workspaces_delete on public.workspaces;
create policy workspaces_delete on public.workspaces for delete to authenticated
  using (owner_id = auth.uid() and personal = false);

-- workspace_members：メンバーは閲覧、owner/admin のみ追加・変更・削除
--   owner 権限の付与・owner 行の変更は owner のみ。ワークスペース所有者の行は削除不可。
--   個人ワークスペースにはメンバーを追加できない。本人は脱退（自分の行の削除）可。
drop policy if exists members_select on public.workspace_members;
create policy members_select on public.workspace_members for select to authenticated
  using (public.is_member(workspace_id));
drop policy if exists members_insert on public.workspace_members;
create policy members_insert on public.workspace_members for insert to authenticated
  with check (
    public.is_ws_admin(workspace_id)
    and not public.ws_is_personal(workspace_id)
    and (role <> 'owner' or public.ws_role(workspace_id) = 'owner')
  );
drop policy if exists members_update on public.workspace_members;
create policy members_update on public.workspace_members for update to authenticated
  using (
    public.is_ws_admin(workspace_id)
    and user_id <> public.ws_owner(workspace_id)
    and (role <> 'owner' or public.ws_role(workspace_id) = 'owner')
  )
  with check (
    public.is_ws_admin(workspace_id)
    and user_id <> public.ws_owner(workspace_id)
    and (role <> 'owner' or public.ws_role(workspace_id) = 'owner')
  );
drop policy if exists members_delete on public.workspace_members;
create policy members_delete on public.workspace_members for delete to authenticated
  using (
    user_id <> public.ws_owner(workspace_id)
    and (
      user_id = auth.uid()
      or (public.is_ws_admin(workspace_id)
          and (role <> 'owner' or public.ws_role(workspace_id) = 'owner'))
    )
  );

-- invitations：owner/admin のみ（受諾は accept_invitation 関数経由）
drop policy if exists invitations_all on public.invitations;
create policy invitations_all on public.invitations for all to authenticated
  using (public.is_ws_admin(workspace_id))
  with check (public.is_ws_admin(workspace_id) and not public.ws_is_personal(workspace_id));

-- questions：メンバー閲覧、editor 以上が作成・更新、owner/admin が削除
drop policy if exists questions_select on public.questions;
create policy questions_select on public.questions for select to authenticated
  using (public.is_member(workspace_id));
drop policy if exists questions_insert on public.questions;
create policy questions_insert on public.questions for insert to authenticated
  with check (public.can_edit(workspace_id) and created_by = auth.uid());
drop policy if exists questions_update on public.questions;
create policy questions_update on public.questions for update to authenticated
  using (public.can_edit(workspace_id)) with check (public.can_edit(workspace_id));
drop policy if exists questions_delete on public.questions;
create policy questions_delete on public.questions for delete to authenticated
  using (public.is_ws_admin(workspace_id));

-- question_versions：メンバー閲覧のみ（追加はトリガー）
drop policy if exists qv_select on public.question_versions;
create policy qv_select on public.question_versions for select to authenticated
  using (public.is_member(workspace_id));

-- materials：questions と同じ。ただし published 以外は viewer に見せない
drop policy if exists materials_select on public.materials;
create policy materials_select on public.materials for select to authenticated
  using (public.can_read_material(workspace_id, status));
drop policy if exists materials_insert on public.materials;
create policy materials_insert on public.materials for insert to authenticated
  with check (public.can_edit(workspace_id) and created_by = auth.uid());
drop policy if exists materials_update on public.materials;
create policy materials_update on public.materials for update to authenticated
  using (public.can_edit(workspace_id)) with check (public.can_edit(workspace_id));
drop policy if exists materials_delete on public.materials;
create policy materials_delete on public.materials for delete to authenticated
  using (public.is_ws_admin(workspace_id));

-- reviews：メンバー閲覧。editor 以上はレビュー依頼（pending）を作成。
--          承認・差し戻し（状態の変更）は reviewer 以上のみ。
drop policy if exists reviews_select on public.reviews;
create policy reviews_select on public.reviews for select to authenticated
  using (public.is_member(workspace_id));
drop policy if exists reviews_insert on public.reviews;
create policy reviews_insert on public.reviews for insert to authenticated
  with check (
    (state = 'pending' and (public.can_edit(workspace_id) or public.can_review(workspace_id)))
    or (state in ('approved','rejected') and public.can_review(workspace_id))
  );
drop policy if exists reviews_update on public.reviews;
create policy reviews_update on public.reviews for update to authenticated
  using (public.can_review(workspace_id)) with check (public.can_review(workspace_id));
drop policy if exists reviews_delete on public.reviews;
create policy reviews_delete on public.reviews for delete to authenticated
  using (public.is_ws_admin(workspace_id));

-- comments：メンバー閲覧・作成、本人のみ削除
drop policy if exists comments_select on public.comments;
create policy comments_select on public.comments for select to authenticated
  using (public.is_member(workspace_id));
drop policy if exists comments_insert on public.comments;
create policy comments_insert on public.comments for insert to authenticated
  with check (public.is_member(workspace_id) and author_id = auth.uid());
drop policy if exists comments_delete on public.comments;
create policy comments_delete on public.comments for delete to authenticated
  using (author_id = auth.uid());

-- history：メンバー閲覧、挿入のみ（更新・削除不可）
drop policy if exists history_select on public.history;
create policy history_select on public.history for select to authenticated
  using (public.is_member(workspace_id));
drop policy if exists history_insert on public.history;
create policy history_insert on public.history for insert to authenticated
  with check (public.is_member(workspace_id) and actor_id = auth.uid());

-- ai_jobs：本人とワークスペースの owner/admin が閲覧。挿入は service role のみ
drop policy if exists ai_jobs_select on public.ai_jobs;
create policy ai_jobs_select on public.ai_jobs for select to authenticated
  using (user_id = auth.uid() or (workspace_id is not null and public.is_ws_admin(workspace_id)));

-- learning_results：メンバー閲覧、editor 以上が挿入、owner/admin が削除
drop policy if exists lr_select on public.learning_results;
create policy lr_select on public.learning_results for select to authenticated
  using (public.is_member(workspace_id));
drop policy if exists lr_insert on public.learning_results;
create policy lr_insert on public.learning_results for insert to authenticated
  with check (public.can_edit(workspace_id));
drop policy if exists lr_delete on public.learning_results;
create policy lr_delete on public.learning_results for delete to authenticated
  using (public.is_ws_admin(workspace_id));

-- ---------------------------------------------------------------------
-- テーブル権限（RLS の前段。Supabase 既定の全権付与を絞る）
-- ---------------------------------------------------------------------
revoke all on public.profiles, public.workspaces, public.workspace_members, public.invitations,
  public.questions, public.question_versions, public.materials, public.reviews, public.comments,
  public.history, public.ai_jobs, public.learning_results
  from anon, authenticated;

grant select, insert                 on public.profiles          to authenticated;
grant update (display_name)          on public.profiles          to authenticated;
grant select, insert, delete         on public.workspaces        to authenticated;
grant update (name)                  on public.workspaces        to authenticated;
grant select, insert, delete         on public.workspace_members to authenticated;
grant update (role)                  on public.workspace_members to authenticated;
grant select, insert, update, delete on public.invitations       to authenticated;
grant select, insert, update, delete on public.questions         to authenticated;
grant select                         on public.question_versions to authenticated;
grant select, insert, update, delete on public.materials         to authenticated;
grant select, insert, delete         on public.reviews           to authenticated;
grant update (state, comment)        on public.reviews           to authenticated;
grant select, insert, delete         on public.comments          to authenticated;
grant select, insert                 on public.history           to authenticated;
grant select                         on public.ai_jobs           to authenticated;
grant select, insert, delete         on public.learning_results  to authenticated;

grant select, insert, update, delete on public.profiles, public.workspaces, public.workspace_members,
  public.invitations, public.questions, public.question_versions, public.materials, public.reviews,
  public.comments, public.history, public.ai_jobs, public.learning_results
  to service_role;

-- ---------------------------------------------------------------------
-- RPC 関数
-- ---------------------------------------------------------------------
-- 招待の受諾：呼び出し者のメールアドレスが招待先と一致すれば、招待された役割でメンバーに追加
create or replace function public.accept_invitation(token text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  inv   public.invitations%rowtype;
  me    uuid := auth.uid();
  v_email text;
begin
  if me is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  select u.email into v_email from auth.users u where u.id = me;

  select * into inv from public.invitations i
  where i.token = accept_invitation.token
  for update;

  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0002';
  end if;
  if inv.accepted_at is not null then
    raise exception 'invitation_already_used' using errcode = '22023';
  end if;
  if inv.expires_at < now() then
    raise exception 'invitation_expired' using errcode = '22023';
  end if;
  if v_email is null or lower(trim(v_email)) <> lower(trim(inv.email)) then
    raise exception 'invitation_email_mismatch' using errcode = '42501';
  end if;

  insert into public.workspace_members(workspace_id, user_id, role)
  values (inv.workspace_id, me, inv.role)
  on conflict (workspace_id, user_id) do update
    set role = case when public.workspace_members.role = 'owner'
                    then 'owner' else excluded.role end;

  update public.invitations
     set accepted_at = now(), accepted_by = me
   where id = inv.id;

  insert into public.history(workspace_id, actor_id, action, target, detail)
  values (inv.workspace_id, me, 'member.join', me::text, jsonb_build_object('role', inv.role));

  return inv.workspace_id;
end $$;

-- 教材をチームのワークスペースへ「コピー」して共有（元の教材はそのまま）
create or replace function public.share_material_to_workspace(material_id uuid, target_ws uuid)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  src    public.materials%rowtype;
  me     uuid := auth.uid();
  new_id uuid;
begin
  if me is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select * into src from public.materials m where m.id = share_material_to_workspace.material_id;
  if not found or not public.can_read_material(src.workspace_id, src.status) then
    raise exception 'material_not_found' using errcode = 'P0002';
  end if;
  if not public.can_edit(target_ws) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if public.ws_is_personal(target_ws) then
    raise exception 'target_is_personal' using errcode = '22023';
  end if;

  insert into public.materials(workspace_id, local_id, data, rev, status, shared_from, created_by)
  values (target_ws, null, src.data, 1, 'draft', src.id, me)
  returning id into new_id;

  insert into public.history(workspace_id, actor_id, action, target, detail)
  values (target_ws, me, 'material.share', new_id::text,
          jsonb_build_object('from', src.id, 'from_workspace', src.workspace_id));

  return new_id;
end $$;

-- チームのワークスペースを作成（作成者は owner）。
-- INSERT ... RETURNING は owner 登録トリガーより前に SELECT ポリシーで判定されるため関数で作る。
create or replace function public.create_workspace(name text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  me     uuid := auth.uid();
  new_id uuid;
begin
  if me is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if create_workspace.name is null or length(trim(create_workspace.name)) = 0 then
    raise exception 'name_required' using errcode = '22023';
  end if;
  insert into public.workspaces(name, owner_id, personal)
  values (trim(create_workspace.name), me, false)
  returning id into new_id;
  insert into public.history(workspace_id, actor_id, action, target)
  values (new_id, me, 'workspace.create', new_id::text);
  return new_id;
end $$;

revoke all on function public.create_workspace(text) from public, anon;
grant execute on function public.create_workspace(text) to authenticated;
revoke all on function public.accept_invitation(text) from public, anon;
revoke all on function public.share_material_to_workspace(uuid, uuid) from public, anon;
grant execute on function public.accept_invitation(text) to authenticated;
grant execute on function public.share_material_to_workspace(uuid, uuid) to authenticated;
