import '../models/enemy.dart';
import '../models/stage.dart';
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

/// NPC との会話の中身
class NpcTalk {
  const NpcTalk({
    required this.npc,
    required this.lines,
    this.questReady = false,
    this.questDone = false,
  });

  final NpcDef npc;
  final List<String> lines;

  /// 頼みごとを果たしていて、ごほうびを受け取れる
  final bool questReady;

  /// 頼みごとのごほうびを受け取りずみ
  final bool questDone;
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
  };

  /// ハブ（国のスタート地点）の語り部
  static const storyteller = NpcDef(
    name: '語り部のおばば',
    greeting: 'よう来たね、若い冒険者。昔話をひとつ、聞いていきな。',
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
  }) {
    final npc = of(terrain);
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
    );
  }

  /// 語り部の話（集めた欠片の数で変わる）
  static NpcTalk storytellerTalk(Set<String> fragments) {
    final n = fragments.length;
    final lines = <String>[
      storyteller.greeting,
      Story.prologue[2],
      Story.prologue[3],
      switch (n) {
        0 => 'まだ欠片はひとつも見つかっていないようだね。まずはこの国の奥をめざしてごらん。',
        < 6 =>
          '欠片を$n個も取りもどしたのかい。${Story.worlds.where((w) => fragments.contains(w.worldId)).map((w) => w.fragment).join('、')}…あたたかい光だねえ。',
        _ => '6つの欠片がそろったね！ 世界の中心への道がひらいたよ。ホームの「物語」から挑めるはずさ。',
      },
      '忘れてもいい。また学べばいいんだよ。それが、忘却の魔王にいちばん効く魔法さ。',
    ];
    return NpcTalk(npc: storyteller, lines: lines);
  }
}
