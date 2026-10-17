import 'dart:math';

import '../vocab/fsrs.dart';
import '../vocab/vocab_book.dart';
import '../vocab/vocab_progress.dart';

/// クラスルーム：6ケタのコードで集まった友だちと、単語の小テスト・定期テストの
/// 「範囲と日付」を共有して、いっしょに準備する。
///
/// 共有するのは「単語帳の名前・番号の範囲・日付」だけ。単語の中身は共有しない
/// （市販の単語帳の内容を配らないため）。メンバーは自分の端末にある同じ単語帳から出題する。

/// 範囲の種類
enum ClassTaskKind {
  /// 単語の小テスト（だいたい毎週）。1週間前から準備
  quiz('小テスト', 7),

  /// 定期テスト。2週間前から準備
  exam('定期テスト', 14);

  const ClassTaskKind(this.label, this.prepDays);
  final String label;

  /// 準備をはじめる日数（試験日の何日前から）
  final int prepDays;

  static ClassTaskKind parse(Object? v) =>
      v == 'exam' ? ClassTaskKind.exam : ClassTaskKind.quiz;
}

/// クラスで共有する範囲（1つの小テスト・定期テスト）
class ClassTask {
  const ClassTask({
    required this.id,
    required this.kind,
    required this.title,
    required this.bookKey,
    required this.bookTitle,
    required this.from,
    required this.to,
    required this.date,
  });

  final String id;
  final ClassTaskKind kind;

  /// 名前（例：「第7回 単語テスト」）
  final String title;

  /// どの単語帳か（[ClassBooks.keyOf]）と、表示用の名前
  final String bookKey;
  final String bookTitle;

  /// 単語帳の番号の範囲（両端を含む）
  final int from;
  final int to;

  /// 試験日（日付だけ。時刻は 0:00）
  final DateTime date;

  int get size => to - from + 1;

  /// 準備をはじめる日
  DateTime get prepStart =>
      DateTime(date.year, date.month, date.day - kind.prepDays);

  /// 今日から試験日までの日数（当日は 0。過ぎていれば負）
  int daysLeft(DateTime now) => DateTime(date.year, date.month, date.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;

  /// 準備期間に入っているか（試験日の当日まで）
  bool active(DateTime now) {
    final d = daysLeft(now);
    return d >= 0 && d <= kind.prepDays;
  }

  /// 試験日が過ぎたか
  bool over(DateTime now) => daysLeft(now) < 0;

  /// この範囲の単語（[book] の番号で選ぶ）
  List<VocabCard> cardsIn(VocabBook book) => [
        for (final c in book.cards)
          if (c.number != null && c.number! >= from && c.number! <= to) c,
      ];

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'bookKey': bookKey,
        'bookTitle': bookTitle,
        'from': from,
        'to': to,
        'date': ClassDates.key(date),
      };

  /// 壊れたデータは null（読み飛ばす）
  static ClassTask? fromMap(Object? m) {
    if (m is! Map) return null;
    final from = m['from'], to = m['to'];
    final date = ClassDates.parse(m['date']);
    final id = m['id'], key = m['bookKey'];
    if (id is! String || key is! String) return null;
    if (from is! num || to is! num || date == null) return null;
    if (from > to || from < 1) return null;
    return ClassTask(
      id: id,
      kind: ClassTaskKind.parse(m['kind']),
      title: (m['title'] as String?)?.trim() ?? '',
      bookKey: key,
      bookTitle: (m['bookTitle'] as String?) ?? key,
      from: from.toInt(),
      to: to.toInt(),
      date: date,
    );
  }
}

/// クラスルーム
class Classroom {
  const Classroom({
    required this.code,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.members,
    required this.tasks,
    this.expiresAt,
    this.closed = false,
  });

  /// 6ケタのコード（ドキュメントの ID でもある）
  final String code;
  final String name;
  final String ownerId;
  final String ownerName;

  /// メンバー（ユーザーID → ニックネーム）。作った人も入る
  final Map<String, String> members;
  final List<ClassTask> tasks;

  /// コードの有効期限（これを過ぎると新しく入れない）
  final DateTime? expiresAt;
  final bool closed;

  /// 1つのクラスに入れる人数
  static const maxMembers = 40;

  /// 1つのクラスに置ける範囲の数
  static const maxTasks = 30;

  /// コードの有効期間
  static const lifetime = Duration(days: 180);

  bool isOwner(String? uid) => uid != null && uid == ownerId;
  bool isMember(String? uid) => uid != null && members.containsKey(uid);
  bool get full => members.length >= maxMembers;
  bool expired(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!);

  /// 今準備中の範囲（試験日が近い順）と、これからの範囲
  List<ClassTask> upcoming(DateTime now) {
    final list = [
      for (final t in tasks)
        if (!t.over(now)) t,
    ]..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  ClassTask? task(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Map<String, Object?> toMap() => {
        'code': code,
        'name': name,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'members': members,
        'tasks': [for (final t in tasks) t.toMap()],
        'closed': closed,
      };

  factory Classroom.fromMap(String code, Map<String, Object?> m,
          {DateTime? expiresAt}) =>
      Classroom(
        code: code,
        name: (m['name'] as String?) ?? 'クラス',
        ownerId: (m['ownerId'] as String?) ?? '',
        ownerName: (m['ownerName'] as String?) ?? '',
        members: {
          if (m['members'] is Map)
            for (final e in (m['members'] as Map).entries)
              if (e.key is String) e.key as String: '${e.value}',
        },
        tasks: [
          if (m['tasks'] is List)
            for (final t in m['tasks'] as List)
              if (ClassTask.fromMap(t) case final task?) task,
        ],
        expiresAt: expiresAt,
        closed: m['closed'] == true,
      );

  Classroom copyWith({
    String? name,
    Map<String, String>? members,
    List<ClassTask>? tasks,
    bool? closed,
    DateTime? expiresAt,
  }) =>
      Classroom(
        code: code,
        name: name ?? this.name,
        ownerId: ownerId,
        ownerName: ownerName,
        members: members ?? this.members,
        tasks: tasks ?? this.tasks,
        expiresAt: expiresAt ?? this.expiresAt,
        closed: closed ?? this.closed,
      );

  /// 6ケタのコード（100000〜999999）
  static String newCode([Random? random]) =>
      (100000 + (random ?? Random.secure()).nextInt(900000)).toString();

  static bool validCode(String s) => RegExp(r'^[1-9]\d{5}$').hasMatch(s.trim());

  /// 名前・ニックネームの長さの上限
  static const maxName = 20;

  /// 名前を整える（前後の空白を取り、長すぎるものは切る。空なら [fallback]）
  static String cleanName(String s, {String fallback = 'クラス'}) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return fallback;
    return t.length > maxName ? t.substring(0, maxName) : t;
  }
}

/// 日付の文字列（YYYY-MM-DD）
class ClassDates {
  const ClassDates._();

  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parse(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
    if (m == null) return null;
    final d = DateTime(
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
    );
    // 2月30日のような存在しない日は除く
    if (key(d) != v) return null;
    return d;
  }
}

/// 単語帳の照合：クラスの範囲を、自分の端末の単語帳と結びつける
class ClassBooks {
  const ClassBooks._();

  /// 単語帳の名前から作る、みんなで同じになる鍵（空白・大文字小文字を無視）
  static String keyOf(VocabBook book) => normalize(book.title);

  static String normalize(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[\s　・_\-]+'), '')
      .replaceAll('（', '(')
      .replaceAll('）', ')');

  /// 範囲に合う、自分の単語帳（番号つきの単語がある単語帳だけ）
  static VocabBook? match(ClassTask task, Iterable<VocabBook> books) {
    for (final b in books) {
      if (keyOf(b) == task.bookKey && b.cards.any((c) => c.number != null)) {
        return b;
      }
    }
    return null;
  }
}

/// 範囲の準備の進みぐあいと、今日の分
class ClassPlanner {
  const ClassPlanner._();

  /// 「覚えた」とみなす：その単語を1回以上学習し、いま忘れかけていない
  static bool learned(CardProgress? p, DateTime now) {
    if (p == null) return false;
    final s = p.status(now);
    return s == CardStatus.stable || s == CardStatus.shaky;
  }

  /// 範囲のうち、覚えた単語の数
  static int learnedCount(
    List<VocabCard> cards,
    BookProgress progress,
    DateTime now,
  ) =>
      cards.where((c) => learned(progress.cards[c.id], now)).length;

  /// 今日の分の問題（試験日から逆算）。
  ///
  /// - 前日・当日：範囲の単語を、苦手なものから全部（最終チェック）
  /// - それ以外：まだ学習していない単語を残りの日数で割った数＋範囲の復習
  static List<VocabTask> today(
    ClassTask task,
    List<VocabCard> cards,
    BookProgress progress,
    DateTime now, {
    int reviewLimit = 40,
  }) {
    if (cards.isEmpty) return const [];
    final days = max(0, task.daysLeft(now));
    if (days <= 1) return finalCheck(cards, progress, now);
    final unseen = [
      for (final c in cards)
        if (!progress.cards.containsKey(c.id)) c,
    ];
    // 前日は最終チェックにするので、その前日までに覚え終える
    final studyDays = max(1, days - 1);
    final introducedToday = [
      for (final c in cards)
        if (_introducedOn(progress.cards[c.id], now)) c,
    ].length;
    final quota = max(
      0,
      ((unseen.length + introducedToday) / studyDays).ceil() - introducedToday,
    );
    final tasks = <VocabTask>[];
    // 復習（忘れかけている順）
    final due = <(VocabCard, double)>[];
    for (final c in cards) {
      final p = progress.cards[c.id];
      final s = p?.skills[VocabSkill.meaning];
      if (s == null || s.due.isAfter(now)) continue;
      due.add((c, Fsrs.retrievabilityAt(s, now)));
    }
    due.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (c, _) in due.take(reviewLimit)) {
      tasks.add(VocabTask(c.id, VocabMode.choiceMeaning));
    }
    for (final c in unseen.take(quota)) {
      tasks.add(VocabTask(c.id, VocabMode.flashcard, isNew: true));
    }
    return tasks;
  }

  /// 最終チェック：範囲の単語を、苦手・まだの単語から順に全部
  static List<VocabTask> finalCheck(
    List<VocabCard> cards,
    BookProgress progress,
    DateTime now,
  ) {
    double weakness(VocabCard c) {
      final s = progress.cards[c.id]?.skills[VocabSkill.meaning];
      return s == null ? -1 : Fsrs.retrievabilityAt(s, now);
    }

    final sorted = [...cards]
      ..sort((a, b) => weakness(a).compareTo(weakness(b)));
    return [for (final c in sorted) VocabTask(c.id, VocabMode.choiceMeaning)];
  }

  static bool _introducedOn(CardProgress? p, DateTime now) {
    final t = p?.introduced;
    return t != null &&
        t.year == now.year &&
        t.month == now.month &&
        t.day == now.day;
  }
}

/// クラス共闘ボス：範囲ごとに1体。メンバーの正解の合計で削る
class ClassBoss {
  const ClassBoss._();

  /// ボスの体力：範囲の単語数 × 人数（1人あたり、範囲を1周ぶん正解すれば倒せる）。
  /// 参加している人数で決まるので、少人数のクラスでも倒せる
  static int maxHp(ClassTask task, int members) =>
      max(1, task.size * max(1, members));

  /// 1回の書きこみで足せる正解数の上限（いたずら防止。ルールと同じ値）
  static const maxPerWrite = 100;

  /// 残りの体力
  static int hpLeft(ClassTask task, int members, int dealt) =>
      max(0, maxHp(task, members) - dealt);
}
