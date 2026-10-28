import '../models/player_stats.dart';
import '../models/question.dart';
import '../models/stage.dart';
import 'realm.dart';

/// 予想問題を小問ごとに解く。
///
/// 大問ごとのまとまり（本文・前書き＝Passage）をそのまま使い、順番どおりに出す
/// （前の小問が次の小問の誘導になっていることがあるため）。
class YosouGroup {
  const YosouGroup(
      {required this.id, required this.title, required this.questions});

  final String id;
  final String title;
  final List<QuizQuestion> questions;

  /// 問題データを大問ごとに分ける（出てきた順。本文がない問題は直前の大問に続ける）
  static List<YosouGroup> of(List<QuizQuestion> questions) {
    final out = <YosouGroup>[];
    final order = <String>[];
    final byId = <String, List<QuizQuestion>>{};
    final titles = <String, String>{};
    for (final q in questions) {
      final id = groupId(q);
      if (!byId.containsKey(id)) {
        order.add(id);
        byId[id] = [];
        titles[id] = q.passage?.title ?? id;
      }
      byId[id]!.add(q);
    }
    for (final id in order) {
      out.add(YosouGroup(id: id, title: titles[id]!, questions: byId[id]!));
    }
    return out;
  }

  /// 大問のまとまりの名前（本文の id。なければ問題 id の先頭）
  static String groupId(QuizQuestion q) =>
      q.passage?.id ??
      q.id.substring(0, q.id.lastIndexOf('_').clamp(0, q.id.length));
}

/// 予想問題のバトル（定期テストの海より時間に余裕があり、何度かまちがえても続けられる）
abstract final class YosouBattle {
  static StageDef stage({
    required String id,
    required String title,
    required String worldId,
    required int level,
    required int questions,
  }) {
    final player = PlayerStats.forLevel(level);
    final h = id.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7fffffff);
    final monsters = [
      ...VoyageMonsters.surface(StudyRealm.sea),
      ...VoyageMonsters.deep(StudyRealm.sea),
    ];
    final m = monsters[h % monsters.length];
    // ふつうの正解で、問題の数（最大12）だけ当てれば倒せる。6回まちがえると倒れる
    final hits = questions.clamp(3, 12);
    final attack = (player.maxHp / 6 + player.defense / 2).ceil() + 1;
    return StageDef(
      id: 'yosou_battle_$id',
      worldId: worldId,
      order: 1,
      name: title,
      region: '予想問題',
      isBoss: true,
      expReward: 0,
      questionSetIds: const [],
      timeLimitSeconds: 90,
      readingTimeLimitSeconds: 240,
      grammarTheme: title,
      enemy: m.toEnemy(
        id: 'yosou_enemy_$id',
        maxHp: player.attack * hits,
        attack: attack,
        introLine: '「$title」…本番の前に、ここで力を試すがいい！',
      ),
    );
  }
}
