import '../models/rpg_progress.dart';
import 'story.dart';

/// 物語の場面で話す人
enum StorySpeaker {
  /// 地の文（語り）
  narrator(''),

  /// 主人公（名前は {name} に置きかわる）
  hero('{name}'),

  /// 国の守護神（名前と姿は場面ごとに決まる）
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

  /// 話す人の名前（守護神など、場面ごとに変わるとき）
  final String? name;

  /// 話す人の姿（enemy_painter の look）と色。守護神のせりふで使う
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

  /// 守護神の色（ARGB）
  final int? keeperLook;

  /// 進行状況に残す「読んだ」しるし
  String get flag => 'story:$id';
}

/// つづりクエストの物語の場面。
///
/// あらすじ：
/// 大樹アカデミアが枯れはじめ、5つの国の守護神が暴走した。留守番をしていた
/// 言霊の勇者の見習いは、白紙の聖典「スペル・グリモワール」に学んだ正解を綴り、
/// 守護神たちを浄化していく。守護神の暴走した力は、学年の道の果てごとに分かれて
/// 暴れていて、すべての道の果てで勝つと、守護神は正気にもどって「国の証」と
/// 「知識の欠片」を授けてくれる。5つの欠片がそろうと天空の図書院がひらき、
/// 虚無の霧ネブラとの決戦では、救った守護神たちが駆けつけて力を託してくれる。
class StoryScenes {
  const StoryScenes._();

  static const _colors = {
    'japanese': 0xFF8E3B46,
    'math': 0xFF5A4A2A,
    'english': 0xFF2F5D7C,
    'science': 0xFF4B3A7A,
    'social': 0xFF6B5030,
  };

  /// 国の章の番号（1〜5）。物語の画面に並べる順で、挑む順は自由
  static int chapterOf(String worldId) =>
      Story.worlds.indexWhere((w) => w.worldId == worldId) + 1;

  static bool _has(String worldId) =>
      Story.worlds.any((w) => w.worldId == worldId);

  /// 守護神のせりふ（暴走しているとき）
  static StoryLine _g(String worldId, String text) {
    final w = Story.of(worldId);
    return StoryLine(StorySpeaker.keeper, text,
        name: w.guardian, look: w.guardianLook, color: w.guardianColor);
  }

  /// 守護神のせりふ（正気にもどったあと。色が明るくなる）
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
    title: '序章　白紙のグリモワール',
    color: 0xFF3E5B3A,
    lines: [
      StoryLine(_n, '世界の中心には、すべての知識を葉に変えて茂る大樹「アカデミア」がある。'),
      StoryLine(_n, '大樹を守るのは「言霊（つづり）の勇者」たち。……けれど先代の勇者たちは、遠い旅に出たまま帰らない。'),
      StoryLine(_n, 'ある朝。アカデミアの葉が、はらはらと茶色く散りはじめた。'),
      StoryLine(_n, '大樹とつながる5つの国から、守護神たちのうめき声が聞こえてくる。苦しみのあまり、暴走してしまったのだ。'),
      StoryLine(_h, '先輩たちは、まだ帰ってこない……。「まだ未熟だから」って、留守番を任されたけど……。'),
      StoryLine(_n, 'そのとき、{name}の手の中で、白紙の本が光った。聖典「スペル・グリモワール」。'),
      StoryLine(_n, '学んだ正解を書きこむ（綴る）と、その言葉が奇跡の魔法になる――勇者だけが使える本だ。'),
      StoryLine(_h, '……このページは、まだ真っ白。でも、学べば書ける。書けば、戦える。'),
      StoryLine(_h, '守護神たちは、悪者じゃない。苦しんでいるだけなんだ。だったら、ぼくが助けにいく！'),
      StoryLine(_n, '和の礎の国、数理の迷宮国、異界の港町、万物の実験庭園、時空の回廊。'),
      StoryLine(_n, 'どの国から行くかは、きみが決めていい。得意な教科でも、好きな景色の国でも。'),
      StoryLine(_n, '――見習い勇者{name}の旅が、いま始まる。'),
    ],
  );

  static List<StoryScene> _world(String w) {
    final c = _colors[w]!;
    final ch = chapterOf(w);
    final story = Story.of(w);
    StoryScene scene(String kind, String title, List<StoryLine> lines) =>
        StoryScene(
          id: '$w:$kind',
          chapter: ch,
          title: title,
          color: c,
          keeperLook: story.guardianColor,
          lines: lines,
        );
    switch (w) {
      case 'japanese':
        return [
          scene('intro', '和の礎の国　黒く染まった空', [
            const StoryLine(_n, '和の礎の国。言葉と文字の礎がきずかれた、桜と筆の国。'),
            const StoryLine(_n, 'けれど今、空には黒いインクのしずくが降り、人びとの言葉はとげとげしくなっていた。'),
            _g(w, 'カァァ……！ うるさい、うるさい……！ もう、とげの言葉は聞きたくない……！'),
            const StoryLine(_h, 'あれが、この国の守護神……筆の尾羽をもつ鳥の精霊、カラスバ。'),
            const StoryLine(_n, 'カラスバは、人びとの悪口や乱暴な言葉を吸いこみすぎて、体が真っ黒なインクに染まってしまったのだ。'),
            const StoryLine(_n, 'その暴れる力は、学年の道ごとに分かれ、それぞれの道の果てで荒れくるっている。'),
            const StoryLine(_h, 'ひらがな、漢字、言葉のきまり、物語……。正しく美しい言葉を、グリモワールに綴っていこう。'),
          ]),
          scene('boss', '和の礎の国　墨の羽', [
            const StoryLine(_n, '道の果て。墨のしぶきをまき散らしながら、カラスバが舞いおりた。'),
            _g(w, '言葉なんて、人を傷つけるだけだ……！ おまえの言葉も、どうせとげだらけなんだろう！'),
            const StoryLine(_h, 'ちがう。言葉は、だれかを温めることだってできる。それを、いまから見せる！'),
            const StoryLine(_n, 'グリモワールのページが、白く光りはじめた。'),
          ]),
          scene('clear', '和の礎の国　白羽の紋章', [
            const StoryLine(_n, '最後の答えを綴ったとき、カラスバの体から黒いインクが流れ落ちていった。'),
            const StoryLine(_n, 'そこに立っていたのは、雪のように白い、美しい鳥だった。'),
            _p(w, '……わたしは、なにを……。そうか、きみが止めてくれたのだね。'),
            _p(w, '言葉は、心を傷つけるトゲにも、温める羽毛にもなる。美しい言の葉を紡いでくれて、ありがとう。'),
            _p(w, 'この「白羽の紋章」と「言の葉の欠片」を。わたしの力も、きみのグリモワールに託そう。'),
            const StoryLine(_n, 'グリモワールの1ページめに、白い羽の紋章が浮かびあがった。'),
          ]),
        ];
      case 'math':
        return [
          scene('intro', '数理の迷宮国　狂った歯車', [
            const StoryLine(_n, '数理の迷宮国。数と図形のきまりで組みあげられた、歯車と回廊の国。'),
            const StoryLine(_n, 'けれど今、迷宮の歯車はでたらめに回り、通路は勝手に組みかわっていた。'),
            _g(w, 'ケイサン、フメイ。キンコウ、ホウカイ。……シンニュウシャ、ハイジョ。'),
            const StoryLine(_h, '歯車と天秤でできた時計仕掛けの巨人……あれが守護神、カラクリ・ゴーレム。'),
            const StoryLine(_n, '世界の計算が狂ったせいで歯車のバランスが崩れ、ゴーレムは止まらない永久機関と化していた。'),
            const StoryLine(_h, 'たし算から方程式まで、一段ずつ。正しい計算で、歯車の狂いを直してみせる！'),
          ]),
          scene('boss', '数理の迷宮国　永久機関', [
            const StoryLine(_n, '迷宮の最深部。ゴーレムの胸の天秤が、ぐらぐらとかたむいている。'),
            _g(w, 'ゴサ、ゴサ、ゴサ。スベテノ答エハ、クルッテイル。'),
            const StoryLine(_h, 'だったら、ひとつずつ確かめればいい。式を立てて、計算して、たしかめる！'),
          ]),
          scene('clear', '数理の迷宮国　天秤の紋章', [
            const StoryLine(_n, 'カチリ。最後の歯車がかみ合うと、ゴーレムの胸の天秤が、ぴたりと水平になった。'),
            _p(w, '……完璧な均衡を取りもどした。論理の力、見事なり。', color: 0xFFD8B45A),
            const StoryLine(_n, 'ゴーレムは静かに片ひざをつき、{name}に敬礼した。迷宮の通路が、まっすぐに開いていく。'),
            _p(w, '「天秤の紋章」と「数の欠片」を授ける。勇者よ、道は空けた。進まれよ。', color: 0xFFD8B45A),
          ]),
        ];
      case 'english':
        return [
          scene('intro', '異界の港町　閉ざされた港', [
            const StoryLine(_n, '異界の港町。世界中の船が集まり、いろいろな言葉が行き交っていた港。'),
            const StoryLine(_n, 'けれど今、港は黒い嵐に閉ざされ、一そうの船も出入りできない。'),
            _g(w, '……ワカラナイ……コトバガ、ワカラナイ……！ コワイ……ダレモ、チカヅクナ……！'),
            const StoryLine(_h, '嵐の中心に、世界中の文字の鱗をもつ巨大な魚……海獣バベル・リヴァイアサン！'),
            const StoryLine(_n, '互いの言葉が通じない恐怖から嵐が生まれ、リヴァイアサンはその嵐をまとって港を閉ざしてしまったのだ。'),
            const StoryLine(_h, 'あいさつ、単語、文のつくり方……。言葉をつなげば、きっと心も通じるはず。'),
          ]),
          scene('boss', '異界の港町　嵐の海獣', [
            const StoryLine(_n, '荒れくるう波の上に、リヴァイアサンが巨大な頭をもたげた。'),
            _g(w, 'シラナイ言葉ハ、コワイ。コワイモノハ、ゼンブ沈メル……！'),
            const StoryLine(_h, '知らない言葉は、こわくない。一語ずつ、ちゃんとつなげて伝えるよ。'),
            const StoryLine(_h, 'Hello. I am {name}. I want to help you!'),
          ]),
          scene('clear', '異界の港町　羅針の紋章', [
            const StoryLine(_n, '正しくつながった言葉が光の帆になって、嵐を吹きはらっていく。'),
            _p(w, '……聞こえた。おまえの言葉が、ちゃんと聞こえた。', color: 0xFF7EC8F0),
            _p(w, '未知の言葉を恐れず、伝える勇気を持てたのだな。その勇気が、わたしの嵐を晴らした。', color: 0xFF7EC8F0),
            const StoryLine(_n, '雲が切れ、港に光がさしこむ。止まっていた船が、いっせいに帆を上げた。'),
            _p(w, 'この「羅針の紋章」と「ことばの欠片」を持ってゆけ。どんな海でも、迷わぬように。', color: 0xFF7EC8F0),
          ]),
        ];
      case 'science':
        return [
          scene('intro', '万物の実験庭園　くるった法則', [
            const StoryLine(_n, '万物の実験庭園。生き物、物、熱や光、天気や星――世界の仕組みを確かめる庭。'),
            const StoryLine(_n, 'けれど今、庭の半分は燃え、もう半分は凍りつき、雨と日照りが同時に降っていた。'),
            _g(w, 'ア、アツイ……ツメタイ……！ イタイ、イタイ……！'),
            const StoryLine(_h, '右半身が炎、左半身が氷……炎氷竜カオス・エレメンタル。'),
            const StoryLine(_n, '熱・光・気候の法則が混ざり合い、竜はその激しい痛みに耐えかねて暴れているのだ。'),
            const StoryLine(_h, '観察して、実験して、なぜそうなるかを考える。正しい法則で、痛みをしずめよう。'),
          ]),
          scene('boss', '万物の実験庭園　炎と氷', [
            const StoryLine(_n, '炎と氷の嵐の中心で、カオス・エレメンタルが苦しげに吠えた。'),
            _g(w, '近づくな……！ 燃えても、凍っても、止まらないんだ……！'),
            const StoryLine(_h, 'だいじょうぶ。熱がどう伝わるか、光がどう進むか、ぼくが解き明かす！'),
          ]),
          scene('clear', '万物の実験庭園　炎氷の紋章', [
            const StoryLine(_n, '炎と氷が、ゆっくりと混ざりあうのをやめた。竜の体から、あたたかい光があふれる。'),
            _p(w, '……痛みが、消えていく。世界の仕組みを解き明かしてくれたおかげだ。', color: 0xFF9FD8C8),
            const StoryLine(_n, '荒れくるう竜は、穏やかな精霊の姿にもどっていた。庭園に、四季がふたたびめぐりはじめる。'),
            _p(w, '「炎氷の紋章」と「ことわりの欠片」を。ありがとう、小さな勇者。', color: 0xFF9FD8C8),
          ]),
        ];
      default:
        // 時空の回廊（社会）
        return [
          scene('intro', '時空の回廊　砂になる歴史', [
            const StoryLine(_n, '時空の回廊。むかしから今まで、人びとのくらしと歴史、世界の地図がつながる回廊。'),
            const StoryLine(_n, 'けれど今、回廊の壁画は砂になって崩れ、地図は白紙にもどりかけていた。'),
            _g(w, '誰も覚えていない……。誰も、ふりかえらない……。ならば、すべて砂にしてしまえ。'),
            const StoryLine(_h, '過去と現代の武具をまとった騎士……幽幻騎士クロノス・ナイト。'),
            const StoryLine(_n, '歴史や人びとの営みを忘れられた悲しみから、騎士は自暴自棄になってしまったのだ。'),
            const StoryLine(_h, 'くらし、地図、歴史、社会のしくみ……。覚えている人がいるって、ぼくが伝える！'),
          ]),
          scene('boss', '時空の回廊　砂の騎士', [
            const StoryLine(_n, '回廊の果て。砂嵐の中から、クロノス・ナイトが剣を抜いた。'),
            _g(w, '人びとの歩みなど、無駄だったのだ。忘れられるくらいなら、はじめからなかったことにする。'),
            const StoryLine(_h, '無駄なんかじゃない。いまのくらしは、ぜんぶ昔の人の歩みの上にあるんだ！'),
          ]),
          scene('clear', '時空の回廊　砂時計の紋章', [
            const StoryLine(_n, '{name}が地理と歴史の事実を綴るたびに、崩れた壁画がよみがえっていく。'),
            _p(w, '……思い出した。人々の歩んできた道は、決して無駄ではなかったのだな。', color: 0xFFE0C890),
            const StoryLine(_n, '騎士は剣をおさめ、胸を張った。その鎧に、誇りの光がもどっていた。'),
            _p(w, '「砂時計の紋章」と「時の欠片」を、きみに。これからの歴史は、きみたちが刻むのだ。', color: 0xFFE0C890),
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
      StoryLine(_n, '5つの欠片がそろったとき、大樹アカデミアのいちばん上に、光の扉があらわれた。'),
      StoryLine(_n, '扉の先は、世界の中心「天空の図書院」。……けれど本棚はすべて、灰色の霧にのみこまれていた。'),
      StoryLine(_x, '……よく来たね、小さな勇者。つかれたでしょう？'),
      StoryLine(_x, 'わたしはネブラ。知識を忘れて、考えることをやめた心のすきまから生まれた霧。'),
      StoryLine(_x, '解かなくてもいい。考えなくてもいい。……楽な暗闇へ、おいで……。'),
      StoryLine(_h, '（……まぶたが、重い……グリモワールの文字が、かすんでいく……）'),
      StoryLine(_n, 'そのとき――5つの光が、霧をつらぬいて図書院に飛びこんできた。'),
      StoryLine(StorySpeaker.keeper, '迷いの霧よ、正体を見せよ。言葉は、心の迷いを暴く！',
          name: '巨鳥カラスバ', look: 'bird', color: 0xFFF5F2E8),
      StoryLine(StorySpeaker.keeper, '霧の動きを計算した。隙は、そこだ！',
          name: '巨神カラクリ・ゴーレム', look: 'golem', color: 0xFFD8B45A),
      StoryLine(StorySpeaker.keeper, '霧は、熱で晴れる。弱点の属性を突け！',
          name: '炎氷竜カオス・エレメンタル', look: 'dragon', color: 0xFF9FD8C8),
      StoryLine(StorySpeaker.keeper, '思い出せ。世界は、たくさんの人の歩みでつながっている！',
          name: '幽幻騎士クロノス・ナイト', look: 'knight', color: 0xFFE0C890),
      StoryLine(StorySpeaker.keeper, 'さあ、世界中へ響く、最後の呪文を紡げ！',
          name: '海獣バベル・リヴァイアサン', look: 'leviathan', color: 0xFF7EC8F0),
      StoryLine(_h, 'みんな……！ ありがとう。5つの国の力を、ぜんぶグリモワールに綴る！'),
      StoryLine(_x, 'むだだよ……。学んだことなんて、いつか忘れる……。'),
      StoryLine(_h, '忘れたら、また学べばいい。考えることを、ぼくはやめない！'),
    ],
  );

  /// エピローグ（天空の図書院の決戦に勝ったあと）
  static const epilogue = StoryScene(
    id: 'finale:after',
    chapter: 7,
    title: '終章　満開のアカデミア',
    color: 0xFF3E6B4A,
    lines: [
      StoryLine(_x, 'なぜ……考えることを、やめないの……？ 霧が……晴れていく……。'),
      StoryLine(_n, '最後の呪文が図書院じゅうに響きわたり、灰色の霧は光の粒になってほどけていった。'),
      StoryLine(_n, '霧の晴れた本棚には、いままで{name}が綴ってきた、たくさんの正解が並んでいた。'),
      StoryLine(_n, 'グリモワールは、もう白紙ではない。5つの紋章が、表紙で静かにかがやいている。'),
      StoryLine(StorySpeaker.keeper, 'よくやった。きみこそ、一人前の「真の言霊の勇者」だ。',
          name: '5つの国の守護神たち'),
      StoryLine(_n, 'その日、大樹アカデミアの枝という枝に、満開の花が咲きほこった。'),
      StoryLine(_n, '花びらは5つの国にふりそそぎ、人びとはまた、学ぶことの楽しさを思い出した。'),
      StoryLine(_h, '……でも、グリモワールには、まだ白いページが残ってる。'),
      StoryLine(_n, '学びに、終わりはない。忘れかけたら「復習の塔」へ。新しいことは、また次の道へ。'),
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

  /// その国の道の果ての守護神に、はじめて挑む前の場面
  static StoryScene boss(String worldId) => byId('$worldId:boss');

  /// 守護神を浄化して、欠片と紋章を受け取ったときの場面
  static StoryScene clear(String worldId) => byId('$worldId:clear');

  /// 読んだか
  static bool seen(RpgProgress p, StoryScene s) =>
      p.fieldFlags.contains(s.flag);

  /// 読んだしるしをつけた進行状況
  static RpgProgress markSeen(RpgProgress p, StoryScene s) =>
      p.copyWith(fieldFlags: {...p.fieldFlags, s.flag});

  /// 国のフィールドに入ったときに見せる場面（まだ読んでいないもの。序章→国の導入→欠片）
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
