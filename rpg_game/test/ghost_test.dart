import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

VersusMatch _match(int seed) => VersusMatch(
      questions: loadStage01().questions,
      names: const ['あお', 'あか'],
      rounds: 5,
      random: Random(seed),
    );

int _wrong(VersusMatch m) =>
    (m.current.correctIndex + 1) % m.current.choices.length;

void main() {
  test('対戦から自分の答え方を記録する。相手にとられた問題は null', () {
    final m = _match(7);
    m.answer(0, m.current.correctIndex, elapsed: const Duration(seconds: 2));
    m.answer(1, m.current.correctIndex, elapsed: const Duration(seconds: 1));
    m.answer(0, _wrong(m), elapsed: const Duration(seconds: 3));
    m.answer(1, m.current.correctIndex, elapsed: const Duration(seconds: 4));
    m.timeout();
    m.answer(0, m.current.correctIndex, elapsed: const Duration(seconds: 5));
    final g = GhostRun.fromMatch(m,
        side: 0, name: 'あお', setIds: const ['s1'], seed: 7);
    expect(g.answers.map((a) => a == null ? null : (a.ms, a.ok)), [
      (2000, true),
      null,
      (3000, false),
      null,
      (5000, true),
    ]);
    expect(g.usable, isTrue);
    final back = GhostRun.fromMap(g.toMap())!;
    expect(back.answers.map((a) => a == null ? null : (a.ms, a.ok)),
        g.answers.map((a) => a == null ? null : (a.ms, a.ok)));
    expect(back.setIds, ['s1']);
    expect(GhostRun.fromMap({'name': 1}), isNull);
  });

  test('ゴーストは記録どおりの時間・正誤で答え、答えなかった問題には答えない', () {
    const run = GhostRun(
      name: 'あお',
      setIds: ['s1'],
      seed: 7,
      rounds: 3,
      answers: [GhostAnswer(1500, true), null, GhostAnswer(800, false)],
    );
    final m = _match(7);
    final cpu = GhostCpu(run, random: Random(1));
    expect(cpu.thinkTime(m.current), const Duration(milliseconds: 1500));
    expect(cpu.choose(m.current), m.current.correctIndex);
    m.timeout();
    expect(cpu.thinkTime(m.current), GhostCpu.never);
    m.timeout();
    expect(cpu.thinkTime(m.current), const Duration(milliseconds: 800));
    expect(cpu.choose(m.current), isNot(m.current.correctIndex));
    // 記録より先は答えない
    m.timeout();
    expect(cpu.thinkTime(m.current), GhostCpu.never);
  });
}
