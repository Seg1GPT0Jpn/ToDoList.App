#!/bin/sh
# つづりクエスト 小中学生版（for elementary and junior high school）を作るため、
# リポジトリの写しの中身を小中学生版に入れかえる。
#
# プログラムの仕組みは高校生版と共通で、ちがうのは中身（ワールド・問題・学習体系・授業・物語・アイコン）だけ。
# 中身は editions/junior/files/ に、リポジトリと同じ場所の名前で置いてある。
#
# 使い方（CI や、手元の別の写しで。もとにもどすときは git checkout -- . && git clean -fd）：
#   sh editions/junior/apply.sh
#   cd rpg_game_app && flutter build web --wasm --release --dart-define=TSUZURI_JUNIOR=true
set -e
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"

# 高校生版だけの同梱ファイルを外す（フォルダは pubspec.yaml に書いてあるので残し、中身だけ消す）
for d in \
  rpg_game/assets/question_bundles \
  rpg_game/assets/questions \
  rpg_game/assets/words \
  rpg_game/assets/cards \
  rpg_game/assets/lessons \
  rpg_game_app/assets/vocab \
  rpg_game_app/assets/materials \
  rpg_game_app/assets/mock_exams \
  rpg_game_app/assets/texts
do
  [ -d "$d" ] && find "$d" -type f -delete
done

# 小中学生版の中身を重ねる
cp -R editions/junior/files/. .

# Web 版の題名（ほかは高校生版と同じ最新のものを使う）
sed -i \
  -e 's#content="つづりクエスト"#content="つづりクエスト 小中"#' \
  -e 's#<title>つづりクエスト</title>#<title>つづりクエスト for elementary and junior high school</title>#' \
  rpg_game_app/web/index.html
sed -i \
  -e 's#"name": "つづりクエスト"#"name": "つづりクエスト for elementary and junior high school"#' \
  -e 's#"short_name": "つづりクエスト"#"short_name": "つづりクエスト 小中"#' \
  rpg_game_app/web/manifest.json
grep -q 'つづりクエスト 小中' rpg_game_app/web/index.html
grep -q 'つづりクエスト 小中' rpg_game_app/web/manifest.json

echo "小中学生版の中身に入れかえました"
