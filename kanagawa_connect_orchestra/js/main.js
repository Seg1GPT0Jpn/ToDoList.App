/* =========================================================
   かながわコネクトオーケストラ  main.js
   - スマートフォン用ナビゲーション
   - フッターの年表示
   - スクロール時のフェードイン
   リンク先（参加希望フォーム・Instagram など）はすべて HTML に直接記載しています。
   ========================================================= */

(function () {
  "use strict";

  const root = document.documentElement;
  root.classList.remove("no-js");
  root.classList.add("js");

  /* ---------- Mobile navigation ---------- */
  const toggle = document.querySelector(".nav-toggle");
  const nav = document.getElementById("global-nav");

  if (toggle && nav) {
    const label = toggle.querySelector("[data-nav-label]");
    const isOpen = () => toggle.getAttribute("aria-expanded") === "true";

    const setOpen = (open) => {
      toggle.setAttribute("aria-expanded", String(open));
      if (label) label.textContent = open ? "メニューを閉じる" : "メニューを開く";
      nav.classList.toggle("is-open", open);
    };

    toggle.addEventListener("click", () => setOpen(!isOpen()));

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && isOpen()) {
        setOpen(false);
        toggle.focus();
      }
    });

    // メニュー外をタップしたら閉じる
    document.addEventListener("click", (e) => {
      if (isOpen() && !nav.contains(e.target) && !toggle.contains(e.target)) {
        setOpen(false);
      }
    });

    // リンクを選んだら閉じる（同じページ内の移動でもメニューが残らないように）
    nav.addEventListener("click", (e) => {
      if (e.target.closest("a")) setOpen(false);
    });

    // PC幅になったら状態をリセット
    const desktop = window.matchMedia("(min-width: 1000px)");
    const onChange = (mq) => {
      if (mq.matches) setOpen(false);
    };
    if (desktop.addEventListener) {
      desktop.addEventListener("change", onChange);
    } else if (desktop.addListener) {
      desktop.addListener(onChange); // 古いSafari向け
    }

    // ブラウザの「戻る」でキャッシュから復帰した際にメニューを閉じる
    window.addEventListener("pageshow", () => setOpen(false));
  }

  /* ---------- Footer year ---------- */
  const year = String(new Date().getFullYear());
  document.querySelectorAll("[data-year]").forEach((el) => {
    el.textContent = year;
  });

  /* ---------- Reveal on scroll ---------- */
  const reveals = document.querySelectorAll(".reveal");
  if (reveals.length) {
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduceMotion || !("IntersectionObserver" in window)) {
      reveals.forEach((el) => el.classList.add("is-visible"));
    } else {
      const io = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              entry.target.classList.add("is-visible");
              io.unobserve(entry.target);
            }
          });
        },
        { rootMargin: "0px 0px -10% 0px", threshold: 0.05 }
      );
      reveals.forEach((el) => io.observe(el));
    }
  }
})();
