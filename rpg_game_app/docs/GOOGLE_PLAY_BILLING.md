# つづりクエスト Google Play 課金設定

このプロジェクトの有料ワールドは、Google Play の「買い切り型（非消費型）」商品として販売します。

## 商品 ID

| ワールド | product ID | 現在の予定価格 |
| --- | --- | ---: |
| 理の国（理科） | world_science | ¥250 |
| 時と地の国（社会） | world_social | ¥250 |
| 言の葉の国（国語） | world_japanese | ¥250 |
| 数理の国（数学） | world_math | ¥250 |
| 情報の国（情報） | world_information | ¥250 |

価格はソースコードではなく Google Play Console の商品設定が最終的な販売価格です。アプリでは Google Play から取得した表示価格を出します。

## 1. Google Play Console

Google Play Console に、Android アプリのパッケージ名を com.kazu.rpg_game_app として登録してください。

その後、収益化メニューから「1 回限りの商品」を 5 件作成します。

商品 ID は次の文字列をそのまま使います。

- world_science
- world_social
- world_japanese
- world_math
- world_information

このアプリではランダム型の商品ではなく、各ワールドを一度購入すると恒久的に使える買い切り商品として扱います。

## 2. Google Play Developer API

Google Cloud で Google Play Developer API を有効にします。

そのうえでサービス アカウントを作成し、Google Play Console の「ユーザーと権限」に追加します。

Play Billing API を使うために、Google の公式ドキュメントにある以下の権限を付与してください。

- 売上データ、注文、解約アンケートの回答の閲覧
- 注文と定期購入の管理

サービス アカウントの秘密鍵 JSON は、このリポジトリには絶対に入れないでください。

Cloud Functions は Application Default Credentials を使うため、通常は Firebase/Google Cloud 側のサービス アカウント権限だけ設定すればよく、秘密鍵 JSON をアプリに同梱する必要はありません。

## 3. Cloud Functions

rpg_game_app/functions/ が購入検証サーバーです。

rpg_game_app で次を実行します。

    npm --prefix functions install
    npm --prefix functions run build
    firebase deploy --only functions
    firebase deploy --only firestore:rules

デプロイする関数名は verifyGooglePlayPurchase です。

関数は asia-northeast1 に配置しています。

## 4. 購入の流れ

本番の流れは次のとおりです。

1. ユーザーが Google ログインする
2. 「Google Playで購入」を押す
3. Google Play が購入処理を行う
4. Google Play が返した購入トークンを Firebase Functions に送る
5. Functions が Google Play Developer API の purchases.products.get で購入状態を検証する
6. purchaseState が PURCHASED の場合だけ users/{uid}/rpg_purchases/{worldId} を作成する
7. Functions が Google Play 側の購入を acknowledge する
8. アプリ側が購入済みワールドを解放する
9. 次回ログイン時は Firestore の rpg_purchases を読み、購入済みワールドを復元する

PENDING の購入はワールドを解放しません。

## 5. 購入情報の復元

ホーム右上のメニューに「Google Playの購入を復元」を追加しています。

機種変更、アプリ再インストール、ローカルデータの消失などのあとでも、Google ログイン後に復元処理を呼べます。

## 6. プロモーションコード

既存のプロモーションコード機能は残しています。

- 友人・親しい人向けのコード配布はそのまま
- Google Play の通常購入と別ルート
- 「コードを入力」の導線も削除していません

## 7. Google Play でのテスト

実課金を一般公開する前に、Google Play のテスト用アカウントを使って、内部テストなどの Play 配布版で次を確認します。

1. 商品情報が表示される
2. 購入ダイアログが Google Play から表示される
3. 購入完了後にワールドが開く
4. アプリを終了・再起動しても開く
5. Google アカウントで再ログインしても開く
6. 「Google Playの購入を復元」で戻る
7. PENDING 中にワールドが開かない
8. キャンセル時にワールドが開かない
9. 別のアカウントに購入トークンを付け替えられない

## 8. アプリの package name を変更する場合

Android の applicationId を変更した場合は、Cloud Functions の PACKAGE_NAME も同じ値に変更してください。

現在は com.kazu.rpg_game_app です。

Google Play の商品 ID を変更した場合は、以下の両方を変更します。

- GooglePlayPurchaseService.worldIdForProduct
- functions/src/index.ts の PRODUCT_TO_WORLD

## 9. 重要な注意

Google Play の購入トークン、サービス アカウント鍵、Firebase の秘密鍵などを Flutter アプリの assets や GitHub に入れないでください。

購入検証と購入承認はバックエンドで行う設計です。
