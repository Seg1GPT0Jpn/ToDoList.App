// 曲目候補の管理画面（admin.html）
// Google アカウントでログインし、Firestore Security Rules で許可された管理者だけが一覧を閲覧できます。
// （画面側で隠すだけでなく、データの読み取り自体をルールで管理者に限定しています）
import {
  getAuth, connectAuthEmulator, GoogleAuthProvider,
  signInWithPopup, signInWithRedirect, signOut, onAuthStateChanged,
} from "firebase/auth";
import {
  collection, query, orderBy, getDocs, deleteDoc, doc,
} from "firebase/firestore/lite";
import {
  getApp, getDb, isLocal, COLLECTION, CATEGORIES, PARTICIPATION, EMULATOR_PORTS,
} from "./firebase-init.js";

const root = document.querySelector("[data-admin]");

if (root) {
  const $ = (sel) => root.querySelector(sel);
  const views = {
    loading: $("[data-admin-loading]"),
    signedOut: $("[data-admin-signed-out]"),
    denied: $("[data-admin-denied]"),
    panel: $("[data-admin-panel]"),
  };
  const statusEl = $("[data-admin-status]");
  const rowsEl = $("[data-admin-rows]");
  const countEl = $("[data-admin-count]");
  const emptyEl = $("[data-admin-empty]");
  const filterBtns = [...root.querySelectorAll("[data-filter]")];

  let items = [];
  let filter = "all";

  const show = (name) => {
    Object.entries(views).forEach(([key, el]) => {
      el.hidden = key !== name;
    });
  };
  const setStatus = (msg, isError = false) => {
    statusEl.textContent = msg;
    statusEl.classList.toggle("is-error", isError);
  };

  const fmtDate = (ts) => (ts && typeof ts.toDate === "function"
    ? ts.toDate().toLocaleString("ja-JP", { dateStyle: "medium", timeStyle: "short" })
    : "");

  function cell(text, className) {
    const td = document.createElement("td");
    if (className) td.className = className;
    td.textContent = text || "";
    return td;
  }

  function render() {
    const counts = { all: items.length };
    Object.keys(CATEGORIES).forEach((k) => {
      counts[k] = items.filter((it) => it.category === k).length;
    });
    filterBtns.forEach((btn) => {
      const key = btn.dataset.filter;
      btn.setAttribute("aria-pressed", String(key === filter));
      btn.querySelector("[data-count]").textContent = counts[key] ?? 0;
    });

    const list = filter === "all" ? items : items.filter((it) => it.category === filter);
    countEl.textContent = `${filter === "all" ? "すべて" : CATEGORIES[filter]}：${list.length}件`;
    emptyEl.hidden = list.length > 0;

    // 利用者が入力した文字列は textContent でのみ表示（HTMLとして解釈しない）
    rowsEl.replaceChildren(...list.map((it) => {
      const tr = document.createElement("tr");
      tr.append(cell(CATEGORIES[it.category] || it.category, "admin-table__cat"));
      tr.append(cell(it.title, "admin-table__title"));
      tr.append(cell(it.composer || "—", "admin-table__composer"));

      const who = document.createElement("td");
      const nm = document.createElement("span");
      nm.className = "admin-table__name";
      nm.textContent = it.name;
      const mail = document.createElement("a");
      mail.href = `mailto:${it.email}`;
      mail.textContent = it.email;
      const part = document.createElement("span");
      part.className = "admin-table__meta";
      part.textContent = PARTICIPATION[it.participationStatus] || "";
      who.append(nm, mail, part);
      tr.append(who);

      tr.append(cell(it.reason || "—", "admin-table__reason"));
      tr.append(cell(fmtDate(it.timestamp), "admin-table__date"));

      const ops = document.createElement("td");
      const del = document.createElement("button");
      del.type = "button";
      del.className = "admin-table__delete";
      del.textContent = "削除";
      del.setAttribute("aria-label", `「${it.title}」の提案を削除`);
      del.addEventListener("click", () => remove(it));
      ops.append(del);
      tr.append(ops);
      return tr;
    }));
  }

  async function load() {
    setStatus("読み込み中…");
    try {
      const db = await getDb();
      const snap = await getDocs(query(collection(db, COLLECTION), orderBy("timestamp", "desc")));
      items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      show("panel");
      render();
      setStatus(`最終更新：${new Date().toLocaleTimeString("ja-JP")}`);
    } catch (err) {
      if (err && err.code === "permission-denied") {
        show("denied");
        setStatus("");
      } else {
        console.error(err);
        setStatus("一覧を読み込めませんでした。時間をおいて再度お試しください。", true);
      }
    }
  }

  async function remove(it) {
    if (!window.confirm(`「${it.title}」（${it.name}さん）の提案を削除します。元に戻せません。よろしいですか？`)) return;
    try {
      const db = await getDb();
      await deleteDoc(doc(db, COLLECTION, it.id));
      items = items.filter((x) => x.id !== it.id);
      render();
      setStatus("1件削除しました。");
    } catch (err) {
      console.error(err);
      setStatus("削除できませんでした。", true);
    }
  }

  function downloadCsv() {
    const esc = (v) => {
      let s = String(v ?? "");
      if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`; // 表計算ソフトでの数式実行を防ぐ
      return `"${s.replace(/"/g, '""')}"`;
    };
    const head = ["カテゴリー", "曲名", "作曲者", "提案者", "メールアドレス", "参加状況", "理由", "投稿日"];
    const rows = items.map((it) => [
      CATEGORIES[it.category] || it.category, it.title, it.composer, it.name, it.email,
      PARTICIPATION[it.participationStatus] || "", it.reason, fmtDate(it.timestamp),
    ]);
    const csv = [head, ...rows].map((r) => r.map(esc).join(",")).join("\r\n");
    const blob = new Blob(["﻿" + csv], { type: "text/csv;charset=utf-8" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = `program-suggestions-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  }

  filterBtns.forEach((btn) => btn.addEventListener("click", () => {
    filter = btn.dataset.filter;
    render();
  }));

  (async () => {
    let auth;
    try {
      const app = await getApp();
      auth = getAuth(app);
      if (isLocal) {
        connectAuthEmulator(auth, `http://127.0.0.1:${EMULATOR_PORTS.auth}`, { disableWarnings: true });
      }
    } catch (err) {
      console.error(err);
      show("signedOut");
      setStatus("この環境では管理画面を利用できません。公開中のサイト（Firebase Hosting）で開いてください。", true);
      return;
    }

    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: "select_account" });

    root.querySelectorAll("[data-signin]").forEach((btn) => btn.addEventListener("click", async () => {
      setStatus("");
      try {
        await signInWithPopup(auth, provider);
      } catch (err) {
        if (err && (err.code === "auth/popup-blocked" || err.code === "auth/operation-not-supported-in-this-environment")) {
          await signInWithRedirect(auth, provider);
        } else if (err && err.code !== "auth/popup-closed-by-user" && err.code !== "auth/cancelled-popup-request") {
          console.error(err);
          setStatus("ログインできませんでした。もう一度お試しください。", true);
        }
      }
    }));
    root.querySelectorAll("[data-signout]").forEach((btn) => btn.addEventListener("click", () => signOut(auth)));
    root.querySelector("[data-reload]").addEventListener("click", load);
    root.querySelector("[data-csv]").addEventListener("click", downloadCsv);

    onAuthStateChanged(auth, (user) => {
      items = [];
      rowsEl.replaceChildren();
      root.querySelectorAll("[data-admin-email]").forEach((el) => {
        el.textContent = user ? user.email : "";
      });
      if (user) {
        load();
      } else {
        show("signedOut");
        setStatus("");
      }
    });
  })();
}
