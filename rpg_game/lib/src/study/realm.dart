import '../models/enemy.dart';
import '../models/question.dart';
import '../world/terrain.dart';

/// 学習モードの世界。
///
/// - 定期テストの海：船で海を進み、終盤は潜水艦で深海へ潜っていく
/// - 模擬試験の空：飛行船で雲の上を進み、終盤はロケットで宇宙へ昇っていく。
///   海よりさらに難しい（上級者向け）
enum StudyRealm {
  sea(
    title: '定期テストの海',
    vehicle: '船',
    deepVehicle: '潜水艦',
    surface: Terrain.ocean,
    deep: Terrain.abyss,
    hitsToWin: 15,
    missesToLose: 3,
    timeRate: 0.6,
    color: 0xFF1F4E79,
  ),
  sky(
    title: '模擬試験の空',
    vehicle: '飛行船',
    deepVehicle: 'ロケット',
    surface: Terrain.cloudSea,
    deep: Terrain.space,
    hitsToWin: 16,
    missesToLose: 2,
    timeRate: 0.5,
    color: 0xFF3949AB,
  );

  const StudyRealm({
    required this.title,
    required this.vehicle,
    required this.deepVehicle,
    required this.surface,
    required this.deep,
    required this.hitsToWin,
    required this.missesToLose,
    required this.timeRate,
    required this.color,
  });

  final String title;

  /// 前半の乗り物
  final String vehicle;

  /// 終盤（深海・宇宙）の乗り物
  final String deepVehicle;

  /// 前半の地形（大海原・雲海）
  final Terrain surface;

  /// 終盤の地形（深海・宇宙）
  final Terrain deep;

  /// ふつうの正解（チェイン・クリティカルなし）で倒すのに必要な回数
  final int hitsToWin;

  /// 何回まちがえると倒れるか
  final int missesToLose;

  /// 制限時間の倍率（RPG に対して）
  final double timeRate;

  /// テーマの色（ARGB）
  final int color;

  static StudyRealm parse(String? name) =>
      values.where((r) => r.name == name).firstOrNull ?? sea;

  /// 航路の何番目（0始まり）から終盤（深海・宇宙）か。
  /// 全体の4分の1ほど（最後の試験本番をふくむ）。2つ以上あれば前半も必ず残す。
  static int deepFrom(int total) {
    if (total <= 1) return 0;
    final deep = (total / 4).ceil().clamp(1, total - 1);
    return total - deep;
  }

  /// 航路の [index] 番目の地形
  Terrain terrainAt(int index, int total) =>
      index >= deepFrom(total) ? deep : surface;

  /// 終盤に入ったときの演出の文
  String get diveMessage => switch (this) {
        sea => '潜水艦に乗りかえた！ ここから先は光のとどかない深海。範囲の奥底へ潜っていこう。',
        sky => 'ロケットに乗りかえた！ 雲をつきぬけて、宇宙へ。ここからが本番だ。',
      };
}

/// 海・空の魔物のひな形
class VoyageMonster {
  const VoyageMonster(
    this.name,
    this.look,
    this.color,
    this.description,
    this.introLine,
    this.defeatLine,
  );

  final String name;
  final String look;
  final int color;
  final String description;
  final String introLine;
  final String defeatLine;

  EnemyDef toEnemy({
    required String id,
    required int maxHp,
    required int attack,
    QuestionCategory? weakness,
    String? introLine,
  }) =>
      EnemyDef(
        id: id,
        name: name,
        maxHp: maxHp,
        attack: attack,
        look: look,
        color: color,
        weakness: weakness,
        description: description,
        introLine: introLine ?? this.introLine,
        defeatLine: defeatLine,
      );
}

/// 定期テストの海・模擬試験の空に出る魔物たち
class VoyageMonsters {
  const VoyageMonsters._();

  /// 前半（大海原・雲海）の魔物
  static List<VoyageMonster> surface(StudyRealm realm) =>
      realm == StudyRealm.sea ? _seaSurface : _skySurface;

  /// 終盤（深海・宇宙）の魔物
  static List<VoyageMonster> deep(StudyRealm realm) =>
      realm == StudyRealm.sea ? _seaDeep : _skyDeep;

  /// 航路の最後の「試験本番」のボス
  static VoyageMonster boss(StudyRealm realm) =>
      realm == StudyRealm.sea ? _seaBoss : _skyBoss;

  /// [index] 番目（全 [total]）のエリアの魔物。[seed] で並びを変える
  static VoyageMonster at(
    StudyRealm realm,
    int index,
    int total, {
    int seed = 0,
    bool boss = false,
  }) {
    if (boss) return VoyageMonsters.boss(realm);
    final pool =
        index >= StudyRealm.deepFrom(total) ? deep(realm) : surface(realm);
    return pool[(index + seed) % pool.length];
  }

  /// 海・空の魔物の見た目（図鑑用）
  static Set<String> get looks => {
        for (final m in [
          ..._seaSurface,
          ..._seaDeep,
          _seaBoss,
          ..._skySurface,
          ..._skyDeep,
          _skyBoss,
        ])
          m.look,
      };

  static const _seaSurface = [
    VoyageMonster(
      'うっかりクラゲ',
      'jellyfish',
      0xFFB39DDB,
      'ふわふわ流れてきて、うっかりミスを誘う。刺されると頭がぼんやりする。',
      'ふわ〜…その答え、ほんとに合ってる？',
      'しびれが…とれた…',
    ),
    VoyageMonster(
      'ひっかけガニ',
      'crab',
      0xFFE57373,
      'ひっかけ問題のはさみを持つ。かたい甲羅で、ちょっとやそっとの攻撃は効かない。',
      'このはさみで、答えをちょきんとひっかけてやる！',
      'よ、横歩きで逃げるしかない…',
    ),
    VoyageMonster(
      'ふくれっつらフグ',
      'puffer',
      0xFFFFD54F,
      'まちがえるとぷくっとふくれる。トゲだらけの体で体当たりしてくる。',
      'ぷくーっ！ 範囲が広すぎて、ふくれちゃう！',
      'しゅるる…しぼんじゃった…',
    ),
    VoyageMonster(
      '赤点ザメ',
      'shark',
      0xFF78909C,
      '赤点のにおいをかぎつけて寄ってくる。続けて正解しないと、なかなか傷がつかない。',
      'くんくん…赤点のにおいがするぞ！',
      'ちっ…今回はにおわなかったか…',
    ),
    VoyageMonster(
      '暗記ダコ',
      'octopus',
      0xFFD1495B,
      '8本の足で8つの用語を同時に覚えている。まちがえると墨をはいて、問題を読みにくくする。',
      '8本の足で覚えた知識、おまえに負けるものか！',
      '墨が…切れた…',
    ),
    VoyageMonster(
      'ヒラメキエイ',
      'ray',
      0xFF5C8FB0,
      '大きなひれで水をすべる。迷っているあいだに、すいっと逃げてしまう。',
      'もたもたしてると、すり抜けちゃうよ〜',
      'ひらめきの…速さに…負けた…',
    ),
    VoyageMonster(
      'ノンビリガメ',
      'turtle',
      0xFF6B9A5B,
      '方眼もようの甲らをもつウミガメ。のんびりしているが、とにかくかたい。',
      'あわてないで…ゆっくり…でも正確にね…',
      '甲らが…ひびわれた…',
    ),
    VoyageMonster(
      'タツノシルベ',
      'seahorse',
      0xFFF2A65A,
      'まっすぐ立って泳ぐ海の道しるべ。考えこむと見失う。',
      'こっちだよ…ついてこられるかな？',
      '道…まちがえちゃった…',
    ),
    VoyageMonster(
      'ホシノカケラ',
      'starfish',
      0xFFEF8A62,
      '3体で星座を作るヒトデ。1体が弱ると次が現れる。',
      '仲間をぜんぶ倒せるかな？',
      '星座が…ほどけた…',
    ),
  ];

  static const _seaDeep = [
    VoyageMonster(
      '深海アンコウ',
      'angler',
      0xFF455A64,
      '暗い深海で、ちょうちんの光で「わかったつもり」を誘い出す。',
      'この光に近づいておいで…わかった気がするだろう？',
      'ちょうちんが…消えた…',
    ),
    VoyageMonster(
      'ダイオウ難問イカ',
      'squid',
      0xFFEF9A9A,
      '深海にひそむ巨大なイカ。長い触手で、長い問題をからませてくる。',
      '長い問題で、しめあげてやる！',
      '触手が…ほどけた…',
    ),
    VoyageMonster(
      'モノシリクジラ',
      'whale',
      0xFF3F6C9C,
      '深い海を泳ぐ物知りのクジラ。大きな体でダメージを受け流す。',
      '知識の量なら、だれにも負けないぞ…',
      'わしより…物知りだったか…',
    ),
    VoyageMonster(
      'ウツボルト',
      'eel',
      0xFF6D8B4E,
      '岩かげから急に飛び出すウツボ。連続正解の勢いに弱い。',
      'ガブッ！ 油断したな！',
      '勢いに…のまれた…',
    ),
    VoyageMonster(
      'アンモナイト博士',
      'ammonite',
      0xFFC9A27E,
      '化石から目覚めた博士。殻にこもって守りを固める。',
      'この殻、弱点を突かずに割れるかね？',
      'ほう…殻が…割れたか…',
    ),
    VoyageMonster(
      'トゲトゲウニ',
      'urchin',
      0xFF5E4B8B,
      'とげを伸ばしてダメージを受け流すウニ。',
      'とげに気をつけな！',
      'とげが…ぬけた…',
    ),
  ];

  static const _seaBoss = VoyageMonster(
    '範囲の海竜リヴァイアサン',
    'leviathan',
    0xFF1F4E79,
    '試験範囲の海の底で眠っていた海竜。範囲のすべてを飲みこんでいる。',
    'ここは範囲の底。すべての問いに答えられる者だけが、浮かびあがれる！',
    'み、見事だ…海面へ帰るがいい…',
  );

  static const _skySurface = [
    VoyageMonster(
      '雨雲ぼうず',
      'cloudling',
      0xFF90A4AE,
      '頭の上に雨雲をのせている。まちがえると雨をふらせて、次の問題を読みにくくする。',
      'ざあざあ…集中なんて、させないよ！',
      '晴れちゃった…',
    ),
    VoyageMonster(
      '偏差値ガラス',
      'bird',
      0xFF37474F,
      '偏差値の数字を集める黒い鳥。連続で正解しないと、ひらりとかわされる。',
      'カァ！ おまえの偏差値、いくつだ？',
      'カァ…上がってる…',
    ),
    VoyageMonster(
      '雷鳴のカミナリ玉',
      'thunder',
      0xFFFFCA28,
      'ゴロゴロと鳴る雷のかたまり。続けて正解しないと、ほとんどダメージが通らない。',
      'ゴロゴロ…一問でもまちがえたら、落とすぞ！',
      'ゴロ…ゴロ…',
    ),
    VoyageMonster(
      '模試ワイバーン',
      'wyvern',
      0xFF5C6BC0,
      '模試の会場の空を飛びまわる翼竜。うろこがかたく、打たれ強い。',
      'この空は、判定の空だ。落ちたくなければ答えろ！',
      'つばさが…',
    ),
    VoyageMonster(
      'フウセンオバケ',
      'balloon',
      0xFFEF5350,
      'ふわふわ浮かぶ風船のおばけ。すばやく答えないとつかまらない。',
      'つかまえてごらん〜',
      'ぱちん…われちゃった…',
    ),
    VoyageMonster(
      'タコアゲ',
      'kite',
      0xFFFFB74D,
      'しっぽに札をつけて舞う凧。連続正解の勢いを風で吹き飛ばす。',
      'その勢い、風で止めてやる！',
      '糸が…切れた…',
    ),
    VoyageMonster(
      'テンシノシオリ',
      'angel',
      0xFFE3F2FD,
      '空の図書館を守る天使。弱点の分野を見ぬかれると弱い。',
      'このしおりの先へは、通しません',
      'しおりが…落ちた…',
    ),
    VoyageMonster(
      'ハクシキフクロウ',
      'owl',
      0xFF8D6E63,
      '夜の雲海で講義するフクロウ。まちがえると難問を出してくる。',
      'では、この問題はどうかね？',
      'ほう…よく学んでおる…',
    ),
  ];

  static const _skyDeep = [
    VoyageMonster(
      '隕石ゴーレム',
      'meteor',
      0xFF8D6E63,
      '宇宙から落ちてきた岩のかたまり。とても打たれ強い。',
      'ゴゴゴ…ぶつかるまで、あと少し…',
      'ゴ…くだけた…',
    ),
    VoyageMonster(
      'E判定UFO',
      'ufo',
      0xFF80CBC4,
      'ぴかぴか光って「E判定」の光線をあびせてくる。まちがえると、むずかしい問題を呼びよせる。',
      'ピピピ…判定を、はじめます…',
      'ピ…判定、A…？',
    ),
    VoyageMonster(
      'フェニックス',
      'phoenix',
      0xFFD64545,
      '赤ペンの炎から生まれた不死鳥。炎の翼でダメージを受け流す。',
      'その答え、赤ペンで採点してやろう！',
      '見事…花丸を…あげよう…',
    ),
    VoyageMonster(
      'ペガサスパート',
      'pegasus',
      0xFFF5F5F5,
      '五線譜の雲を駆けるペガサス。遅れた答えはかわされる。',
      'テンポよく答えないと、追いつけないよ！',
      '拍子が…くずれた…',
    ),
    VoyageMonster(
      'グリフォンガード',
      'griffin',
      0xFFC9A066,
      '知識の宝物庫を守る門番。弱点を突くまで守りが固い。',
      'ここから先は、本物の実力が必要だ',
      '通るがいい…',
    ),
    VoyageMonster(
      'ニジヘビ',
      'rainbow',
      0xFF7986CB,
      '7色の帯で体を守るヘビ。2問続けて正解しないと効かない。',
      '7色ぜんぶ、見ぬけるかな？',
      '虹が…消えていく…',
    ),
  ];

  static const _skyBoss = VoyageMonster(
    '天空の審判アストラル',
    'astral',
    0xFF3949AB,
    '星空の果てで、すべての答えを見とおす審判。模試の範囲のすべてを知っている。',
    'ここは星の果て。おまえの本当の実力を、判定しよう！',
    '判定…合格圏…みごとだ…',
  );
}
