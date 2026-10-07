// MyAI: ブラウザ内(WebGPU)で動くローカルLLMチャット。
// 推論エンジンは WebLLM (https://github.com/mlc-ai/web-llm) を使用。
const WEBLLM_URL = "https://esm.run/@mlc-ai/web-llm@0.2";

// 日本語が得意な順に優先表示するモデル(存在するものだけ表示)
const PREFERRED_MODELS = [
  /^Qwen3-1\.7B-q4f16_1/,
  /^Qwen2\.5-1\.5B-Instruct-q4f16_1/,
  /^Qwen3-4B-q4f16_1/,
  /^Qwen2\.5-3B-Instruct-q4f16_1/,
  /^gemma-2-2b-it-q4f16_1/,
  /^Llama-3\.2-3B-Instruct-q4f16_1/,
  /^Qwen3-0\.6B-q4f16_1/,
  /^Qwen2\.5-0\.5B-Instruct-q4f16_1/,
];
const MAX_HISTORY = 20; // モデルに渡す直近メッセージ数(コンテキスト長対策)

const DEFAULT_SETTINGS = {
  aiName: "MyAI",
  systemPrompt:
    "あなたは「MyAI」という名前の、親切で賢い日本語アシスタントです。\n" +
    "- ユーザーの質問に正確かつ簡潔に答えてください。\n" +
    "- 分からないことは推測せず「分かりません」と伝えてください。\n" +
    "- 必要に応じて箇条書きやコード例を使ってください。",
  temperature: 0.7,
  modelId: "",
};

// ---------- storage ----------
const store = {
  get(key, fallback) {
    try { const v = localStorage.getItem(key); return v ? JSON.parse(v) : fallback; }
    catch { return fallback; }
  },
  set(key, value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* 保存不可でも動作は継続 */ }
  },
};

let settings = { ...DEFAULT_SETTINGS, ...store.get("myai.settings", {}) };
let conversations = store.get("myai.conversations", []);
let currentId = store.get("myai.currentId", null);

let webllm = null;
let engine = null;      // 送信可能な状態のエンジン(読み込み中はnull)
let engineInstance = null;
let loadedModel = null;
let generating = false;

// ---------- DOM ----------
const $ = (id) => document.getElementById(id);
const els = {
  title: $("title"), status: $("status"), progress: $("progress"), messages: $("messages"),
  composer: $("composer"), input: $("input"), sendBtn: $("sendBtn"),
  menuBtn: $("menuBtn"), newBtn: $("newBtn"), drawer: $("drawer"), panel: $("panel"),
  convList: $("convList"), modelSelect: $("modelSelect"), loadBtn: $("loadBtn"),
  aiName: $("aiName"), systemPrompt: $("systemPrompt"), temperature: $("temperature"), tempVal: $("tempVal"),
  saveSettings: $("saveSettings"), resetSettings: $("resetSettings"),
  exportBtn: $("exportBtn"), clearBtn: $("clearBtn"),
};

function setStatus(text, progress) {
  els.status.textContent = text;
  if (progress !== undefined) els.progress.style.width = `${Math.round(progress * 100)}%`;
}

// ---------- conversations ----------
function current() {
  let conv = conversations.find((c) => c.id === currentId);
  if (!conv) conv = newConversation();
  return conv;
}

function newConversation() {
  const conv = { id: crypto.randomUUID(), title: "新しい会話", messages: [], createdAt: Date.now() };
  conversations.unshift(conv);
  currentId = conv.id;
  persist();
  return conv;
}

function persist() {
  store.set("myai.conversations", conversations);
  store.set("myai.currentId", currentId);
}

// ---------- rendering ----------
function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

// 最低限のMarkdown: ```コードブロック```、`インライン`、**太字**
function renderMarkdown(text) {
  const parts = text.split(/```(?:[\w+-]*)\n?([\s\S]*?)(?:```|$)/g);
  return parts.map((part, i) => {
    if (i % 2 === 1) return `<pre><code>${escapeHtml(part)}</code></pre>`;
    return escapeHtml(part)
      .replace(/`([^`\n]+)`/g, "<code>$1</code>")
      .replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>");
  }).join("");
}

// Qwen3などの思考過程 <think>...</think> を分離
function splitThinking(text) {
  const m = text.match(/^\s*<think>([\s\S]*?)(<\/think>|$)([\s\S]*)$/);
  if (!m) return { think: "", answer: text };
  return { think: m[1].trim(), answer: m[3].trimStart() };
}

function renderMessageInto(div, role, content) {
  if (role === "user") { div.textContent = content; return; }
  const { think, answer } = splitThinking(content);
  div.innerHTML = (think ? `<div class="think">${escapeHtml(think)}</div>` : "") + renderMarkdown(answer);
}

function renderMessages() {
  const conv = current();
  els.messages.innerHTML = "";
  if (conv.messages.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.innerHTML = `<strong>${escapeHtml(settings.aiName)}</strong><br>` +
      (engine ? "何でも話しかけてください。" : "☰ メニューからモデルを読み込んでください。");
    els.messages.appendChild(empty);
    return;
  }
  for (const m of conv.messages) appendMessage(m.role, m.content);
  scrollToBottom();
}

function appendMessage(role, content) {
  const empty = els.messages.querySelector(".empty");
  if (empty) empty.remove();
  const div = document.createElement("div");
  div.className = `msg ${role}`;
  renderMessageInto(div, role, content);
  els.messages.appendChild(div);
  return div;
}

function scrollToBottom() {
  els.messages.scrollTop = els.messages.scrollHeight;
}

function renderConvList() {
  els.convList.innerHTML = "";
  for (const c of conversations) {
    const li = document.createElement("li");
    if (c.id === currentId) li.className = "active";
    const span = document.createElement("span");
    span.textContent = c.title;
    const del = document.createElement("button");
    del.textContent = "削除";
    del.onclick = (e) => {
      e.stopPropagation();
      if (!confirm(`「${c.title}」を削除しますか？`)) return;
      conversations = conversations.filter((x) => x.id !== c.id);
      if (currentId === c.id) currentId = conversations[0]?.id ?? null;
      persist(); renderAll();
    };
    li.onclick = () => { currentId = c.id; persist(); renderAll(); closeDrawer(); };
    li.append(span, del);
    els.convList.appendChild(li);
  }
}

function renderSettings() {
  els.aiName.value = settings.aiName;
  els.systemPrompt.value = settings.systemPrompt;
  els.temperature.value = settings.temperature;
  els.tempVal.textContent = settings.temperature;
  els.title.textContent = settings.aiName;
}

function renderAll() {
  renderSettings();
  renderConvList();
  renderMessages();
  updateSendState();
}

function updateSendState() {
  if (generating) {
    els.sendBtn.textContent = "停止";
    els.sendBtn.disabled = false;
  } else {
    els.sendBtn.textContent = "送信";
    els.sendBtn.disabled = !engine || !els.input.value.trim();
  }
}

// ---------- drawer ----------
function openDrawer() { renderConvList(); els.drawer.classList.add("open"); }
function closeDrawer() { els.drawer.classList.remove("open"); }

// ---------- model ----------
async function initWebLLM() {
  if (!("gpu" in navigator)) {
    setStatus("この端末/ブラウザはWebGPUに未対応です。最新のChrome・Edge、またはiOS 26以降のSafariでお試しください。");
    return;
  }
  try {
    setStatus("AIエンジンを読み込み中…");
    webllm = await import(WEBLLM_URL);
  } catch (e) {
    setStatus(`AIエンジンの読み込みに失敗しました: ${e.message}`);
    return;
  }
  populateModels();
  setStatus("☰ メニューからモデルを選んで「読み込む」を押してください。");
  // 前回使ったモデルはキャッシュ済みなら自動で読み込む
  if (settings.modelId && await isCached(settings.modelId)) loadModel(settings.modelId);
}

function populateModels() {
  const list = webllm.prebuiltAppConfig.model_list
    .filter((m) => !/embed/i.test(m.model_id) && /q4f16_1|q4f32_1/.test(m.model_id));
  const rank = (id) => {
    const i = PREFERRED_MODELS.findIndex((re) => re.test(id));
    return i === -1 ? Infinity : i;
  };
  list.sort((a, b) => rank(a.model_id) - rank(b.model_id) || a.model_id.localeCompare(b.model_id));

  els.modelSelect.innerHTML = "";
  for (const m of list) {
    const opt = document.createElement("option");
    opt.value = m.model_id;
    const vram = m.vram_required_MB ? ` (約${(m.vram_required_MB / 1024).toFixed(1)}GB)` : "";
    opt.textContent = (rank(m.model_id) < Infinity ? "★ " : "") + m.model_id + vram;
    els.modelSelect.appendChild(opt);
  }
  const saved = list.find((m) => m.model_id === settings.modelId);
  els.modelSelect.value = saved ? saved.model_id : list[0]?.model_id ?? "";
}

async function isCached(modelId) {
  try { return await webllm.hasModelInCache(modelId); } catch { return false; }
}

async function loadModel(modelId) {
  if (!webllm || !modelId) return;
  if (generating) return;
  els.loadBtn.disabled = true;
  engine = null;
  updateSendState();
  try {
    setStatus(`${modelId} を準備中…`, 0);
    const progressCb = (r) => setStatus(r.text, r.progress);
    if (!engineInstance) {
      engineInstance = await webllm.CreateMLCEngine(modelId, { initProgressCallback: progressCb });
    } else {
      engineInstance.setInitProgressCallback(progressCb);
      await engineInstance.reload(modelId);
    }
    engine = engineInstance;
    loadedModel = modelId;
    settings.modelId = modelId;
    store.set("myai.settings", settings);
    setStatus(`準備完了: ${modelId}`, 0);
    renderMessages();
  } catch (e) {
    setStatus(`モデルの読み込みに失敗しました: ${e.message}（端末のメモリ不足の場合は小さいモデルを選んでください）`, 0);
  } finally {
    els.loadBtn.disabled = false;
    updateSendState();
  }
}

// ---------- chat ----------
async function send(text) {
  const conv = current();
  conv.messages.push({ role: "user", content: text });
  if (conv.title === "新しい会話") conv.title = text.slice(0, 30);
  persist();
  appendMessage("user", text);

  const replyDiv = appendMessage("assistant", "…");
  scrollToBottom();
  generating = true;
  updateSendState();

  const history = conv.messages.slice(-MAX_HISTORY).map((m) => ({
    role: m.role,
    // 過去の思考過程はモデルに渡さない(コンテキスト節約)
    content: m.role === "assistant" ? splitThinking(m.content).answer : m.content,
  }));
  const messages = [{ role: "system", content: settings.systemPrompt }, ...history];

  let reply = "";
  try {
    const stream = await engine.chat.completions.create({
      messages, stream: true, temperature: Number(settings.temperature),
    });
    for await (const chunk of stream) {
      reply += chunk.choices[0]?.delta?.content ?? "";
      renderMessageInto(replyDiv, "assistant", reply);
      scrollToBottom();
    }
  } catch (e) {
    reply += `\n\n[エラー: ${e.message}]`;
    renderMessageInto(replyDiv, "assistant", reply);
  } finally {
    generating = false;
    if (reply.trim()) {
      conv.messages.push({ role: "assistant", content: reply });
    } else {
      replyDiv.remove();
    }
    persist();
    updateSendState();
    setStatus(`準備完了: ${loadedModel}`);
  }
}

// ---------- events ----------
els.composer.addEventListener("submit", (e) => {
  e.preventDefault();
  if (generating) { engine?.interruptGenerate(); return; }
  const text = els.input.value.trim();
  if (!text || !engine) return;
  els.input.value = "";
  autoResize();
  send(text);
});

els.input.addEventListener("keydown", (e) => {
  // PCではEnterで送信、Shift+Enterで改行。日本語変換中は送信しない
  if (e.key === "Enter" && !e.shiftKey && !e.isComposing && matchMedia("(pointer: fine)").matches) {
    e.preventDefault();
    els.composer.requestSubmit();
  }
});

function autoResize() {
  els.input.style.height = "auto";
  els.input.style.height = `${Math.min(els.input.scrollHeight, 140)}px`;
}
els.input.addEventListener("input", () => { autoResize(); updateSendState(); });

els.menuBtn.onclick = openDrawer;
els.drawer.addEventListener("click", (e) => { if (e.target === els.drawer) closeDrawer(); });
els.newBtn.onclick = () => { newConversation(); renderAll(); els.input.focus(); };
els.loadBtn.onclick = () => { closeDrawer(); loadModel(els.modelSelect.value); };

els.temperature.oninput = () => { els.tempVal.textContent = els.temperature.value; };
els.saveSettings.onclick = () => {
  settings.aiName = els.aiName.value.trim() || DEFAULT_SETTINGS.aiName;
  settings.systemPrompt = els.systemPrompt.value.trim() || DEFAULT_SETTINGS.systemPrompt;
  settings.temperature = Number(els.temperature.value);
  store.set("myai.settings", settings);
  renderAll();
  closeDrawer();
};
els.resetSettings.onclick = () => {
  if (!confirm("キャラクター設定を初期値に戻しますか？")) return;
  settings = { ...DEFAULT_SETTINGS, modelId: settings.modelId };
  store.set("myai.settings", settings);
  renderAll();
};

els.exportBtn.onclick = () => {
  const blob = new Blob([JSON.stringify(conversations, null, 2)], { type: "application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = `myai-conversations-${new Date().toISOString().slice(0, 10)}.json`;
  a.click();
  URL.revokeObjectURL(a.href);
};
els.clearBtn.onclick = () => {
  if (!confirm("すべての会話を削除しますか？（元に戻せません）")) return;
  conversations = [];
  currentId = null;
  persist();
  renderAll();
};

// ---------- start ----------
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("sw.js").catch(() => {});
}
renderAll();
initWebLLM();
