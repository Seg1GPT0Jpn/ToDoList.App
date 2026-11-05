import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';

// 社会の問題の作り方。地理の計算（時差・縮尺・人口密度など）と、
// 年代が定まっているできごとの年表から作る（説が分かれる年は入れない）。

// ---------------- 地理：計算 ----------------

String _lon(int deg) => deg == 0
    ? '経度0度'
    : deg > 0
        ? '東経$deg度'
        : '西経${-deg}度';

String _clock(int dayOffset, int hour) {
  final h = hour % 24;
  final ampm = h < 12 ? '午前' : '午後';
  final h12 = h % 12;
  final day = switch (dayOffset) { -1 => '12月31日', 0 => '1月1日', _ => '1月2日' };
  return '$day$ampm$h12時';
}

GenQ? _timeDiff(Random r) {
  final places = [135, 0, -75, -120, 150, 120, 30, -45, 105, 60, -90, 15];
  final a = r.pick(places);
  var b = r.pick(places);
  if (a == b) b = 0;
  if (a == b) return null;
  final hour = r.range(0, 23);
  final diff = (b - a) ~/ 15; // b が a より何時間進んでいるか
  final t = hour + diff;
  final dayOff = t < 0
      ? -1
      : t >= 24
          ? 1
          : 0;
  final ans = _clock(dayOff, (t % 24 + 24) % 24);
  String alt(int d) {
    final tt = hour + d;
    return _clock(
        tt < 0
            ? -1
            : tt >= 24
                ? 1
                : 0,
        (tt % 24 + 24) % 24);
  }

  return GenQ(
    prompt:
        '${_lon(a)}を標準時子午線とする地点が1月1日${_clock(0, hour).substring(4)}のとき、${_lon(b)}を標準時子午線とする地点は何日の何時？（サマータイムは考えない）',
    answer: ans,
    wrong: [alt(-diff), alt(diff + 1), alt(diff - 1), alt(diff + 12), alt(0)],
    explanation:
        '経度15度で1時間の時差。経度の差 ${(b - a).abs()} 度なので ${diff.abs()} 時間。東ほど時刻が進んでいる。',
    category: QuestionCategory.thinking,
  );
}

GenQ? _scale(Random r) {
  final s = r.pick([25000, 50000]);
  final cm = r.range(1, 20);
  final m = cm * s ~/ 100;
  String dist(int meters) => meters % 1000 == 0
      ? '${meters ~/ 1000} km'
      : meters >= 1000
          ? '${Fmt.dec(meters, 3)} km'
          : '$meters m';
  return GenQ(
    prompt:
        '${s ~/ 10000}万${s % 10000 == 0 ? '' : '${s % 10000 ~/ 1000}千'}分の1の地形図で、地図上の長さが $cm cm のとき、実際の距離は？',
    answer: dist(m),
    wrong: [
      dist(m * 10),
      dist(m ~/ 10 == 0 ? m * 2 : m ~/ 10),
      dist(m * 2),
      dist(cm * (s == 25000 ? 50000 : 25000) ~/ 100)
    ],
    explanation: '$cm cm×$s＝${cm * s} cm＝$m m',
  );
}

GenQ? _contour(Random r) {
  final s = r.pick([25000, 50000]);
  final main = r.nextBool();
  final v = s == 25000 ? (main ? 10 : 50) : (main ? 20 : 100);
  final label = s == 25000 ? '2万5千分の1' : '5万分の1';
  return GenQ(
    prompt: '$labelの地形図で、${main ? '主曲線' : '計曲線'}は何 m ごとに引かれる？',
    answer: '$v m',
    wrong: ['10 m', '20 m', '50 m', '100 m', '5 m'],
    explanation: '2万5千分の1：主曲線10 m・計曲線50 m、5万分の1：主曲線20 m・計曲線100 m',
    category: QuestionCategory.knowledge,
  );
}

GenQ? _density(Random r) {
  final area =
      r.pick([10, 20, 25, 40, 50, 100, 200, 250, 400, 500]); // 万 km²ではなく千 km²
  final d = r.range(5, 400);
  final pop = area * d; // 千人
  return GenQ(
    prompt: '人口 ${pop * 1000} 人、面積 ${area * 1000} km² の地域の人口密度は？',
    answer: '$d 人/km²',
    wrong: [
      '${d * 10} 人/km²',
      '${max(1, d ~/ 10)} 人/km²',
      '${d + 1} 人/km²',
      '${Rat(area, d)} 人/km²'
    ],
    explanation: '人口÷面積＝${pop * 1000}÷${area * 1000}',
  );
}

GenQ? _antipode(Random r) {
  final lat = r.range(1, 80), lon = r.range(1, 179);
  final north = r.nextBool(), east = r.nextBool();
  String pt(bool n, int la, bool e, int lo) =>
      '${n ? '北緯' : '南緯'}$la度・${e ? '東経' : '西経'}$lo度';
  return GenQ(
    prompt: '${pt(north, lat, east, lon)}の地点の、地球の反対側の地点（対せき点）は？',
    answer: pt(!north, lat, !east, 180 - lon),
    wrong: [
      pt(!north, lat, !east, lon),
      pt(north, lat, !east, 180 - lon),
      pt(!north, lat, east, 180 - lon),
      pt(!north, 90 - lat, !east, 180 - lon)
    ],
    explanation: '緯度は北と南を入れかえ、経度は 180 から引いて東と西を入れかえる。',
    category: QuestionCategory.thinking,
  );
}

GenQ? _exchange(Random r) {
  if (r.nextBool()) {
    final rate = r.pick([100, 110, 120, 125, 140, 150, 160]);
    final usd = r.pick([10, 20, 50, 100, 200, 500, 1000]);
    return GenQ(
      prompt: '1ドル＝$rate円のとき、$usdドルの商品は何円？',
      answer: '${usd * rate}円',
      wrong: [
        '${usd * rate * 10}円',
        '${Rat(usd * 100, rate)}円',
        '${usd + rate}円',
        '${usd * (rate - 10)}円'
      ],
      explanation: '$usd×$rate',
    );
  }
  final a = r.pick([90, 100, 110, 120, 130, 140, 150]);
  var b = r.pick([90, 100, 110, 120, 130, 140, 150]);
  if (a == b) b = a + 20;
  final weak = b > a; // 1ドルにより多くの円が必要 → 円安
  return GenQ(
    prompt: '為替相場が1ドル＝$a円から1ドル＝$b円になった。これは円高・円安のどちら？',
    answer: weak ? '円安' : '円高',
    wrong: [weak ? '円高' : '円安', '変わらない', 'ドル安'],
    explanation: weak
        ? '1ドルを買うのに多くの円が必要になったので、円の価値が下がった（円安）。'
        : '少ない円で1ドルを買えるようになったので、円の価値が上がった（円高）。',
    category: QuestionCategory.thinking,
  );
}

// ---------------- 歴史：年表 ----------------

/// （年, できごと）。年が負なら紀元前
typedef _Event = (int, String);

String _year(int y) => y < 0 ? '紀元前${-y}年' : '$y年';

/// 年→できごと・できごと→年・古い順
Gen _history(List<_Event> events) => (Random r) {
      final kind = r.nextInt(3);
      final (y, e) = r.pick(events);
      if (kind == 0) {
        final others = [
          for (final o in events)
            if (o.$1 != y) o.$2,
        ]..shuffle(r);
        if (others.length < 3) return null;
        return GenQ(
          prompt: '${_year(y)}のできごとは？',
          answer: e,
          wrong: others,
          explanation: '${_year(y)}：$e',
          category: QuestionCategory.knowledge,
        );
      }
      if (kind == 1) {
        final years = {
          for (final o in events)
            if (o.$1 != y) o.$1,
          y + 1,
          y - 1,
          y + 10,
          y - 10,
        }.toList()
          ..remove(y)
          ..shuffle(r);
        return GenQ(
          prompt: '「$e」は何年？',
          answer: _year(y),
          wrong: [for (final v in years) _year(v)],
          explanation: '${_year(y)}：$e',
          category: QuestionCategory.knowledge,
        );
      }
      // 古い順に並べたとき何番目
      final pool = <_Event>[];
      final usedYears = <int>{};
      for (final o in [...events]..shuffle(r)) {
        if (usedYears.add(o.$1)) pool.add(o);
        if (pool.length == 4) break;
      }
      if (pool.length < 4) return null;
      final sorted = [...pool]..sort((a, b) => a.$1.compareTo(b.$1));
      final pos = r.range(1, 4);
      const labels = ['ア', 'イ', 'ウ', 'エ'];
      final listed =
          [for (var i = 0; i < 4; i++) '${labels[i]} ${pool[i].$2}'].join('　');
      final ans = labels[pool.indexOf(sorted[pos - 1])];
      return GenQ(
        prompt: '次のできごとを古い順に並べたとき、$pos番目は？　$listed',
        answer: ans,
        wrong: labels,
        explanation: sorted.map((x) => '${_year(x.$1)} ${x.$2}').join('→'),
        category: QuestionCategory.thinking,
      );
    };

const _jhist = <String, List<_Event>>{
  'social.jhist.ancient.kofun': [
    (607, '小野妹子を遣隋使として送る'),
    (645, '大化の改新が始まる'),
    (663, '白村江の戦い'),
    (672, '壬申の乱'),
  ],
  'social.jhist.ancient.nara': [
    (701, '大宝律令が定められる'),
    (710, '平城京に都を移す'),
    (743, '墾田永年私財法が出される'),
    (752, '東大寺の大仏の開眼供養'),
  ],
  'social.jhist.ancient.heian': [
    (794, '平安京に都を移す'),
    (894, '菅原道真の提案で遣唐使を停止する'),
    (1016, '藤原道長が摂政になる'),
    (1086, '白河上皇が院政を始める'),
  ],
  'social.jhist.ancient.insei': [
    (1086, '白河上皇が院政を始める'),
    (1156, '保元の乱'),
    (1159, '平治の乱'),
    (1167, '平清盛が太政大臣になる'),
  ],
  'social.jhist.medieval.kamakura': [
    (1185, '源頼朝が守護・地頭を置く'),
    (1192, '源頼朝が征夷大将軍になる'),
    (1221, '承久の乱'),
    (1232, '御成敗式目が定められる'),
  ],
  'social.jhist.medieval.mongol': [
    (1274, '文永の役'),
    (1281, '弘安の役'),
    (1297, '永仁の徳政令'),
    (1232, '御成敗式目が定められる'),
  ],
  'social.jhist.medieval.muromachi': [
    (1333, '鎌倉幕府が滅びる'),
    (1338, '足利尊氏が征夷大将軍になる'),
    (1392, '南北朝が統一される'),
    (1404, '日明貿易（勘合貿易）が始まる'),
  ],
  'social.jhist.medieval.sengoku': [
    (1428, '正長の土一揆'),
    (1467, '応仁の乱が始まる'),
    (1485, '山城国一揆'),
    (1488, '加賀の一向一揆'),
  ],
  'social.jhist.early_modern.shokuho': [
    (1543, '鉄砲が伝わる'),
    (1549, 'ザビエルがキリスト教を伝える'),
    (1560, '桶狭間の戦い'),
    (1573, '室町幕府が滅びる'),
    (1575, '長篠の戦い'),
    (1582, '本能寺の変'),
    (1588, '刀狩令が出される'),
    (1590, '豊臣秀吉が全国を統一する'),
  ],
  'social.jhist.early_modern.edo': [
    (1600, '関ヶ原の戦い'),
    (1603, '徳川家康が江戸幕府を開く'),
    (1615, '武家諸法度が定められる'),
    (1635, '参勤交代が制度化される'),
    (1637, '島原・天草一揆'),
    (1639, 'ポルトガル船の来航を禁止する'),
    (1641, 'オランダ商館を長崎の出島に移す'),
  ],
  'social.jhist.early_modern.reform': [
    (1716, '徳川吉宗が享保の改革を始める'),
    (1772, '田沼意次が老中になる'),
    (1787, '松平定信が寛政の改革を始める'),
    (1837, '大塩平八郎の乱'),
    (1841, '水野忠邦が天保の改革を始める'),
  ],
  'social.jhist.early_modern.bakumatsu': [
    (1853, 'ペリーが浦賀に来航する'),
    (1854, '日米和親条約を結ぶ'),
    (1858, '日米修好通商条約を結ぶ'),
    (1860, '桜田門外の変'),
    (1866, '薩長同盟が結ばれる'),
    (1867, '大政奉還'),
  ],
  'social.jhist.modern.meiji': [
    (1868, '五箇条の御誓文が出される'),
    (1869, '版籍奉還'),
    (1871, '廃藩置県'),
    (1872, '学制が公布される'),
    (1873, '地租改正が始まる'),
    (1877, '西南戦争'),
  ],
  'social.jhist.modern.constitution': [
    (1874, '民撰議院設立の建白書が出される'),
    (1881, '国会開設の勅諭が出される'),
    (1885, '内閣制度ができる'),
    (1889, '大日本帝国憲法が発布される'),
    (1890, '第1回帝国議会が開かれる'),
  ],
  'social.jhist.modern.wars': [
    (1894, '日清戦争が始まる'),
    (1895, '下関条約を結ぶ'),
    (1902, '日英同盟を結ぶ'),
    (1904, '日露戦争が始まる'),
    (1905, 'ポーツマス条約を結ぶ'),
    (1910, '韓国を併合する'),
    (1911, '関税自主権を回復する'),
  ],
  'social.jhist.modern.taisho': [
    (1914, '第一次世界大戦が始まる'),
    (1915, '中国に二十一か条の要求を出す'),
    (1918, '米騒動が起こる'),
    (1923, '関東大震災'),
    (1925, '普通選挙法が成立する'),
  ],
  'social.jhist.modern.showa': [
    (1929, '世界恐慌が始まる'),
    (1931, '満州事変'),
    (1932, '五・一五事件'),
    (1933, '国際連盟を脱退する'),
    (1936, '二・二六事件'),
    (1937, '日中戦争が始まる'),
    (1941, '太平洋戦争が始まる'),
    (1945, 'ポツダム宣言を受け入れる'),
  ],
  'social.jhist.contemporary.postwar': [
    (1946, '日本国憲法が公布される'),
    (1950, '朝鮮戦争が始まる'),
    (1951, 'サンフランシスコ平和条約を結ぶ'),
    (1956, '日ソ共同宣言に調印する'),
    (1945, 'ポツダム宣言を受け入れる'),
  ],
  'social.jhist.contemporary.growth': [
    (1964, '東京オリンピックが開かれる'),
    (1965, '日韓基本条約を結ぶ'),
    (1972, '沖縄が日本に復帰する'),
    (1973, '第一次石油危機'),
    (1978, '日中平和友好条約を結ぶ'),
    (1985, 'プラザ合意'),
  ],
};

const _whist = <String, List<_Event>>{
  'social.whist.ancient.greece': [
    (-490, 'マラトンの戦い'),
    (-480, 'サラミスの海戦'),
    (-431, 'ペロポネソス戦争が始まる'),
    (-334, 'アレクサンドロス大王の東方遠征が始まる'),
  ],
  'social.whist.ancient.rome': [
    (-27, 'ローマが帝政になる（オクタウィアヌスがアウグストゥスの称号を受ける）'),
    (395, 'ローマ帝国が東西に分裂する'),
    (476, '西ローマ帝国が滅びる'),
    (-334, 'アレクサンドロス大王の東方遠征が始まる'),
  ],
  'social.whist.ancient.china': [
    (-221, '秦の始皇帝が中国を統一する'),
    (-202, '劉邦が漢を建てる'),
    (581, '隋が建国される'),
    (618, '唐が建国される'),
  ],
  'social.whist.medieval.europe': [
    (800, 'カールの戴冠'),
    (1077, 'カノッサの屈辱'),
    (1096, '第1回十字軍'),
    (1215, 'マグナ・カルタが定められる'),
    (1453, '百年戦争が終わる'),
  ],
  'social.whist.medieval.islam': [
    (622, 'ムハンマドがメッカからメディナへ移る（ヒジュラ）'),
    (661, 'ウマイヤ朝が成立する'),
    (750, 'アッバース朝が成立する'),
    (1453, 'オスマン帝国がコンスタンティノープルを攻め落とす'),
  ],
  'social.whist.medieval.china': [
    (907, '唐が滅びる'),
    (960, '宋（北宋）が建国される'),
    (1368, '明が建国される'),
    (618, '唐が建国される'),
  ],
  'social.whist.medieval.mongol': [
    (1206, 'チンギス・ハンが即位する'),
    (1271, 'フビライが国号を元とする'),
    (1368, '明が建国される'),
    (1274, '元軍が日本に襲来する（文永の役）'),
  ],
  'social.whist.early_modern.discovery': [
    (1488, 'バルトロメウ・ディアスが喜望峰に到達する'),
    (1492, 'コロンブスがアメリカ大陸近くの島に到達する'),
    (1498, 'ヴァスコ・ダ・ガマがインドに到達する'),
    (1522, 'マゼランの艦隊が世界周航を達成する'),
  ],
  'social.whist.early_modern.renaissance': [
    (1517, 'ルターが九十五か条の論題を発表する'),
    (1534, 'イエズス会が結成される'),
    (1545, 'トリエント公会議が始まる'),
    (1492, 'コロンブスがアメリカ大陸近くの島に到達する'),
  ],
  'social.whist.early_modern.absolutism': [
    (1588, 'イギリスがスペインの無敵艦隊を破る'),
    (1618, '三十年戦争が始まる'),
    (1642, 'ピューリタン革命が始まる'),
    (1648, 'ウェストファリア条約'),
    (1688, '名誉革命'),
  ],
  'social.whist.modern.revolution': [
    (1689, '権利の章典が出される'),
    (1776, 'アメリカ独立宣言'),
    (1789, 'フランス革命が始まる'),
    (1804, 'ナポレオンが皇帝になる'),
    (1815, 'ウィーン議定書が結ばれる'),
  ],
  'social.whist.modern.industrial': [
    (1769, 'ワットが蒸気機関を改良する'),
    (1825, 'ストックトン・ダーリントン間で蒸気機関車が走る'),
    (1830, 'リヴァプール・マンチェスター鉄道が開通する'),
    (1776, 'アメリカ独立宣言'),
  ],
  'social.whist.modern.nation': [
    (1840, 'アヘン戦争が始まる'),
    (1848, 'フランスで二月革命が起こる'),
    (1861, 'アメリカで南北戦争が始まる'),
    (1863, 'リンカンが奴隷解放宣言を出す'),
    (1871, 'ドイツ帝国が成立する'),
  ],
  'social.whist.modern.imperialism': [
    (1898, 'アメリカ・スペイン戦争'),
    (1911, '辛亥革命が起こる'),
    (1914, '第一次世界大戦が始まる'),
    (1871, 'ドイツ帝国が成立する'),
  ],
  'social.whist.contemporary.ww1': [
    (1914, '第一次世界大戦が始まる'),
    (1917, 'ロシア革命が起こる'),
    (1919, 'ヴェルサイユ条約が結ばれる'),
    (1920, '国際連盟が発足する'),
  ],
  'social.whist.contemporary.ww2': [
    (1929, '世界恐慌が始まる'),
    (1933, 'ヒトラーが首相になる'),
    (1939, '第二次世界大戦が始まる'),
    (1945, '国際連合が発足する'),
  ],
  'social.whist.contemporary.global': [
    (1949, '中華人民共和国が成立する'),
    (1962, 'キューバ危機'),
    (1989, 'ベルリンの壁が崩壊する'),
    (1991, 'ソ連が解体する'),
    (1993, 'EU（ヨーロッパ連合）が発足する'),
  ],
};

final Map<String, List<Gen>> socialPrefixGens = {
  for (final e in {..._jhist, ..._whist}.entries) e.key: [_history(e.value)],
};

final Map<String, List<Gen>> socialGens = {
  'social.geo.map.maps': [_timeDiff, _scale],
  'social.geo.map.position.time': [_timeDiff],
  'social.geo.map.maps.topo': [_scale, _contour],
  'social.geo.map.position.latlon': [_antipode],
  'social.geo.industry.population.distribution': [_density],
  'social.pol.economy.global.exchange': [_exchange],
};
