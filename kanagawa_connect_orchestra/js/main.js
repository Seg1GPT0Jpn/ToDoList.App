/* =========================================================
   かながわコネクトオーケストラ  main.js
   ========================================================= */

/**
 * サイト共通設定
 * --------------------------------------------------------
 * Instagram の URL が決まったら instagramUrl に設定してください。
 * 空文字のままだと、Instagram への導線は「準備中」表示になります。
 *   例: instagramUrl: "https://www.instagram.com/xxxxx/"
 */
const SITE_CONFIG = {
  instagramUrl: "",
  joinFormUrl:
    "https://docs.google.com/forms/d/e/1FAIpQLSeNVFDq4rLClPT58n83vJLcjM70ODNXvUeHCRUNjm0TzqEUAA/viewform?usp=sharing&ouid=104860576931330456926",
};

(function () {
  "use strict";

  const root = document.documentElement;
  root.classList.remove("no-js");
  root.classList.add("js");

  /* ---------- Mobile navigation ---------- */
  const toggle = document.querySelector(".nav-toggle");
  const nav = document.getElementById("global-nav");

  if (toggle && nav) {
    const setOpen = (open) => {
      toggle.setAttribute("aria-expanded", String(open));
      toggle.setAttribute("aria-label", open ? "メニューを閉じる" : "メニューを開く");
      nav.classList.toggle("is-open", open);
    };

    toggle.addEventListener("click", () => {
      setOpen(toggle.getAttribute("aria-expanded") !== "true");
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && toggle.getAttribute("aria-expanded") === "true") {
        setOpen(false);
        toggle.focus();
      }
    });

    nav.addEventListener("click", (e) => {
      if (e.target.closest("a")) setOpen(false);
    });

    window.matchMedia("(min-width: 960px)").addEventListener("change", (mq) => {
      if (mq.matches) setOpen(false);
    });
  }

  /* ---------- Instagram links ---------- */
  document.querySelectorAll("[data-instagram-link]").forEach((el) => {
    const label = el.querySelector("[data-instagram-label]");
    if (SITE_CONFIG.instagramUrl) {
      el.setAttribute("href", SITE_CONFIG.instagramUrl);
      el.setAttribute("target", "_blank");
      el.setAttribute("rel", "noopener noreferrer");
      el.removeAttribute("aria-disabled");
      el.removeAttribute("tabindex");
      if (label) label.textContent = "Instagram（新しいタブで開きます）";
    } else {
      // URL未設定：リンクとして機能させず「準備中」と明示する
      el.removeAttribute("href");
      el.setAttribute("aria-disabled", "true");
      if (label) label.textContent = "Instagram（準備中）";
    }
  });

  /* ---------- Join form links ---------- */
  document.querySelectorAll("[data-join-form]").forEach((el) => {
    el.setAttribute("href", SITE_CONFIG.joinFormUrl);
  });

  /* ---------- Footer year ---------- */
  document.querySelectorAll("[data-year]").forEach((el) => {
    el.textContent = String(new Date().getFullYear());
  });

  /* ---------- Reveal on scroll ---------- */
  const reveals = document.querySelectorAll(".reveal");
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (!("IntersectionObserver" in window) || reduceMotion) {
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
})();
