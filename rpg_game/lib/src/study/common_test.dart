import 'dart:math';

import '../data/catalog.dart';
import '../models/enemy.dart';
import '../models/question.dart';
import '../models/stage.dart';
import '../models/world.dart';

/// 共通テスト遺跡の階。下の階ほどやさしく、上の階ほど共通テストに近い。
///
/// ※ 問題はすべて自作の問題。共通テストの過去問は使っていない。
///   「思考・計算・読解」の問題や、複数の教科をまたぐ出題で、本番の形に近づける。
enum RuinsFloor {
  basic('第1階層', '基礎', '各ルートの前半のエリアから'),
  standard('第2階層', '標準', '各ルートの中ほどのエリアから'),
  applied('第3階層', '共通テスト型', '考察・計算・読解の問題だけ'),
  mixed('第4階層', '複合', '3教科以上をまぜて出題'),
  real('最上階', '本番想定', '全教科・制限時間みじかめ・分野横断のボス');

  const RuinsFloor(this.label, this.title, this.description);
  final String label;
  final String title;
  final String description;
}

class CommonTest {
  const CommonTest._();

  /// 共通テスト型とみなす問題の種類
  static const appliedCategories = {
    QuestionCategory.thinking,
    QuestionCategory.calculation,
    QuestionCategory.reading,
  };

  /// ルートの中での位置（0〜1）
  static double _position(WorldDef w, StageDef s) {
    final same = w.stages.where((x) => x.branch == s.branch).toList();
    return same.length <= 1 ? 0 : same.indexOf(s) / (same.length - 1);
  }

  /// その階で使うステージ（解放済みの教科 [worlds] から、日ごとに入れかわる）
  static List<StageDef> stagesFor(
    RuinsFloor floor,
    List<WorldDef> worlds, {
    required int seed,
    int limit = 8,
  }) {
    final rnd = Random(seed);
    final pool = <StageDef>[
      for (final w in worlds)
        for (final s in w.stages)
          if (!s.isBoss &&
              switch (floor) {
                RuinsFloor.basic => _position(w, s) <= 0.34,
                RuinsFloor.standard =>
                  _position(w, s) > 0.3 && _position(w, s) <= 0.7,
                _ => _position(w, s) > 0.3,
              })
            s,
    ]..shuffle(rnd);
    if (floor == RuinsFloor.mixed || floor == RuinsFloor.real) {
      // 教科がかたよらないように、教科ごとに順番に取る
      final bySubject = <String, List<StageDef>>{};
      for (final s in pool) {
        bySubject.putIfAbsent(s.worldId, () => []).add(s);
      }
      final out = <StageDef>[];
      var i = 0;
      while (out.length < limit && bySubject.values.any((l) => i < l.length)) {
        for (final l in bySubject.values) {
          if (i < l.length && out.length < limit) out.add(l[i]);
        }
        i++;
      }
      return out;
    }
    return pool.take(limit).toList();
  }

  /// その階の問題にしぼる（第3階層以上は、考察・計算・読解を中心に）
  static List<QuizQuestion> filter(RuinsFloor floor, List<QuizQuestion> qs) {
    if (floor.index < RuinsFloor.applied.index) return qs;
    final applied =
        qs.where((q) => appliedCategories.contains(q.category)).toList();
    // 少なすぎるときは、ほかの問題もまぜる
    return applied.length >= 12 ? applied : qs;
  }

  /// その階で戦うボスの数（下の階ほど少ない）
  static int bossCount(RuinsFloor floor) => const [2, 3, 3, 4, 5][floor.index];

  /// 階のボスたち（登場する順）。前のボスが弱ると、次のボスが乱入してきて
  /// 2体のボスが重なって戦う。HP は引き継ぐので、最後まで気がぬけない。
  static List<EnemyDef> guardians(RuinsFloor floor, {required int level}) {
    final base = 60 + level * 9 + floor.index * 22;
    final attack = 7 + level ~/ 2 + floor.index * 3;
    final all = <EnemyDef>[
      EnemyDef(
        id: 'ruins_${floor.name}_1',
        name: switch (floor) {
          RuinsFloor.basic => '遺跡の見張り',
          RuinsFloor.standard => '遺跡の門番',
          RuinsFloor.applied => '思考のゴーレム',
          RuinsFloor.mixed => '複合のキマイラ',
          RuinsFloor.real => '開門の番兵',
        },
        maxHp: base,
        attack: attack,
        look: const [
          'book',
          'compass',
          'golem',
          'dragon',
          'knight'
        ][floor.index],
        color: 0xFF6D5A3A,
        description: '共通テスト遺跡の${floor.label}（${floor.title}）を守る。',
        introLine: 'この階の問いに、すべて答えてみよ。…ひとりでは終わらぬぞ。',
        defeatLine: 'まだだ…あとは、あいつにまかせる…！',
      ),
      EnemyDef(
        id: 'ruins_${floor.name}_2',
        name: '石板のゴーレム',
        maxHp: base,
        attack: attack,
        look: 'golem',
        color: 0xFF8D8170,
        ability: EnemyAbility.sturdy,
        description: '古い石板に刻まれた問いから生まれた。とても打たれ強い。',
        introLine: '石板の問いを、解いてみせよ！',
        defeatLine: '石板が…割れた…',
      ),
      EnemyDef(
        id: 'ruins_${floor.name}_3',
        name: '図表の番人',
        maxHp: base,
        attack: attack,
        look: 'protractor',
        color: 0xFF5B7DB1,
        ability: EnemyAbility.disrupt,
        description: 'グラフと表を読ませる番人。まちがえると、長い問題を出してくる。',
        introLine: 'この図、きちんと読めるかな？',
        defeatLine: '読み取られてしまったか…',
      ),
      EnemyDef(
        id: 'ruins_${floor.name}_4',
        name: '分野横断のスフィンクス',
        maxHp: base,
        attack: attack,
        look: 'binder',
        color: 0xFFB08D57,
        ability: EnemyAbility.chainLock,
        description: '教科の壁をこえた問いを出す。続けて正解しないと、ほとんど効かない。',
        introLine: '教科のさかいめは、ここにはない。',
        defeatLine: '見事…すべての知識がつながっている…',
      ),
    ];
    final count = bossCount(floor);
    final bosses = [
      for (var i = 0; i < count - 1; i++) all[i % all.length],
      EnemyDef(
        id: 'ruins_${floor.name}_last',
        name: switch (floor) {
          RuinsFloor.basic => '基礎の石像',
          RuinsFloor.standard => '標準の大石像',
          RuinsFloor.applied => '考察の賢者像',
          RuinsFloor.mixed => '複合の巨像',
          RuinsFloor.real => '本番の守護者',
        },
        maxHp: (base * 1.3).round(),
        attack: attack + 2,
        look: floor == RuinsFloor.real ? 'dragon' : 'knight',
        color: floor == RuinsFloor.real ? 0xFF4A3B2A : 0xFF7A6A50,
        description: '${floor.label}の最後に立ちはだかる、遺跡の主。',
        introLine: '重なる試練を越えてきたか。最後の問いだ！',
        defeatLine: 'みごとだ。次の階へ進むがよい。',
      ),
    ];
    return bosses;
  }

  /// 階のボスの連戦（バトルのステージ）。最初のボスが [StageDef.enemy]、
  /// 続くボスが [StageDef.reinforcements]。
  static StageDef stage(
    RuinsFloor floor,
    List<StageDef> picked, {
    required int level,
  }) {
    final bosses = guardians(floor, level: level);
    return StageDef(
      id: 'ruins_${floor.name}',
      worldId:
          picked.isEmpty ? RpgCatalog.englishWorldId : picked.first.worldId,
      order: floor.index + 1,
      name: '共通テスト遺跡・${floor.label}',
      region: '共通テスト遺跡',
      isBoss: true,
      enemy: bosses.first,
      reinforcements: bosses.sublist(1),
      questionSetIds: [for (final s in picked) ...s.questionSetIds],
      expReward: 0,
      timeLimitSeconds: floor == RuinsFloor.real ? 18 : 25,
      readingTimeLimitSeconds: floor == RuinsFloor.real ? 55 : 70,
      grammarTheme: '共通テスト遺跡・${floor.title}',
    );
  }
}

/// 模試ダンジョン：制限時間の中で、教科を順に進んでいく。
/// 最後に教科ごとの点数（100点満点）と、弱点の単元を出す。
class MockExam {
  const MockExam._();

  /// 1教科あたりの問題数
  static const perSubject = 5;

  /// 1教科あたりの時間（秒）
  static const secondsPerSubject = 150;

  /// 教科の問題を選ぶ（その教科のステージから、日ごとに入れかわる）
  static List<StageDef> stagesFor(WorldDef world, {required int seed}) {
    final pool = world.stages.where((s) => !s.isBoss).toList()
      ..shuffle(Random(seed + world.id.hashCode));
    return pool.take(3).toList();
  }

  /// 点数（100点満点）
  static int score(int correct, int asked) =>
      asked == 0 ? 0 : (correct * 100 / asked).round();
}
