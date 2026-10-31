# Android 版を Google Play に上げる

`.github/workflows/release-android.yml` が、署名した App Bundle を作って Google Play のテスト（クローズドテストなど）に上げる。
GitHub の **Actions → 「Android版を Google Play に上げる」→ Run workflow** で動く。

- バージョンコードは実行の番号＋100 で自動で決まる（手で上げた 1〜100 とかぶらない）
- 変更点（テスターに見える文）は、Run workflow のときに入れられる
- トラックはふつう `alpha`（クローズドテスト）。内部テストなら `internal`

## 最初に1回だけすること

### 1. 最初の App Bundle を手で上げる

Google の決まりで、最初の1つは Play Console から手で上げる。PC で：

```
cd C:\Users\kzmse\tq-2d\rpg_game_app
flutter build appbundle --release
```

`build\app\outputs\bundle\release\app-release.aab` を、Play Console のクローズドテストの「リリースを作成」にドロップする。
（署名には `android\key.properties` とアップロード鍵 `upload-keystore.jks` を使う。どちらも Git に入れない）

### 2. アップロード鍵を GitHub に登録する

GitHub のリポジトリ → **Settings → Secrets and variables → Actions → New repository secret** で：

| 名前 | 中身 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | 下のコマンドでコピーされる文字（鍵ファイルを文字にしたもの） |
| `ANDROID_KEYSTORE_PASSWORD` | 鍵を作ったときに決めたパスワード |

```
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\kzmse\upload-keystore.jks")) | Set-Clipboard
```

（鍵の別名は `upload`、鍵のパスワードはキーストアと同じものとして扱う）

### 3. Google Play に上げる権限（サービスアカウント）を作る

1. [Google Cloud コンソール](https://console.cloud.google.com/) で、プロジェクト `tsuzuri-quest-v2` を選ぶ
2. 「API とサービス → ライブラリ」で **Google Play Android Developer API** を有効にする
3. 「IAM と管理 → サービスアカウント → サービスアカウントを作成」。名前は `play-upload` など（役割はつけなくてよい）
4. 作ったサービスアカウント →「鍵 → 鍵を追加 → 新しい鍵を作成 → JSON」。JSON ファイルがダウンロードされる
5. Play Console →「ユーザーと権限 → 新しいユーザーを招待」で、サービスアカウントのメールアドレス（`…@tsuzuri-quest-v2.iam.gserviceaccount.com`）を入れ、
   アプリ「つづりクエスト」に **「テスト トラックへのアプリのリリース」** などのリリースの権限をつけて招待する
6. GitHub の Secrets に `PLAY_SERVICE_ACCOUNT_JSON` を作り、JSON ファイルの中身をまるごと貼る（JSON ファイルはそのあと消してよい）

### 4. Google ログインのための署名（SHA-1）を Firebase に登録する

Play から入れたアプリは Google が署名し直すので、Play Console の「テストとリリース → アプリの完全性 → アプリの署名」の
**アプリ署名鍵の証明書**の SHA-1 と SHA-256 を、Firebase（tsuzuri-quest-v2）→ プロジェクトの設定 → Android アプリ →
「フィンガープリントを追加」に登録する。これをしないと、Play から入れたアプリで Google ログインできない。

## うまくいかないとき

- 「Only releases with status draft may be created on draft app」：アプリがまだ一度も公開されていない。
  Run workflow の status を `draft` にして実行し、Play Console で下書きを公開する
- 「The caller does not have permission」：3 の 5（Play Console の招待と権限）を確かめる。招待してから使えるまで数時間かかることがある
- 「APK specifies a version code that has already been used」：もう一度 Run workflow する（番号が進む）
