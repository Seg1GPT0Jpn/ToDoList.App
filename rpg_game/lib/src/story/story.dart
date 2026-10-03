import '../data/catalog.dart';
import '../models/enemy.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';

/// 教科の国ごとの物語
class WorldStory {
  const WorldStory({
    required this.worldId,
    required this.guardian,
    required this.guardianLook,
    required this.guardianColor,
    required this.fragment,
    required this.emblem,
    required this.clearText,
  });

  final String worldId;

  /// その国の守護神（暴走して、国のボスになっている）
  final String guardian;

  /// 守護神の姿（enemy_painter の look）と色
  final String guardianLook;
  final int guardianColor;

  /// 守護神から受け取る「知識の欠片」
  final String fragment;

  /// 守護神が正気にもどって授けてくれる「国の証（エンブレム）」
  final String emblem;

  /// 国を救ったときの文
  final String clearText;
}

/// つづりクエストの世界の物語。
///
/// 世界を支える大樹「アカデミア」が枯れはじめ、5つの国の守護神（賢者）たちが暴走した。
/// 先代の勇者たちが旅立ったあと、留守番をしていた「言霊（つづり）の勇者」の見習いが、
/// 白紙の聖典「スペル・グリモワール」に学んだ正解を綴り、守護神たちを浄化していく。
/// 5つの国は好きな順に挑める。5つの欠片がそろうと「天空の図書院」がひらき、
/// 虚無の霧ネブラとの最終決戦になる。
class Story {
  const Story._();

  static const title = '言霊の勇者と大樹アカデミア';

  static const prologue = [
    '世界の中心には、すべての知識を根から吸いあげて葉を茂らせる大樹「アカデミア」がある。',
    'その大樹を守ってきたのが「言霊（つづり）の勇者」たち。けれど先代の勇者たちは、遠い旅に出たまま帰ってこない。',
    '勇者たちが旅立ったあと、アカデミアは枯れはじめ、大樹とつながる5つの国の守護神たちが暴走してしまった。',
    'きみは「まだ未熟だから」と留守番を任されていた、言霊の勇者の見習い。',
    '手にしたのは、白紙の聖典「スペル・グリモワール」。学んだ正解を書きこむ（綴る）と、奇跡の魔法が発動する。',
    '和の礎の国・数理の迷宮国・異界の港町・万物の実験庭園・時空の回廊――得意な教科、好きな雰囲気の国から、自由に挑もう。',
    '倒す相手は、ただの悪者ではない。苦しんで暴れている守護神たちを、知識の力で助けにいくのだ。',
    '5つの国の「知識の欠片」がそろったとき、世界の中心「天空の図書院」への扉がひらく――。',
  ];

  /// 国の順（物語の画面に並べる順。挑む順は自由）
  static const worlds = <WorldStory>[
    WorldStory(
      worldId: 'japanese',
      guardian: '巨鳥カラスバ',
      guardianLook: 'bird',
      guardianColor: 0xFF2A2A3A,
      fragment: '言の葉の欠片',
      emblem: '白羽の紋章',
      clearText: 'カラスバは純白の鳥にもどった。和の礎の国に、美しい言の葉がふたたび舞う。',
    ),
    WorldStory(
      worldId: 'math',
      guardian: '巨神カラクリ・ゴーレム',
      guardianLook: 'golem',
      guardianColor: 0xFF9C7A3C,
      fragment: '数の欠片',
      emblem: '天秤の紋章',
      clearText: '歯車の狂いが直り、数理の迷宮国は完璧な均衡を取りもどした。',
    ),
    WorldStory(
      worldId: 'english',
      guardian: '海獣バベル・リヴァイアサン',
      guardianLook: 'leviathan',
      guardianColor: 0xFF2B5F8A,
      fragment: 'ことばの欠片',
      emblem: '羅針の紋章',
      clearText: '嵐が晴れ、異界の港町に船がもどった。知らない言葉の人とも、心を通わせられる。',
    ),
    WorldStory(
      worldId: 'science',
      guardian: '炎氷竜カオス・エレメンタル',
      guardianLook: 'dragon',
      guardianColor: 0xFF7A3FA0,
      fragment: 'ことわりの欠片',
      emblem: '炎氷の紋章',
      clearText: '熱も光も気候も、正しい法則にもどった。万物の実験庭園に、穏やかな季節がめぐる。',
    ),
    WorldStory(
      worldId: 'social',
      guardian: '幽幻騎士クロノス・ナイト',
      guardianLook: 'knight',
      guardianColor: 0xFF6B5B45,
      fragment: '時の欠片',
      emblem: '砂時計の紋章',
      clearText: 'クロノス・ナイトは誇りを取りもどした。時空の回廊に、人びとの歩みがふたたび刻まれる。',
    ),
  ];

  static WorldStory of(String worldId) =>
      worlds.firstWhere((w) => w.worldId == worldId);

  /// その国のルートの最後のステージ（すべて倒すと欠片が手に入る）
  static List<StageDef> finalsOf(String worldId) {
    final w = RpgCatalog.world(worldId);
    final last = <String, StageDef>{};
    for (final s in w.stages) {
      last[s.branch] = s;
    }
    return last.values.toList();
  }

  /// 取りもどした欠片（国の ID）
  static Set<String> fragments(RpgProgress p) => {
        for (final w in worlds)
          if (finalsOf(w.worldId)
              .every((s) => p.clearedStageIds.contains(s.id)))
            w.worldId,
      };

  /// 天空の図書院への扉がひらいたか
  static bool centerOpen(RpgProgress p) => fragments(p).length == worlds.length;

  static const centerStageId = 'world_center_final';

  /// 天空の図書院の決戦。5つの国の最後のボスの範囲すべてから出題する（小中学校の総まとめ）
  static StageDef centerStage() {
    final sets = <String>[];
    for (final w in worlds) {
      for (final s in finalsOf(w.worldId)) {
        for (final id in s.questionSetIds) {
          if (!sets.contains(id)) sets.add(id);
        }
      }
    }
    return StageDef(
      id: centerStageId,
      worldId: 'english',
      order: 1,
      name: '天空の図書院',
      region: '天空の図書院',
      isBoss: true,
      enemy: const EnemyDef(
        id: 'nebra',
        name: '虚無の霧ネブラ',
        maxHp: 2600,
        attack: 60,
        look: 'ghost',
        color: 0xFF4A4660,
        description: '知識を忘れ去り、考えることをやめてしまった心の隙間から生まれた怪物。5教科すべての問いで立ちはだかる。',
        introLine: '解かなくてもいい、考えなくてもいい……楽な暗闇へおいで……。',
        defeatLine: 'なぜ……考えることを、やめないの……？ 霧が……晴れていく……。',
      ),
      questionSetIds: sets,
      expReward: 1000,
      timeLimitSeconds: 25,
      readingTimeLimitSeconds: 70,
      recommendedLevel: 40,
      grammarTheme: '小中学校の総まとめ（5教科）',
      vocabLevel: '全範囲',
    );
  }
}
