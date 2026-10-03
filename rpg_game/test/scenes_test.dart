import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  group('物語の場面', () {
    test('序章・5つの国（導入・ボス前・欠片）・終章の場面がある', () {
      final all = StoryScenes.all;
      expect(all.length, 1 + 5 * 3 + 2);
      expect({for (final s in all) s.id}.length, all.length,
          reason: 'ID は重ならない');
      for (final s in all) {
        expect(s.lines, isNotEmpty, reason: s.id);
        expect(s.title, isNotEmpty);
      }
      for (final w in Story.worlds) {
        expect(StoryScenes.chapterOf(w.worldId), inInclusiveRange(1, 5));
        expect(StoryScenes.intro(w.worldId).chapter,
            StoryScenes.chapterOf(w.worldId));
      }
    });

    test('{name} は主人公の名前に置きかわる', () {
      const line = StoryLine(StorySpeaker.hero, '{name}です');
      expect(line.textFor('つづり'), 'つづりです');
      expect(line.speakerName('つづり'), 'つづり');
      final keeper = StoryScenes.intro('english')
          .lines
          .firstWhere((l) => l.speaker == StorySpeaker.keeper);
      expect(keeper.speakerName('x'), '言葉の女王リリカ');
    });

    test('国に入ると、序章→導入の順に、まだ読んでいない場面だけが出る', () {
      var p = RpgProgress.initial;
      expect(StoryScenes.onEnterWorld(p, 'english').map((s) => s.id),
          ['prologue', 'english:intro']);
      for (final s in StoryScenes.onEnterWorld(p, 'english')) {
        p = StoryScenes.markSeen(p, s);
      }
      expect(StoryScenes.onEnterWorld(p, 'english'), isEmpty);
      expect(StoryScenes.onEnterWorld(p, 'science').map((s) => s.id),
          ['science:intro']);
      expect(StoryScenes.unlocked(p).length, 2);
      // 試験ワールドなどには場面がない
      expect(StoryScenes.onEnterWorld(p, 'exam_x'), isEmpty);
    });

    test('最後のボスの前に一度だけ場面が出て、欠片を取ると欠片の場面が出る', () {
      var p = RpgProgress.initial;
      final finals = Story.finalsOf('english');
      final finalStage = finals.first;
      expect(
          StoryScenes.beforeFinalBoss(p, 'english', 'english_j1_01'), isNull);
      final boss = StoryScenes.beforeFinalBoss(p, 'english', finalStage.id);
      expect(boss?.id, 'english:boss');
      p = StoryScenes.markSeen(p, boss!);
      expect(StoryScenes.beforeFinalBoss(p, 'english', finalStage.id), isNull);
      p = p.copyWith(clearedStageIds: {
        ...p.clearedStageIds,
        for (final s in finals) s.id,
      });
      expect(StoryScenes.onEnterWorld(p, 'english').map((s) => s.id),
          contains('english:clear'));
    });
  });
}
