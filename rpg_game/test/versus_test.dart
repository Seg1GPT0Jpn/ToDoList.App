import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

VersusMatch _match({int rounds = 15}) => VersusMatch(
      questions: loadStage01().questions,
      names: const ['あお', 'あか'],
      rounds: rounds,
      random: Random(3),
    );

int _wrong(VersusMatch m) =>
    (m.current.correctIndex + 1) % m.current.choices.length;

void main() {
  group('早押し対戦', () {
    test('正解すると相手にダメージ。はやく答えるとボーナス、続けて正解するともっと強い', () {
      final m = _match();
      final slow = m.answer(0, m.current.correctIndex,
          elapsed: const Duration(seconds: 10));
      expect(slow.damage, VersusMatch.baseDamage);
      expect(m.players[1].hp, 100 - VersusMatch.baseDamage);
      final fast = m.answer(0, m.current.correctIndex,
          elapsed: const Duration(seconds: 1));
      expect(fast.fast, isTrue);
      expect(fast.combo, 2);
      expect(fast.damage, VersusMatch.baseDamage + VersusMatch.fastBonus + 4);
      expect(m.round, 3);
    });

    test('お手つきすると自分にダメージ。その問題は相手だけが答えられる', () {
      final m = _match();
      final q = m.current;
      final miss = m.answer(0, _wrong(m), elapsed: const Duration(seconds: 2));
      expect(miss.correct, isFalse);
      expect(miss.roundOver, isFalse);
      expect(m.players[0].hp, 100 - VersusMatch.missDamage);
      expect(m.isLocked(0), isTrue);
      expect(() => m.answer(0, q.correctIndex, elapsed: Duration.zero),
          throwsStateError);
      expect(identical(m.current, q), isTrue, reason: 'まだ同じ問題');
      final hit =
          m.answer(1, q.correctIndex, elapsed: const Duration(seconds: 3));
      expect(hit.correct, isTrue);
      expect(hit.roundOver, isTrue);
      expect(m.isLocked(0), isFalse, reason: '次の問題ではまた答えられる');
    });

    test('2人ともまちがえると、ダメージなしで次の問題へ', () {
      final m = _match();
      m.answer(0, _wrong(m), elapsed: const Duration(seconds: 1));
      final t = m.answer(1, _wrong(m), elapsed: const Duration(seconds: 2));
      expect(t.roundOver, isTrue);
      expect(m.round, 2);
      expect(m.players[0].hp, m.players[1].hp);
    });

    test('HP が 0 になったら決着。問題数を使い切ったら HP が多いほうの勝ち', () {
      final m = _match(rounds: 30);
      while (!m.isOver) {
        m.answer(1, m.current.correctIndex,
            elapsed: const Duration(seconds: 1));
      }
      expect(m.players[0].down, isTrue);
      expect(m.winner, 1);

      final n = _match(rounds: 2);
      n.answer(0, n.current.correctIndex, elapsed: const Duration(seconds: 9));
      n.timeout();
      expect(n.isOver, isTrue);
      expect(n.winner, 0);

      final draw = _match(rounds: 1);
      draw.timeout();
      expect(draw.winner, isNull);
    });

    test('CPU は強さに合わせて正解し、強いほどはやく答える', () {
      final m = _match();
      final rates = <CpuLevel, double>{};
      for (final level in CpuLevel.values) {
        final cpu = VersusCpu(level, random: Random(1));
        var ok = 0;
        var ms = 0;
        for (var i = 0; i < 400; i++) {
          if (m.current.isCorrect(cpu.choose(m.current))) ok++;
          ms += cpu.thinkTime(m.current).inMilliseconds;
        }
        rates[level] = ok / 400;
        expect(ok / 400, closeTo(level.accuracy, 0.07), reason: level.name);
        expect(ms / 400, lessThan(level.maxSeconds * 1000 + 2000));
      }
      expect(rates[CpuLevel.master]!, greaterThan(rates[CpuLevel.easy]!));
      // お手つきした答えはもう選ばない
      final cpu = VersusCpu(CpuLevel.easy, random: Random(2));
      final avoid = {
        for (var i = 0; i < 4; i++)
          if (i != m.current.correctIndex) i
      };
      expect(cpu.choose(m.current, avoid: avoid.difference({_wrong(m)})),
          anyOf(m.current.correctIndex, _wrong(m)));
    });
  });
}
