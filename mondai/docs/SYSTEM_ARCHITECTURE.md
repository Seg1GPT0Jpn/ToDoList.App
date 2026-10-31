# システム構成（SYSTEM_ARCHITECTURE）

## 方針と判断理由
| 項目 | 採用 | 理由 |
| --- | --- | --- |
| フロント | ビルド不要の **ES モジュール**（`<script type="module">`）＋ **JSDoc 型注釈を `tsc --checkJs` で型検査** | GitHub Pages のブランチ公開をそのまま使える（Pages の設定変更・ビルド工程が不要）。TypeScript の型検査の利点は得つつ、既存 JS を段階的に移行できる |
| サーバー | **Supabase**（Auth・Postgres・行単位セキュリティ RLS・Edge Functions） | ユーザー選択。無料枠で認証・DB・サーバー関数がそろい、権限をサーバー側（RLS）で強制できる |
| AI | **Claude（Anthropic）** を Supabase Edge Function 経由で呼ぶ。プロバイダー抽象化層あり | ユーザー選択。API キーはサーバーの秘密情報にのみ置く |
| ローカル保存 | IndexedDB（v2 で問題・教材・履歴などのストアを追加） | オフライン・未ログインでも全機能（AI・チーム以外）が動く |
| 数式 | KaTeX（既存） | |
| 計算検証 | ブラウザ側の式評価（自前の安全な数式パーサ） | AI の自己申告だけに頼らず、数値の答えを機械で検算する |
| テスト | Vitest（ロジック）＋ Playwright（E2E）＋ PGlite（RLS の検証） | Docker 不要で DB の権限ルールまでテストできる |

## レイヤー
```
mondai/
  index.html            アプリの枠（ナビ・各ページの入れ物）
  js/
    main.js             起動・ルーティング
    core/               どの画面にも依存しない土台
      db.js             IndexedDB（v2）とリポジトリ
      events.js         変更通知
      util.js           ID・日時・エスケープ等
      backup.js         バックアップ／復元
    domain/             業務ロジック（DOM に触らない → Vitest でテスト）
      question.js       問題モデル・検証・正規化・版管理
      search.js         検索（AND/OR/除外/タグ/項目指定）
      similarity.js     類似問題検出
      material.js       教材（ページ・ブロック）モデル
      exam.js           テスト自動編成・配点・複数バージョン
      answersheet.js    解答欄の自動生成
      csv.js            CSV 入出力
      mathcheck.js      数式の安全な評価（検算）
    data/               取り込み・内蔵データ
      importer.js, unit-names.js, unit-groups.js
    render/             印刷用 HTML 生成（render.js を移行）
    ai/                 AI クライアント（Edge Function 呼び出し・ジョブ履歴）
    cloud/              Supabase クライアント・同期・チーム
    ui/                 各ページ（home, bank, studio, editor, exam, answers, library, team, analytics, settings）
  supabase/             DB マイグレーション（SQL・RLS）と Edge Function
  tests/                unit / e2e / db
  docs/                 本資料一式
```

## データの流れ
- 取り込みデータ・内蔵問題は「読み取り専用の元データ」。編集すると **同じ ID のユーザー版**を `questions` ストアに保存して上書き表示する（元データは消さない）。
- 教材は問題を **スナップショット（使用時点のコピー）＋参照 ID・版番号**で持つ。問題バンクが更新されても過去の教材は変わらない。差分がある場合は「最新版に更新」を選べる。
- ログイン中は、ワークスペースに共有した問題・教材を Supabase と同期する。個人のローカルデータは明示的に共有するまでサーバーに送らない。
