# 現状調査（CURRENT_SYSTEM_AUDIT）

調査日：2026-10-31／対象：`main`（d333017 時点）

## リポジトリ構成
| パス | 内容 |
| --- | --- |
| `/index.html`, `/manifest.json`, `/sw.js`, `/icon-512.png` | 既存の「日課ルーティン」ToDo アプリ（本開発の対象外。触らない） |
| `/mondai/` | プリント作成アプリ（本開発の対象） |
| `/mondai/index.html` | 4タブの1ページアプリ（データ／問題をえらぶ／単語・用語テスト／プリント） |
| `/mondai/js/db.js` | IndexedDB `mondai-db` v1、ストア `datasets`（取り込みデータを丸ごと保存） |
| `/mondai/js/importer.js` | zip/json を読み、3形式（かながわ・つづり・予想問題）＋単語帳・用語カードを共通形式に変換 |
| `/mondai/js/render.js` | 問題・本文・図・表・解答欄・解答解説の HTML 生成、選択肢の並べ替え、大問まとめ |
| `/mondai/js/app.js` | 画面制御（絞り込み・カート・設定・保存・単語テスト）約600行 |
| `/mondai/js/unit-names.js`, `unit-groups.js` | つづり単元コード → 日本語単元名・統合単元名の対応表 |
| `/mondai/builtin/hs.json` | 内蔵問題 3,840 問（高校5教科96単元×40問） |
| `/mondai/css/style.css` | 画面・印刷用 CSS |

## 技術構成
- ビルドなしの素の HTML/CSS/JS（IIFE＋グローバル）。外部ライブラリは CDN：KaTeX 0.16.9、JSZip 3.10.1。
- 公開：GitHub Pages（`main` ブランチのルート）。`/mondai/` で公開。
- テスト：リポジトリ内には無し（これまでは Playwright スクリプトを作業環境で実行して確認）。

## 既存機能一覧
1. zip/json の取り込み（IndexedDB 保存、同種データは ID でマージ）、データ削除
2. 内蔵問題の自動読み込み（`builtin/hs.json`）
3. 絞り込み：教科・段階・学年・科目・単元（複数選択）・難易度・形式・出典・区分・キーワード（AND）
4. ランダム追加（基礎／標準／応用／指定なしの数を指定）、ページ単位の一括追加
5. 単語・用語テスト生成（意味／見出し／4択／例文空所）
6. プリント：タイトル・注意書き・選択肢記号・段組・解答欄（問題下／別紙）・解答解説・文字サイズ・配点（データ／均等100点）・選択肢シャッフル・名前欄・日付・出典表示・大問まとめ（形式／単元）
7. プリントの保存（localStorage `mondai.saved`）、カート（`mondai.cart`）、設定（`mondai.settings`）
8. 印刷／PDF 保存（ブラウザ印刷）
9. 数式（KaTeX）、下線・傍線・空欄記法、SVG 図（無害化）、簡易グラフ、表、共通本文

## 既存データ形式（共通問題形式）
`{ id, src, stage, subj, course, grade, unit, subunit, uord, ucode, set, cat, type, stem, sentence, choices[], cl[], ai[], ans, expl, steps[], fig, table, sid, level, lines, grid, pts, rubric[{c,p}], subs[], compact }`
type：`choice / multi / order / tf / short / written / steps`

## 確認した問題点・制約
- 問題の新規作成・編集・削除ができない（取り込み・内蔵のみ）。
- 保存データが localStorage と IndexedDB に分散。バックアップ手段がない。
- プリントはカート＋設定のみで、見出し・自由テキスト・改ページ等の教材編集ができない。
- 用紙サイズ（A4固定）・向き・余白・ページ番号・ヘッダー/フッターが設定できない。
- ダークモードなし。スマホでは絞り込み欄が長く操作しづらい。
- 検索は AND のみ（OR・除外・タグなし）。類似問題の検出なし。
- 認証・共有・AI 連携なし（サーバーが無いため）。
- 自動テストがリポジトリに無い。
