import '../data/catalog.dart';
import 'junior_lessons.dart';

/// 宿で受けられる授業（次の敵の文法テーマの要点）。
class LessonPoint {
  const LessonPoint(this.heading, this.body, this.example);
  final String heading;
  final String body;
  final String example;
}

class InnLesson {
  const InnLesson({
    required this.stageId,
    required this.teacher,
    required this.title,
    required this.points,
  });

  /// 次に戦うステージ
  final String stageId;
  final String teacher;
  final String title;
  final List<LessonPoint> points;
}

class InnLessons {
  const InnLessons._();

  /// 手書きの授業があればそれ、なければ要点が空の授業（アプリ側で問題から作る）
  static InnLesson forStage(String stageId) =>
      all.where((l) => l.stageId == stageId).firstOrNull ??
      InnLesson(
        stageId: stageId,
        teacher: '${RpgCatalog.stage(stageId).name}の宿・先生',
        title: RpgCatalog.stage(stageId).grammarTheme,
        points: const [],
      );

  static const all = JuniorLessons.all;
}
