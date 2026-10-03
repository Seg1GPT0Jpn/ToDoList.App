import '../data/catalog.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';
import 'story.dart';

/// 国の物語の設定（国の特徴・国民・守護神・暴走した理由・学ぶ理由・ボス）
class NationLore {
  const NationLore({
    required this.worldId,
    required this.motto,
    required this.land,
    required this.people,
    required this.guardian,
    required this.guardianNote,
    required this.forgotten,
    required this.whyLearn,
    required this.midBossNote,
    required this.bossNote,
    required this.chapters,
  });

  final String worldId;

  /// 国のことば（ひとこと）
  final String motto;

  /// 国の特徴
  final String land;

  /// 国民
  final String people;

  /// 守護神の名前と説明
  final String guardian;
  final String guardianNote;

  /// 守護神が暴走した理由
  final String forgotten;

  /// ここで学ぶ理由（物語の上で）
  final String whyLearn;

  /// 中ボス・ボスの伏線
  final String midBossNote;
  final String bossNote;

  /// 進むと読めるようになる物語（ストーリーアーカイブ）
  final List<String> chapters;
}

/// ストーリーアーカイブの1話
class ArchiveEntry {
  const ArchiveEntry({
    required this.id,
    required this.worldId,
    required this.title,
    required this.text,
    required this.unlocked,
    required this.hint,
  });

  final String id;
  final String worldId;
  final String title;
  final String text;
  final bool unlocked;

  /// まだ読めないときの、読めるようになる条件
  final String hint;
}

/// 5つの国の物語。数学をなぜここで学ぶのか、英単語をなぜ覚えるのかが、
/// 物語の上でもつながるようにする。
abstract final class Lore {
  static const nations = <NationLore>[
    NationLore(
      worldId: 'japanese',
      motto: '言葉は、心を傷つけるトゲにも、温める羽毛にもなる',
      land: '言葉と文字の礎がきずかれた、桜と筆の国。古い都には和歌がただよい、町には物語の本屋が並ぶ。',
      people: '筆を持つ「フデ族」。むかしの人の心を読みとき、今の人の心を書き記す。',
      guardian: '巨鳥カラスバ',
      guardianNote: '筆の尾羽をもつ鳥の精霊。国じゅうの言葉を聞き、美しい言の葉を空にまいて国を守ってきた。',
      forgotten: 'カラスバは、人びとの悪口や乱暴な言葉を吸いこみすぎて、体が真っ黒なインクに染まり、暴走してしまった。',
      whyLearn: 'ひらがな・漢字・言葉のきまりを学び、物語や説明文を読みとくことは、美しい言葉を取りもどすこと。正しく美しい言葉を綴るほど、カラスバのインクは薄れていく。',
      midBossNote: '道のとちゅうの番人は、読み・書き・意味の一字のちがいを見のがさない。言葉をていねいに扱う者だけが先へ進める。',
      bossNote: '道の果てでは、墨に染まったカラスバが待つ。知識をつなぎ、本文を根拠に考える者の言葉だけが、カラスバの心に届く。',
      chapters: [
        'フデ族の家では、子どもが生まれると最初に一首の歌を贈る。言葉は、いちばん古い贈り物だから。',
        '最初の漢字を取りもどすと、本屋の棚でほこりをかぶっていた一冊が、ぱらりと開いた。',
        '漢文の碑には、こう刻まれていた。「学びて思はざれば則ち罔し」。学ぶだけでは足りない、考えなければ。',
        'カラスバは、黒く染まっても空から言葉を聞くのをやめなかった。いつか、温かい言葉が届くと信じていたから。',
        '白い羽が国じゅうに舞った日、人びとは「ありがとう」と口にするのが、少しだけ照れくさくなくなった。',
      ],
    ),
    NationLore(
      worldId: 'math',
      motto: '正しい道すじは、いつも美しい',
      land: '歯車と回廊で組みあげられた迷宮の国。天秤の橋、比例の階段、どこまでも続く数直線の通路がある。',
      people: '証明を愛する「カズ族」。答えが合うことより、なぜそうなるかを説明できることを大切にする。',
      guardian: '巨神カラクリ・ゴーレム',
      guardianNote: '歯車と天秤でできた時計仕掛けの巨人。迷宮の歯車を正しく回し、国の均衡を保ってきた。',
      forgotten: '世界の計算が狂ったせいで歯車のバランスが崩れ、ゴーレムは止まらない永久機関と化して暴走している。',
      whyLearn: '算数・数学を学ぶのは、狂った歯車をひとつずつ直すこと。式の意味と、解き方の筋道を取りもどせば、天秤はふたたび水平になる。',
      midBossNote: '道のとちゅうの番人は、公式を当てはめるだけでは倒せない。図をかき、場合を分けて考える者だけが先へ進める。',
      bossNote: '道の果てでは、カラクリ・ゴーレムが待つ。「どの考え方を、なぜ使うのか」を説明できる者だけが、歯車の狂いを直せる。',
      chapters: [
        'カズ族の子どもは、答えを言うと必ず「なぜ？」と聞き返される。答えより、道すじが宝物だから。',
        '最初の計算を取りもどしたとき、止まっていた歯車がひとつ、ぎしりと音を立てて回りだした。',
        '確率の部屋の番人は言った。「運に見えるものにも、数えられるきまりがある」。',
        '迷宮の壁に、ひとすじの補助線が引かれた。たった一本の線で、見えなかった道が見えた。',
        'ゴーレムの天秤が水平にもどった日、迷宮のいちばん奥に、一行の証明が刻まれていた。「Q.E.D.」',
      ],
    ),
    NationLore(
      worldId: 'english',
      motto: '言葉は、知らない人と出会うための橋',
      land: '海に開かれた港町。世界中の船が集まり、たくさんの言葉が行き交っていた。灯台は、どの国の船にも同じ光を送る。',
      people: '言葉を編む「ツヅリ族」。単語は糸、文法は編み方。一枚の布（文章）を編んで、遠くの国へ手紙を送っていた。',
      guardian: '海獣バベル・リヴァイアサン',
      guardianNote: '世界中の文字の鱗をもつ巨大な魚。港の海を守り、遠い国の言葉を運んできた。',
      forgotten: '互いの言葉が通じない恐怖から嵐が生まれ、リヴァイアサンはその嵐をまとって港を閉ざしてしまった。',
      whyLearn: '英単語を覚えることは、ほどけた糸を一本ずつ拾い集めること。文法を学ぶことは、編み方を思い出すこと。言葉をつなげば、リヴァイアサンにも心が届く。',
      midBossNote: '道のとちゅうの番人は、「いつのことか」「だれがしたのか」で言葉をねじまげる。文のつくりを見ぬける者だけが先へ進める。',
      bossNote: '道の果てでは、嵐をまとったリヴァイアサンが待つ。1文ずつではなく、伝えたいことの流れを読む力が試される。',
      chapters: [
        '港町の灯台には、むかし毎晩、世界中の言葉で「おやすみ」が灯されていた。',
        '最初の単語を取りもどしたとき、港の小舟が一そう、ゆっくりと岸を離れた。言葉がもどれば、旅ももどる。',
        '番人のひとりは言った。「言葉は、ねじまげれば武器になる」。けれど、正しく編めば、それは橋にもなる。',
        'リヴァイアサンの鱗の文字は、ひとつひとつが、だれかが勇気を出して伝えた言葉だった。',
        '嵐が晴れた夜、遠い国から一通の手紙が届いた。そこには、たったひとこと「Hello」と書いてあった。',
      ],
    ),
    NationLore(
      worldId: 'science',
      motto: 'なぜ？と問うことが、世界を動かす',
      land: '森と海と星空がひとつにつながった実験庭園。りんごが落ちること、花が咲くこと、星がめぐることに、すべて理由がある。',
      people: '実験好きの「ハカリ族」。何でも量って、比べて、記録する。「たぶん」ではなく「たしかめた」が口ぐせ。',
      guardian: '炎氷竜カオス・エレメンタル',
      guardianNote: '炎と氷の力をあわせもつ竜。熱と光と気候のバランスを守り、庭園に四季をめぐらせてきた。',
      forgotten: '熱・光・気候の法則が混ざり合ってしまい、カオス・エレメンタルはその激しい痛みに耐えかねて暴れている。',
      whyLearn: '生き物・物・エネルギー・地球を学ぶことは、混ざり合った法則をほどくこと。法則がわかれば、竜の痛みはしずまっていく。',
      midBossNote: '道のとちゅうの番人たちは、知っているだけでは倒せない。実験の結果から考える者だけが、先の道へ進める。',
      bossNote: '道の果てでは、炎と氷の竜が待つ。熱がどう伝わり、光がどう進むか――仕組みを解き明かす者だけが、竜の痛みを止められる。',
      chapters: [
        'ハカリ族の子どもは、生まれて最初に「ものさし」をもらう。世界を量ることが、世界を知る第一歩だから。',
        'ふりこのエリアを越えたとき、止まっていた大時計がひとつ、カチリと動いた。',
        '老錬金術師は言った。「まぜれば変わる。でも、何がどれだけ変わるかは、決まっているのじゃ」。',
        '地層の壁には、何億年もの記録が書きこまれていた。どんな嵐も、石に刻まれた時間は消せない。',
        '竜が穏やかな精霊にもどった夜、庭園の空に、ひさしぶりに流れ星が降った。',
      ],
    ),
    NationLore(
      worldId: 'social',
      motto: 'わたしたちは、どこから来て、どこへ行くのか',
      land: '時代と土地をむすぶ、果てしない回廊。壁には人びとのくらしの絵が描かれ、窓からは世界の国々が見える。',
      people: '語り継ぐ「トキノ族」と、地図を描く「チズ族」。ふたつの民が力を合わせて、人びとの歩みを記録してきた。',
      guardian: '幽幻騎士クロノス・ナイト',
      guardianNote: '過去と現代の武具をまとった騎士。回廊を守り、人びとの歩みを後の世へ伝えてきた。',
      forgotten: '「誰にも歴史や営みを覚えてもらえないなら、すべて砂にしてしまおう」――忘れられた悲しみから、騎士は自暴自棄になっている。',
      whyLearn: 'くらし・地理・歴史・公民を学ぶのは、人びとの歩みを思い出し、今とつなぎなおすため。覚えている人がいるかぎり、騎士の誇りは消えない。',
      midBossNote: '時代の境目には、関所を守る番人がいる。前の時代の終わりと、次の時代の始まりを結びつけられなければ通れない。',
      bossNote: '道の果てでは、クロノス・ナイトが待つ。過去を知るだけでなく、それを使ってこれからを考えられるかが試される。',
      chapters: [
        'トキノ族の長老は、毎朝ひとつずつ昔話をする。同じ話は二度としない。歴史はいくら語っても尽きないから。',
        '最初の時代を取りもどすと、崩れかけた壁画に、小さな田んぼの絵がよみがえった。',
        'チズ族の少女は、白紙の地図に一本の川を描いた。川のそばに町ができ、町と町を道が結んだ。',
        '関所の番人は言った。「年号を覚えるのは、本を読むための目次を作るようなもの。本文を読まねば意味がない」。',
        '騎士が剣をおさめた日、回廊の最後の壁に、空白がひとつ残されていた。「ここに描くのは、きみたちだ」。',
      ],
    ),
  ];

  static NationLore? of(String worldId) =>
      nations.where((n) => n.worldId == worldId).firstOrNull;

  /// その国でクリアしたエリアの割合（0〜1）
  static double progressOf(RpgProgress p, String worldId) {
    final stages = RpgCatalog.world(worldId).stages;
    if (stages.isEmpty) return 0;
    return stages.where((s) => p.clearedStageIds.contains(s.id)).length /
        stages.length;
  }

  /// ストーリーアーカイブ：国ごとに5話。国に入る・2割・5割・8割・欠片で読めるようになる
  static List<ArchiveEntry> archive(RpgProgress p) {
    const thresholds = [0.0, 0.2, 0.5, 0.8, 1.0];
    const hints = [
      'この国のエリアを1つクリアすると読める',
      'この国のエリアを2割クリアすると読める',
      'この国のエリアを半分クリアすると読める',
      'この国のエリアを8割クリアすると読める',
      'この国の守護神を救うと読める',
    ];
    final fragments = Story.fragments(p);
    return [
      for (final n in nations)
        for (var i = 0; i < n.chapters.length; i++)
          ArchiveEntry(
            id: '${n.worldId}_$i',
            worldId: n.worldId,
            title: '${RpgCatalog.world(n.worldId).name} 第${i + 1}話',
            text: n.chapters[i],
            unlocked: i == 4
                ? fragments.contains(n.worldId)
                : i == 0
                    ? progressOf(p, n.worldId) > 0
                    : progressOf(p, n.worldId) >= thresholds[i],
            hint: hints[i],
          ),
    ];
  }

  /// ステージの先にいる、次のボス（同じ道で、まだ倒していないもの）
  static StageDef? nextBoss(RpgProgress p, StageDef from) {
    final w = RpgCatalog.world(from.worldId);
    for (final s in w.stages) {
      if (s.branch != from.branch || s.order < from.order) continue;
      if (s.isBoss && !p.clearedStageIds.contains(s.id)) return s;
    }
    return null;
  }
}
