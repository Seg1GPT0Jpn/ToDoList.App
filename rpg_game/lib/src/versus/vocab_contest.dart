import 'dart:math';

import '../models/rpg_progress.dart';
import '../vocab/meaning_text.dart';
import '../vocab/vocab_book.dart';

/// 週替わり単語バトル：LEAP・EEVI を開いている人みんなで、決まった日に同じ範囲・同じ問題で点数を競う。
///
/// 日程と範囲は、管理者（[ContestRules.adminEmail]）だけが変えられる設定（[ContestConfig]）で決まる。
/// 置くのは単語帳の名前・番号の範囲・日付と、1人ずつのニックネーム・正解数・点数だけ。単語の中身は置かない。
abstract final class ContestRules {
  /// 日程と範囲を変えられるアカウント（Firestore のルールにも同じものを書く）
  static const adminEmail = 'kzmsegawa@gmail.com';

  static bool isAdmin(String? email) =>
      email != null && email.trim().toLowerCase() == adminEmail;

  /// 1種類あたりの問題数の上限（4種類で 400 問。ルールの上限もこれで決まる）
  static const maxCount = 100;

  /// 1種類を始めてから結果を送るまでの時間の上限（ルールと同じ）
  static const partWindow = Duration(minutes: 30);

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

  /// UTC の時刻を、日本時間の「10/29（木）18:00」にする
  static String time(DateTime utc) {
    final j = utc.toUtc().add(const Duration(hours: 9));
    return '${label(j)}${j.hour}:${j.minute.toString().padLeft(2, '0')}';
  }

  static const _dayWords = {-2: '2日前', -1: '前日', 0: '当日', 1: '翌日', 2: '2日後'};

  /// バトルの日の 0 時からの分を「前日 18:00」にする
  static String offset(int minutes) {
    final day = (minutes / 1440).floor();
    final rest = minutes - day * 1440;
    final word = _dayWords[day] ?? '$day日';
    return '$word ${rest ~/ 60}:${(rest % 60).toString().padLeft(2, '0')}';
  }

  /// 「前日 18:00」「翌日 8:00」「-1 18:00」を、バトルの日の 0 時からの分に直す
  static int? parseOffset(String s) {
    final m =
        RegExp(r'^\s*(2日前|前日|当日|翌日|2日後|[-+]?\d+)\s*(\d{1,2})[:：](\d{2})\s*$')
            .firstMatch(s);
    if (m == null) return null;
    final w = m.group(1)!;
    final day = _dayWords.entries.where((e) => e.value == w).firstOrNull?.key ??
        int.parse(w);
    final h = int.parse(m.group(2)!), mi = int.parse(m.group(3)!);
    if (h > 23 || mi > 59 || day.abs() > 3) return null;
    return day * 1440 + h * 60 + mi;
  }

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
    this.count = 100,
    this.skips = const {},
    this.ranges = const {},
    this.extras = const {},
    this.enabled = true,
    this.openMin = -360,
    this.closeMin = 1440,
  });

  /// 単語帳の ID（'leap'・'eevi'。名前とパスワードで開いた単語帳の ID と同じ）
  final String bookId;
  final String title;

  /// 第1回の日付（日本の暦の日付を UTC の 0 時で持つ）
  final DateTime first;
  final int firstFrom;
  final int width;

  /// 1種類あたりの問題数（フラッシュカード・日→英・英→日・例文の4種類）
  final int count;
  final Set<String> skips;
  final Map<String, ContestRange> ranges;
  final Map<String, ContestRange> extras;
  final bool enabled;

  /// 受付の始まりと終わり（バトルの日の、日本時間 0 時からの分。前日 18:00 なら -360）
  final int openMin;
  final int closeMin;

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
        openMin: openMin,
        closeMin: closeMin,
      );

  /// いま受付中の回（なければ null）
  ContestRound? openAt(DateTime now) =>
      _near(now).where((r) => r.isOpen(now)).firstOrNull;

  /// 次に受付が始まる回（なければ null）
  ContestRound? nextAt(DateTime now) =>
      _near(now).where((r) => r.openAt.isAfter(now)).firstOrNull;

  /// 受付が終わった、いちばん新しい回（なければ null）
  ContestRound? lastClosed(DateTime now) {
    ContestRound? last;
    for (final r in rounds(first, 600)) {
      if (r.closeAt.isAfter(now)) break;
      last = r;
    }
    return last;
  }

  /// [now] のころの回（受付の時間は前後に数日ずれうるので、1週前から見る）
  List<ContestRound> _near(DateTime now) => rounds(
        ContestRules.jstToday(now).subtract(const Duration(days: 7)),
        6,
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
    int? openMin,
    int? closeMin,
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
        openMin: openMin ?? this.openMin,
        closeMin: closeMin ?? this.closeMin,
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
        'open': openMin,
        'close': closeMin,
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
    final count = (m['count'] as num?)?.toInt() ?? 100;
    final fallback = ContestConfig.initial.plans[bookId];
    var open = (m['open'] as num?)?.toInt() ?? fallback?.openMin ?? -360;
    var close = (m['close'] as num?)?.toInt() ?? fallback?.closeMin ?? 1440;
    if (close <= open) (open, close) = (-360, 1440);
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
      openMin: open,
      closeMin: close,
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
  /// EEVI は 10/30（金）の 301〜350 から毎週金曜（受付は木曜 18:00〜金曜 19:15）、
  /// LEAP は 11/1（日）の 1801〜1900 から毎週日曜（受付は土曜 18:00〜月曜 8:00）。
  /// 11/13（金）と 11/22（日）はお休み
  static final initial = ContestConfig({
    'eevi': ContestPlan(
      bookId: 'eevi',
      title: 'EEVI',
      first: DateTime.utc(2026, 10, 30),
      firstFrom: 301,
      width: 50,
      count: 50,
      skips: const {'2026-11-13'},
      openMin: -360,
      closeMin: 19 * 60 + 15,
    ),
    'leap': ContestPlan(
      bookId: 'leap',
      title: 'LEAP',
      first: DateTime.utc(2026, 11, 1),
      firstFrom: 1801,
      width: 100,
      count: 100,
      skips: const {'2026-11-22'},
      openMin: -360,
      closeMin: 32 * 60,
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

  /// いま受付中の回（LEAP・EEVI の順）
  List<ContestRound> openAt(DateTime now) => [
        for (final id in books)
          if (plans[id]?.openAt(now) case final r?) r,
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
    this.openMin = -360,
    this.closeMin = 1440,
  });

  final String bookId;
  final String title;
  final DateTime date;
  final ContestRange range;
  final int count;
  final int openMin;
  final int closeMin;

  /// その日の日本時間 0 時（UTC）
  DateTime get _midnight => date.subtract(const Duration(hours: 9));

  /// 受付の始まりと終わり（UTC）
  DateTime get openAt => _midnight.add(Duration(minutes: openMin));
  DateTime get closeAt => _midnight.add(Duration(minutes: closeMin));

  bool isOpen(DateTime now) => !now.isBefore(openAt) && now.isBefore(closeAt);
  bool isClosed(DateTime now) => !now.isBefore(closeAt);

  /// 「10/29（木）18:00〜10/30（金）19:15」
  String get window =>
      '${ContestRules.time(openAt)}〜${ContestRules.time(closeAt)}';

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

  /// 4種類の問題（[ContestPart] の順。自分の単語帳から作る。同じ単語帳ならみんな同じになる）
  List<List<ContestQuestion>> parts(VocabBook book) =>
      ContestQuestions.build(book, range, count, seed);
}

/// 問題の種類
enum ContestPart {
  flash('フラッシュカード', '英単語と意味が合っていれば〇、ちがえば×', Duration(seconds: 5)),
  jaEn('日→英', '意味に合う英単語を選ぶ', Duration(seconds: 8)),
  enJa('英→日', '英単語の意味を選ぶ', Duration(seconds: 8)),
  cloze('例文', '例文の空らんに入る語を選ぶ', Duration(seconds: 12));

  const ContestPart(this.label, this.how, this.limit);
  final String label;
  final String how;

  /// 1問の制限時間
  final Duration limit;
}

/// 1問
class ContestQuestion {
  const ContestQuestion({
    required this.part,
    required this.card,
    required this.prompt,
    required this.choices,
    required this.answer,
    this.sub = '',
  });

  final ContestPart part;
  final VocabCard card;

  /// 大きく出す文字（英単語・意味・空らんのある例文）
  final String prompt;

  /// 小さく出す文字（フラッシュカードの意味・例文の訳）
  final String sub;
  final List<String> choices;
  final int answer;
}

/// 点数：正解で100点、早いほど最大50点を足す。1問の満点は [perQuestion]
abstract final class ContestScoring {
  static const perQuestion = 150;

  static int points(bool correct, Duration took, Duration limit) {
    if (!correct) return 0;
    final ms = limit.inMilliseconds;
    final left = (ms - took.inMilliseconds).clamp(0, ms);
    return 100 + (50 * left / ms).round();
  }

  /// 得点（満点に対する割合を 0〜10000 で。100.00% が 10000）
  static int score(int points, int questions) => questions == 0
      ? 0
      : (points * 10000 / (questions * perQuestion)).round().clamp(0, 10000);

  /// 「87.35%」
  static String percent(int score) =>
      '${score ~/ 100}.${(score % 100).toString().padLeft(2, '0')}%';
}

/// 4種類の問題づくり
abstract final class ContestQuestions {
  static List<List<ContestQuestion>> build(
    VocabBook book,
    ContestRange range,
    int count,
    int seed,
  ) {
    final n = count.clamp(1, ContestRules.maxCount);
    final usable = [
      for (final c in book.cards)
        if (usableChoiceText(c.term) && usableChoiceText(c.shortMeaning)) c,
    ];
    final inRange = [
      for (final c in usable)
        if (c.number != null &&
            c.number! >= range.from &&
            c.number! <= range.to)
          c,
    ]..sort((a, b) => a.number!.compareTo(b.number!));
    final withExample = [
      for (final c in inRange)
        if (c.hasExample) c,
    ];
    return [
      for (final part in ContestPart.values)
        _part(
          part,
          part == ContestPart.cloze ? withExample : inRange,
          usable,
          n,
          Random(seed + part.index * 7919),
        ),
    ];
  }

  /// 範囲の単語を、[n] 問になるまで並べる（1周ごとに順番を変える）
  static List<VocabCard> _order(List<VocabCard> pool, int n, Random r) {
    final out = <VocabCard>[];
    while (pool.isNotEmpty && out.length < n) {
      out.addAll([...pool]..shuffle(r));
    }
    return out.take(n).toList();
  }

  static List<ContestQuestion> _part(
    ContestPart part,
    List<VocabCard> pool,
    List<VocabCard> all,
    int n,
    Random r,
  ) {
    if (pool.length < 2 || all.length < 4) return const [];
    final out = <ContestQuestion>[];
    for (final c in _order(pool, n, r)) {
      final q = switch (part) {
        ContestPart.flash => _flash(c, all, r),
        ContestPart.jaEn => _choose(
            part,
            c,
            all,
            r,
            prompt: c.shortMeaning,
            label: (e) => e.term,
          ),
        ContestPart.enJa => _choose(
            part,
            c,
            all,
            r,
            prompt: c.term,
            label: (e) => e.shortMeaning,
          ),
        ContestPart.cloze => _choose(
            part,
            c,
            all,
            r,
            prompt: VocabCard.clozeOf(c.example, c.term) ?? c.example,
            sub: c.exampleJa,
            answer: c.clozeAnswer,
            label: (e) => e.hasExample ? e.clozeAnswer : e.term,
          ),
      };
      if (q != null) out.add(q);
    }
    return out;
  }

  /// 半分は正しい意味、半分はほかの単語の意味を出す
  static ContestQuestion? _flash(VocabCard c, List<VocabCard> all, Random r) {
    final right = r.nextBool();
    var shown = c.shortMeaning;
    if (!right) {
      final others = [
        for (final e in all)
          if (e.shortMeaning != c.shortMeaning) e.shortMeaning,
      ];
      if (others.isEmpty) return null;
      shown = others[r.nextInt(others.length)];
    }
    return ContestQuestion(
      part: ContestPart.flash,
      card: c,
      prompt: c.term,
      sub: shown,
      choices: const ['〇 合っている', '× ちがう'],
      answer: right ? 0 : 1,
    );
  }

  static ContestQuestion? _choose(
    ContestPart part,
    VocabCard c,
    List<VocabCard> all,
    Random r, {
    required String prompt,
    required String Function(VocabCard) label,
    String? answer,
    String sub = '',
  }) {
    final right = answer ?? label(c);
    final wrong = <String>{};
    final others = [
      for (final e in all)
        if (!identical(e, c) && label(e) != right) e,
    ];
    var guard = 0;
    while (wrong.length < 3 && others.isNotEmpty && guard++ < 60) {
      wrong.add(label(others[r.nextInt(others.length)]));
    }
    if (wrong.length < 3) return null;
    final choices = [right, ...wrong]..shuffle(r);
    return ContestQuestion(
      part: part,
      card: c,
      prompt: prompt,
      sub: sub,
      choices: choices,
      answer: choices.indexOf(right),
    );
  }
}

/// 1人分の参加記録。
///
/// 4種類（[ContestPart]）は、分野ごとにでも、一気にでも、好きな順に1回ずつ挑戦できる。
/// 始めた種類は [starts] に時刻が入り、そこから [ContestRules.partWindow] のうちに結果を送ると
/// [scores] に得点が入る。始めたまま結果を送らなかった種類は、記録なし（0点）。
class ContestEntry {
  const ContestEntry({
    required this.uid,
    required this.name,
    required this.correct,
    required this.score,
    this.scores = const {},
    this.starts = const {},
    this.points = 0,
  });

  final String uid;
  final String name;

  /// 4種類の合計の正解数
  final int correct;

  /// 得点（満点に対する割合。0〜10000 で、100.00% が 10000。[ContestScoring.score]）
  final int score;

  /// 種類の番号 → その種類の得点（0〜10000。解き終わった種類だけ）
  final Map<int, int> scores;

  /// 種類の番号 → 始めた時刻
  final Map<int, DateTime> starts;

  /// 4種類の合計の点数（正解100点＋速さ。得点はこれを満点で割ったもの）
  final int points;

  /// 解き終わった種類の数
  int get section => scores.length;

  /// 4種類とも解き終わったか
  bool get done => scores.length >= ContestPart.values.length;

  /// その種類の得点（まだ解いていなければ null）
  int? partScore(int part) => scores[part];

  /// その種類を、もう始めたか（始めたら、もう一度は挑戦できない）
  bool started(int part) =>
      starts.containsKey(part) || scores.containsKey(part);

  /// 始めたのに結果を送っていない種類（記録なし）
  bool abandoned(int part, DateTime now) =>
      starts.containsKey(part) &&
      !scores.containsKey(part) &&
      !now.isBefore(starts[part]!.add(ContestRules.partWindow));

  /// その種類を始めた記録
  ContestEntry withStart(int part, DateTime at) => ContestEntry(
        uid: uid,
        name: name,
        correct: correct,
        score: score,
        scores: scores,
        starts: {...starts, part: at},
        points: points,
      );

  /// 1種類を解き終わったあとの記録
  ContestEntry next({
    required int part,
    required int partScore,
    required int partCorrect,
    required int partPoints,
    required int totalQuestions,
  }) {
    final p = points + partPoints;
    return ContestEntry(
      uid: uid,
      name: name,
      correct: correct + partCorrect,
      score: ContestScoring.score(p, totalQuestions),
      scores: {...scores, part: partScore},
      starts: starts,
      points: p,
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'correct': correct,
        'score': score,
        'points': points,
        'done': done,
        'section': section,
        // 分野ごとの順位表のため、種類ごとの得点を別の項目に置く（p0〜p3）
        for (final e in scores.entries) 'p${e.key}': e.value,
        for (final e in starts.entries) 's${e.key}': e.value,
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
      scores: {
        for (var i = 0; i < ContestPart.values.length; i++)
          if (m['p$i'] is num) i: (m['p$i'] as num).toInt(),
      },
      starts: {
        for (var i = 0; i < ContestPart.values.length; i++)
          if (m['s$i'] is DateTime) i: m['s$i'] as DateTime,
      },
      points: (m['points'] as num?)?.toInt() ?? 0,
    );
  }

  /// その種類の得点の高い順（[part] が null なら総合の得点の順）
  static List<ContestEntry> rankBy(Iterable<ContestEntry> all, int? part) {
    if (part == null) return rank(all);
    final out = [
      for (final e in all)
        if (e.partScore(part) != null) e,
    ];
    out.sort((a, b) => b.partScore(part)!.compareTo(a.partScore(part)!));
    return out;
  }

  /// 得点の高い順（同点は正解数の多い順）。1種類も解き終わっていない人は入れない
  static List<ContestEntry> rank(Iterable<ContestEntry> all) {
    final out = [
      for (final e in all)
        if (e.section > 0) e
    ];
    out.sort((a, b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : b.correct.compareTo(a.correct);
    });
    return out;
  }
}

/// 最終ランキングの入賞と報酬。
///
/// 入賞するのは、参加した人数が2〜4人なら1位、5〜9人なら上位2人、10人以上なら上位3人
/// （総合の得点。同じ得点なら同じ順位）。受け取った報酬は [RpgProgress.claimedRewards] に
/// 「contest:回のID:順位」で残し、2回は受け取れない。
abstract final class ContestPrizes {
  /// 入賞する人数
  static int winners(int players) => players >= 10
      ? 3
      : players >= 5
          ? 2
          : players >= 2
              ? 1
              : 0;

  /// 入賞した順位（1〜3。入賞していなければ null）。[above] は自分より得点の高い人数
  static int? place(int above, int players) {
    final rank = above + 1;
    return rank <= winners(players) ? rank : null;
  }

  static const _exp = [2000, 1200, 800];
  static const medals = ['🥇', '🥈', '🥉'];

  static int exp(int place) => _exp[place - 1];
  static String medal(int place) => medals[place - 1];

  static const _prefix = 'contest:';

  static String id(String roundId, int place) => '$_prefix$roundId:$place';

  /// その回の報酬を受け取った順位（まだなら null）
  static int? claimed(RpgProgress p, String roundId) {
    for (final c in p.claimedRewards) {
      if (c.startsWith('$_prefix$roundId:')) {
        return int.tryParse(c.substring(c.lastIndexOf(':') + 1));
      }
    }
    return null;
  }

  /// 報酬を受け取った進行状況（経験値は [Progression.addExp] で別に足す）
  static RpgProgress claim(RpgProgress p, String roundId, int place) =>
      p.copyWith(claimedRewards: {...p.claimedRewards, id(roundId, place)});

  /// 入賞した回数（[bookId] があればその単語帳だけ、[place] があればその順位だけ）
  static int count(RpgProgress p, {String? bookId, int? place}) => [
        for (final c in p.claimedRewards)
          if (c.startsWith(_prefix))
            if (bookId == null || c.startsWith('$_prefix$bookId-'))
              if (place == null || c.endsWith(':$place')) c,
      ].length;
}
