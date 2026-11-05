import '../models/enemy.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';
import 'lore.dart';
import '../world/terrain.dart';
import 'story.dart';

/// フィールドの住人（NPC）
class NpcDef {
  const NpcDef({
    required this.name,
    required this.greeting,
    required this.color,
  });

  final String name;

  /// 地形にちなんだ、最初のあいさつ
  final String greeting;

  /// 服の色（ARGB）
  final int color;
}

/// 住人の役割（世界観とゲームのしくみをつなぐ）
enum NpcRole {
  lore('語り手', '国の歴史と、ここで学ぶ理由を語る'),
  tutor('先生', 'この単元の学び方のコツを教える'),
  quest('頼みごと', '探しものを頼み、見つけるとお礼をくれる'),
  review('復習係', 'まちがえた問題や、復習の日が来た問題を知らせる'),
  scout('見張り', 'この先のボスの手ごわさを教える'),
  merchant('道具屋', 'カード・装備・仲間の使い方を教える');

  const NpcRole(this.label, this.description);
  final String label;
  final String description;

  /// エリアの番号で決まる役割（小部屋があるエリアは頼みごと）
  static NpcRole forArea(int area, {required bool hasNook}) {
    if (hasNook) return quest;
    return const [lore, tutor, review, scout, merchant][area % 5];
  }
}

/// NPC との会話の中身
class NpcTalk {
  const NpcTalk({
    required this.npc,
    required this.lines,
    this.questReady = false,
    this.questDone = false,
    this.role = NpcRole.lore,
  });

  final NpcDef npc;
  final List<String> lines;

  /// 頼みごとを果たしていて、ごほうびを受け取れる
  final bool questReady;

  /// 頼みごとのごほうびを受け取りずみ
  final bool questDone;

  /// 住人の役割
  final NpcRole role;
}

/// フィールドの住人たち。エリアの地形ごとに1人ずついて、
/// この先の魔物のことや、その単元のあなたの熟練度に合わせたアドバイスをくれる。
/// 小さな頼みごと（エリアの奥の宝箱をさがす）もある。
class Npcs {
  const Npcs._();

  /// 頼みごとのごほうび（経験値）
  static const questExp = 40;

  static const _byTerrain = <Terrain, NpcDef>{
    Terrain.meadow: NpcDef(
        name: '羊飼いのメイ',
        greeting: 'いい風だね。ここは冒険のはじまりにぴったりの場所だよ。',
        color: 0xFF8CC06B),
    Terrain.flower: NpcDef(
        name: '花屋のハナ',
        greeting: '花の名前も、ことばの意味も、毎日すこしずつ覚えるのがコツよ。',
        color: 0xFFF06292),
    Terrain.forest: NpcDef(
        name: 'きこりのゴロー',
        greeting: '森は道が入り組んでるぞ。迷ったら来た道をもどるんだ。',
        color: 0xFF4F8A4A),
    Terrain.hill: NpcDef(
        name: '登山家のタカ',
        greeting: '一歩ずつ登れば、どんな坂もこえられる。勉強も同じさ。',
        color: 0xFFB08968),
    Terrain.river: NpcDef(
        name: '渡し守のカワ',
        greeting: '川は橋のあるところでしかわたれないよ。寄り道の橋もあるからね。',
        color: 0xFF5FA8CC),
    Terrain.beach: NpcDef(
        name: '漁師のハマ',
        greeting: '潮の満ち引きみたいに、覚えたことも引いていく。だから何度も復習するんだ。',
        color: 0xFF4F81BD),
    Terrain.harbor: NpcDef(
        name: '船長のミナト',
        greeting: '港には遠い国の知識も集まってくる。耳をすませてごらん。',
        color: 0xFF37474F),
    Terrain.cave: NpcDef(
        name: '坑夫のドワ', greeting: '暗い洞窟でも、知識の光があれば進めるさ。', color: 0xFF8D6E63),
    Terrain.crystal: NpcDef(
        name: '水晶の精リィ',
        greeting: '水晶は、あなたの学びを映す鏡。正解するほど、きらきら光るの。',
        color: 0xFFB39DDB),
    Terrain.ruins: NpcDef(
        name: '考古学者のコウ',
        greeting: '古い遺跡には、忘れられた知識がねむっている。ひびの入った柱をよく見てごらん。',
        color: 0xFFC9B79A),
    Terrain.shrine: NpcDef(
        name: '神主のミヤ', greeting: 'ようこそ。心をしずめて、問いに向き合いなされ。', color: 0xFFC0504D),
    Terrain.town: NpcDef(
        name: '町の子どもソラ',
        greeting: 'ねえねえ、冒険者さん！ この町の宿の先生、教えるのがうまいんだよ。',
        color: 0xFFF2B84B),
    Terrain.workshop: NpcDef(
        name: '職人のテツ', greeting: '道具も知識も、使えば使うほど手になじむ。', color: 0xFF757575),
    Terrain.library: NpcDef(
        name: '司書のフミ',
        greeting: 'お静かに。…でも、分からないことを聞くのは大歓迎ですよ。',
        color: 0xFF6D4C41),
    Terrain.tower: NpcDef(
        name: '時計守りのトキ', greeting: 'カチ、コチ。時間は大事に使うのじゃぞ。', color: 0xFF7D7A8C),
    Terrain.sky: NpcDef(
        name: '風の旅人フウ',
        greeting: '雲の切れ目に気をつけて。空の上では、ひらめきが大事なんだ。',
        color: 0xFF90CAF9),
    Terrain.snow: NpcDef(
        name: '雪国のユキ',
        greeting: 'さむいね！ 体をあたためるには、頭もたくさん使うといいよ。',
        color: 0xFF81D4FA),
    Terrain.desert: NpcDef(
        name: '砂の商人サバ',
        greeting: '砂漠で水が大事なように、勉強では復習が大事なのさ。',
        color: 0xFFD7A45E),
    Terrain.lava: NpcDef(
        name: '火の番人ホムラ',
        greeting: 'ここまで来たか。火の山の魔物はつわものぞろいだ。',
        color: 0xFFE4572E),
    Terrain.castle: NpcDef(
        name: '城の衛兵ジン',
        greeting: 'この先は王の間。ここまでに学んだことが試されるぞ。',
        color: 0xFF6A4C93),
    Terrain.ocean: NpcDef(
        name: '航海士のナギ',
        greeting: 'いい風だ！ 島と島のあいだの航路を見きわめて進もう。うずしおには近づくなよ。',
        color: 0xFF1F6F9F),
    Terrain.abyss: NpcDef(
        name: '深海探査員のシズク',
        greeting: 'ここは光のとどかない深海。暗いのは、まだ知らないことが多いしるし。ライトは知識でつくのよ。',
        color: 0xFF26A69A),
    Terrain.cloudSea: NpcDef(
        name: '気球乗りのソラノ',
        greeting: '雲の上へようこそ！ 雷雲の切れ目に落ちないよう、虹の道を使うといいよ。',
        color: 0xFF7986CB),
    Terrain.space: NpcDef(
        name: '宇宙飛行士のホシノ',
        greeting: 'ここまで来たら、あとは本番だけ。星をつないで星座をつくるように、知識をつなげよう。',
        color: 0xFFE0E0E0),
  };

  /// ハブ（国のスタート地点）の語り部
  static const storyteller = NpcDef(
    name: '語り部のおばば',
    greeting: 'よう来たね、見習いの勇者さん。昔話をひとつ、聞いていきな。',
    color: 0xFF8064A2,
  );

  static NpcDef of(Terrain terrain) => _byTerrain[terrain]!;

  /// エリアの住人との会話。
  ///
  /// [score] はその単元の熟練度（判定できなければ null）。
  /// [nookIsSecret] はそのエリアの小部屋が隠し通路なら true、知識の扉なら false、なければ null。
  static NpcTalk talk(
    StageDef stage,
    Terrain terrain, {
    int? score,
    bool? nookIsSecret,
    bool nookChestOpened = false,
    bool questRewarded = false,
    int area = 0,
    RpgProgress? progress,
    int dueReviews = 0,
    int ghosts = 0,
  }) {
    final npc = of(terrain);
    final role = NpcRole.forArea(area, hasNook: nookIsSecret != null);
    final e = stage.enemy;
    final ability = e.effectiveAbility;
    final lines = <String>[
      npc.greeting,
      [
        'この先の「${e.name}」は',
        if (ability != EnemyAbility.none)
          '${ability.label}の魔物だよ。${ability.description}。'
        else
          '手ごわい魔物だよ。',
        if (e.weakness != null) '弱点は「${e.weakness!.label}」の問題らしい。',
      ].join(),
      if (stage.grammarTheme.isNotEmpty)
        switch (score) {
          null => 'ここで学ぶのは「${stage.grammarTheme}」。はじめてなら、宿の授業を受けてから行くといいよ。',
          < 60 =>
            '「${stage.grammarTheme}」はまだ苦手みたいだね（熟練度$score）。このあたりが暗いのはそのせい。宿で練習すれば、きっと明るくなるよ。',
          < 80 =>
            '「${stage.grammarTheme}」はもう少し（熟練度$score）。あと一息で、このあたりに知識の光がさすよ。',
          _ =>
            '「${stage.grammarTheme}」はもうばっちりだね（熟練度$score）！ 光に照らされて、隠れていた道も見えるはずだよ。',
        },
    ];
    lines.addAll(_roleLines(role, stage, area, progress, dueReviews, ghosts));
    var ready = false;
    if (nookIsSecret != null) {
      final where = nookIsSecret ? 'ひびの入った岩（隠し通路）' : '知識の扉';
      if (questRewarded) {
        lines.add('宝箱を見つけてくれてありがとう。またいつでも寄っていってね。');
      } else if (nookChestOpened) {
        lines.add('あっ、$whereの奥の宝箱を見つけてくれたんだね！ お礼にこれをどうぞ。（経験値 +$questExp）');
        ready = true;
      } else {
        lines.add(
            '【頼みごと】このエリアのどこかに$whereがあって、その奥に宝箱があるらしいんだ。見つけて開けたら、また話しかけてね。');
      }
    }
    return NpcTalk(
      npc: npc,
      lines: lines,
      questReady: ready,
      questDone: questRewarded,
      role: role,
    );
  }

  /// 学び方のコツ（教科ごと）
  static const tips = <String, List<String>>{
    'english': [
      '単語は「見て意味がわかる」だけでなく「日本語から英語が出る」まで練習するといいよ。',
      '長い英文は、まず動詞を探して、主語と動詞のセットで区切って読むんだ。',
      '文法問題でまちがえたら、正しい文を声に出して3回読むと、耳でも覚えられるよ。',
    ],
    'math': [
      '公式は丸暗記より、一度自分で導いてみると忘れにくいよ。',
      '解けなかった問題は、解説を読んだあと、何も見ずにもう一度解いてみよう。',
      '場合分けが出たら、「どこで答えが変わるか」の境目を先に探すんだ。',
    ],
    'science': [
      '用語を覚えるときは、「何のために・どんなしくみで」をセットにするといいよ。',
      '計算問題は、単位をそろえてから式を立てるだけで、まちがいがぐっと減るよ。',
      'グラフの問題では、軸が何を表しているかを最初に確かめよう。',
    ],
    'social': [
      '年号は、前後のできごととセットで「流れ」として覚えるといいよ。',
      '地理は、地図を思いうかべながら覚えると忘れにくいんだ。',
      '用語を覚えたら、「なぜ起きたか」「その結果どうなったか」を一言で言えるか試してごらん。',
    ],
    'japanese': [
      '説明文は、「しかし」「つまり」のあとに筆者の言いたいことが来ることが多いよ。',
      '漢字は、部首と音読み・訓読みをセットで覚えると忘れにくいよ。',
      '物語は、登場人物の気持ちが変わったところに線を引いてみよう。',
    ],
  };

  static List<String> _roleLines(
    NpcRole role,
    StageDef stage,
    int area,
    RpgProgress? progress,
    int dueReviews,
    int ghosts,
  ) {
    final lore = Lore.of(stage.worldId);
    switch (role) {
      case NpcRole.lore:
        if (lore == null) return const [];
        return [
          '【語り手】${lore.forgotten}',
          lore.whyLearn,
        ];
      case NpcRole.tutor:
        final t = tips[stage.worldId] ?? tips['english']!;
        return ['【先生】${t[area % t.length]}'];
      case NpcRole.review:
        return [
          if (dueReviews > 0)
            '【復習係】復習の日が来た問題が$dueReviews問あるよ。ホームの「復習の塔」で片づけると、忘れにくくなるんだ。'
          else
            '【復習係】いまは復習の日が来た問題はないみたい。えらいね！',
          if (ghosts > 0) 'このエリアには、まちがえた問題の亡霊が$ghosts体さまよってる。話しかけると再戦できるよ。',
        ];
      case NpcRole.scout:
        final boss = progress == null ? null : Lore.nextBoss(progress, stage);
        if (boss == null) {
          return ['【見張り】この道のボスは、もう倒したみたいだね。たいしたもんだ。'];
        }
        return [
          '【見張り】この道の先には「${boss.enemy.name}」がいる。${boss.name}で待ちかまえているよ。',
          if (lore != null)
            stage.order <= boss.order - 4 ? lore.midBossNote : lore.bossNote,
          'ボスは装甲を持っている。装甲を割る種類の問題を、先に練習しておくといいよ。',
        ];
      case NpcRole.merchant:
        return [
          '【道具屋】宝箱のレアカードはデッキに入れて使えるよ。「むすびの栞」はチェインを切る魔物に効くんだ。',
          '装備は、その教科のバトルで効くものもある。ホームの「装備」から付けかえてごらん。',
        ];
      case NpcRole.quest:
        return const [];
    }
  }

  /// 語り部の話（集めた証の数で変わる）
  static NpcTalk storytellerTalk(Set<String> fragments) {
    final n = fragments.length;
    final lines = <String>[
      storyteller.greeting,
      Story.prologue[2],
      Story.prologue[4],
      if (n == 0)
        'まだ証はひとつも集まっていないようだね。道の果てで狂気に呑まれた守護者を、知識の力で正気にもどしておやり。'
      else if (n < Story.worlds.length)
        '証を$n個も集めたのかい。${Story.worlds.where((w) => fragments.contains(w.worldId)).map((w) => w.fragment).join('、')}…守護者たちも、きっと喜んでいるよ。'
      else
        '${Story.worlds.length}つの証がそろったね！ 大樹の天頂に、天空の図書院への光の柱があらわれたよ。ホームの「物語」から挑めるはずさ。',
      '忘れてもいい。また学べばいいんだよ。考えることをやめない心が、虚無の霧にいちばん効く魔法さ。',
    ];
    return NpcTalk(npc: storyteller, lines: lines);
  }
}
