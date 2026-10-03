import '../data/catalog.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';
import 'story.dart';

/// 国の物語の設定（国の特徴・国民・守護者・忘却された理由・学ぶ理由・ボス）
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

  /// 守護者の名前と説明
  final String guardian;
  final String guardianNote;

  /// 国が忘却された理由
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
      worldId: 'english',
      motto: 'ことばは、知らない人と出会うための橋',
      land: '海と草原に囲まれた港の国。むかしは世界じゅうの船が集まり、たくさんのことばが行き交っていた。',
      people: 'ことばを編む「ツヅリ族」。単語は糸、文法は編み方。一枚の布（文章）を編んで、遠くの国へ手紙を送っていた。',
      guardian: '翻訳の灯台守リンガ',
      guardianNote: '岬の灯台で、すべてのことばを照らし合わせていた守護者。いまは灯りが消え、灯台に閉じこめられている。',
      forgotten:
          '忘却の魔王は、まず「単語の糸」をほどいた。糸がなければ布は編めない。人びとは文法の編み方だけを覚えていても、何も伝えられなくなった。',
      whyLearn:
          '英単語を覚えることは、ほどけた糸を一本ずつ拾い集めること。文法を学ぶことは、編み方を思い出すこと。両方そろって、ようやく灯台にふたたび光がともる。',
      midBossNote: '道のとちゅうの番人は、「過去形」と「進行形」でことばをねじまげる。いつのことかを見ぬけない者は先へ進めない。',
      bossNote: '道の果てで待つのは、長い英文を丸ごと飲みこむ竜。1文ずつではなく、文章全体の流れを読む力が試される。',
      chapters: [
        '港の国の灯台には、むかし毎晩、世界じゅうのことばで「おやすみ」が灯されていた。',
        '最初の単語を取りもどしたとき、港の小舟が一そう、ゆっくりと岸を離れた。ことばが戻れば、旅も戻る。',
        '四天王のひとりは言った。「ことばは、ねじまげれば武器になる」。けれど、正しく編めば、それは盾にもなる。',
        '灯台守リンガは、閉じこめられた部屋でずっと単語を数えていた。「忘れても、また覚えればいい。何度でも」。',
        '灯台に光がもどった夜、遠い国から一通の手紙が届いた。そこには、たったひとこと「Hello」と書いてあった。',
      ],
    ),
    NationLore(
      worldId: 'science',
      motto: 'なぜ？と問うことが、世界を動かす',
      land: '山と海と星空がひとつにつながった国。りんごが落ちること、花が咲くこと、星がめぐることに、すべて理由がある国。',
      people: '実験好きの「ハカリ族」。何でも量って、比べて、記録する。「たぶん」ではなく「たしかめた」が口ぐせ。',
      guardian: '法則の観測者ノア',
      guardianNote: '天文台から世界のきまりを見守っていた守護者。いまは望遠鏡がくもり、何も見えなくなっている。',
      forgotten:
          '魔王は「なぜ」という問いを奪った。人びとはものが落ちても、季節が変わっても、理由を考えなくなった。理由を忘れた世界では、自然のきまりがばらばらにほどけていく。',
      whyLearn: '生き物・物・エネルギー・地球と宇宙を学ぶことは、ほどけた「きまり」を結び直すこと。法則がわかれば、空も大地もまた正しく動きはじめる。',
      midBossNote: '道のとちゅうの番人たちは、知っているだけでは倒せない。実験の結果から考える者だけが、先の道へ進める。',
      bossNote: '道の果てでは、原子・遺伝・宇宙という「いちばん大きなきまり」が待っている。',
      chapters: [
        'ハカリ族の子どもは、生まれて最初に「ものさし」をもらう。世界を量ることが、世界を知る第一歩だから。',
        '振り子のエリアを越えたとき、止まっていた大時計がひとつ、カチリと動いた。',
        '実験の道で出会った老錬金術師は言った。「まぜれば変わる。でも、何がどれだけ変わるかは、決まっているのじゃ」。',
        '地層の壁には、何億年もの記録が書きこまれていた。忘却の魔王でさえ、石に刻まれた時間は消せなかった。',
        '観測者ノアの望遠鏡がふたたび星をとらえた夜、国じゅうの空に、ひさしぶりに流れ星が降った。',
      ],
    ),
    NationLore(
      worldId: 'social',
      motto: 'わたしたちは、どこから来て、どこへ行くのか',
      land: '年表の川が流れ、地図の大地が広がる国。川をさかのぼれば昔の時代へ、大地を歩けば世界の国々へつながっている。',
      people: '語り継ぐ「トキノ族」と、地図を描く「チズ族」。ふたつの民が力を合わせて、人びとの歩みを記録してきた。',
      guardian: '年表の守り人クロニクル',
      guardianNote: '時の川のほとりで、すべてのできごとを順番どおりに並べていた守護者。いまは年表がばらばらに散っている。',
      forgotten:
          '魔王は「つながり」を断ち切った。できごとの年号は残っても、なぜ起きたのか、次に何が起きたのかがわからない。人びとは同じまちがいをくり返すようになった。',
      whyLearn:
          '歴史を学ぶのは、できごとを因果の糸で結び直すため。地理を学ぶのは、場所と暮らしのつながりを知るため。公民を学ぶのは、社会のしくみを知り、自分たちで決められるようになるため。',
      midBossNote: '時代の境目には、関所を守る番人がいる。前の時代の終わりと、次の時代の始まりを結びつけられなければ通れない。',
      bossNote: '道の果てでは「いま」を問われる。過去を知るだけでなく、それを使ってこれからを考えられるかが試される。',
      chapters: [
        'トキノ族の長老は、毎朝ひとつずつ昔話をする。同じ話は二度としない。歴史はいくら語っても尽きないから。',
        '最初の時代を取りもどすと、時の川に小さな舟が浮かんだ。舟は、次の時代へと流れていった。',
        'チズ族の少女は、白紙の地図に一本の川を描いた。川のそばに町ができ、町と町を道が結んだ。',
        '関所の番人は言った。「年号を覚えるのは、本を読むための目次を作るようなもの。本文を読まねば意味がない」。',
        'クロニクルの年表がふたたびつながったとき、そこには最後の空らんがあった。「ここに書くのは、きみたちだ」。',
      ],
    ),
    NationLore(
      worldId: 'japanese',
      motto: '心は、ことばにしてはじめて伝わる',
      land: '桜と月の国。古い都には和歌がただよい、町には物語の本屋が並ぶ。漢文の碑が、遠い大陸との縁を伝えている。',
      people: '筆を持つ「フデ族」。むかしの人の心を読みとき、今の人の心を書き記す。',
      guardian: '言霊の巫女コトノハ',
      guardianNote: 'ことばに宿る力（言霊）を守っていた巫女。いまは声を失い、歌を詠めなくなっている。',
      forgotten:
          '魔王は「行間」を消した。文字は読めても、そこにこめられた気持ちや筆者の考えが読みとれない。人びとは、ことばの表面だけですれちがうようになった。',
      whyLearn:
          '物語や説明文は筆者の考えと心の動きを、古文と漢文は千年前の人の思いを読みとく力。行間を読めるようになると、巫女の声が少しずつもどってくる。',
      midBossNote: '漢字と言葉の道では、読み・書き・意味の門番が待つ。一字のちがいを見失うと、迷い込む。',
      bossNote: '最後は、初めて読む文章の総合読解。知識をつなぎ、本文を根拠に考える者だけが巫女のもとへたどりつく。',
      chapters: [
        'フデ族の家では、子どもが生まれると最初に一首の歌を贈る。ことばは、いちばん古い贈り物だから。',
        '最初の物語を取りもどすと、本屋の棚にほこりをかぶっていた一冊が、ぱらりと開いた。',
        '漢文の碑には、こう刻まれていた。「学びて思はざれば則ち罔し」。学ぶだけでは足りない、考えなければ。',
        '巫女コトノハは、声を失っても筆を離さなかった。書きつづけることが、いつか声を取りもどす道だと知っていたから。',
        '巫女がふたたび歌を詠んだとき、桜の花びらがいっせいに舞い上がった。その歌は、国じゅうの人の心に届いた。',
      ],
    ),
    NationLore(
      worldId: 'math',
      motto: '正しい道すじは、いつも美しい',
      land: '塔と橋が数式で設計された国。放物線のアーチ、ベクトルの風見鶏、無限に続く階段がある。',
      people: '証明を愛する「カズ族」。答えが合うことより、なぜそうなるかを説明できることを大切にする。',
      guardian: '証明の建築家エウクレイア',
      guardianNote: '国じゅうの塔と橋を設計した守護者。いまは設計図が白紙になり、建物が少しずつかたむいている。',
      forgotten:
          '魔王は「筋道」を奪った。人びとは公式だけを覚え、なぜその公式を使うのかを忘れた。理由のない計算は、少しのずれで崩れてしまう。',
      whyLearn: '数学を学ぶのは、国の設計図を描き直すこと。式の意味と、方針の立て方を取りもどせば、かたむいた塔もまたまっすぐに立つ。',
      midBossNote: '単元ごとの「応用」の番人は、公式を当てはめるだけでは倒せない。場合分けや、ちがう単元を組み合わせる発想が必要だ。',
      bossNote: '中3の果ての番人は、関数・図形・三平方の定理を自在に使う。「どの道具を、なぜ使うのか」を説明できる者だけが勝てる。',
      chapters: [
        'カズ族の子どもは、答えを言うと必ず「なぜ？」と聞き返される。答えより、道すじが宝物だから。',
        '最初の公式を取りもどしたとき、かたむいていた橋が、ぎしりと音を立ててまっすぐになった。',
        '確率の森の番人は言った。「運に見えるものにも、数えられるきまりがある」。',
        'エウクレイアの白紙の設計図に、ひとすじの補助線が引かれた。たった一本の線で、見えなかった道が見えた。',
        '塔がすべてまっすぐに立った日、無限に続く階段のてっぺんに、一行の証明が刻まれていた。「Q.E.D.」',
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
      'この国の欠片を取りもどすと読める',
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
