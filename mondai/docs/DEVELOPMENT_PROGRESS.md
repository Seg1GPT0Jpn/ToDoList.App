# 進捗・再開メモ（DEVELOPMENT_PROGRESS）

最終更新：2026-10-31

## 完了
- Phase 0〜6 の実装（詳細と実装状況は `docs/FUNCTIONAL_REQUIREMENTS.md`）
- テスト：ロジックの単体テスト 111 件・DB の権限テスト 48 件（PGlite で実際の SQL を実行）・E2E 28 件（Playwright）すべて成功。型検査（tsc --checkJs）エラーなし。

## 外部サービスの設定が必要で、実環境では未確認のもの
- Supabase：SQL（`supabase/migrations/0001_init.sql`）は PGlite で検証済み。実際の Supabase プロジェクトへの適用・ログイン（メールのリンク）・招待・共有・レビューは、設定後に確認が必要。
- AI：Edge Function（`supabase/functions/ai/`）は型検査のみ。Deno での実行と Claude API の呼び出しは未確認。Supabase の無料プランでは Edge Function の実行時間に上限があるため、問題生成は 1 回 5 問ずつに分けている。

## 既知の問題・制限
- 内蔵問題に「数値だけ違う」問題が 4 組ある（BI-HS-MATH1-U04-B08/S10、BI-HS-MATH3-U01-S06/A05、BI-HS-MATHA-U03-B05/S08、BI-HS-MATHA-U03-B06/S09）。誤りではないが、同じテストに並ぶと似て見える。
- 同時編集（同じ教材を複数人が同時に編集）は未対応。チームでは共有した教材をコピーして編集し、レビューで承認する方式。
- 数値を変えたテストの別バージョンは未対応（問題順・選択肢順の入れかえのみ）。
- 図形の作図機能はない（画像の挿入で代用）。
- PDF はブラウザの印刷機能で作る。ヘッダー・フッター・ページ番号は Chrome / Edge（131 以降）で表示される。
- データは端末ごとの保存（IndexedDB）。端末をまたぐには「バックアップ」か、ログインしてワークスペースに共有する。

## 次にやるなら
1. 実際の Supabase プロジェクトで SQL・Edge Function をデプロイし、`supabase/README.md` の手順で動作確認。
2. 同じ教材の同時編集（Supabase Realtime）。
3. 数値替え版の自動生成（AI＋機械検算＋再検証）。
4. 学習結果の解答時間の記録と分析。

## テストの実行方法
```bash
cd mondai
npm install
npm test               # 単体テスト＋DB の権限テスト
npm run typecheck      # 型検査
npm run test:e2e       # ブラウザでの通しテスト（Playwright と Chromium が必要）
```
