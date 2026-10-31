import 'dart:math';

import '../battle/question_deck.dart';
import 'versus_match.dart';

/// ゴーストの1問ぶんの答え
class GhostAnswer {
  const GhostAnswer(this.ms, this.ok);

  /// 出題から答えるまで（ミリ秒）
  final int ms;
  final bool ok;
}

/// ゴースト：ほかの人がランダム対戦で遊んだときの答え方の記録。
///
/// 同じ問題（[setIds] と [seed]）で、その人が答えた時間と正誤をそのまま再現する。
/// 相手に先に答えられて答えなかった問題は null（ゴーストも答えない）。
/// 送るのはニックネームと、問題ごとの時間・正誤だけ。
class GhostRun {
  const GhostRun({
    required this.name,
    required this.setIds,
    required this.seed,
    required this.rounds,
    required this.answers,
  });

  final String name;
  final List<String> setIds;
  final int seed;
  final int rounds;
  final List<GhostAnswer?> answers;

  static const maxRounds = 30;
  static const maxMs = 60000;

  /// 記録として使えるだけ答えているか（少なすぎる記録はゴーストにしない）
  bool get usable => answers.whereType<GhostAnswer>().length >= 3;

  /// 終わった対戦から、[side] の人の答え方を記録する
  static GhostRun fromMatch(
    VersusMatch match, {
    required int side,
    required String name,
    required List<String> setIds,
    required int seed,
  }) {
    final answers = <GhostAnswer?>[];
    GhostAnswer? mine;
    for (final t in match.turns) {
      if (t.side == side && mine == null) {
        mine = GhostAnswer(t.ms.clamp(0, maxMs), t.correct);
      }
      if (t.roundOver) {
        answers.add(mine);
        mine = null;
      }
    }
    return GhostRun(
      name: name,
      setIds: setIds,
      seed: seed,
      rounds: match.rounds,
      answers: answers.take(maxRounds).toList(),
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'setIds': setIds,
        'seed': seed,
        'rounds': rounds,
        'answers': [
          for (final a in answers) a == null ? -1 : (a.ok ? a.ms : -2 - a.ms),
        ],
      };

  /// 壊れたデータは null
  static GhostRun? fromMap(Object? m) {
    if (m is! Map) return null;
    final name = m['name'], setIds = m['setIds'], answers = m['answers'];
    final seed = m['seed'], rounds = m['rounds'];
    if (name is! String ||
        setIds is! List ||
        answers is! List ||
        seed is! num ||
        rounds is! num) {
      return null;
    }
    // 正解は ms、不正解は -2-ms、答えなかったら -1 で詰めて送る
    GhostAnswer? decode(Object? v) {
      if (v is! num) return null;
      final n = v.toInt();
      if (n == -1) return null;
      return n >= 0
          ? GhostAnswer(min(n, maxMs), true)
          : GhostAnswer(min(-2 - n, maxMs), false);
    }

    return GhostRun(
      name: name,
      setIds: [
        for (final s in setIds)
          if (s is String) s,
      ],
      seed: seed.toInt(),
      rounds: rounds.toInt().clamp(1, maxRounds),
      answers: [for (final a in answers.take(maxRounds)) decode(a)],
    );
  }
}

/// ゴーストの動き：記録どおりの時間に、記録どおりの正誤で答える
class GhostCpu extends VersusCpu {
  GhostCpu(this.run, {Random? random})
      : _random = random ?? Random(),
        super(CpuLevel.normal, random: random);

  final GhostRun run;
  final Random _random;
  int _round = 0;
  GhostAnswer? _now;

  /// 答えない問題（相手にとられた問題など）
  static const never = Duration(days: 1);

  @override
  Duration thinkTime(PresentedQuestion q) {
    final i = _round++;
    _now = i < run.answers.length ? run.answers[i] : null;
    final a = _now;
    return a == null ? never : Duration(milliseconds: a.ms);
  }

  @override
  int choose(PresentedQuestion q, {Set<int> avoid = const {}}) {
    if (_now?.ok ?? false) return q.correctIndex;
    final wrong = [
      for (var i = 0; i < q.choices.length; i++)
        if (i != q.correctIndex && !avoid.contains(i)) i,
    ];
    return wrong.isEmpty
        ? q.correctIndex
        : wrong[_random.nextInt(wrong.length)];
  }
}
