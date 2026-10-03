import '../models/rpg_progress.dart';
import 'story.dart';

/// 物語の場面で話す人
enum StorySpeaker {
  /// 地の文（語り）
  narrator(''),

  /// 主人公（名前は {name} に置きかわる）
  hero('{name}'),

  /// しおり：主人公といっしょに旅をする、しおりの精。記憶をなくしている
  shiori('しおり'),

  /// ノイズ：仮面の少年。忘却の魔王の手下として、行く先々に現れる
  noise('ノイズ'),

  /// 忘却の魔王
  oblivion('忘却の魔王'),

  /// その国の守り人（名前は場面ごとに決まる）
  keeper('');

  const StorySpeaker(this.label);
  final String label;
}

/// 物語のせりふ1つ
class StoryLine {
  const StoryLine(this.speaker, this.text, {this.name});

  final StorySpeaker speaker;
  final String text;

  /// 話す人の名前（守り人など、場面ごとに変わるとき）
  final String? name;

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

  /// 何章か（0 = 序章、1〜6 = 各国、7 = 終章）
  final int chapter;
  final String title;
  final List<StoryLine> lines;

  /// 場面の背景の色（ARGB）
  final int color;

  /// 守り人の服の色（ARGB）
  final int? keeperLook;

  /// 進行状況に残す「読んだ」しるし
  String get flag => 'story:$id';
}

/// 章（国）ごとの守り人
class _Keeper {
  const _Keeper(this.name, this.color);
  final String name;
  final int color;
}

/// つづりクエストの物語の場面。
///
/// あらすじ：
/// 忘却の魔王に知識をうばわれ、世界は5つの国に分かれた。見習い冒険者の主人公は、
/// 記憶をなくした「しおりの精」しおりと旅に出る。行く先々で、仮面の少年ノイズが
/// 「どうせ覚えても、すぐ忘れる」と立ちはだかる。欠片を集めるたびに、しおりは記憶を
/// 取りもどしていく。しおりの正体は、世界の図書館で「覚えている心」を守っていた司書。
/// 魔王は、人びとがあきらめて手ばなした「忘れられた学び」が集まって生まれた存在だった。
/// 最後に主人公は、魔王を消すのではなく「もう一度学ぶ」ことで、忘れられた知識を取りもどす。
class StoryScenes {
  const StoryScenes._();

  static const _keepers = {
    'english': _Keeper('言葉の女王リリカ', 0xFF4F81BD),
    'science': _Keeper('ことわりの博士ニュート', 0xFF4F8A4A),
    'social': _Keeper('年代記の長老クロノ', 0xFFB08968),
    'japanese': _Keeper('歌よみのことは', 0xFFC0504D),
    'math': _Keeper('設計士ユークリ', 0xFF6A4C93),
  };

  static const _colors = {
    'english': 0xFF2F5D7C,
    'science': 0xFF2E6B3F,
    'social': 0xFF7A5230,
    'japanese': 0xFF8E3B46,
    'math': 0xFF4B3A7A,
  };

  static const _order = [
    'english',
    'science',
    'social',
    'japanese',
    'math',
  ];

  /// 国の章の番号（1〜6）
  static int chapterOf(String worldId) => _order.indexOf(worldId) + 1;

  static StoryLine _k(String worldId, String text) =>
      StoryLine(StorySpeaker.keeper, text, name: _keepers[worldId]!.name);

  static const _n = StorySpeaker.narrator;
  static const _h = StorySpeaker.hero;
  static const _s = StorySpeaker.shiori;
  static const _z = StorySpeaker.noise;
  static const _o = StorySpeaker.oblivion;

  /// 序章
  static const prologue = StoryScene(
    id: 'prologue',
    chapter: 0,
    title: '序章　しおりの精',
    color: 0xFF5D4037,
    lines: [
      StoryLine(_n, 'むかし、世界は一つの大きな「知識の世界」だった。'),
      StoryLine(_n, 'ところがある日、「忘却の魔王」があらわれ、知識をうばって世界を5つの国に引きさいた。'),
      StoryLine(_n, '――それから、どれくらいの時がたっただろう。'),
      StoryLine(_n, '見習い冒険者の{name}は、古いノートのあいだに、光る何かがはさまっているのを見つけた。'),
      StoryLine(_s, '……ん……ここは……？ あなたは、だれ？'),
      StoryLine(_h, '{name}。見習いの冒険者だよ。きみは？'),
      StoryLine(_s, 'わたしは……しおり。しおりの精、だと思う。……それ以外、なにも思い出せないの。'),
      StoryLine(_s, 'でも、一つだけ覚えてる。5つの国に散らばった「知識の欠片」を集めれば、世界はもとにもどるって。'),
      StoryLine(_s, 'それから……欠片を集めたら、わたしの記憶も、もどる気がするの。'),
      StoryLine(_h, 'じゃあ、いっしょに行こう。問いに答えて、魔物をたおして、欠片を取りもどすんだ。'),
      StoryLine(_s, 'うん！ まずは、ことばの国――英語の国へ。よろしくね、{name}！'),
    ],
  );

  static List<StoryScene> _world(String w) {
    final c = _colors[w]!;
    final ch = chapterOf(w);
    final keeper = _keepers[w]!;
    StoryScene scene(String kind, String title, List<StoryLine> lines) =>
        StoryScene(
          id: '$w:$kind',
          chapter: ch,
          title: '第$ch章　$title',
          color: c,
          keeperLook: keeper.color,
          lines: lines,
        );
    switch (w) {
      case 'english':
        return [
          scene('intro', 'ことばの消えた国', [
            const StoryLine(_n, '英語の国。かつては遠い国の人びととも、ことばで心を通わせていた国。'),
            _k(w, 'ようこそ、旅の方。……わたしはリリカ。この国の、ことばの女王です。'),
            _k(w, '魔王に「ことばの欠片」をうばわれてから、人びとは文のつくり方を忘れてしまいました。'),
            _k(w, '主語と動詞のならびも、時のあらわし方も……。となりの人と話すことさえ、むずかしいのです。'),
            const StoryLine(_s, 'ことばがつながらないなんて……さみしいね。'),
            const StoryLine(_h, 'ぼくたちが取りもどします。一つずつ、文法をたしかめながら進みます。'),
            _k(w, 'ありがとう。……最後の玉座には、ことばを書きかえる竜がいます。どうか気をつけて。'),
          ]),
          scene('boss', '仮面の少年', [
            const StoryLine(_n, '玉座へ続く道。その前に、仮面をつけた少年が立っていた。'),
            const StoryLine(_z, 'へえ、ここまで来たんだ。……でも、むだだよ。'),
            const StoryLine(_z, 'どうせ覚えても、すぐ忘れる。テストが終われば、ぜんぶ消える。ぼくは、それを知ってる。'),
            const StoryLine(_h, 'きみは、だれ？'),
            const StoryLine(_z, 'ノイズ。忘却の魔王さまの……まあ、手伝いみたいなものさ。'),
            const StoryLine(_s, '（……あの子の声、どこかで聞いたことがある気がする……）'),
            const StoryLine(_z, 'せいぜいがんばりなよ。竜は、きみの答えを書きかえるよ。'),
          ]),
          scene('clear', 'ことばの欠片', [
            const StoryLine(_n, '竜がたおれると、玉座の上に、青く光る「ことばの欠片」がうかびあがった。'),
            _k(w, '聞こえますか……？ 町の人びとが、また話しはじめています！'),
            const StoryLine(_s, 'あっ……！ 欠片にさわったら、少し思い出した。'),
            const StoryLine(
                _s, 'わたし、大きな図書館にいた。たくさんの本と……だれかの「覚えていたい」って気持ちに囲まれて。'),
            _k(w, 'この「言葉の鍵」を。次の国、理の国への道がひらくでしょう。'),
            const StoryLine(_h, '行こう、しおり。きみの記憶も、ぜんぶ取りもどそう。'),
          ]),
        ];
      case 'science':
        return [
          scene('intro', 'くるった自然', [
            const StoryLine(_n, '理の国。空の星も、水の流れも、決まりにしたがって動いていた国。'),
            _k(w, 'おお、旅人か！ わしはニュート。この国のことわりを研究しておる。'),
            _k(w, '見てくれ、りんごが空に落ちていく。欠片をうばわれてから、自然の決まりがくるってしまったのじゃ。'),
            const StoryLine(_s, '小3から中3まで……学年ごとに、道が7本あるみたい。'),
            _k(w, 'そうじゃ。4つの玉座すべての竜をたおさねば、「ことわりの欠片」はもどらん。'),
            const StoryLine(_h, 'なぜそうなるのか、考えながら進みます。答えを覚えるだけじゃなくて。'),
            _k(w, 'うむ、よい心がけじゃ！ 実験と観察こそ、ことわりへの近道じゃよ。'),
          ]),
          scene('boss', 'ノイズの問い', [
            const StoryLine(_z, 'また会ったね。……ねえ、なんで勉強なんてするの？'),
            const StoryLine(_z, '公式なんて、使わなければ忘れる。実験の手順だって、次の日には思い出せない。'),
            const StoryLine(_h, '忘れることもあるよ。でも、一度わかったことは、もう一度わかるのが速くなる。'),
            const StoryLine(_z, '……ふん。きれいごとだね。'),
            const StoryLine(_s, 'ノイズ……あなた、本当は――'),
            const StoryLine(_z, 'うるさい！ ……竜のところへ行けば、わかるさ。'),
          ]),
          scene('clear', 'ことわりの欠片', [
            const StoryLine(_n, '4つの玉座の竜がしずまると、緑に光る「ことわりの欠片」が、空からゆっくりおりてきた。'),
            _k(w, 'りんごが……ちゃんと下に落ちた！ ことわりがもどったぞ！'),
            const StoryLine(_s, '……また一つ、思い出した。わたしのいた図書館には、「司書」がいたの。'),
            const StoryLine(_s, '司書は、人びとが学んだことを、一冊ずつ本にして守っていた。……それが、わたし？'),
            _k(w, 'この「実験の鍵」を持っていきなさい。時と地の国が待っておる。'),
          ]),
        ];
      case 'social':
        return [
          scene('intro', '白紙の年表', [
            const StoryLine(_n, '時と地の国。人びとの歩みと、世界の地図が記された国。'),
            _k(w, 'よく来られた。わしはクロノ。この国の年代記を守る者じゃ。'),
            _k(w, 'じゃが、見よ。年表は白紙、地図は空白。人びとは、自分たちがどこから来たのかを忘れてしもうた。'),
            const StoryLine(_s, 'くらしと地いき、日本の歴史、地理、公民……道がたくさん！'),
            _k(w, '過去を知ることは、今を知ること。今を知ることは、これからを考えることじゃ。'),
            const StoryLine(_h, '年表を、もう一度うめていきます。'),
          ]),
          scene('boss', 'ノイズの記憶', [
            const StoryLine(_z, '……年表か。ぼくにも、昔は書きこんでいたノートがあった。'),
            const StoryLine(_h, 'ノイズ？'),
            const StoryLine(_z, 'がんばって覚えた。でもテストの点は悪くて、先生にも友だちにも笑われた。'),
            const StoryLine(_z, 'だから、ノートを閉じた。忘れてしまえば、もう、くやしくないから。'),
            const StoryLine(_s, '……ノイズ……。'),
            const StoryLine(_z, '……しゃべりすぎた。先へ行けよ。竜たちが待ってる。'),
          ]),
          scene('clear', '時の欠片', [
            const StoryLine(
                _n, '白紙だった年表に、文字がよみがえっていく。茶色に光る「時の欠片」が、{name}の手の中にあった。'),
            _k(w, '聞こえるか。人びとが、自分たちの物語を語りはじめたぞ。'),
            const StoryLine(_s, '思い出したの。図書館には、とじられたノートが集まる「忘れものの棚」があった。'),
            const StoryLine(
                _s, 'だれかがあきらめて手ばなした学びは、みんなそこにしまわれて……いつか、とても大きな影になった。'),
            const StoryLine(_h, 'それって、まさか……'),
            _k(w, 'この「年表の鍵」を。言の葉の国へ進むがよい。'),
          ]),
        ];
      case 'japanese':
        return [
          scene('intro', '聞こえなくなった歌', [
            const StoryLine(_n, '言の葉の国。千年前の歌も、昨日の物語も、ことばのまま残されてきた国。'),
            _k(w, 'ようこそ。わたしはことは。この国で、歌をよむ者です。'),
            _k(w, '欠片をうばわれてから、古い歌の意味がわからなくなりました。むかしの人の心の声が、聞こえないのです。'),
            const StoryLine(_s, 'ひらがな、漢字、物語、説明文、古文……ことばにも、いろいろな道があるんだね。'),
            _k(w, '読みとくことは、書いた人の心に会いにいくこと。どうか、その心を取りもどしてください。'),
          ]),
          scene('boss', 'ことばの刃', [
            const StoryLine(_z, '読解なんて、正解があいまいじゃないか。筆者の気持ちなんて、わかるわけない。'),
            const StoryLine(_h, 'だから、本文にもどって、根拠をさがすんだ。書いてあることから考える。'),
            const StoryLine(_z, '……根拠、か。ぼくが手ばなしたノートにも、そう書いてあった気がする。'),
            const StoryLine(_s, 'ノイズ、あなたは本当は、学ぶのが好きだったんじゃない？'),
            const StoryLine(_z, '……！ そ、そんなこと……竜にやられちまえ！'),
          ]),
          scene('clear', '言の葉の欠片', [
            const StoryLine(_n, '紅く光る「言の葉の欠片」がひらめくと、国じゅうに、古い歌がひびきわたった。'),
            _k(w, '聞こえる……むかしの人の、かなしみも、よろこびも。'),
            const StoryLine(_s, '全部、思い出した。わたしは図書館の司書、しおり。「覚えている心」を守る役目だった。'),
            const StoryLine(
                _s, '忘れものの棚の影――それが、忘却の魔王。みんながあきらめた学びが集まって、生まれてしまったの。'),
            const StoryLine(_h, 'じゃあ、魔王は……たおすだけじゃ、だめなのかもしれない。'),
            _k(w, 'この「筆の鍵」を。数の国へ。'),
          ]),
        ];
      default:
        // 数の国（最後の国）
        return [
          scene('intro', 'くずれる橋', [
            const StoryLine(_n, '数の国。数と図形の調和で、橋も塔も美しく建てられていた国。'),
            _k(w, 'きみたちが旅の人かい？ ぼくはユークリ。この国の設計士さ。'),
            _k(w, '欠片がうばわれてから、計算が合わなくなって、橋も塔も、かたむいてしまったんだ。'),
            const StoryLine(_s, '小1のたし算から、中3の数学まで……一歩ずつ、積み上げる道だね。'),
            _k(w, 'そう。数学は、前に学んだことの上に、次が立つ。一段ぬかすと、上がぐらつくんだ。'),
            const StoryLine(_h, 'わからないところまで、もどってもいい。確かめながら行こう。'),
          ]),
          scene('boss', '証明', [
            const StoryLine(_z, '……なあ、{name}。まちがえるのが、こわくないのか？'),
            const StoryLine(_h, 'こわいよ。でも、まちがえたところが、次にわかるところだから。'),
            const StoryLine(_z, '……まちがえたところが、わかるところ……。'),
            const StoryLine(_z, 'ぼくは、まちがいを見たくなくて、答案を捨てた。それで……魔王さまに拾われたんだ。'),
            const StoryLine(_s, 'ノイズ、あなたの捨てた答案も、忘れものの棚にあるはず。まだ、取りもどせるよ。'),
            const StoryLine(_z, '……考えたよ。忘れるのは、こわい。でも、もう一度やってみるのは……もっとこわい。'),
            const StoryLine(_h, 'いっしょにやろう。わからないところは、いっしょに調べればいい。'),
            const StoryLine(_z, '行けよ。世界の中心で、魔王さまが待ってる。ぼくも、あとで行く。'),
          ]),
          scene('clear', '数の欠片', [
            const StoryLine(_n, '紫に光る「数の欠片」が組みあがると、かたむいていた塔が、まっすぐに立ちなおった。'),
            _k(w, 'すごい……計算が、ぴったり合う！ これで5つの国が、またつながった！'),
            const StoryLine(_s, '5つの欠片がそろった……。世界の中心への道が、ひらいたよ。'),
            const StoryLine(
                _s, '{name}。魔王は、たおすんじゃない。「もう一度学ぶ」ことで、忘れられた学びを取りもどすの。'),
            const StoryLine(_h, 'わかった。……行こう、世界の中心へ。'),
          ]),
        ];
    }
  }

  /// 終章（世界の中心の決戦の前）
  static const finaleBefore = StoryScene(
    id: 'finale:before',
    chapter: 7,
    title: '終章　世界の中心',
    color: 0xFF2A1F3D,
    lines: [
      StoryLine(_n, '世界の中心。そこには、とじられたノートが山のように積みあがっていた。'),
      StoryLine(_o, 'よく来た、冒険者。そして……しおり。ひさしぶりだな。'),
      StoryLine(_s, '忘却の魔王……あなたは、みんなが手ばなした学びの影。'),
      StoryLine(_o, 'そうだ。人は忘れる。あきらめる。わたしは、その重さのすべてだ。'),
      StoryLine(_o, '欠片を返せ。知識など、また忘れられるだけだ！'),
      StoryLine(_z, '――待って！'),
      StoryLine(_n, '仮面をはずしたノイズが、ぼろぼろのノートを胸にかかえて走ってきた。'),
      StoryLine(_z, 'ぼくは、もう一度やる。このノートを、もう一度ひらく！'),
      StoryLine(_h, '忘れても、また学べばいい。……5つの国の全部の問いで、きみに答えるよ！'),
    ],
  );

  /// エピローグ（世界の中心の決戦に勝ったあと）
  static const epilogue = StoryScene(
    id: 'finale:after',
    chapter: 7,
    title: '終章　もう一度ひらくノート',
    color: 0xFF3E5C76,
    lines: [
      StoryLine(_o, 'ばかな……忘れても、また学ぶというのか……。'),
      StoryLine(_n, '魔王の体から、たくさんのノートのページが、光になってほどけていく。'),
      StoryLine(_n, 'それは、人びとがあきらめた学び。ページは空をわたり、それぞれの持ち主のもとへ帰っていった。'),
      StoryLine(_s, '見て。みんなのノートが、もう一度ひらかれていく。'),
      StoryLine(_z, '……ぼくのノートにも、まだ続きが書ける。ありがとう、{name}。'),
      StoryLine(_o, '……人は、忘れる。それでも……。ならば、わたしは「復習の塔」で待とう。忘れたころに、また来るがいい。'),
      StoryLine(_n, 'こうして、知識の世界は、ふたたび一つになった。'),
      StoryLine(_s, '{name}、旅はここで終わりじゃないよ。学びは、いつでも続けられるんだから。'),
      StoryLine(_n, '―― つづりクエスト　おしまい。……そして、あなたの学びは、まだ続く。'),
    ],
  );

  /// すべての場面（章の順）
  static List<StoryScene> get all => [
        prologue,
        for (final w in _order) ..._world(w),
        finaleBefore,
        epilogue,
      ];

  static StoryScene byId(String id) => all.firstWhere((s) => s.id == id);

  /// 国に入ったときの場面
  static StoryScene intro(String worldId) => byId('$worldId:intro');

  /// その国の最後のボスの前の場面
  static StoryScene boss(String worldId) => byId('$worldId:boss');

  /// 欠片を取りもどしたときの場面
  static StoryScene clear(String worldId) => byId('$worldId:clear');

  /// 読んだか
  static bool seen(RpgProgress p, StoryScene s) =>
      p.fieldFlags.contains(s.flag);

  /// 読んだしるしをつけた進行状況
  static RpgProgress markSeen(RpgProgress p, StoryScene s) =>
      p.copyWith(fieldFlags: {...p.fieldFlags, s.flag});

  /// 国のフィールドに入ったときに見せる場面（まだ読んでいないもの。序章→国の導入→欠片）
  static List<StoryScene> onEnterWorld(RpgProgress p, String worldId) {
    if (!_order.contains(worldId)) return const [];
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
    if (!_order.contains(worldId)) return null;
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
