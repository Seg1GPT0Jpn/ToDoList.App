import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri_quest_3d/game/field_battle.dart';
import 'package:tsuzuri_quest_3d/game/questions.dart';
import 'package:tsuzuri_quest_3d/game/save3d.dart';
import 'package:tsuzuri_quest_3d/title_screen.dart';

List<QuizQuestion> _questions() => [
  for (var i = 0; i < 6; i++)
    QuizQuestion(
      id: 'q$i',
      category: QuestionCategory.values.first,
      prompt: '問題$i',
      choices: ['正解$i', 'ちがう$i-a', 'ちがう$i-b', 'ちがう$i-c'],
      answerIndex: 0,
    ),
];

FieldBattle _battle() {
  final stage = RpgCatalog.world('english').stages.first;
  return FieldBattle(
    BattleEngine(
      player: BattlePower.forStage(RpgProgress.initial, stage),
      enemy: stage.enemy,
      questions: _questions(),
      timeLimit: Duration(seconds: stage.timeLimitSeconds),
    ),
  );
}

int _correct(FieldBattle b) => b.question.correctIndex;
int _wrong(FieldBattle b) => (b.question.correctIndex + 1) % 4;

void main() {
  group('その場で戦うバトル', () {
    test('正解すると剣をふる時間になり、当てると敵のHPが減る', () {
      final b = _battle();
      final hp = b.engine.enemyHp;
      expect(b.choose(_correct(b), const Duration(seconds: 1)), isTrue);
      expect(b.phase, FieldBattlePhase.swing);
      expect(b.engine.enemyHp, hp, reason: '当てるまではダメージなし');
      final r = b.hit(const Duration(milliseconds: 300));
      expect(r.correct, isTrue);
      expect(b.engine.enemyHp, lessThan(hp));
      expect(b.phase, FieldBattlePhase.feedback);
    });

    test('すばやく答えて すばやく当てるとクリティカル、遅いとふつう', () {
      final fast = _battle();
      fast.choose(_correct(fast), const Duration(milliseconds: 500));
      expect(fast.hit(const Duration(milliseconds: 300)).quick, isTrue);
      final slow = _battle();
      slow.choose(_correct(slow), const Duration(milliseconds: 500));
      expect(slow.hit(const Duration(seconds: 30)).quick, isFalse);
    });

    test('ふり遅れはダメージ半分（部分点）で、反撃も受ける', () {
      final hit = _battle();
      hit.choose(_correct(hit), const Duration(seconds: 3));
      final full = hit.hit(const Duration(seconds: 2)).damageToEnemy;
      final late = _battle();
      late.choose(_correct(late), const Duration(seconds: 3));
      final r = late.late();
      expect(late.lastWasLate, isTrue);
      expect(r.correct, isFalse);
      expect(r.damageToEnemy, greaterThan(0));
      expect(r.damageToEnemy, lessThan(full));
    });

    test('不正解・時間切れは剣をふれず、敵の反撃を受ける', () {
      final b = _battle();
      final hp = b.engine.playerHp;
      expect(b.choose(_wrong(b), const Duration(seconds: 1)), isFalse);
      expect(b.phase, FieldBattlePhase.feedback);
      expect(b.engine.playerHp, lessThan(hp));
      expect(() => b.hit(Duration.zero), throwsStateError);
      b.next();
      expect(b.phase, FieldBattlePhase.asking);
      b.timeout();
      expect(b.last!.timedOut, isTrue);
    });

    test('正解して当て続けると勝ち、間違え続けると負ける', () {
      final win = _battle();
      for (var i = 0; i < 50 && !win.isOver; i++) {
        win.choose(_correct(win), const Duration(seconds: 1));
        win.hit(const Duration(milliseconds: 200));
        win.next();
      }
      expect(win.phase, FieldBattlePhase.won);
      expect(win.summary().won, isTrue);
      final lose = _battle();
      for (var i = 0; i < 50 && !lose.isOver; i++) {
        lose.choose(_wrong(lose), const Duration(seconds: 1));
        lose.next();
      }
      expect(lose.phase, FieldBattlePhase.lost);
    });
  });

  testWidgets('タイトルで3D版のデータを消しても、2D版のデータは残る', (t) async {
    SharedPreferences.setMockInitialValues({
      'rpg_progress_v1': '2D版のデータ',
      Save3D.progressKey: '{"level":3}',
      Save3D.fieldKey: '{}',
    });
    await t.pumpWidget(const MaterialApp(home: TitleScreen()));
    await t.pumpAndSettle();
    expect(find.text('つづきから'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('title-reset')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('title-reset-ok')));
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('rpg_progress_v1'), '2D版のデータ');
    expect(prefs.containsKey(Save3D.progressKey), isFalse);
    expect(prefs.containsKey(Save3D.fieldKey), isFalse);
    expect(find.text('冒険をはじめる'), findsOneWidget);
  });

  test('3D版のバトルで出せない問題（図・聞き取り）は除く', () {
    final base = _questions().first;
    expect(Questions3D.playable(base), isTrue);
    QuizQuestion copy(Map<String, dynamic> extra) =>
        QuizQuestion.fromJson({...base.toJson(), ...extra});
    expect(
      Questions3D.playable(
        copy({
          'figure': {'type': 'graph'},
        }),
      ),
      isFalse,
    );
    expect(Questions3D.playable(copy({'listen': true})), isFalse);
  });
}
