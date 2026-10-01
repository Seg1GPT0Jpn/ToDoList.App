import 'learning_record.dart';
import 'proficiency.dart';

/// 保護者・先生に送る、学習のまとめ（文章）
abstract final class StudyReport {
  static const subjects = {
    'english': '英語',
    'science': '理科',
    'social': '社会',
    'japanese': '国語',
    'math': '数学',
    'information': '情報',
    'music': '音楽',
  };

  static String _pct(int c, int a) =>
      a == 0 ? '-' : '${(c * 100 / a).round()}%';

  static String text(LearningRecord r, int today, {String? name}) {
    final lines = <String>[
      '📘 つづりクエスト 学習レポート${name == null ? '' : '（$name）'}',
      '学習した日：${r.studyDays.length}日（連続 ${r.streakDays(today)}日）',
      'とりくんだ問題：${r.answeredCount()}問（回答 ${r.totalAnswers()}回・正答率 ${_pct(r.totalCorrect(), r.totalAnswers())}）',
      '習得した問題：${r.masteredCount()}問',
      '',
      '【教科別】',
    ];
    for (final MapEntry(key: id, value: label) in subjects.entries) {
      final stats = r.stats.values
          .where((s) => LearningRecord.subjectOf(s.setId) == id)
          .toList();
      if (stats.isEmpty) continue;
      final att = stats.fold(0, (a, s) => a + s.attempts);
      final cor = stats.fold(0, (a, s) => a + s.correct);
      lines.add(
        '・$label：${stats.length}問 正答率${_pct(cor, att)} 習得${r.masteredCount(id)}問',
      );
    }
    final weak = [
      for (final e in Proficiency.bySubject(r).entries)
        for (final s in e.value)
          if (s.rated) s,
    ]..sort((a, b) => a.score.compareTo(b.score));
    if (weak.isNotEmpty) {
      lines
        ..add('')
        ..add('【にがてな分野】');
      for (final s in weak.take(3)) {
        lines.add(
            '・${subjects[s.subject] ?? s.subject} ${s.field}（${s.score}点）');
      }
    }
    return lines.join('\n');
  }
}
