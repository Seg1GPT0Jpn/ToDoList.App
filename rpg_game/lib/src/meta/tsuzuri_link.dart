import '../curriculum/curriculum.dart';
import '../curriculum/curriculum_progress.dart';
import '../learning/learning_record.dart';
import 'study_log.dart';

/// つづり（学校生活アプリ）から届いた、これからのテスト・提出物の1件
class TsuzuriUpcoming {
  const TsuzuriUpcoming({
    required this.date,
    required this.title,
    required this.kindLabel,
    required this.isTest,
    this.subject,
    this.detail,
    this.period,
  });

  final DateTime date;

  /// 例：ECⅠ LEAP単語テスト
  final String title;

  /// 例：小テスト・定期テスト・提出物
  final String kindLabel;
  final bool isTest;

  /// つづりの科目名（例：ECⅠ・数学Ⅰ・化学基礎）
  final String? subject;

  /// 範囲など（例：1201〜1300、p.20〜35）
  final String? detail;

  /// 時限
  final int? period;

  /// 練習に使うクエストの教科（わからなければ null）
  String? get worldId => TsuzuriLink.worldFor(subject ?? title);

  /// 今日から何日後か
  int daysFrom(DateTime today) => DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;

  Map<String, dynamic> toMap() => {
        'date': StudyLog.dayKey(date),
        'title': title,
        'kind': kindLabel,
        'isTest': isTest,
        if (subject != null) 'subject': subject,
        if (detail != null) 'detail': detail,
        if (period != null) 'period': period,
      };

  /// 読めないものは null
  static TsuzuriUpcoming? fromMap(Map<String, dynamic> m) {
    final date = DateTime.tryParse('${m['date']}');
    final title = m['title'];
    if (date == null || title is! String || title.isEmpty) return null;
    return TsuzuriUpcoming(
      date: DateTime(date.year, date.month, date.day),
      title: title,
      kindLabel: m['kind'] as String? ?? '',
      isTest: m['isTest'] as bool? ?? true,
      subject: m['subject'] as String?,
      detail: m['detail'] as String?,
      period: (m['period'] as num?)?.toInt(),
    );
  }
}

/// つづりの時間割の1コマ
class TsuzuriLesson {
  const TsuzuriLesson({required this.period, required this.subject});
  final int period;

  /// つづりの科目名（例：ECⅠ）
  final String subject;

  String? get worldId => TsuzuriLink.worldFor(subject);

  Map<String, dynamic> toMap() => {'period': period, 'subject': subject};
}

/// つづりの目標（勉強時間・数値の目標）
class TsuzuriGoal {
  const TsuzuriGoal({
    required this.title,
    required this.studyTime,
    required this.current,
    required this.target,
    this.unit = '',
    this.subject,
    this.due,
  });

  final String title;

  /// 勉強時間の目標（単位は時間）
  final bool studyTime;
  final double current;
  final double target;
  final String unit;
  final String? subject;
  final DateTime? due;

  /// 進み具合（0〜1）
  double get ratio =>
      target <= 0 ? 0 : (current / target).clamp(0, 1).toDouble();

  String get label {
    String n(double v) =>
        v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
    return studyTime
        ? '${n(current)}/${n(target)}時間'
        : '${n(current)}/${n(target)}$unit';
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': studyTime ? 'studyTime' : 'number',
        'current': current,
        'target': target,
        'unit': unit,
        if (subject != null) 'subject': subject,
        if (due != null) 'dueDate': StudyLog.dayKey(due!),
      };
}

/// つづりとの連携で、やりとりするデータの形（Firestore はつづりの方を使う）。
///
/// - つづり → クエスト：`users/{uid}/quest_link/upcoming`（これからのテストと、1週間の時間割）、
///   `users/{uid}/goals`（目標。つづりがもともと保存している場所を読む）
/// - クエスト → つづり：`users/{uid}/study_sessions/quest_{日付}_{教科}`（勉強時間）と
///   `users/{uid}/quest_link/results`（教科ごとの時間・問題数・正答率、テストごとの対策時間、苦手な単元）
///
/// 送るのは教科名・時間・問題数・単元名だけ（問題の文章や単語帳の中身は送らない）。
class TsuzuriLink {
  const TsuzuriLink._();

  /// つづりの Web 版
  static const tsuzuriUrl = 'https://school-planner-30628.web.app';

  /// つづりクエストの Web 版
  static const questUrl = 'https://tsuzuri-quest-v2.web.app';

  /// つづりの勉強記録に書く「メモ」（クエストから来た記録の目印）
  static const sessionMemo = 'つづりクエスト';

  /// 送る勉強時間の日数（さかのぼって直せる範囲）
  static const syncDays = 14;

  /// クエストの教科 → つづりの勉強記録の科目名
  static const subjectLabels = {
    'english': '英語',
    'sea': '英語',
    'math': '数学',
    'japanese': '国語',
    'science': '理科',
    'social': '社会',
    'information': '情報',
    'music': '音楽',
  };

  static String subjectLabel(String worldId) => subjectLabels[worldId] ?? 'その他';

  /// つづりの科目名から、クエストの教科を推し量る
  static String? worldFor(String name) {
    const rules = <(String, List<String>)>[
      ('information', ['情報']),
      ('music', ['音楽']),
      ('math', ['数学', '数Ⅰ', '数Ⅱ', '数A', '数B', '数C', '数Ⅲ']),
      (
        'english',
        ['英語', 'EC', 'ＥＣ', '論表', '論理・表現', 'コミュ', 'LEAP', '英単語', '英文法']
      ),
      (
        'japanese',
        ['国語', '現代の国語', '現国', '言語文化', '古典', '古文', '漢文', '文学', '論理国語', '漢字']
      ),
      ('science', ['理科', '化学', '生物', '物理', '地学', '科学と人間生活']),
      ('social', ['社会', '地理', '歴史', '日本史', '世界史', '公共', '政治', '経済', '倫理']),
    ];
    for (final (world, words) in rules) {
      if (words.any(name.contains)) return world;
    }
    return null;
  }

  /// つづりの勉強記録に書く文書（文書 ID → 中身）。
  /// 1日・1教科で1件にまとめ、同じ ID に上書きするので何度送っても重ならない。
  /// 中身の `date` は Timestamp に直して保存する（その日の 0:00）。
  static Map<String, Map<String, Object?>> sessions(
    StudyLog log, {
    required DateTime now,
  }) {
    final out = <String, Map<String, Object?>>{};
    for (var i = 0; i < syncDays; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final bySubject = <String, int>{};
      for (final e in log.on(day).entries) {
        final label = subjectLabel(e.key);
        bySubject[label] = (bySubject[label] ?? 0) + e.value.seconds;
      }
      for (final e in bySubject.entries) {
        final minutes = e.value ~/ 60;
        if (minutes < 1) continue;
        out[sessionId(day, e.key)] = {
          'subject': e.key,
          'date': day,
          'minutes': minutes,
          'memo': sessionMemo,
        };
      }
    }
    return out;
  }

  /// 勉強記録の文書 ID（例：quest_2026-10-18_英語）
  static String sessionId(DateTime day, String label) =>
      'quest_${StudyLog.dayKey(day)}_$label';

  /// 送った勉強記録のうち、もう時間がなくなった（消すべき）文書 ID
  static List<String> staleSessions(
    Iterable<String> sentIds,
    Map<String, Map<String, Object?>> current,
  ) =>
      [
        for (final id in sentIds)
          if (!current.containsKey(id)) id,
      ];

  /// つづりのホームに出す「クエストの成果」
  static Map<String, dynamic> results(
    StudyLog log,
    LearningRecord record, {
    required DateTime now,
    Map<String, int> prepMinutes = const {},
  }) {
    final weekFrom = now.subtract(const Duration(days: 6));
    final today = log.total(from: now, to: now);
    final week = log.total(from: weekFrom, to: now);
    final weak = CurriculumProgress.of(record).weakest(limit: 5);
    // 教科ごと（英語と英文法のように、つづりで同じ科目名になるものはまとめる）
    Map<String, StudyDay> bySubject(Iterable<DateTime> days) {
      final out = <String, StudyDay>{};
      for (final d in days) {
        for (final e in log.on(d).entries) {
          final label = subjectLabel(e.key);
          out[label] = (out[label] ?? const StudyDay()).plus(e.value);
        }
      }
      return out;
    }

    final last7 = [
      for (var i = 0; i < 7; i++) DateTime(now.year, now.month, now.day - i),
    ];
    return {
      'v': 2,
      'today': _sum(today),
      'week': _sum(week),
      'days': {
        for (final d in last7)
          StudyLog.dayKey(d): {
            for (final e in bySubject([d]).entries) e.key: _sum(e.value),
          },
      },
      'subjects': {
        for (final e in bySubject(last7).entries) e.key: _sum(e.value),
      },
      'tests': {
        for (final e in prepMinutes.entries)
          if (e.value > 0) e.key: e.value,
      },
      'weak': [
        for (final p in weak)
          {
            'unit': Curriculum.breadcrumb(p.node.id),
            'accuracy': p.accuracy!,
          },
      ],
    };
  }

  /// テストを見分けるキー（つづりの「クエストで対策した時間」に使う。例：2026-10-19|ECⅠ LEAP単語テスト）
  static String testKey(TsuzuriUpcoming t) =>
      '${StudyLog.dayKey(t.date)}|${t.title}';

  /// 範囲の「1201〜1300」から番号の範囲を読む（なければ null）
  static (int, int)? numberRange(String? detail) {
    if (detail == null) return null;
    final m = RegExp(r'(\d+)\s*[〜~～\-－ー]\s*(\d+)').firstMatch(detail);
    if (m == null) return null;
    final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
    return a <= b ? (a, b) : (b, a);
  }

  /// つづりの時間割：日付 → その日の授業（時限の順）
  static Map<String, List<TsuzuriLesson>> parseLessons(
    Map<String, dynamic>? doc,
  ) {
    final out = <String, List<TsuzuriLesson>>{};
    for (final e in ((doc?['lessons'] as Map?) ?? const {}).entries) {
      final list = <TsuzuriLesson>[
        for (final raw in (e.value as List?) ?? const [])
          if (raw is Map && raw['subject'] is String)
            TsuzuriLesson(
              period: (raw['period'] as num?)?.toInt() ?? 0,
              subject: raw['subject'] as String,
            ),
      ]..sort((a, b) => a.period.compareTo(b.period));
      if (list.isNotEmpty) out['${e.key}'] = list;
    }
    return out;
  }

  /// つづりの目標（達成していないもの。勉強時間の目標を先に）
  static List<TsuzuriGoal> parseGoals(Iterable<Map<String, dynamic>> docs) {
    final out = <TsuzuriGoal>[
      for (final m in docs)
        if (m['achieved'] != true &&
            m['title'] is String &&
            (m['title'] as String).isNotEmpty &&
            (m['type'] == 'studyTime' || m['type'] == 'number'))
          TsuzuriGoal(
            title: m['title'] as String,
            studyTime: m['type'] == 'studyTime',
            current: (m['current'] as num?)?.toDouble() ?? 0,
            target: (m['target'] as num?)?.toDouble() ?? 0,
            unit: m['unit'] as String? ?? '',
            subject: m['subject'] as String?,
            due: DateTime.tryParse('${m['dueDate']}'),
          ),
    ];
    out.sort((a, b) {
      if (a.studyTime != b.studyTime) return a.studyTime ? -1 : 1;
      final da = a.due, db = b.due;
      if (da == null || db == null) return da == null ? 1 : -1;
      return da.compareTo(db);
    });
    return out;
  }

  static Map<String, int> _sum(StudyDay d) =>
      {'minutes': d.minutes, 'answered': d.answered, 'correct': d.correct};

  /// つづりの upcoming 文書を読む（日付順、今日より前は除く）
  static List<TsuzuriUpcoming> parseUpcoming(
    Map<String, dynamic>? doc, {
    required DateTime today,
  }) {
    final items = <TsuzuriUpcoming>[
      for (final raw in (doc?['items'] as List?) ?? const [])
        if (raw is Map)
          if (TsuzuriUpcoming.fromMap(Map<String, dynamic>.from(raw))
              case final item?)
            if (item.daysFrom(today) >= 0) item,
    ];
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }
}
