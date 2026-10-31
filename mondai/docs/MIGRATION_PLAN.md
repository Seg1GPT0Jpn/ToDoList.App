# 移行計画（MIGRATION_PLAN）

## 対象
旧版（〜2026-10-31）の保存データ：
- IndexedDB `mondai-db` v1：`datasets`（取り込んだ zip）
- localStorage：`mondai.cart`（作業中のプリント）、`mondai.saved`（保存したプリント）、`mondai.settings`（設定）

## 方法（自動・1 回だけ・元データは消さない）
1. IndexedDB を v2 に上げ、ストア（questions, versions, materials, materialVersions, history, aiJobs, results, ratings, kv）を追加。既存の `datasets` はそのまま使う。
2. 初回起動時に `js/core/migrate.js` が、`mondai.saved` の各プリントと `mondai.cart` を「教材」に変換して保存（`fromLegacy()`）。カートの教材は「作業中の教材」にする。
3. 済んだ印 `migrated.v2` を記録。localStorage の旧データは消さない（念のため残す）。
4. 取り込み済みの問題は形を変えずに読み、表示用の単元名などは読み込み時に付ける（`applyUnitNames`）。

## 問題データの形の変更
既存の共通問題形式に項目を足しただけで、既存の項目の意味は変えていない（後方互換）。新しい項目がない問題は `normalizeQuestion()` が既定値を補う。

## 戻し方
アプリのファイルを旧版に戻しても、`datasets` と localStorage の旧データが残っているので旧版で開ける（新版で作った教材・問題は旧版では見えない）。

## 確認
E2E テスト「移行：旧版のカートと保存プリントが教材になる（元データは残る）」で確認済み。
