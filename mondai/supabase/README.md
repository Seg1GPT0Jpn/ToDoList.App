# クラウド（Supabase）とAIの設定手順

この手順は、プログラミングの経験がなくても進められるように書いています。
クラウドを設定しなくても、アプリは自分のパソコンの中（ブラウザ）だけで使えます。
設定すると「チームでの共有・レビュー」と「AI による問題作成」が使えるようになります。

所要時間：30〜40 分ほど。費用：Supabase は無料プランで足ります（AI の利用料は Anthropic に別途かかります）。

---

## 0. 大事な注意（鍵の扱い）

Supabase と Anthropic では、いくつかの「鍵（キー）」が出てきます。扱いを間違えないでください。

| 鍵 | どこに入れるか | 公開してよいか |
| --- | --- | --- |
| **Project URL**（`https://xxxx.supabase.co`） | アプリの「設定」画面 | よい |
| **anon key**（public key） | アプリの「設定」画面 | **よい**。だれでも見られますが、データの読み書きの権限はデータベース側の「行単位セキュリティ（RLS）」で守られているので安全です |
| **service_role key**（secret key） | どこにも入れない（Supabase が Edge Function に自動で渡します） | **絶対にだめ**。RLS を無視してすべてのデータを読み書きできる鍵です。ブラウザ・アプリの設定画面・GitHub に入れないでください |
| **Anthropic API キー**（`sk-ant-...`） | Supabase の「Edge Function の秘密情報」だけ | **絶対にだめ**。ブラウザ・アプリの設定画面・GitHub に入れないでください |

万一、service_role key や Anthropic API キーを公開してしまったら、すぐにそれぞれの管理画面で鍵を作り直して（ローテーション）ください。

---

## 1. Supabase のプロジェクトを作る

1. <https://supabase.com> を開き、「Start your project」から GitHub アカウントなどでサインアップします。
2. 「New project」を押します。
   - **Name**：`mondai` など分かりやすい名前
   - **Database Password**：「Generate a password」で作り、安全な場所に控えます（このあとの手順では使いません）
   - **Region**：`Northeast Asia (Tokyo)` を選ぶと速くなります
   - **Plan**：Free
3. 「Create new project」を押し、準備ができるまで 1〜2 分待ちます。

## 2. データベースの表と権限を作る（SQL を貼り付けて実行）

1. 左のメニューから **SQL Editor** を開きます。
2. 「New query」を押します。
3. このリポジトリの `mondai/supabase/migrations/0001_init.sql` をテキストエディタ（またはGitHub上の「Raw」表示）で開き、**全文をコピー**して SQL Editor に貼り付けます。
4. 右下の **Run** を押します。「Success. No rows returned」と出れば完了です。
   - 「すでに存在します（already exists）」のような誤りが出た場合は、同じ SQL を 2 回目に実行した可能性があります。新しいプロジェクトでやり直すか、管理者に相談してください。
5. 左メニューの **Table Editor** を開き、`profiles` `workspaces` `questions` などの表ができていることを確認します。
   各表に「RLS enabled」と表示されていれば、権限の設定も入っています。

> 作られる主なもの
> - 表：profiles / workspaces / workspace_members / invitations / questions / question_versions / materials / reviews / comments / history / ai_jobs / learning_results
> - 新規ユーザー登録時に「個人ワークスペース」を自動作成する仕組み
> - 問題を編集するたびに旧版を自動で保存する仕組み
> - 役割（owner・admin・editor・reviewer・viewer）ごとの読み書きの制限

## 3. メールでのログインを設定する

1. 左メニューの **Authentication** → **Sign In / Providers**（または「Providers」）を開き、**Email** が有効（Enabled）になっていることを確認します。
   - ログインはメールに届くリンクを押す方式（マジックリンク）です。パスワードは使いません。
2. **Authentication** → **URL Configuration** を開きます。
   - **Site URL**：`https://seg1gpt0jpn.github.io/ToDoList.App/mondai/`
   - **Redirect URLs** に「Add URL」で次を追加します：
     - `https://seg1gpt0jpn.github.io/ToDoList.App/mondai/`
     - `https://seg1gpt0jpn.github.io/ToDoList.App/mondai/**`
   - 「Save」を押します。
3. （任意）無料プランでは送れるメールの数に上限があります（1 時間に数通程度）。
   先生が多い学校で使う場合は **Authentication** → **Emails** → **SMTP Settings** で学校や会社のメールサーバーを設定してください。

## 4. AI のサーバー関数（Edge Function）を置く

AI 機能を使わない場合、この手順は飛ばしてかまいません（チーム機能は使えます）。

### 4-1. Anthropic の API キーを用意する

1. <https://console.anthropic.com> でアカウントを作り、「Billing」で支払い方法を登録します。
2. 「API Keys」→「Create Key」でキーを作り、表示された `sk-ant-...` を控えます（この画面を閉じると二度と表示されません）。

### 4-2. Supabase CLI で関数をデプロイする

パソコンに「ターミナル」（Windows は「PowerShell」）で次の操作をします。

1. Supabase CLI を入れます（どれか 1 つ）。
   - Mac：`brew install supabase/tap/supabase`
   - Windows：`scoop bucket add supabase https://github.com/supabase/scoop-bucket.git` → `scoop install supabase`
   - Node.js がある場合：`npx supabase --version` で毎回 `npx supabase ...` として使えます
2. このリポジトリをダウンロード（GitHub の「Code」→「Download ZIP」を展開、または `git clone`）し、ターミナルで `mondai` フォルダに移動します。
   ```
   cd ToDoList.App/mondai
   ```
3. ログインして、自分のプロジェクトにつなぎます。`<project-ref>` は Supabase の Project Settings → General にある「Reference ID」（`https://<project-ref>.supabase.co` の部分）です。
   ```
   supabase login
   supabase link --project-ref <project-ref>
   ```
4. 関数をデプロイします。
   ```
   supabase functions deploy ai
   ```
5. 秘密情報（シークレット）を登録します。`sk-ant-...` は 4-1 で控えたキーに置き換えてください。
   ```
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-xxxxxxxx
   supabase secrets set AI_MODEL=claude-opus-5-5
   supabase secrets set AI_DAILY_TOKEN_LIMIT=200000
   ```
   - `AI_MODEL`：使うモデル。省略すると `claude-opus-5-5`
   - `AI_DAILY_TOKEN_LIMIT`：1 人が 1 日（日本時間の午前 9 時に切り替わります）に使えるトークン数の上限。省略すると 200,000
   - 任意：`AI_EFFORT`（`low`/`medium`/`high`/`xhigh`/`max`、既定 `high`。低いほど安く速い）、`ALLOWED_ORIGIN`（呼び出しを許すサイト。例 `https://seg1gpt0jpn.github.io`。既定はすべて許可）、`AI_FALLBACKS=off`（安全判定で断られたときに別モデルへ自動で切り替える機能を止める）
   - `SUPABASE_URL` `SUPABASE_ANON_KEY` `SUPABASE_SERVICE_ROLE_KEY` は Supabase が自動で関数に渡すので、登録は不要です。

> CLI を使わずに、Supabase の画面（Edge Functions → 「Deploy a new function」→「Via Editor」）から作ることもできます。
> その場合は関数名を `ai` にし、`supabase/functions/ai/` の 4 ファイル（`index.ts` `prompts.ts` `providers/types.ts` `providers/anthropic.ts`）を同じフォルダ構成で作成してください。
> 秘密情報は Edge Functions → **Secrets** で登録できます。

## 5. アプリに接続情報を入れる

1. Supabase の **Project Settings** → **API**（または「Data API」と「API Keys」）を開きます。
2. 次の 2 つをコピーします。
   - **Project URL**（`https://xxxx.supabase.co`）
   - **anon public** key（`eyJ...` で始まる長い文字列、または `sb_publishable_...`）
   - ※ `service_role` / `secret` と書かれた鍵は**コピーしないでください**。
3. アプリ <https://seg1gpt0jpn.github.io/ToDoList.App/mondai/> を開き、**設定** 画面の「クラウド（Supabase）」に貼り付けて保存します。
4. メールアドレスを入れて「ログイン」を押し、届いたメールのリンクを開くとログインできます。
   初回ログイン時に、自分だけが使える「個人」ワークスペースが自動で作られます。

## 6. チームで使う

- **チームを作る**：チーム画面で「ワークスペースを作成」。作った人が owner（所有者）になります。
- **招待する**：owner / admin が相手のメールアドレスと役割を指定して招待を作り、表示されたリンクを相手に送ります（メールは自動送信されません）。相手は**招待されたメールアドレスでログインして**リンクを開くと参加できます。リンクの有効期限は 14 日です。
- **役割**

  | 役割 | できること |
  | --- | --- |
  | owner（所有者） | すべて。メンバー管理、ワークスペースの削除 |
  | admin（管理者） | メンバーの追加・役割変更・削除（owner 以外）、名前の変更、AI 利用履歴の閲覧 |
  | editor（編集者） | 問題・教材・学習結果の作成と更新、レビュー依頼、AI での問題作成 |
  | reviewer（レビュー担当） | 下書きを含む閲覧、レビューの承認・差し戻し、AI での解答・校閲 |
  | viewer（閲覧者） | 閲覧のみ（教材は「公開（published）」のものだけ） |

- **承認と公開の流れ**：編集者が「レビュー依頼」→ 教材は「レビュー中」（問題は「検証中」）。レビュー担当者が承認すると「承認済み」、差し戻すと教材は「下書き」（問題は「要修正」）に自動で戻ります。教材を「公開」できるのは owner・admin・editor で、**承認済みの教材だけ**です（viewer に見えるのは公開済みの教材だけ）。
- **個人の教材の共有**：個人ワークスペースの教材は自分しか見られません。チームへ共有すると**コピー**が作られ、元の教材は非公開のまま残ります。

## 7. うまくいかないとき

| 症状 | 確認すること |
| --- | --- |
| ログインのメールが届かない | 迷惑メールフォルダ。無料プランの送信上限（時間をおいて再試行）。手順 3 の Site URL / Redirect URLs |
| メールのリンクを開くと別のページに行く | 手順 3 の Redirect URLs にアプリの URL が入っているか |
| 「not_configured」と出る | 設定画面の URL と anon key。AI の場合は手順 4 の関数デプロイと `ANTHROPIC_API_KEY` |
| 「forbidden」と出る | 自分の役割（viewer は作成・編集できません。AI の問題作成は editor 以上） |
| 「quota_exceeded」と出る | その日の AI 利用上限に達しました。翌日まで待つか `AI_DAILY_TOKEN_LIMIT` を増やします |
| 「provider_error」と出る | Anthropic の API キーが正しいか、支払い設定があるか。Supabase の Edge Functions → ai → Logs で詳細を確認できます |
| 「bad_output」と出る | AI の出力が形式に合いませんでした。もう一度実行してください |
