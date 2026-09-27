import '../data/catalog.dart';
import '../models/stage.dart';
import 'learning_record.dart';
import 'proficiency.dart';

/// 教科ごとの信号（赤：苦手、黄：もう少し、緑：得意）
enum Signal { red, yellow, green, none }

class SubjectSignal {
  const SubjectSignal({
    required this.subject,
    required this.field,
    required this.score,
    required this.signal,
  });

  final String subject;

  /// いちばん苦手な分野
  final String field;
  final int score;
  final Signal signal;
}

/// 今日のおすすめ（1つ）
class Recommendation {
  const Recommendation({required this.text, this.stage, this.review = false});

  final String text;

  /// 練習するエリア（あれば）
  final StageDef? stage;

  /// 復習の塔へ行くおすすめか
  final bool review;
}

/// 学習ナビゲーター：答えた記録から「今日のあなた」を分析して、
/// 何を勉強すればよいかを提案する（端末の中だけで計算する）。
class StudyNavigator {
  const StudyNavigator._();

  /// 教科ごとの信号（答えた教科だけ。苦手な順）
  static List<SubjectSignal> signals(LearningRecord record) {
    final out = <SubjectSignal>[];
    for (final e in Proficiency.bySubject(record).entries) {
      final rated = e.value.where((f) => f.rated).toList()
        ..sort((a, b) => a.score.compareTo(b.score));
      if (rated.isEmpty) continue;
      final worst = rated.first;
      out.add(
        SubjectSignal(
          subject: e.key,
          field: worst.field,
          score: worst.score,
          signal: worst.score < 60
              ? Signal.red
              : worst.score < 80
                  ? Signal.yellow
                  : Signal.green,
        ),
      );
    }
    out.sort((a, b) => a.score.compareTo(b.score));
    return out;
  }

  /// 気づいたこと（「最近、数学Aで3回まちがえています」など）
  static List<String> insights(LearningRecord record, {required int today}) {
    final out = <String>[];
    // 最近1週間のまちがい（単元ごと）
    final missBySet = <String, int>{};
    final goodBySet = <String, int>{};
    for (final s in record.stats.values) {
      if (today - s.lastDay > 7) continue;
      if (s.missStreak > 0) missBySet[s.setId] = (missBySet[s.setId] ?? 0) + 1;
      if (s.streak >= 2) goodBySet[s.setId] = (goodBySet[s.setId] ?? 0) + 1;
    }
    final misses = missBySet.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in misses.take(2)) {
      if (e.value < 2) break;
      final stage = Proficiency.stageOfSet(e.key);
      if (stage == null) continue;
      out.add(
        '最近、${RpgCatalog.world(stage.worldId).subject}の「${stage.grammarTheme}」で${e.value}問まちがえたままです。',
      );
    }
    final goods = goodBySet.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (goods.isNotEmpty && goods.first.value >= 3) {
      final stage = Proficiency.stageOfSet(goods.first.key);
      if (stage != null) {
        out.add(
          '${RpgCatalog.world(stage.worldId).subject}の「${stage.grammarTheme}」は、続けて正解できるようになってきました。',
        );
      }
    }
    final due = record.stats.values.where((s) => s.isDue(today)).length;
    if (due >= 20) {
      out.add('復習の日が来た問題が$due問あります。今日は復習を中心にするとよさそうです。');
    }
    if (record.stats.isEmpty) {
      out.add('まずは英語ワールドのエリア1から始めてみよう。答えるほど、あなたに合ったおすすめが出せます。');
    }
    return out;
  }

  /// 今日のおすすめ学習（3つまで）
  static List<Recommendation> today(LearningRecord record,
      {required int today}) {
    final out = <Recommendation>[];
    for (final (stage, score) in Proficiency.weakestUnits(record, limit: 2)) {
      if (score.score >= 85) break;
      out.add(
        Recommendation(
          text:
              '${RpgCatalog.world(stage.worldId).subject}・${stage.grammarTheme}を10問（正答率${score.score}%）',
          stage: stage,
        ),
      );
    }
    final missed = record.stats.values
        .where((s) => s.missStreak > 0 && today - s.lastDay <= 2)
        .length;
    if (missed > 0) {
      out.add(
        Recommendation(
          text: '昨日までにまちがえた問題を${missed.clamp(1, 5)}問復習する',
          review: true,
        ),
      );
    } else if (record.stats.values.any((s) => s.isDue(today))) {
      out.add(const Recommendation(text: '復習の日が来た問題を解く', review: true));
    }
    return out.take(3).toList();
  }
}
