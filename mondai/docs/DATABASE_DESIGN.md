# データベース設計（DATABASE_DESIGN）

ローカル（IndexedDB）とクラウド（Supabase Postgres）で **同じ形のレコード**を使う。

## 1. 問題（Question）
共通問題形式（既存）を拡張する。既存キーはそのまま有効（後方互換）。

| キー | 型 | 内容 |
| --- | --- | --- |
| `id` | string | 一意 ID。ユーザー作成は `U-` + ULID、AI 生成は `AI-` + ULID |
| `rev` | number | 版番号（1から） |
| `type` | string | `choice` `multi` `order` `tf` `short` `written` `steps`（`QUESTION_TYPES` に登録すれば追加可能） |
| `stem`, `sentence` | string | 問題文・付属の文 |
| `choices` | string[] | 選択肢 |
| `ai` | number[] | 正解の選択肢番号（choice/multi/order） |
| `ans` | string | 正答（短答・記述・正誤） |
| `alts` | string[] | 別解・許容解 |
| `expl` | string | 解説 |
| `explBasic`, `explAdvanced` | string | 初学者向け・発展解説 |
| `steps` | string[] | 解説の手順 |
| `mistakes` | string[] | よくある誤答 |
| `rubric` | {c,p}[] | 採点基準・部分点 |
| `pts` | number | 配点 |
| `time` | number | 想定解答時間（秒） |
| `stage` `subj` `course` `grade` `field` `unit` `subunit` | string | 段階・教科・科目・学年・分野・単元・小単元 |
| `level` | `基礎`/`標準`/`応用` | 難易度 |
| `knowledge` | string[] | 必要な知識 |
| `intent` | string | 出題意図 |
| `src` | string | 出典（`内蔵` `かながわ` `つづり` `予想問題` `自作` `AI` など） |
| `origin` | `builtin`/`imported`/`user`/`ai` | 由来 |
| `author` | string | 作成者 |
| `createdAt`, `updatedAt` | ISO 文字列 | |
| `status` | `unverified`/`verifying`/`verified`/`approved`/`needs_fix` | 検証状態 |
| `tags` | string[] | タグ |
| `related` | string[] | 関連問題 ID |
| `check` | {expr, expect} | 計算検証用の式（任意） |
| `fig` `table` `sid` `lines` `grid` `subs` `cl` `compact` | | 既存どおり |
| `deleted` | boolean | 論理削除（元データの非表示に使う） |

### 版管理
`questionVersions` ストアに `{ id, rev, data, savedAt, note }` を保存。編集のたびに旧版を退避する。

## 2. 教材（Material）
```
Material {
  id, kind, title, subtitle, notes, tags[], folder, author,
  createdAt, updatedAt, rev, status ('draft'|'review'|'approved'|'published'|'archived'),
  page: { size:'A4'|'B4'|'A3', orientation:'portrait'|'landscape', margin:mm, header, footer, pageNumbers:bool, cols:1|2, font },
  print: { labels, answer:'inline'|'sheet'|'none', key:'expl'|'ans'|'none', points, group, shuffle, name, date, meta, seed },
  blocks: Block[],
  exam?: ExamSpec
}
Block =
  { id, type:'heading', text, level }
| { id, type:'text', text }                      // 数式・下線記法可
| { id, type:'section', title, inst }            // 大問の見出し
| { id, type:'question', ref, rev, q, pts? }     // q は使用時点のスナップショット
| { id, type:'pagebreak' }
| { id, type:'table', header[], rows[][], caption }
| { id, type:'image', src(dataURL), alt, width }
| { id, type:'space', lines }                    // 自由な解答欄・メモ欄
```
`kind`：`worksheet`（授業プリント）`summary`（要点まとめ）`review`（復習）`drill`（問題集）`wordtest`（単語テスト）`quiz`（小テスト）`test`（定期テスト）`mock`（模擬試験）`entrance`（入試対策）`answers`（解答集）など。テンプレートは kind ごとの初期ブロック・初期設定。

## 3. テスト仕様（ExamSpec）
`{ timeMin, total, sections:[{title, type?, count}], levelRatio:{基礎,標準,応用}, unitRatio:{unit:weight}, typeRatio, include:{subj,course,units[]}, exclude:{units[], tags[]}, versions:['A','B'] }`
配点は合計＝満点になるよう自動調整し、保存時に検証する。

## 4. その他
| ストア／テーブル | 内容 |
| --- | --- |
| `history` | 操作履歴 `{id, at, action, target, detail}` |
| `aiJobs` | AI 実行履歴 `{id, at, action, input, output, model, tokens, status}` |
| `results` | 学習結果 `{id, materialId, questionId, learner, correct(bool/score), timeSec, at}`（手入力・CSV 取り込み） |
| `ratings` | 問題評価 `{questionId, stars, comment, at}` |
| `settings` | アプリ設定（Supabase URL・anon key、AI 利用、テーマ等） |
| `datasets` | 既存（取り込みデータ） |

## 5. Supabase（クラウド）
| テーブル | 主な列 | RLS |
| --- | --- | --- |
| `profiles` | id(=auth.uid), display_name | 本人のみ更新、同じワークスペースのメンバーは閲覧 |
| `workspaces` | id, name, owner_id, personal(bool) | メンバーのみ閲覧、owner/admin のみ更新 |
| `workspace_members` | workspace_id, user_id, role(owner/admin/editor/reviewer/viewer) | メンバーは閲覧、owner/admin のみ追加・変更 |
| `invitations` | workspace_id, email, role, token | owner/admin のみ |
| `questions` | id, workspace_id, data jsonb, rev, status, created_by, updated_at | メンバー閲覧、editor 以上が作成・更新 |
| `question_versions` | question_id, rev, data | 閲覧はメンバー、追加はトリガー |
| `materials` | id, workspace_id, data jsonb, status, created_by | 同上。`published` 以外は viewer に非表示 |
| `reviews` | target_type, target_id, workspace_id, state, reviewer_id, comment | reviewer 以上が承認・差し戻し |
| `comments` | target_type, target_id, workspace_id, body, author_id | メンバー閲覧・作成、本人のみ削除 |
| `history` | workspace_id, actor_id, action, target | メンバー閲覧、挿入のみ |
| `ai_jobs` | user_id, workspace_id, action, model, tokens, status | 本人とワークスペース管理者のみ閲覧。挿入は Edge Function（service role） |
| `learning_results` | workspace_id, material_id, question_id, learner, score | メンバー閲覧、editor 以上が挿入 |

個人の教材は個人ワークスペース（`personal=true`、メンバーは本人のみ）に置くので初期状態で非公開。チームへの共有は **コピーを作る**（元の個人教材と分離）。
