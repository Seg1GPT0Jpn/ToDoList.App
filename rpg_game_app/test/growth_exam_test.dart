import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/meta/growth_screen.dart';
import 'package:rpg_game_app/meta/learning_status_screen.dart';
import 'package:rpg_game_app/study/comprehensive_exam_screen.dart';

import 'harness.dart';

Future<void> frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 問題セットの読み込み（本物の非同期）を終わらせる。
/// 途中のまま次のテストに進むと、アセットの読み込みが止まったまま残るため
Future<void> settle(WidgetTester t, {int rounds = 30}) async {
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('成長と学習ルート：記録がなくても開け、教科を切りかえられる', (t) async {
    await openScreen(t, const GrowthScreen(), frames: 20);
    await settle(t);
    expect(find.byKey(const ValueKey('growth-measures')), findsOneWidget);
    expect(find.text('初見正答率'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const ValueKey('phase-ladder')), 200);
    expect(find.textContaining('いまの段：フェーズ1'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const ValueKey('growth-all')), -200);
    await t.tap(find.byKey(const ValueKey('growth-math')));
    await frames(t, 3);
    expect(t.takeException(), isNull);
  });

  testWidgets('苦手な単元があると、前提をさかのぼった学習ルートが出る', (t) async {
    final services = await openScreen(t, const GrowthScreen(subject: 'math'));
    await settle(t);
    QuestionStat stat(String unit, int correct) => QuestionStat(
      setId: 'math_x',
      unit: unit,
      attempts: 2,
      correct: correct,
      first: correct > 0 ? 1 : 2,
    );
    await services.meta.save(
      record: LearningRecord(
        stats: {
          for (var i = 0; i < 6; i++) ...{
            'e$i': stat('math.m2.calculus.apply.extremum', 0),
            'g$i': stat('math.m1.quad.graph.vertex', 0),
          },
        },
      ),
    );
    await frames(t, 5);
    final card = find.byKey(const ValueKey('route-math.m2.calculus.apply'));
    await t.scrollUntilVisible(card, 200);
    expect(find.textContaining('根本の原因は前提の「'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('総合演習：始めて答え、採点すると分析と記録が残る', (t) async {
    // ほかのテストのフェイクの時間の中で始めたアセットの読み込みを持ちこさない
    rootBundle.clear();
    final services = await openScreen(
      t,
      const ComprehensiveExamScreen(subject: 'math'),
      frames: 5,
    );
    // 問題セットの読み込み（本物の非同期）を待つ
    for (var i = 0; i < 100; i++) {
      if (find.byKey(const ValueKey('exam-start')).evaluate().isNotEmpty) break;
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('exam-start')), findsOneWidget);
    expect(find.textContaining('点満点'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('exam-start')));
    await frames(t, 2);
    expect(find.byKey(const ValueKey('exam-clock')), findsOneWidget);
    // 4択の問題が出るまで進めて答える（それ以外はとばす）
    var answered = 0;
    for (var i = 0; i < 14 && answered < 3; i++) {
      final choice = find.byKey(const ValueKey('exam-choice-0'));
      if (choice.evaluate().isNotEmpty) {
        await t.ensureVisible(choice);
        await t.tap(choice);
        answered++;
      } else {
        final skip = find.byKey(const ValueKey('exam-skip'));
        await t.ensureVisible(skip);
        await t.tap(skip);
      }
      await frames(t, 2);
    }
    expect(answered, greaterThan(0));
    final finish = find.byKey(const ValueKey('exam-finish'));
    if (finish.evaluate().isNotEmpty) {
      await t.ensureVisible(finish);
      await t.tap(finish);
    }
    await frames(t, 5);
    expect(find.byKey(const ValueKey('exam-score')), findsOneWidget);
    expect(find.text('分野ごと'), findsOneWidget);
    expect(services.meta.record.stats.length, answered);
    final stat = services.meta.record.stats.values.first;
    expect(AnswerProfile.decode(stat.profile), isNotNull);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('学習ステータスから成長と総合演習へ行ける', (t) async {
    await openScreen(t, const LearningStatusScreen());
    expect(find.byKey(const ValueKey('open-growth')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-exam-from-status')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('open-growth')));
    await frames(t, 10);
    await settle(t);
    expect(find.byType(GrowthScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
