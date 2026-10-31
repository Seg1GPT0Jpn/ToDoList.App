import '../models/rpg_progress.dart';
import 'story.dart';

/// 物語の場面で話す人
enum StorySpeaker {
  /// 地の文（語り）
  narrator(''),

  /// 主人公（名前は {name} に置きかわる）
  hero('{name}'),

  /// 守護者・長老など（名前と姿は場面ごとに決まる）
  keeper(''),

  /// 虚無の霧ネブラ（ラスボス）
  nebra('虚無の霧ネブラ');

  const StorySpeaker(this.label);
  final String label;
}

/// 物語のせりふ1つ
class StoryLine {
  const StoryLine(this.speaker, this.text, {this.name, this.look, this.color});

  final StorySpeaker speaker;
  final String text;

  /// 話す人の名前（守護者など、場面ごとに変わるとき）
  final String? name;

  /// 話す人の姿（enemy_painter の look）と色。守護者のせりふで使う
  final String? look;
  final int? color;

  /// 画面に出す名前
  String speakerName(String heroName) =>
      (name ?? speaker.label).replaceAll('{name}', heroName);

  /// 画面に出す文（{name} を主人公の名前に置きかえる）
  String textFor(String heroName) => text.replaceAll('{name}', heroName);
}

/// 物語の場面（読み終えると、進行状況に「読んだ」しるしがつく）
class StoryScene {
  const StoryScene({
    required this.id,
    required this.chapter,
    required this.title,
    required this.lines,
    this.color = 0xFF6D4C41,
    this.keeperLook,
  });

  final String id;

  /// 何章か（0 = 序章、1〜5 = 各国、7 = 終章）
  final int chapter;
  final String title;
  final List<StoryLine> lines;

  /// 場面の背景の色（ARGB）
  final int color;

  /// 守護者の色（ARGB）
  final int? keeperLook;

  /// 進行状況に残す「読んだ」しるし
  String get flag => 'story:$id';
}

/// つづりクエストの物語の場面。
///
/// あらすじ：
/// 世界を調和させていた「理の輝石」が砕け、黒い霧が五つの国を侵食した。霧に触れた
/// 守護者たちは狂気に呑まれる。まだ自らの文字を持たない見習い勇者は、白紙の聖典
/// 「スペル・グリモワール」に乱れた理の真の名を刻み直し、守護者たちを正気にもどして
/// 五つの証を集める。天空の図書院で虚無の霧ネブラと対決し、守護者たちの力を背に、
/// 最後の「つづり」を刻む。
class StoryScenes {
  const StoryScenes._();

  static const _colors = {
    'japanese': 0xFF8E3B46,
    'math': 0xFF5A4A2A,
    'english': 0xFF2F5D7C,
    'science': 0xFF4B3A7A,
    'social': 0xFF6B5030,
  };

  /// 国の章の番号（1〜5＝第一章〜第五章）。挑む順は自由
  static int chapterOf(String worldId) =>
      Story.worlds.indexWhere((w) => w.worldId == worldId) + 1;

  static bool _has(String worldId) =>
      Story.worlds.any((w) => w.worldId == worldId);

  /// 守護者のせりふ（狂気に呑まれているとき）
  static StoryLine _g(String worldId, String text) {
    final w = Story.of(worldId);
    return StoryLine(StorySpeaker.keeper, text,
        name: w.guardian, look: w.guardianLook, color: w.guardianColor);
  }

  /// 守護者のせりふ（正気にもどったあと。色が明るくなる）
  static StoryLine _p(String worldId, String text, {int color = 0xFFF5F2E8}) {
    final w = Story.of(worldId);
    return StoryLine(StorySpeaker.keeper, text,
        name: w.guardian, look: w.guardianLook, color: color);
  }

  static const _n = StorySpeaker.narrator;
  static const _h = StorySpeaker.hero;
  static const _x = StorySpeaker.nebra;

  /// 序章
  static const prologue = StoryScene(
    id: 'prologue',
    chapter: 0,
    title: '序章　白紙の旅立ち',
    color: 0xFF3E5B3A,
    lines: [
      StoryLine(
          _n, '世界の中心にそびえる大樹「アカデミア」。その幹に広がる無数の枝葉は、人々の知識や探求心と共鳴し、五つの豊かな国を抱えていた。'),
      StoryLine(_n, 'かつて世界を調和させていた「理の輝石」が砕け散るまでは。'),
      StoryLine(
          _n, '砕けた石の破片は黒い霧へと変わり、五つの国を侵食した。霧に触れた守護者たちは狂気に呑まれ、世界から「理解」が失われていく。'),
      StoryLine(_n, '残されたのは、まだ自らの文字を持たない見習い勇者と、白紙の聖典「スペル・グリモワール」だけだった。'),
      StoryLine(_n, '始まりの広場に立つ幼き勇者{name}は、先代の英雄たちが残した古びた革表紙の本を握りしめていた。'),
      StoryLine(_n, '表紙には金色の装飾が施されているが、中身には一切の文字が書かれていない。'),
      StoryLine(StorySpeaker.keeper, 'お前が書き記すのだ。',
          name: _elderName, color: _elderColor),
      StoryLine(StorySpeaker.keeper,
          'この世界を救う唯一の手段は、剣で切り裂くことではない。乱れた理を正しく見極め、その真の名をグリモワールへ刻み直すことだ。',
          name: _elderName, color: _elderColor),
      StoryLine(_n, '広場の長老は、震える手で勇者の肩を押した。'),
      StoryLine(_n, '勇者の目の前には、五つの国へと続く転送門が円を描いて並んでいる。'),
      StoryLine(_n, 'どこから向かうかは、勇者自身の意志に委ねられていた。'),
    ],
  );

  static const _elderName = '広場の長老';
  static const _elderColor = 0xFF8064A2;

  static const _kanji = ['一', '二', '三', '四', '五'];

  static List<StoryScene> _world(String w) {
    final c = _colors[w]!;
    final ch = chapterOf(w);
    final story = Story.of(w);
    final head = '第${_kanji[ch - 1]}章';
    StoryScene scene(String kind, String title, List<StoryLine> lines) =>
        StoryScene(
          id: '$w:$kind',
          chapter: ch,
          title: '$head　$title',
          color: c,
          keeperLook: story.guardianColor,
          lines: lines,
        );
    switch (w) {
      case 'japanese':
        return [
          scene('intro', '言の葉の国　墨染めの森', [
            const StoryLine(_n, '足を踏み入れた「言の葉の国」は、かつて言霊の清流が流れる美しい庭園だった。'),
            const StoryLine(
                _n, 'しかし今や、木々の葉には乱暴な殴り書きが刻まれ、川の水は真っ黒なインクのように濁り果てている。'),
            const StoryLine(_n, '森の奥へ進む勇者の前に立ちふさがるのは、文字の順番が崩壊した奇怪な怪物たち。'),
            const StoryLine(_n,
                '意味をなさなくなった単語の槍を振り回す敵に対し、勇者はグリモワールを開き、散らばった文字の破片を正しく整えていく。'),
            const StoryLine(_n, '主語と述語が結ばれ、比喩の意味が明かされるたび、敵は元の小鳥や草木へと還っていった。'),
          ]),
          scene('boss', '沈黙の巨鳥', [
            const StoryLine(_n, '最深部「言霊の大講堂」で待ち受けていたのは、巨大な筆の尾羽を持つ巨鳥「カラスバ」。'),
            const StoryLine(
                _n, 'その白かったはずの羽毛は、世界中から集まった悪口や嘲笑の墨を吸い込み、重くドロドロに染まっていた。'),
            _g(w, '誰もが言葉で他人を切り裂く……ならば、すべての言葉を沈黙の闇に塗り潰してしまえばいい！'),
            const StoryLine(_n, 'カラスバは黒インクの嵐を巻き起こし、勇者の言葉を奪おうとする。'),
          ]),
          scene('clear', '言霊の羽ペン', [
            const StoryLine(
                _n, '勇者は濁流のような暴言をかいくぐり、相手を気遣い、傷を癒やすための真摯な言葉をグリモワールに強く書き殴った。'),
            const StoryLine(_n,
                '光を放つ言霊がカラスバの全身を包み込む。黒いインクが剥がれ落ち、純白の羽を取り戻したカラスバは、静かに頭を垂れた。'),
            _p(w, '言葉は刃にもなれば、凍えた心を包む羽毛にもなる。忘れていた温もりを思い出させてくれたな。'),
            const StoryLine(_n, 'カラスバから託されたのは、柔らかな風を宿す「言霊の羽ペン」。これが最初の鍵となった。'),
          ]),
        ];
      case 'math':
        return [
          scene('intro', '数理の迷宮国　狂った天秤', [
            const StoryLine(_n, '次に勇者が訪れたのは、幾何学模様のタイルが敷き詰められた「数理の迷宮国」。'),
            const StoryLine(
                _n, '本来ならば狂いなく時を刻むはずの時計塔は針をデタラメに回し、左右対称だった建造物はバランスを崩して傾いていた。'),
            const StoryLine(_n, '重さの概念が崩れ、軽石が地面を砕き、巨岩が風船のように浮かんでいる。'),
            const StoryLine(_n, '道行く算術兵たちは、解けない連立方程式の幻影に囚われて暴走していた。'),
            const StoryLine(
                _n, '勇者は床の図形の面積を導き出し、狂った速度で迫るトラップの到達時間を計算して迷宮を突破していく。'),
          ]),
          scene('boss', '永久の歯車', [
            const StoryLine(_n, '最深部の「論理の大時計台」には、巨大な真鍮の巨人「カラクリ・ゴーレム」が鎮座していた。'),
            const StoryLine(_n, 'その胸にある大天秤は激しく揺れ動き、歯車は摩擦で火花を散らしている。'),
            _g(w, '等号が成立しない……解が存在しない世界に、存在する価値などない。すべてを零へと還元する。'),
            const StoryLine(_n, 'ゴーレムの両腕から放たれるのは、あらゆる数値をゼロにリセットする無慈悲な波動。'),
          ]),
          scene('clear', '黄金の歯車', [
            const StoryLine(_n, '勇者は回避しながら、ゴーレムの全身を巡る歯車の歯数、回転比、天秤の傾きを正確に読み解く。'),
            const StoryLine(_n,
                '胸のコアに隠された最後の計算式を解き明かし、ぴったり釣り合う答えをグリモワールに刻み込んだ瞬間、ゴーレムの軋む音が止まった。'),
            const StoryLine(_n, 'ガチリと噛み合った最後の歯車が、澄んだ鐘の音を響かせる。'),
            _p(w, '等号は美しく結ばれた。論理の道筋を恐れずに歩んだ勇者よ、見事である。', color: 0xFFD8B45A),
            const StoryLine(_n, 'ゴーレムの胸から、完璧な対称性を誇る「黄金の歯車」が勇者の手に渡った。'),
          ]),
        ];
      case 'english':
        return [
          scene('intro', '異界の港町　閉ざされた海峡', [
            const StoryLine(_n, '「異界の港町」は、本来であれば様々な海を渡る商人たちで賑わうはずの場所だった。'),
            const StoryLine(_n, 'しかし港は濃い霧と大しけに閉ざされ、停泊した船は錆びついている。'),
            const StoryLine(_n, '町の人々は互いの母国語しか話せず、恐怖から互いを疑い、門を閉ざしていた。'),
            const StoryLine(_n,
                '外洋から押し寄せるモンスターたちは、バラバラになったアルファベットの鱗をまとい、奇妙な叫び声をあげて威嚇してくる。'),
            const StoryLine(_n,
                '勇者はそれらの文字を拾い集め、挨拶や感情を伝える単語へと組み替えていく。意味が通じた瞬間、モンスターたちの警戒は解け、光となって海へ消えていった。'),
          ]),
          scene('boss', '孤独な怪獣', [
            const StoryLine(_n, '海峡の出口を塞いでいたのは、巨大な海獣「バベル・リヴァイアサン」。'),
            const StoryLine(_n, 'その巨体には世界中の文字が刻まれているが、互いに反発し合って激しい雷鳴を放っていた。'),
            _g(w, '異なる言葉を持つ者は、互いを傷つけ合うだけだ。理解できぬなら、最初から交わらぬよう海を閉ざす！'),
            const StoryLine(_n, 'リヴァイアサンが巻き起こす大津波が、勇者を呑みこもうと迫る。'),
          ]),
          scene('clear', '通訳の羅針盤', [
            const StoryLine(_n, '大津波に呑まれそうになりながら、勇者は必死に綴りを紡ぐ。'),
            const StoryLine(_n,
                '「Hello」「Help」「Together」――遠く離れた者同士の手を繋ぐための言葉を、海獣の鱗に直接書き込んでいく。'),
            const StoryLine(_n, '文字同士の反発が収まり、青く澄んだ光が海峡全体に広がった。海は凪ぎ、嵐は消え去る。'),
            _p(w, '未知の言葉の向こうに、対話を求める心を見た。我が海は再び開かれた。', color: 0xFF7EC8F0),
            const StoryLine(_n, 'リヴァイアサンは静かに海中へ沈み、波間から「通訳の羅針盤」を勇者へと託した。'),
          ]),
        ];
      case 'science':
        return [
          scene('intro', '万物の実験庭園　乱れる天秤', [
            const StoryLine(_n, '続いて足を踏み入れた「万物の実験庭園」は、自然の法則が完全に崩壊していた。'),
            const StoryLine(
                _n, '水底で火が燃え盛り、氷の山からマグマが噴き出し、植物は光を避けて暗闇で異常増殖を繰り返している。'),
            const StoryLine(_n, '襲いかかるのは、異なる性質を無理やり接ぎ合わされた不完全な生物たち。'),
            const StoryLine(_n,
                '勇者は光の屈折を利用して姿を隠す敵を暴き、酸とアルカリの中和反応を使って障壁を溶かし、植物の光合成を促して道を切り拓いていく。'),
          ]),
          scene('boss', '暴走のキメラ', [
            const StoryLine(
                _n, '庭園の最奥、巨大な試験管が並ぶ「生命の樹」の前にいたのは、炎と氷の双頭を持つ合成獣「カオス・エレメンタル」。'),
            const StoryLine(_n,
                '右半身は超高温で地面を溶かし、左半身は絶対零度で大気を凍らせている。互いの温度差が激痛を生み、怪物は狂乱状態で暴れ回っていた。'),
            _g(w, '熱い……冷たい……世界の理が我を裂く！ すべてを燃やし、すべてを凍てつかせよ！'),
            const StoryLine(_n, '制御不能のエネルギー弾が、雨のように降り注ぐ。'),
          ]),
          scene('clear', '元素の天球儀', [
            const StoryLine(
                _n, 'エネルギー弾が降り注ぐ中、勇者は観察を続けた。炎を消すための酸素の遮断、氷を溶かすための潜熱の移動。'),
            const StoryLine(
                _n, '自然界の法則を一つひとつ適用し、エレメンタルの周囲の熱エネルギーを安定した循環へと導いていく。'),
            const StoryLine(_n, '激痛から解放された怪物は、穏やかな光の粒子へと姿を変えた。'),
            _p(w, 'なぜそうなるのか……理由を知る者が、混沌に安らぎを与えてくれた。', color: 0xFF9FD8C8),
            const StoryLine(_n, '残された光の球は、四季の巡りを宿す「元素の天球儀」となって勇者のグリモワールへ収まった。'),
          ]),
        ];
      default:
        // 時空の回廊（社会）
        return [
          scene('intro', '時空の回廊　砂に埋もれる記憶', [
            const StoryLine(
                _n, '「時空の回廊」は、古代の石造建築、中世の城郭、近代の工場地帯が不気味に重なり合う奇妙な空間だった。'),
            const StoryLine(_n, 'そこでは、過去の人々が築いてきた営みが白い砂となって崩れ落ちていた。'),
            const StoryLine(
                StorySpeaker.keeper, 'どうせすべては過去のこと。知ったところで今を生きる自分には関係ない。',
                name: '回廊の住民', color: 0xFF9E9E9E),
            const StoryLine(
                _n, '住民たちは無気力に瞳を曇らせ、地図は白紙になり、歴史書はインクが掠れて読めなくなっている。'),
            const StoryLine(_n,
                '土地の気候や人々の知恵が生み出した産業を無視した怪物が徘徊する中、勇者は等高線を読み、人々の交易ルートを再現し、古い年表を正しく繋ぎ合わせて進んだ。'),
          ]),
          scene('boss', '幽幻の騎士', [
            const StoryLine(
                _n, '回廊の中心に広がる荒野で待ち受けていたのは、錆びついた全身鎧をまとう「クロノス・ナイト」。'),
            const StoryLine(_n, '無数の折れた旗指物が、彼の背中に突き刺さっていた。'),
            _g(w, '人間が歩んできた苦難の道など、誰も覚えちゃいない。過去を忘れ、今だけを貪る世界など、砂となって消え失せるがいい！'),
            const StoryLine(_n, '騎士の剣は、過去を消し去る風を巻き起こす。'),
          ]),
          scene('clear', '悠久の砂時計', [
            const StoryLine(_n,
                '勇者は退かずに立ち向かい、人々が自然と闘いながら築き上げた堤防の記憶、飢饉を乗り越えるために結ばれた交易の歴史、自由を求めて勝ち取った法の重みを次々とグリモワールに呼び覚ました。'),
            const StoryLine(_n, '騎士の剣が、勇者の額すれすれで止まる。'),
            _g(w, 'お前は知っているのか……我らが流した血も、築いた石垣も、すべて今の世界へと繋がっていることを。'),
            const StoryLine(_n, '騎士の錆びた鎧が剥がれ落ち、誇り高き黄金の甲冑が現れる。'),
            const StoryLine(_n, '騎士は片膝をつき、勇者に「悠久の砂時計」を差し出した。'),
          ]),
        ];
    }
  }

  /// 終章（天空の図書院の決戦の前）
  static const finaleBefore = StoryScene(
    id: 'finale:before',
    chapter: 7,
    title: '終章　天空の図書院',
    color: 0xFF2A2840,
    lines: [
      StoryLine(_n, '五つの証を手に入れたとき、大樹アカデミアの天頂を貫く光の柱が現れ、勇者を「天空の図書院」へと導いた。'),
      StoryLine(_n, 'そこは世界のすべての知識が記録される神聖な場所のはずだった。'),
      StoryLine(_n, 'しかし今、書架は灰色に染まり、中央の台座には底知れぬ黒い霧「ネブラ」が渦巻いている。'),
      StoryLine(_x, 'よくぞここまで無駄な足掻きを重ねたものだ。'),
      StoryLine(_n, 'ネブラは不定形の顔を歪めて嘲笑った。'),
      StoryLine(_x, '言葉を知らなくても生きられる。計算など機械に任せればよい。'),
      StoryLine(_x, '遠い異国のことなど知る必要もなく、自然の仕組みも過去の歴史も、知らなければ誰も傷つかない。'),
      StoryLine(_x, 'なぜ苦しんでまで学ぼうとする？ 考えることをやめれば、どれほど楽になれるか。'),
      StoryLine(_n, 'ネブラの放つ暗黒は、勇者の心に直接「めんどくさい」「意味がない」という甘い毒を注ぎ込む。'),
      StoryLine(_n, '勇者の膝が折れかけ、グリモワールが手から滑り落ちそうになる。'),
      StoryLine(_n, 'その時、集めた五つの証がまばゆい光を放った。背後から声が響く。'),
      StoryLine(StorySpeaker.keeper, '（白きカラスバが、言葉の力を送る）',
          name: '巨鳥カラスバ', look: 'bird', color: 0xFFF5F2E8),
      StoryLine(StorySpeaker.keeper, '（カラクリ・ゴーレムが、迷いを断つ論理を支える）',
          name: 'カラクリ・ゴーレム', look: 'golem', color: 0xFFD8B45A),
      StoryLine(StorySpeaker.keeper, '（バベル・リヴァイアサンが、世界へ届く声を響かせる）',
          name: 'バベル・リヴァイアサン', look: 'leviathan', color: 0xFF7EC8F0),
      StoryLine(StorySpeaker.keeper, '（カオス・エレメンタルが、世界の調和を示す）',
          name: 'カオス・エレメンタル', look: 'dragon', color: 0xFF9FD8C8),
      StoryLine(StorySpeaker.keeper, '（クロノス・ナイトが、先人たちの誇りを勇者の背に宿す）',
          name: 'クロノス・ナイト', look: 'knight', color: 0xFFE0C890),
      StoryLine(_n, '勇者は顔を上げた。'),
      StoryLine(_h, '考えるのをやめたら、誰かの痛みに気づくことも、遠い誰かと笑い合うことも、明日の世界を創ることもできない！'),
    ],
  );

  /// エピローグ（天空の図書院の決戦に勝ったあと）
  static const epilogue = StoryScene(
    id: 'finale:after',
    chapter: 7,
    title: '終章　紡がれる答え',
    color: 0xFF3E6B4A,
    lines: [
      StoryLine(_n,
          '勇者は白紙だったグリモワールの最後の頁に、五教科のすべての知識と自らの旅の記憶をひとつに束ね、最後の「つづり」を力強く刻み込んだ。'),
      StoryLine(_n, '刻まれたのは、単なる記号や暗記の羅列ではない。「世界を知り、誰かと生きていくための誓い」だった。'),
      StoryLine(_n, '放たれた光の奔流が虚無の霧を貫き、ネブラの暗闇を鮮やかな朝焼けの色へと染め替えていく。'),
      StoryLine(_n, '灰色だった書架には色鮮やかな書物が戻り、大樹アカデミアは満開の知恵の花を咲かせた。'),
      StoryLine(_n, '光の中、グリモワールの表紙に勇者自身の真の名――「{name}」が浮かび上がる。'),
      StoryLine(_n, '見習いだった勇者は、世界に新たな理を刻み込んだ「真の言霊の勇者」として、新たな風が吹き抜ける大陸を見つめていた。'),
      StoryLine(_n, '―― つづりクエスト　おしまい。……そして、あなたの学びは、まだ続く。'),
    ],
  );

  /// すべての場面（章の順）
  static List<StoryScene> get all => [
        prologue,
        for (final w in Story.worlds) ..._world(w.worldId),
        finaleBefore,
        epilogue,
      ];

  static StoryScene byId(String id) => all.firstWhere((s) => s.id == id);

  /// 国に入ったときの場面
  static StoryScene intro(String worldId) => byId('$worldId:intro');

  /// その国の道の果ての守護者に、はじめて挑む前の場面
  static StoryScene boss(String worldId) => byId('$worldId:boss');

  /// 守護者を正気にもどし、証を受け取ったときの場面
  static StoryScene clear(String worldId) => byId('$worldId:clear');

  /// 読んだか
  static bool seen(RpgProgress p, StoryScene s) =>
      p.fieldFlags.contains(s.flag);

  /// 読んだしるしをつけた進行状況
  static RpgProgress markSeen(RpgProgress p, StoryScene s) =>
      p.copyWith(fieldFlags: {...p.fieldFlags, s.flag});

  /// 国のフィールドに入ったときに見せる場面（まだ読んでいないもの。序章→国の導入→証）
  static List<StoryScene> onEnterWorld(RpgProgress p, String worldId) {
    if (!_has(worldId)) return const [];
    final got = Story.fragments(p);
    return [
      if (!seen(p, prologue)) prologue,
      if (!seen(p, intro(worldId))) intro(worldId),
      if (got.contains(worldId) && !seen(p, clear(worldId))) clear(worldId),
    ];
  }

  /// その国の最後のボスに挑む前に見せる場面（まだ読んでいなければ）
  static StoryScene? beforeFinalBoss(
      RpgProgress p, String worldId, String stageId) {
    if (!_has(worldId)) return null;
    final isFinal = Story.finalsOf(worldId).any((s) => s.id == stageId);
    if (!isFinal) return null;
    final s = boss(worldId);
    return seen(p, s) ? null : s;
  }

  /// 物語の画面で読める（読んだ）場面
  static List<StoryScene> unlocked(RpgProgress p) => [
        for (final s in all)
          if (seen(p, s)) s
      ];
}
