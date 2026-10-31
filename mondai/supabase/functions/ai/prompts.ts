// 作業（action）ごとのプロンプトと出力検証。
// 出力はすべて JSON。問題はアプリの共通問題形式（DATABASE_DESIGN §1）で返させる。

export type Action =
  | "parse_request"
  | "generate"
  | "solve"
  | "explain"
  | "review"
  | "plan_material"
  | "suggest_review"
  | "vary";

export const ACTIONS: readonly Action[] = [
  "parse_request",
  "generate",
  "solve",
  "explain",
  "review",
  "plan_material",
  "suggest_review",
  "vary",
];

// 入試の形式ごとの作り方（generate / plan_material で、conditions.format または payload.format で指定）
const FORMAT_GUIDE: Record<string, string> = {
  kanagawa:
    "神奈川県公立高校入試の形式に合わせる：中学校の学習範囲。大問「問1」〜、小問「(ア)(イ)…」。選択肢は1〜4の番号で4つ（choice）。" +
    "数値を答える問題は整数が答えになるようにし（マークで「あい」と1けたずつ答えさせる）、type は short。一部に記述（written、字数指定つき）を含めてよい。" +
    "資料・会話文・グラフ（表で表す）を読み取る思考力の問題を入れる。",
  kyotsu:
    "大学入学共通テストの形式に合わせる：高校の学習範囲。大問「第1問」〜、小問「問1」〜。すべてマーク式：選択問題（choice、選択肢は4〜6個）と、" +
    "整数が答えになる数値問題（short、答えは整数のみ。分数や根号は分子・分母・根号の中などを別の小問に分けて整数で答えさせる）だけにする。" +
    "会話文・資料・実験・複数の情報を組み合わせて考える問題、誘導つきの問題を多くする。",
  niji:
    "大学入試の二次試験（記述式）の形式に合わせる：大問「第1問」〜を、誘導つきの小問「(1)(2)(3)」に分ける。答えだけでなく過程・論証を書かせる記述問題（written）" +
    "と、答えを求める問題（short）にする。選択式は使わない。採点基準（rubric）を必ず付け、部分点の観点を示す。難易度は標準〜応用。",
};
function formatGuide(p: Record<string, unknown>): string {
  const c = isObj(p.conditions) ? p.conditions : {};
  const f = String(p.format ?? c.format ?? "");
  return FORMAT_GUIDE[f] ? `\n\n出題形式：${FORMAT_GUIDE[f]}` : "";
}

export type Validation = { ok: true; value: unknown } | { ok: false; reason: string };

export interface ActionSpec {
  system: string;
  buildUser(payload: Record<string, unknown>): string;
  validate(output: unknown): Validation;
  maxTokens: number;
}

const QUESTION_TYPES = ["choice", "multi", "order", "tf", "short", "written", "steps"];
const LEVELS = ["基礎", "標準", "応用"];

const COMMON = [
  "あなたは日本の学校教育（小・中・高）の教材制作を支援する専門家です。",
  "学習指導要領の範囲と学年に合った、正確で誤りのない内容を作成してください。",
  "出力は必ず JSON のみとし、前後に説明文やコードブロック記号（```）を付けないでください。",
  "数式は $...$（KaTeX 記法）で書いてください。",
].join("\n");

const QUESTION_FORMAT = `問題 1 問は次の JSON オブジェクトで表します（不要な項目は省略可）：
{
  "type": "choice" | "multi" | "order" | "tf" | "short" | "written" | "steps",
  "stem": "問題文",
  "sentence": "付属の文（任意）",
  "choices": ["選択肢1", "選択肢2", ...],      // choice/multi/order のとき必須
  "ai": [正解の選択肢番号(0始まり)],            // choice/multi/order のとき必須（order は正しい順序）
  "ans": "正答",                               // tf/short/written/steps のとき必須（tf は "○" か "×"）
  "alts": ["別解・許容解"],
  "expl": "解説",
  "explBasic": "初学者向けの解説",
  "explAdvanced": "発展的な解説",
  "steps": ["解き方の手順1", "手順2"],
  "mistakes": ["よくある誤答とその理由"],
  "rubric": [{"c": "採点基準", "p": 部分点}],
  "pts": 配点(数値),
  "time": 想定解答時間(秒),
  "level": "基礎" | "標準" | "応用",
  "subj": "教科", "grade": "学年", "unit": "単元", "subunit": "小単元",
  "knowledge": ["必要な知識"],
  "intent": "出題意図",
  "check": {"expr": "答えを計算する式（例: (3+5)*2）", "expect": "期待値（例: 16）"}  // 数値で答える計算問題では必須
}`;

function str(v: unknown, max = 20000): string {
  if (v == null) return "";
  const s = typeof v === "string" ? v : JSON.stringify(v, null, 2);
  return s.length > max ? s.slice(0, max) + "\n…（以下省略）" : s;
}

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

/** 問題 1 問の形式検証。問題があれば理由を返す */
export function validateQuestion(q: unknown): string | null {
  if (!isObj(q)) return "問題がオブジェクトではありません";
  if (typeof q.type !== "string" || !QUESTION_TYPES.includes(q.type)) return `type が不正です: ${String(q.type)}`;
  if (typeof q.stem !== "string" || q.stem.trim() === "") return "stem がありません";
  if (q.level != null && !LEVELS.includes(String(q.level))) return `level が不正です: ${String(q.level)}`;
  if (["choice", "multi", "order"].includes(q.type)) {
    if (!Array.isArray(q.choices) || q.choices.length < 2) return "choices が 2 つ以上必要です";
    if (!Array.isArray(q.ai) || q.ai.length === 0) return "ai（正解番号）がありません";
    const n = q.choices.length;
    if (!q.ai.every((i) => Number.isInteger(i) && (i as number) >= 0 && (i as number) < n)) {
      return "ai の番号が選択肢の範囲外です";
    }
    if (q.type === "choice" && q.ai.length !== 1) return "choice の正解は 1 つです";
  } else if (q.ans == null || String(q.ans).trim() === "") {
    return "ans（正答）がありません";
  }
  if (q.rubric != null) {
    if (!Array.isArray(q.rubric) || !q.rubric.every((r) => isObj(r) && typeof r.c === "string" && typeof r.p === "number")) {
      return "rubric は {c, p} の配列にしてください";
    }
  }
  if (q.check != null) {
    if (!isObj(q.check) || typeof q.check.expr !== "string") return "check.expr がありません";
  }
  for (const k of ["alts", "steps", "mistakes", "knowledge"]) {
    if (q[k] != null && !Array.isArray(q[k])) return `${k} は配列にしてください`;
  }
  return null;
}

function normalizeQuestion(q: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = { ...q, origin: "ai", src: "AI", status: "unverified" };
  if (out.pts != null) out.pts = Number(out.pts) || 0;
  if (out.time != null) out.time = Number(out.time) || 0;
  if (out.check && isObj(out.check) && out.check.expect != null) {
    out.check = { expr: out.check.expr, expect: String(out.check.expect) };
  }
  delete out.id; // ID はアプリ側で採番する
  return out;
}

function requireObject(output: unknown, keys: string[]): Validation {
  if (!isObj(output)) return { ok: false, reason: "JSON オブジェクトではありません" };
  for (const k of keys) {
    if (!(k in output)) return { ok: false, reason: `${k} がありません` };
  }
  return { ok: true, value: output };
}

export const SPECS: Record<Action, ActionSpec> = {
  parse_request: {
    maxTokens: 4000,
    system: `${COMMON}
先生の自然文の依頼を、問題作成の構造化条件に変換します。読み取れない項目は null にしてください。
出力形式：
{
  "subj": "教科", "course": "科目", "grade": "学年", "units": ["単元"], "subunits": ["小単元"],
  "level": "基礎" | "標準" | "応用" | null,
  "levelRatio": {"基礎": 数, "標準": 数, "応用": 数} | null,
  "count": 問題数, "types": ["choice" など問題形式"],
  "timeMin": 想定時間(分) | null, "totalPts": 合計点 | null,
  "exclude": {"units": [], "tags": [], "keywords": []},
  "explanation": "none" | "brief" | "detailed",
  "notes": "その他の条件"
}`,
    buildUser: (p) => `依頼文：\n${str(p.text ?? p.request)}`,
    validate: (o) => requireObject(o, ["count"]),
  },

  generate: {
    maxTokens: 16000,
    system: `${COMMON}
条件に合う問題を作成します。既存問題と同じ・ほぼ同じ問題は作らないでください。
計算で数値が答えになる問題には、答えを機械で検算できる check 式を必ず付けてください。
${QUESTION_FORMAT}
出力形式：{"questions": [問題, ...]}`,
    buildUser: (p) =>
      `条件：\n${str(p.conditions ?? p.spec ?? p)}\n\n` +
      `既存問題の要約（重複を避けること）：\n${str(p.existing ?? "なし", 8000)}\n\n` +
      `作成数：${str(p.count ?? (isObj(p.conditions) ? p.conditions.count : null) ?? "条件に従う")}` +
      formatGuide(p),
    validate: (o) => {
      const arr = isObj(o) ? o.questions : Array.isArray(o) ? o : null;
      if (!Array.isArray(arr) || arr.length === 0) return { ok: false, reason: "questions 配列がありません" };
      for (let i = 0; i < arr.length; i++) {
        const err = validateQuestion(arr[i]);
        if (err) return { ok: false, reason: `${i + 1} 問目: ${err}` };
      }
      return { ok: true, value: { questions: arr.map((q) => normalizeQuestion(q as Record<string, unknown>)) } };
    },
  },

  solve: {
    maxTokens: 8000,
    system: `${COMMON}
与えられた問題を、正答を知らない受験者として独立に解いてください。
出力形式：
{"answer": "答え（選択式は選択肢の文）", "ai": [選んだ選択肢番号(0始まり)] | null, "work": ["考え方の手順"], "confidence": 0〜1}`,
    buildUser: (p) => {
      // 正答・解説は伏せて渡す
      const q = isObj(p.question) ? { ...p.question } : {};
      for (const k of ["ai", "ans", "alts", "expl", "explBasic", "explAdvanced", "steps", "mistakes", "rubric", "check"]) delete q[k];
      return `問題：\n${str(q)}`;
    },
    validate: (o) => requireObject(o, ["answer"]),
  },

  explain: {
    maxTokens: 8000,
    system: `${COMMON}
問題と正答をもとに解説を作成します。
出力形式：
{"expl": "詳しい解説", "explBasic": "初学者向け", "explAdvanced": "発展", "steps": ["手順"],
 "alts": ["別解"], "mistakes": ["よくある誤答と理由"], "rubric": [{"c": "採点基準", "p": 点}]}`,
    buildUser: (p) => `問題（正答つき）：\n${str(p.question)}\n\n解説の詳しさ：${str(p.detail ?? "標準")}`,
    validate: (o) => {
      const v = requireObject(o, ["expl"]);
      if (!v.ok) return v;
      const r = (o as Record<string, unknown>).rubric;
      if (r != null && (!Array.isArray(r) || !r.every((x) => isObj(x) && typeof x.c === "string" && typeof x.p === "number"))) {
        return { ok: false, reason: "rubric は {c, p} の配列にしてください" };
      }
      return v;
    },
  },

  review: {
    maxTokens: 8000,
    system: `${COMMON}
問題を校閲します。明確性・選択肢の妥当性（正解が 1 つに定まるか、紛らわしい誤答か）・範囲適合・学年適合・難易度・正答の正しさを点検してください。
出力形式：
{"ok": 問題がなければ true,
 "scores": {"clarity": 1〜5, "choices": 1〜5, "scope": 1〜5, "grade": 1〜5, "difficulty": 1〜5, "correctness": 1〜5},
 "issues": [{"field": "対象項目", "severity": "high" | "medium" | "low", "message": "指摘"}],
 "suggestedLevel": "基礎" | "標準" | "応用",
 "fixed": 修正版の問題（共通問題形式、修正不要なら null）}`,
    buildUser: (p) => `問題：\n${str(p.question)}\n\n想定範囲・学年：${str(p.scope ?? "問題の記載どおり")}`,
    validate: (o) => {
      const v = requireObject(o, ["ok", "issues"]);
      if (!v.ok) return v;
      const fixed = (o as Record<string, unknown>).fixed;
      if (fixed != null) {
        const err = validateQuestion(fixed);
        if (err) return { ok: false, reason: `fixed: ${err}` };
      }
      return v;
    },
  },

  plan_material: {
    maxTokens: 8000,
    system: `${COMMON}
教材の目的から、教材の構成案を作ります。
ブロックの種類：heading(text, level) / text(text) / section(title, inst) / question(want: 必要な問題の条件) / pagebreak / table(header, rows, caption) / space(lines)
出力形式：
{"kind": "worksheet" | "summary" | "review" | "drill" | "wordtest" | "quiz" | "test" | "mock" | "entrance" | "answers",
 "title": "題名", "subtitle": "副題",
 "page": {"size": "A4" | "B4" | "A3", "orientation": "portrait" | "landscape", "cols": 1 | 2},
 "blocks": [{"type": "...", ...}], "notes": "作成上の注意"}`,
    buildUser: (p) => `教材の目的・条件：\n${str(p.purpose ?? p.text ?? p)}${formatGuide(p)}`,
    validate: (o) => {
      const v = requireObject(o, ["title", "blocks"]);
      if (!v.ok) return v;
      if (!Array.isArray((o as Record<string, unknown>).blocks)) return { ok: false, reason: "blocks は配列にしてください" };
      return v;
    },
  },

  suggest_review: {
    maxTokens: 8000,
    system: `${COMMON}
学習結果の集計から、つまずきを分析し復習教材を提案します。
出力形式：
{"summary": "全体の傾向",
 "weakPoints": [{"unit": "単元", "subunit": "小単元", "reason": "根拠（正答率など）", "knowledge": ["不足している知識"]}],
 "plan": {"title": "復習教材の題名", "blocks": [{"type": "...", ...}]},
 "want": [{"unit": "単元", "level": "基礎" | "標準" | "応用", "count": 数, "types": ["choice"]}]}`,
    buildUser: (p) => `学習結果の集計：\n${str(p.stats ?? p.results ?? p)}`,
    validate: (o) => requireObject(o, ["summary", "weakPoints"]),
  },

  vary: {
    maxTokens: 8000,
    system: `${COMMON}
与えられた問題と同じ形・同じ難易度で、数値（係数・データ・量）だけを変えた問題を 1 問作ります。
答え・選択肢（誤答はもとの誤答と同じ種類のまちがいから作る）・解説・採点基準も新しい数値に合わせて作り直し、計算を必ず検算してください。
数値が答えになる場合は、答えを機械で検算できる check 式（例 {"expr": "3*4"}）を付けてください。問題の意味や条件が成り立つ数値にすること。
${QUESTION_FORMAT}
出力形式：{"question": 問題, "changes": "どの数値をどう変えたか"}`,
    buildUser: (p) => `元の問題（正答つき）：\n${str(p.question)}`,
    validate: (o) => {
      if (!isObj(o) || !isObj(o.question)) return { ok: false, reason: "question がありません" };
      const err = validateQuestion(o.question);
      if (err) return { ok: false, reason: err };
      return { ok: true, value: { question: normalizeQuestion(o.question as Record<string, unknown>), changes: o.changes ?? "" } };
    },
  },
};

/** モデル出力から JSON を取り出す（コードブロックや前後の文が混じっても読めるように） */
export function extractJson(text: string): unknown {
  const t = text.trim();
  try {
    return JSON.parse(t);
  } catch { /* 続行 */ }
  const fence = t.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fence) {
    try {
      return JSON.parse(fence[1]);
    } catch { /* 続行 */ }
  }
  const starts = [t.indexOf("{"), t.indexOf("[")].filter((i) => i >= 0);
  if (starts.length) {
    const start = Math.min(...starts);
    const end = Math.max(t.lastIndexOf("}"), t.lastIndexOf("]"));
    if (end > start) {
      try {
        return JSON.parse(t.slice(start, end + 1));
      } catch { /* 続行 */ }
    }
  }
  throw new Error("JSON を読み取れません");
}
