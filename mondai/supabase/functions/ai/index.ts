// Supabase Edge Function `ai`
//   POST { action, payload, workspace_id? }  （Authorization: Bearer <ログイン中のアクセストークン>）
//   → 200 { ok: true, data, job: { id, model, tokens } }
//   → 4xx/5xx { ok: false, error: { code, message } }
// 誤りコード：not_configured / unauthorized / forbidden / quota_exceeded / bad_request / provider_error / bad_output
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.45.4";
import { ACTIONS, type Action, extractJson, SPECS } from "./prompts.ts";
import { AnthropicProvider } from "./providers/anthropic.ts";
import { type AIProvider, ProviderError } from "./providers/types.ts";

// ---- 設定 ---------------------------------------------------------------
const env = { get: (k: string): string | undefined => Deno.env.get(k) };

/** プロバイダー登録表。追加するときは providers/<name>.ts を作ってここに 1 行足す */
const PROVIDERS: Record<string, () => AIProvider> = {
  anthropic: () => new AnthropicProvider(env),
};

const DAILY_LIMIT = Number(env.get("AI_DAILY_TOKEN_LIMIT") ?? "200000") || 200000;

/** 作業ごとに必要な役割 */
const EDITORS = ["owner", "admin", "editor"];
const EDITORS_AND_REVIEWERS = ["owner", "admin", "editor", "reviewer"];
const REQUIRED_ROLES: Record<Action, string[]> = {
  parse_request: EDITORS,
  generate: EDITORS,
  solve: EDITORS_AND_REVIEWERS,
  explain: EDITORS,
  review: EDITORS_AND_REVIEWERS,
  plan_material: EDITORS,
  suggest_review: EDITORS,
};

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": env.get("ALLOWED_ORIGIN") ?? "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

type ErrorCode =
  | "not_configured"
  | "unauthorized"
  | "forbidden"
  | "quota_exceeded"
  | "bad_request"
  | "provider_error"
  | "bad_output";

const STATUS: Record<ErrorCode, number> = {
  not_configured: 503,
  unauthorized: 401,
  forbidden: 403,
  quota_exceeded: 429,
  bad_request: 400,
  provider_error: 502,
  bad_output: 502,
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json; charset=utf-8" },
  });
}

function fail(code: ErrorCode, message: string, extra: Record<string, unknown> = {}): Response {
  return json({ ok: false, error: { code, message, ...extra } }, STATUS[code]);
}

// ---- 補助 ---------------------------------------------------------------
function startOfUtcDay(): string {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  return d.toISOString();
}

async function tokensUsedToday(admin: SupabaseClient, userId: string): Promise<number> {
  const { data, error } = await admin
    .from("ai_jobs")
    .select("tokens")
    .eq("user_id", userId)
    .gte("created_at", startOfUtcDay());
  if (error) throw new Error(`利用量を取得できません: ${error.message}`);
  return (data ?? []).reduce((sum: number, r: { tokens: number | null }) => sum + (r.tokens ?? 0), 0);
}

async function resolveRole(
  admin: SupabaseClient,
  userId: string,
  workspaceId: string | null,
): Promise<{ workspaceId: string | null; role: string | null }> {
  if (!workspaceId) {
    // 指定がなければ個人ワークスペース（本人が owner）
    const { data } = await admin
      .from("workspaces")
      .select("id")
      .eq("owner_id", userId)
      .eq("personal", true)
      .maybeSingle();
    if (!data) return { workspaceId: null, role: null };
    workspaceId = (data as { id: string }).id;
  }
  const { data } = await admin
    .from("workspace_members")
    .select("role")
    .eq("workspace_id", workspaceId)
    .eq("user_id", userId)
    .maybeSingle();
  return { workspaceId, role: (data as { role: string } | null)?.role ?? null };
}

interface JobRecord {
  user_id: string;
  workspace_id: string | null;
  action: string;
  model: string | null;
  input_tokens: number;
  output_tokens: number;
  tokens: number;
  status: "ok" | "error";
  error_code?: string | null;
  input: unknown;
  output: unknown;
}

async function recordJob(admin: SupabaseClient, job: JobRecord): Promise<string | null> {
  const { data, error } = await admin.from("ai_jobs").insert(job).select("id").single();
  if (error) {
    console.error("ai_jobs insert failed", error.message);
    return null;
  }
  return (data as { id: string }).id;
}

// ---- 本体 ---------------------------------------------------------------
Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return fail("bad_request", "POST で呼び出してください");

  const supabaseUrl = env.get("SUPABASE_URL");
  const anonKey = env.get("SUPABASE_ANON_KEY");
  const serviceKey = env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return fail("not_configured", "Supabase の環境変数が設定されていません");
  }

  const providerName = env.get("AI_PROVIDER") ?? "anthropic";
  const makeProvider = PROVIDERS[providerName];
  if (!makeProvider) return fail("not_configured", `未対応の AI プロバイダーです: ${providerName}`);
  const provider = makeProvider();
  if (!provider.isConfigured()) {
    return fail("not_configured", "AI の API キー（ANTHROPIC_API_KEY）が設定されていません。管理者に設定を依頼してください。");
  }

  // 1. JWT 検証
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) return fail("unauthorized", "ログインしてください");
  const jwt = authHeader.slice("Bearer ".length);
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser(jwt);
  if (userErr || !userData?.user) return fail("unauthorized", "ログインの有効期限が切れています。もう一度ログインしてください");
  const userId = userData.user.id;

  // 2. 入力
  let body: { action?: unknown; payload?: unknown; workspace_id?: unknown; workspaceId?: unknown };
  try {
    body = await req.json();
  } catch {
    return fail("bad_request", "JSON の本文が必要です");
  }
  const action = body.action as Action;
  if (!ACTIONS.includes(action)) return fail("bad_request", `不明な action です: ${String(body.action)}`);
  const payload = (typeof body.payload === "object" && body.payload !== null && !Array.isArray(body.payload)
    ? body.payload
    : {}) as Record<string, unknown>;
  const wsParam = (body.workspace_id ?? body.workspaceId ?? null) as string | null;

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 3. ワークスペース権限
  const { workspaceId, role } = await resolveRole(admin, userId, wsParam);
  if (!workspaceId || !role) return fail("forbidden", "このワークスペースのメンバーではありません");
  if (!REQUIRED_ROLES[action].includes(role)) {
    return fail("forbidden", `この操作には編集者以上の権限が必要です（現在：${role}）`);
  }

  // 4. 利用上限
  let used: number;
  try {
    used = await tokensUsedToday(admin, userId);
  } catch (e) {
    return fail("provider_error", (e as Error).message);
  }
  if (used >= DAILY_LIMIT) {
    return fail("quota_exceeded", `本日の AI 利用上限（${DAILY_LIMIT.toLocaleString()} トークン）に達しました`, {
      used,
      limit: DAILY_LIMIT,
    });
  }

  // 5. 呼び出し
  const spec = SPECS[action];
  const userPrompt = spec.buildUser(payload);
  let result;
  try {
    result = await provider.complete({ system: spec.system, user: userPrompt, maxTokens: spec.maxTokens });
  } catch (e) {
    const msg = e instanceof ProviderError ? e.message : `AI 呼び出しに失敗しました: ${(e as Error).message}`;
    await recordJob(admin, {
      user_id: userId, workspace_id: workspaceId, action, model: null,
      input_tokens: 0, output_tokens: 0, tokens: 0,
      status: "error", error_code: "provider_error", input: payload, output: { message: msg },
    });
    return fail("provider_error", msg);
  }
  const tokens = result.usage.inputTokens + result.usage.outputTokens;
  const base = {
    user_id: userId, workspace_id: workspaceId, action, model: result.model,
    input_tokens: result.usage.inputTokens, output_tokens: result.usage.outputTokens, tokens,
    input: payload,
  };

  // 6. 出力検証
  let parsed: unknown;
  try {
    if (result.stopReason === "max_tokens") throw new Error("出力が長すぎて途中で切れました");
    parsed = extractJson(result.text);
  } catch (e) {
    await recordJob(admin, { ...base, status: "error", error_code: "bad_output", output: { raw: result.text.slice(0, 20000) } });
    return fail("bad_output", `AI の出力を読み取れませんでした：${(e as Error).message}`);
  }
  const v = spec.validate(parsed);
  if (!v.ok) {
    await recordJob(admin, { ...base, status: "error", error_code: "bad_output", output: parsed });
    return fail("bad_output", `AI の出力が形式に合いません：${v.reason}`);
  }

  // 7. 記録して返す
  const jobId = await recordJob(admin, { ...base, status: "ok", error_code: null, output: v.value });
  return json({
    ok: true,
    data: v.value,
    job: { id: jobId, model: result.model, tokens, usedToday: used + tokens, limit: DAILY_LIMIT, provider: provider.name },
  });
});
