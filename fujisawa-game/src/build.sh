#!/bin/bash
# src/ の部品を連結して ../index.html を作る
set -e; cd "$(dirname "$0")"
{ sed -n 1,120p head.html; cat engine2_a.js blk_setup.js blk_city.js; sed -n 1,71p blk_land.js; cat engine2_b.js facade.js engine2_c.js places.js city.js stations_detail.js st_*.js engine2_d.js blk_life.js engine2_e.js people.js; echo '</script>'; } > ../index.html
sed -i 's|#trainBox .spd{padding:0 14px 8px;|#trainBox .spd{white-space:pre-line;line-height:1.5;padding:0 14px 8px;|' ../index.html
sed -i 's|<span>藤沢市 全体マップ — 地図をタップするとその場所へワープ</span>|<span>藤沢市と沿線マップ — 地図をタップするとその場所へワープ</span>|' ../index.html
sed -i 's|<div><b>E</b>停車中の電車に乗る / 降りる</div>|<div><b>E</b>停車中の電車に乗る / 降りる・地下駅の出入口</div><div><b>駅</b>近くで時刻表表示・「次の電車まで時間を進める」</div>|' ../index.html
sed -i 's|#toast{top:30%;|#toast{top:40%;|; s|>電車を待つ（早送り）<|>次の電車まで時間を進める<|' ../index.html
echo "built ../index.html"
