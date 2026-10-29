import 'dart:math';

import '../vocab/vocab_book.dart';
import 'word_duel.dart';

/// 週替わり単語バトル：LEAP・EEVI を開いている人みんなで、決まった日に同じ範囲・同じ問題で点数を競う。
///
/// 日程と範囲は、管理者（[ContestRules.adminEmail]）だけが変えられる設定（[ContestConfig]）で決まる。
/// 置くのは単語帳の名前・番号の範囲・日付と、1人ずつのニックネーム・正解数・点数だけ。単語の中身は置かない。
abstract final class ContestRules {
  /// 日程と範囲を変えられるアカウント（Firestore のルールにも同じものを書く）
  static const adminEmail = 'kzmsegawa@gmail.com';

  static bool isAdmin(String? email) =>
      email != null && email.trim().toLowerCase() == adminEmail;

  /// 1回の問題数の上限（ルールの点数の上限もこれで決まる）
  static const maxCount = 50;

  /// 開始してから結果を送るまでの時間の上限（ルールと同じ）
  static const playWindow = Duration(minutes: 8);

  /// 日本時間（バトルの日付は日本の暦で数える）
  static DateTime jstToday(DateTime now) {
    final j = now.toUtc().add(const Duration(hours: 9));
    return DateTime.utc(j.year, j.month, j.day);
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDay(String s) {
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s.trim());
    if (m == null) return null;
    final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final out = DateTime.utc(y, mo, d);
    return out.month == mo ? out : null;
  }

  static const weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  /// 「11/1（日）」
  static String label(DateTime d) =>
      '${d.month}/${d.day}（${weekdays[d.weekday - 1]}）';
}

/// 番号の範囲
class ContestRange {
  const ContestRange(this.from, this.to);
  final int from;
  final int to;

  int get width => to - from + 1;

  @override
  String toString() => '$from〜$to';

  Map<String, Object?> toMap() => {'from': from, 'to': to};

  static ContestRange? fromMap(Object? m) {
    if (m is! Map) return null;
    final f = m['from'], t = m['to'];
    if (f is! num || t is! num || f.toInt() < 1 || t.toInt() < f.toInt()) {
      return null;
    }
    return ContestRange(f.toInt(), t.toInt());
  }

  /// 「301-350」「301〜350」を読む
  static ContestRange? parse(String s) {
    final m = RegExp(r'^\s*(\d+)\s*[-〜~～ー－]\s*(\d+)\s*$').firstMatch(s);
    if (m == null) return null;
    final f = int.parse(m.group(1)!), t = int.parse(m.group(2)!);
    return f >= 1 && t >= f ? ContestRange(f, t) : null;
  }
}

/// 1冊分の日程の決め方。
///
/// [first] から毎週同じ曜日に行い、1回ごとに範囲を [width] ずつ先へ進める
/// （[first] の回が [firstFrom]〜）。[skips] の日はとばし、範囲も進めない。
/// [ranges] の日は、範囲をその日だけ書きかえる（ほかの回の範囲は変わらない）。
/// [extras] の日は、いつもの曜日でなくても、その範囲で行う（範囲は進めない）。
class ContestPlan {
  const ContestPlan({
    required this.bookId,
    required this.title,
    required this.first,
    required this.firstFrom,
    required this.width,
    this.count = 20,
    this.skips = const {},
    this.ranges = const {},
    this.extras = const {},
    this.enabled = true,
  });

  /// 単語帳の ID（'leap'・'eevi'。名前とパスワードで開いた単語帳の ID と同じ）
  final String bookId;
  final String title;

  /// 第1回の日付（日本の暦の日付を UTC の 0 時で持つ）
  final DateTime first;
  final int firstFrom;
  final int width;

  /// 1回の問題数
  final int count;
  final Set<String> skips;
  final Map<String, ContestRange> ranges;
  final Map<String, ContestRange> extras;
  final bool enabled;

  int get weekday => first.weekday;

  /// 数える週の上限（およそ40年）
  static const _maxWeeks = 2000;

  /// [from] の日から、日付の早い順に [n] 回分（[from] の日もふくむ）
  List<ContestRound> rounds(DateTime from, int n) {
    final start = DateTime.utc(from.year, from.month, from.day);
    if (!enabled || n <= 0) return const [];
    final out = <ContestRound>[];
    // いつもの週の回。とばした回は範囲を進めないので、第1回から数える（数百週ぶんなので軽い）
    var k = 0;
    for (var week = 0; week < _maxWeeks && out.length < n; week++) {
      final d = first.add(Duration(days: 7 * week));
      final key = ContestRules.dayKey(d);
      if (skips.contains(key)) continue;
      final base = ContestRange(
        firstFrom + k * width,
        firstFrom + (k + 1) * width - 1,
      );
      k++;
      if (!d.isBefore(start)) out.add(_round(d, ranges[key] ?? base));
    }
    for (final e in extras.entries) {
      final day = ContestRules.parseDay(e.key);
      if (day == null || day.isBefore(start)) continue;
      if (skips.contains(e.key)) continue;
      out.removeWhere((r) => ContestRules.dayKey(r.date) == e.key);
      out.add(_round(day, e.value));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out.take(n).toList();
  }

  ContestRound _round(DateTime d, ContestRange r) => ContestRound(
        bookId: bookId,
        title: title,
        date: d,
        range: r,
        count: count,
      );

  /// その日の回（なければ null）
  ContestRound? on(DateTime day) {
    final r = rounds(day, 1);
    if (r.isEmpty) return null;
    return ContestRules.dayKey(r.first.date) == ContestRules.dayKey(day)
        ? r.first
        : null;
  }

  /// その日より前の、いちばん新しい回（なければ null）
  ContestRound? before(DateTime day) {
    ContestRound? last;
    for (final r in rounds(first.isBefore(day) ? first : day, 600)) {
      if (!r.date.isBefore(day)) break;
      last = r;
    }
    return last;
  }

  ContestPlan copyWith({
    DateTime? first,
    int? firstFrom,
    int? width,
    int? count,
    Set<String>? skips,
    Map<String, ContestRange>? ranges,
    Map<String, ContestRange>? extras,
    bool? enabled,
  }) =>
      ContestPlan(
        bookId: bookId,
        title: title,
        first: first ?? this.first,
        firstFrom: firstFrom ?? this.firstFrom,
        width: width ?? this.width,
        count: count ?? this.count,
        skips: skips ?? this.skips,
        ranges: ranges ?? this.ranges,
        extras: extras ?? this.extras,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'first': ContestRules.dayKey(first),
        'firstFrom': firstFrom,
        'width': width,
        'count': count,
        'skips': skips.toList()..sort(),
        'ranges': {for (final e in ranges.entries) e.key: e.value.toMap()},
        'extras': {for (final e in extras.entries) e.key: e.value.toMap()},
        'enabled': enabled,
      };

  static ContestPlan? fromMap(String bookId, Object? m) {
    if (m is! Map) return null;
    final first = ContestRules.parseDay('${m['first'] ?? ''}');
    final from = m['firstFrom'], width = m['width'];
    if (first == null || from is! num || width is! num || width.toInt() < 1) {
      return null;
    }
    Map<String, ContestRange> rangesOf(Object? raw) => {
          if (raw is Map)
            for (final e in raw.entries)
              if (ContestRules.parseDay('${e.key}') != null &&
                  ContestRange.fromMap(e.value) != null)
                '${e.key}': ContestRange.fromMap(e.value)!,
        };
    final count = (m['count'] as num?)?.toInt() ?? 20;
    return ContestPlan(
      bookId: bookId,
      title: m['title'] is String ? m['title'] as String : bookId.toUpperCase(),
      first: first,
      firstFrom: from.toInt(),
      width: width.toInt(),
      count: count.clamp(1, ContestRules.maxCount),
      skips: {
        if (m['skips'] is List)
          for (final s in m['skips'] as List)
            if (ContestRules.parseDay('$s') != null) '$s',
      },
      ranges: rangesOf(m['ranges']),
      extras: rangesOf(m['extras']),
      enabled: m['enabled'] as bool? ?? true,
    );
  }
}

/// 日程の設定（LEAP と EEVI）
class ContestConfig {
  const ContestConfig(this.plans);

  /// 単語帳の ID → 日程
  final Map<String, ContestPlan> plans;

  static const books = ['leap', 'eevi'];

  /// 設定がまだサーバーにないときの日程。
  /// EEVI は 10/30（金）の 301〜350 から毎週金曜、LEAP は 11/1（日）の 1801〜1900 から毎週日曜。
  /// 11/13（金）と 11/22（日）はお休み
  static final initial = ContestConfig({
    'eevi': ContestPlan(
      bookId: 'eevi',
      title: 'EEVI',
      first: DateTime.utc(2026, 10, 30),
      firstFrom: 301,
      width: 50,
      skips: const {'2026-11-13'},
    ),
    'leap': ContestPlan(
      bookId: 'leap',
      title: 'LEAP',
      first: DateTime.utc(2026, 11, 1),
      firstFrom: 1801,
      width: 100,
      skips: const {'2026-11-22'},
    ),
  });

  Map<String, Object?> toMap() => {
        for (final e in plans.entries) e.key: e.value.toMap(),
      };

  /// 読めない冊は、はじめの設定のまま
  static ContestConfig fromMap(Object? m) {
    if (m is! Map) return initial;
    return ContestConfig({
      for (final id in books)
        id: ContestPlan.fromMap(id, m[id]) ?? initial.plans[id]!,
    });
  }

  /// その日の回（LEAP・EEVI の順）
  List<ContestRound> on(DateTime day) => [
        for (final id in books)
          if (plans[id]?.on(day) case final r?) r,
      ];

  /// これからの回（日付の早い順）
  List<ContestRound> upcoming(DateTime from, int n) {
    final all = [
      for (final id in books) ...?plans[id]?.rounds(from, n),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return all.take(n).toList();
  }
}

/// 1回分のバトル
class ContestRound {
  const ContestRound({
    required this.bookId,
    required this.title,
    required this.date,
    required this.range,
    required this.count,
  });

  final String bookId;
  final String title;
  final DateTime date;
  final ContestRange range;
  final int count;

  /// サーバーで使う ID（「leap-2026-11-01」）
  String get id => '$bookId-${ContestRules.dayKey(date)}';

  /// 問題と選択肢を決める種（みんな同じ問題・同じ並びになる）
  int get seed {
    var h = 0x811c9dc5;
    for (final c in id.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  String get heading => '$title ${range.from}〜${range.to}';

  bool isToday(DateTime now) =>
      ContestRules.dayKey(ContestRules.jstToday(now)) ==
      ContestRules.dayKey(date);

  /// 出題する番号（自分の単語帳から、範囲の中の [count] 語。みんな同じになる）
  List<int> numbers(VocabBook book) => DuelRules.pick(
        book,
        Random(seed),
        from: range.from,
        to: range.to,
        count: count.clamp(1, ContestRules.maxCount),
      );

  List<DuelQuestion> questions(VocabBook book) =>
      DuelRules.build(book, numbers(book), seed);
}

/// 1人分の参加記録
class ContestEntry {
  const ContestEntry({
    required this.uid,
    required this.name,
    required this.correct,
    required this.score,
    required this.done,
  });

  final String uid;
  final String name;
  final int correct;
  final int score;

  /// 最後まで解いて結果を送ったか（始めただけなら false）
  final bool done;

  Map<String, Object?> toMap() => {
        'name': name,
        'correct': correct,
        'score': score,
        'done': done,
      };

  static ContestEntry? fromMap(String uid, Object? m) {
    if (m is! Map) return null;
    final name = m['name'], correct = m['correct'], score = m['score'];
    if (name is! String || correct is! num || score is! num) return null;
    return ContestEntry(
      uid: uid,
      name: name,
      correct: correct.toInt(),
      score: score.toInt(),
      done: m['done'] == true,
    );
  }

  /// 点数の高い順（同点は正解数の多い順）。始めただけの人は入れない
  static List<ContestEntry> rank(Iterable<ContestEntry> all) {
    final out = [
      for (final e in all)
        if (e.done) e
    ];
    out.sort((a, b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : b.correct.compareTo(a.correct);
    });
    return out;
  }
}
