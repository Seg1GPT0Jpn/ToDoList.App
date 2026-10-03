import '../data/catalog.dart';
import '../models/enemy.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';

/// 教科の国ごとの物語
class WorldStory {
  const WorldStory({
    required this.worldId,
    required this.fragment,
    required this.key,
    required this.clearText,
  });

  final String worldId;

  /// その国で取りもどす「知識の欠片」
  final String fragment;

  /// 欠片といっしょに手に入る、次の国への鍵
  final String key;

  /// 国を救ったときの文
  final String clearText;
}

/// つづりクエストの世界の物語。
///
/// かつて一つだった「知識の世界」が、謎の災害によって5つの国に分断された。
/// 主人公は各国を旅して「知識の欠片」を集め、世界を復元していく。
/// 5つの欠片がそろうと「世界の中心」への道がひらき、知識を奪った魔王と決戦になる。
class Story {
  const Story._();

  static const title = '知識の世界と、5つの欠片';

  static const prologue = [
    'むかし、この世界は一つの大きな「知識の世界」だった。',
    'ことば、数、自然、歴史――すべての知識がつながり、人びとは自由に学び、旅をしていた。',
    'ところがある日、「忘却の魔王」があらわれ、世界の知識を奪って引きさいてしまった。',
    '世界は5つの国――英語の国・理の国・時と地の国・言の葉の国・数の国――に分かれ、国と国をつなぐ道は閉ざされた。',
    '奪われた知識は「知識の欠片」となって、それぞれの国のいちばん奥で、魔物たちに守られている。',
    'きみは、ノートとペンを手にした見習いの冒険者。',
    '各国を旅して問いに答え、魔物をたおし、知識の欠片を取りもどそう。',
    '5つの欠片がそろったとき、「世界の中心」への道がひらく――。',
  ];

  static const worlds = <WorldStory>[
    WorldStory(
      worldId: 'english',
      fragment: 'ことばの欠片',
      key: '言葉の鍵',
      clearText: '英語の国に、ことばの流れがもどった。遠くの国の人とも、また話せる。',
    ),
    WorldStory(
      worldId: 'science',
      fragment: 'ことわりの欠片',
      key: '実験の鍵',
      clearText: '理の国に、自然のきまりがもどった。空も大地も、また正しく動きはじめる。',
    ),
    WorldStory(
      worldId: 'social',
      fragment: '時の欠片',
      key: '年表の鍵',
      clearText: '時と地の国に、歴史と地図がもどった。人びとは自分たちの歩みを思い出した。',
    ),
    WorldStory(
      worldId: 'japanese',
      fragment: '言の葉の欠片',
      key: '筆の鍵',
      clearText: '言の葉の国に、物語と歌がもどった。むかしの人の心の声が、また聞こえる。',
    ),
    WorldStory(
      worldId: 'math',
      fragment: '数の欠片',
      key: '公式の鍵',
      clearText: '数の国に、数と図形の調和がもどった。橋も塔も、また正しく建てられる。',
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

  /// 世界の中心への道がひらいたか
  static bool centerOpen(RpgProgress p) => fragments(p).length == worlds.length;

  static const centerStageId = 'world_center_final';

  /// 世界の中心の決戦。5つの国の最後のボスの範囲すべてから出題する（小中学校の総まとめ）
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
      name: '世界の中心',
      region: '世界の中心',
      isBoss: true,
      enemy: const EnemyDef(
        id: 'oblivion_king',
        name: '忘却の魔王',
        maxHp: 2600,
        attack: 60,
        look: 'dragon',
        color: 0xFF3A2A5A,
        description: '世界の知識を奪い、5つの国に引きさいた魔王。すべての教科の問いで立ちはだかる。',
        introLine: 'よくぞ5つの欠片を集めた。だが、知識はふたたび忘却の底へ沈むのだ！',
        defeatLine: 'ばかな…忘れても、また学ぶというのか…。',
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
