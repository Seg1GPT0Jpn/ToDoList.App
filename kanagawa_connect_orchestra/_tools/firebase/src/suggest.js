// 曲目候補フォーム（suggest.html）
// 送信内容は Firestore の programSuggestions コレクションに 1曲 = 1件 で保存します。
import { collection, doc, writeBatch, serverTimestamp } from "firebase/firestore/lite";
import { getDb, COLLECTION, CATEGORIES } from "./firebase-init.js";

const form = document.querySelector("[data-suggest-form]");

if (form) {
  const summary = form.querySelector("[data-error-summary]");
  const summaryList = summary.querySelector("ul");
  const status = form.querySelector("[data-form-status]");
  const submitBtn = form.querySelector("[type=submit]");
  const thanks = document.querySelector("[data-thanks]");
  const categoryBoxes = [...form.querySelectorAll('input[name="category"]')];

  // カテゴリーの選択に合わせて曲名の入力欄を表示
  const syncBlocks = () => {
    categoryBoxes.forEach((box) => {
      const block = form.querySelector(`[data-song="${box.value}"]`);
      block.hidden = !box.checked;
      block.querySelectorAll("input, textarea").forEach((el) => {
        el.disabled = !box.checked;
      });
    });
  };
  categoryBoxes.forEach((box) => box.addEventListener("change", () => {
    syncBlocks();
    clearError("category");
  }));
  syncBlocks();

  // ---------- エラー表示 ----------
  function fieldError(id, message) {
    const el = document.getElementById(`${id}-error`);
    const input = document.getElementById(id);
    if (el) {
      el.textContent = message;
      el.hidden = false;
    }
    if (input) input.setAttribute("aria-invalid", "true");
  }

  function clearError(id) {
    const el = document.getElementById(`${id}-error`);
    const input = document.getElementById(id);
    if (el) {
      el.textContent = "";
      el.hidden = true;
    }
    if (input) input.removeAttribute("aria-invalid");
  }

  form.addEventListener("input", (e) => {
    if (e.target.id) clearError(e.target.id);
  });

  const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

  function validate() {
    const errors = [];
    const add = (id, message) => {
      fieldError(id, message);
      errors.push({ id, message });
    };
    form.querySelectorAll(".field__error").forEach((el) => {
      el.hidden = true;
      el.textContent = "";
    });
    form.querySelectorAll("[aria-invalid]").forEach((el) => el.removeAttribute("aria-invalid"));

    const name = form.elements.name.value.trim();
    const email = form.elements.email.value.trim();
    if (!name) add("sg-name", "お名前（呼ばれたい名前）を入力してください。");
    if (!email) add("sg-email", "メールアドレスを入力してください。");
    else if (!EMAIL_RE.test(email)) add("sg-email", "メールアドレスの形式を確認してください（例：name@example.com）。");

    const checked = categoryBoxes.filter((b) => b.checked);
    if (!checked.length) add("sg-category", "提案するカテゴリーを1つ以上選んでください。");
    checked.forEach((box) => {
      const id = `sg-${box.value}-title`;
      if (!document.getElementById(id).value.trim()) {
        add(id, `${CATEGORIES[box.value]}の「演奏してみたい曲名」を入力してください。`);
      }
    });
    return errors;
  }

  function showSummary(errors) {
    summaryList.replaceChildren(
      ...errors.map(({ id, message }) => {
        const li = document.createElement("li");
        const a = document.createElement("a");
        a.href = `#${id}`;
        a.textContent = message;
        a.addEventListener("click", (e) => {
          e.preventDefault();
          const target = document.getElementById(id);
          (target.matches("fieldset") ? target.querySelector("input") : target).focus();
        });
        li.append(a);
        return li;
      })
    );
    summary.hidden = false;
    summary.focus();
  }

  // ---------- 送信 ----------
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    status.textContent = "";
    status.classList.remove("is-error");

    // スパム対策：人には見えない入力欄に値があれば送信しない
    if (form.elements.website.value) {
      showThanks();
      return;
    }

    const errors = validate();
    if (errors.length) {
      showSummary(errors);
      return;
    }
    summary.hidden = true;

    const base = {
      name: form.elements.name.value.trim(),
      email: form.elements.email.value.trim(),
      participationStatus: form.elements.participation.value || "",
    };

    submitBtn.disabled = true;
    submitBtn.setAttribute("aria-busy", "true");
    status.textContent = "送信しています…";

    try {
      const db = await getDb();
      const batch = writeBatch(db);
      categoryBoxes.filter((b) => b.checked).forEach((box) => {
        const key = box.value;
        batch.set(doc(collection(db, COLLECTION)), {
          ...base,
          category: key,
          title: document.getElementById(`sg-${key}-title`).value.trim(),
          composer: document.getElementById(`sg-${key}-composer`).value.trim(),
          reason: document.getElementById(`sg-${key}-reason`).value.trim(),
          timestamp: serverTimestamp(),
        });
      });
      await batch.commit();
      showThanks();
    } catch (err) {
      console.error(err);
      status.classList.add("is-error");
      status.textContent = err && err.message === "firebase-config-unavailable"
        ? "現在この環境からは送信できません。公開中のサイトから送信するか、時間をおいて再度お試しください。"
        : "送信できませんでした。通信環境を確認して、もう一度お試しください。解決しない場合はお問い合わせページのメールアドレスまでご連絡ください。";
    } finally {
      submitBtn.disabled = false;
      submitBtn.removeAttribute("aria-busy");
    }
  });

  function showThanks() {
    // 続けて提案するときのために、お名前とメールアドレスは残す
    const keep = { name: form.elements.name.value, email: form.elements.email.value };
    form.hidden = true;
    form.reset();
    form.elements.name.value = keep.name;
    form.elements.email.value = keep.email;
    syncBlocks();
    thanks.hidden = false;
    thanks.focus();
    thanks.scrollIntoView({ block: "start" });
  }

  // 「続けて提案する」
  document.querySelectorAll("[data-suggest-again]").forEach((btn) => {
    btn.addEventListener("click", () => {
      thanks.hidden = true;
      form.hidden = false;
      status.textContent = "";
      form.elements.name.focus();
    });
  });
}
