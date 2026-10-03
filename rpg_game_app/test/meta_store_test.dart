import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('学習記録と冒険の記録を保存し、クラウドにも知らせる', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = MetaStore(prefs);
    LearningRecord? pushed;
    store.onLearningSaved = (r) async => pushed = r;
    final record = LearningRecord.empty.recordAll(const [
      AnswerEvent(
        questionId: 'q1',
        setId: 'math_j1_01',
        isCorrect: true,
        elapsedMs: 2000,
      ),
    ], day: 10);
    await store.save(
      record: record,
      journal: PlayerJournal.empty.copyWith(title: 'はじめの一歩'),
    );
    expect(pushed?.stats.length, 1);

    final again = MetaStore(prefs);
    expect(again.record.stats['q1']?.correct, 1);
    expect(again.journal.title, 'はじめの一歩');
  });

  test('使う効果音のファイルがすべてある', () {
    final keys = {
      for (final s in EnemySpeciesCatalog.all) s.sound,
      'se_tap', 'se_correct', 'se_wrong', 'se_attack', 'se_critical', //
      'se_damage', 'se_heal', 'se_chest', 'se_achievement', 'se_block',
      'se_boss_appear',
    };
    for (final k in keys) {
      expect(File('assets/audio/$k.mp3').existsSync(), isTrue, reason: k);
    }
    for (final j in ['victory', 'defeat', 'levelup']) {
      expect(File('assets/audio/jingle_$j.mp3').existsSync(), isTrue);
    }
  });
}
