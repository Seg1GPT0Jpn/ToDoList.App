import 'dart:math';

import 'fsrs.dart';
import 'vocab_book.dart';

/// 単語の「力」。1つの単語でも、意味は分かるのに書けない…を分けて記録する。
enum VocabSkill {
  meaning('意味', '英→日', 0.3),
  recall('想起', '日→英', 0.25),
  spelling('スペル', '書く', 0.2),
  listening('発音', '聞く', 0.1),
  context('例文', '文脈', 0.15);

  const VocabSkill(this.label, this.sub, this.weight);
  final String label;
  final String sub;

  /// 総合の熟練度に占める重み
  final double weight;
}

/// 間違えた理由
enum MistakeReason {
  meaning('意味を忘れた', VocabSkill.meaning),
  spelling('スペルを忘れた', VocabSkill.spelling),
  confused('似た単語と混同した', VocabSkill.meaning),
  pronunciation('発音が分からない', VocabSkill.listening),
  context('文中だと分からない', VocabSkill.context);

  const MistakeReason(this.label, this.skill);
  final String label;

  /// この理由のとき、重点的に練習する力
  final VocabSkill skill;
}

/// 単語の状態（ホームの「今日のあなた」の分類）
enum CardStatus {
  unseen('未学習'),
  weak('弱点'),
  shaky('あやふや'),
  stable('安定');

  const CardStatus(this.label);
  final String label;
}

/// 1語ぶんの学習記録
class CardProgress {
  CardProgress();

  /// 力ごとの記憶の状態（FSRS）
  final Map<VocabSkill, MemoryState> skills = {};

  /// 力ごとの（正解数, 回答数）
  final Map<VocabSkill, (int, int)> answers = {};

  /// 間違えた理由の回数
  final Map<MistakeReason, int> mistakes = {};

  /// 混同した単語
  final Set<String> confusedWith = {};

  DateTime? lastMistake;
  DateTime? introduced;

  int get totalMistakes => mistakes.values.fold(0, (a, b) => a + b);

  /// 力ごとの熟練度（0〜100）。今思い出せる確率と、記憶の安定度と、正答率から出す
  int mastery(VocabSkill k, DateTime now) {
    final s = skills[k];
    if (s == null) return 0;
    final r = Fsrs.retrievabilityAt(s, now);
    final maturity = 1 - exp(-s.stability / 10);
    final (ok, all) = answers[k] ?? (0, 0);
    final acc = (ok + 1) / (all + 2);
    return (100 * r * (0.4 + 0.6 * maturity) * (0.7 + 0.3 * acc))
        .round()
        .clamp(0, 100);
  }

  /// その力を「習得した」といえるか。1回正解しただけでは習得にしない
  bool mastered(VocabSkill k) {
    final s = skills[k];
    return s != null && s.streak >= 3 && s.stability >= 7;
  }

  /// 総合の熟練度（例文のない単語は例文を数えない）
  int overall(DateTime now, {required bool hasExample}) {
    var sum = 0.0, weight = 0.0;
    for (final k in VocabSkill.values) {
      if (k == VocabSkill.context && !hasExample) continue;
      sum += mastery(k, now) * k.weight;
      weight += k.weight;
    }
    return weight == 0 ? 0 : (sum / weight).round();
  }

  CardStatus status(DateTime now) {
    if (skills.isEmpty) return CardStatus.unseen;
    final recentMiss = lastMistake != null &&
        now.difference(lastMistake!) < const Duration(days: 7) &&
        skills.values.any((s) => s.streak < 2);
    final forgetting =
        skills.values.any((s) => Fsrs.retrievabilityAt(s, now) < 0.7);
    if (recentMiss || forgetting) return CardStatus.weak;
    final minR =
        skills.values.map((s) => Fsrs.retrievabilityAt(s, now)).reduce(min);
    if (mastered(VocabSkill.meaning) &&
        mastered(VocabSkill.recall) &&
        minR >= 0.85) {
      return CardStatus.stable;
    }
    return CardStatus.shaky;
  }

  /// 一番多い間違いの理由
  MistakeReason? get topMistake {
    MistakeReason? best;
    for (final e in mistakes.entries) {
      if (best == null || e.value > mistakes[best]!) best = e.key;
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
        'k': {for (final e in skills.entries) e.key.name: e.value.toJson()},
        'a': {
          for (final e in answers.entries) e.key.name: [e.value.$1, e.value.$2],
        },
        if (mistakes.isNotEmpty)
          'm': {for (final e in mistakes.entries) e.key.name: e.value},
        if (confusedWith.isNotEmpty) 'c': confusedWith.toList(),
        if (lastMistake != null) 'lm': lastMistake!.millisecondsSinceEpoch,
        if (introduced != null) 'in': introduced!.millisecondsSinceEpoch,
      };

  factory CardProgress.fromJson(Map<String, dynamic> j) {
    final p = CardProgress();
    for (final e in (j['k'] as Map? ?? {}).entries) {
      final k = _skill(e.key as String);
      if (k != null) {
        p.skills[k] = MemoryState.fromJson(e.value as Map<String, dynamic>);
      }
    }
    for (final e in (j['a'] as Map? ?? {}).entries) {
      final k = _skill(e.key as String);
      final v = e.value as List;
      if (k != null)
        p.answers[k] = ((v[0] as num).toInt(), (v[1] as num).toInt());
    }
    for (final e in (j['m'] as Map? ?? {}).entries) {
      for (final r in MistakeReason.values) {
        if (r.name == e.key) p.mistakes[r] = (e.value as num).toInt();
      }
    }
    p.confusedWith.addAll([for (final c in j['c'] as List? ?? []) c as String]);
    if (j['lm'] != null) {
      p.lastMistake =
          DateTime.fromMillisecondsSinceEpoch((j['lm'] as num).toInt());
    }
    if (j['in'] != null) {
      p.introduced =
          DateTime.fromMillisecondsSinceEpoch((j['in'] as num).toInt());
    }
    return p;
  }

  static VocabSkill? _skill(String name) {
    for (final k in VocabSkill.values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// 1日の学習の記録
class DayStat {
  DayStat();
  int seconds = 0;
  int answered = 0;
  int correct = 0;
  int reviews = 0;
  int news = 0;

  Map<String, dynamic> toJson() =>
      {'s': seconds, 'a': answered, 'c': correct, 'r': reviews, 'n': news};

  factory DayStat.fromJson(Map<String, dynamic> j) => DayStat()
    ..seconds = (j['s'] as num?)?.toInt() ?? 0
    ..answered = (j['a'] as num?)?.toInt() ?? 0
    ..correct = (j['c'] as num?)?.toInt() ?? 0
    ..reviews = (j['r'] as num?)?.toInt() ?? 0
    ..news = (j['n'] as num?)?.toInt() ?? 0;
}

/// 出題のしかた
enum VocabMode {
  flashcard('フラッシュカード', VocabSkill.meaning),
  choiceMeaning('4択 英→日', VocabSkill.meaning),
  choiceTerm('4択 日→英', VocabSkill.recall),
  spelling('スペル入力', VocabSkill.spelling),
  listening('リスニング', VocabSkill.listening),
  cloze('例文穴埋め', VocabSkill.context),
  compare('似た単語の比較', VocabSkill.meaning);

  const VocabMode(this.label, this.skill);
  final String label;
  final VocabSkill skill;

  /// この形式で間違えたときの、ふつうの理由
  MistakeReason get defaultReason => switch (this) {
        spelling => MistakeReason.spelling,
        listening => MistakeReason.pronunciation,
        cloze => MistakeReason.context,
        compare => MistakeReason.confused,
        _ => MistakeReason.meaning,
      };
}

/// 1問ぶんの課題
class VocabTask {
  const VocabTask(this.cardId, this.mode, {this.isNew = false});
  final String cardId;
  final VocabMode mode;

  /// はじめて覚える単語
  final bool isNew;
}

/// 単語帳1冊ぶんの学習記録
class BookProgress {
  BookProgress({this.newPerDay = 10});

  final Map<String, CardProgress> cards = {};
  final Map<String, DayStat> days = {};

  /// 1日に新しく覚える単語の数
  int newPerDay;

  static const fsrs = Fsrs();

  static String dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  DayStat today(DateTime now) => days.putIfAbsent(dayKey(now), DayStat.new);

  /// 今日新しく覚えた数
  int newToday(DateTime now) => days[dayKey(now)]?.news ?? 0;

  /// 答えを記録する
  void record({
    required String cardId,
    required VocabSkill skill,
    required Rating rating,
    required DateTime now,
    MistakeReason? reason,
    String? confusedWith,
    Duration spent = Duration.zero,
    bool isNew = false,
  }) {
    final p = cards.putIfAbsent(cardId, CardProgress.new);
    p.introduced ??= now;
    final old = p.skills[skill];
    p.skills[skill] =
        old == null ? fsrs.first(rating, now) : fsrs.review(old, rating, now);
    final correct = rating != Rating.again;
    final (ok, all) = p.answers[skill] ?? (0, 0);
    p.answers[skill] = (ok + (correct ? 1 : 0), all + 1);
    if (!correct) {
      final r = reason ?? MistakeReason.meaning;
      p.mistakes[r] = (p.mistakes[r] ?? 0) + 1;
      p.lastMistake = now;
      if (confusedWith != null) p.confusedWith.add(confusedWith);
      // 理由に合った力を、すぐにまた練習する
      final target = p.skills[r.skill];
      if (r.skill != skill && target != null) {
        p.skills[r.skill] = MemoryState(
          stability: target.stability,
          difficulty: target.difficulty,
          due: now.add(Fsrs.relearnDelay),
          lastReview: target.lastReview,
          reps: target.reps,
          lapses: target.lapses,
          streak: 0,
        );
      }
    }
    final d = today(now);
    d.answered++;
    if (correct) d.correct++;
    if (isNew) {
      d.news++;
    } else {
      d.reviews++;
    }
    d.seconds += spent.inSeconds;
  }

  /// 連続で学習した日数（今日まだなら昨日まで）
  int streak(DateTime now) {
    var n = 0;
    var t = DateTime(now.year, now.month, now.day);
    if ((days[dayKey(t)]?.answered ?? 0) == 0) {
      t = t.subtract(const Duration(days: 1));
    }
    while ((days[dayKey(t)]?.answered ?? 0) > 0) {
      n++;
      t = t.subtract(const Duration(days: 1));
    }
    return n;
  }

  Map<CardStatus, int> counts(VocabBook book, DateTime now) {
    final out = {for (final s in CardStatus.values) s: 0};
    for (final c in book.cards) {
      final s = cards[c.id]?.status(now) ?? CardStatus.unseen;
      out[s] = out[s]! + 1;
    }
    return out;
  }

  /// 今が復習どきの（単語, 力）の数
  int dueCount(DateTime now) {
    var n = 0;
    for (final p in cards.values) {
      for (final s in p.skills.values) {
        if (!s.due.isAfter(now)) n++;
      }
    }
    return n;
  }

  Map<String, dynamic> toJson() => {
        'npd': newPerDay,
        'cards': {for (final e in cards.entries) e.key: e.value.toJson()},
        'days': {for (final e in days.entries) e.key: e.value.toJson()},
      };

  factory BookProgress.fromJson(Map<String, dynamic> j) {
    final b = BookProgress(newPerDay: (j['npd'] as num?)?.toInt() ?? 10);
    for (final e in (j['cards'] as Map? ?? {}).entries) {
      b.cards[e.key as String] =
          CardProgress.fromJson(e.value as Map<String, dynamic>);
    }
    for (final e in (j['days'] as Map? ?? {}).entries) {
      b.days[e.key as String] =
          DayStat.fromJson(e.value as Map<String, dynamic>);
    }
    return b;
  }
}

/// 似ていて混同しやすい単語を探す（affect / effect、acquire / require など）
class Confusables {
  const Confusables._();

  static int distance(String a, String b) {
    if (a == b) return 0;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = min(min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// [a] と [b] は見た目が似ているか
  static bool similar(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    if (a == b || a.contains(' ') || b.contains(' ')) return false;
    if (a.length < 4 || b.length < 4) return false;
    final limit = min(a.length, b.length) >= 7 ? 2 : 1;
    if (distance(a, b) <= limit) return true;
    // 語尾が同じで、頭だけちがう（acquire / require、affect / effect）
    final tail = min(a.length, b.length) - 2;
    if (tail >= 4 &&
        a.substring(a.length - tail) == b.substring(b.length - tail) &&
        (a.length - b.length).abs() <= 2) {
      return true;
    }
    return false;
  }

  /// 単語帳の中で [card] と混同しやすい単語（記録された混同を先に）
  static List<VocabCard> of(
    VocabBook book,
    VocabCard card, {
    CardProgress? progress,
    int limit = 3,
  }) {
    final out = <VocabCard>[];
    final marked = progress?.confusedWith ?? const <String>{};
    for (final c in book.cards) {
      if (c.id != card.id && marked.contains(c.term)) out.add(c);
    }
    for (final c in book.cards) {
      if (out.length >= limit) break;
      if (c.id == card.id || out.contains(c)) continue;
      if (similar(card.term, c.term)) out.add(c);
    }
    return out.take(limit).toList();
  }
}

/// 「今日の最適学習」を組み立てる。
///
/// 1. 忘れかけている順に復習（思い出せる確率の低いものから）
/// 2. 間違えた理由に合わせて、力ごとの練習を足す（認識 → 想起 → 運用）
/// 3. 混同した単語は比較問題
/// 4. 最後に新しい単語
class VocabPlanner {
  const VocabPlanner._();

  /// その単語で、次に練習をはじめてよい力
  static List<VocabSkill> unlocked(
    VocabCard card,
    CardProgress p, {
    required bool listening,
  }) {
    int reps(VocabSkill k) => p.skills[k]?.reps ?? 0;
    return [
      VocabSkill.meaning,
      if (reps(VocabSkill.meaning) >= 1) VocabSkill.recall,
      if (reps(VocabSkill.recall) >= 1) VocabSkill.spelling,
      if (listening && reps(VocabSkill.meaning) >= 2) VocabSkill.listening,
      if (card.hasExample && reps(VocabSkill.meaning) >= 1) VocabSkill.context,
    ];
  }

  /// 力と記憶の強さから、出題のしかたを選ぶ
  static VocabMode modeFor(VocabSkill k, MemoryState? s) => switch (k) {
        // 最初は4択で見分け（認識）、覚えてきたらカードで思い出す（想起）
        VocabSkill.meaning => s == null || s.stability < 4
            ? VocabMode.choiceMeaning
            : VocabMode.flashcard,
        VocabSkill.recall => VocabMode.choiceTerm,
        VocabSkill.spelling => VocabMode.spelling,
        VocabSkill.listening => VocabMode.listening,
        VocabSkill.context => VocabMode.cloze,
      };

  static List<VocabTask> today(
    VocabBook book,
    BookProgress progress,
    DateTime now, {
    int reviewLimit = 60,
    bool listening = true,
  }) {
    final due = <(VocabCard, VocabSkill, double)>[];
    final fresh = <(VocabCard, VocabSkill)>[];
    for (final c in book.cards) {
      final p = progress.cards[c.id];
      if (p == null) continue;
      for (final k in unlocked(c, p, listening: listening)) {
        final s = p.skills[k];
        if (s == null) {
          fresh.add((c, k));
        } else if (!s.due.isAfter(now)) {
          due.add((c, k, Fsrs.retrievabilityAt(s, now)));
        }
      }
    }
    due.sort((a, b) => a.$3.compareTo(b.$3));

    final tasks = <VocabTask>[];
    final perCard = <String, int>{};
    bool take(VocabCard c, VocabMode m, {bool isNew = false}) {
      if ((perCard[c.id] ?? 0) >= 2) return false;
      perCard[c.id] = (perCard[c.id] ?? 0) + 1;
      tasks.add(VocabTask(c.id, m, isNew: isNew));
      return true;
    }

    for (final (c, k, _) in due) {
      if (tasks.length >= reviewLimit) break;
      take(c, modeFor(k, progress.cards[c.id]!.skills[k]));
    }
    // 混同したことのある単語は比較問題
    var compares = 0;
    for (final (c, _, _) in due) {
      if (compares >= 5) break;
      final p = progress.cards[c.id]!;
      if ((p.mistakes[MistakeReason.confused] ?? 0) > 0 &&
          !tasks.any((t) => t.cardId == c.id && t.mode == VocabMode.compare)) {
        tasks.add(VocabTask(c.id, VocabMode.compare));
        compares++;
      }
    }
    // 覚えた単語の、まだ練習していない力（想起 → スペル → 例文…）
    var extra = 0;
    for (final (c, k) in fresh) {
      if (tasks.length >= reviewLimit || extra >= 15) break;
      if (take(c, modeFor(k, null))) extra++;
    }
    // 新しい単語
    final room = max(0, progress.newPerDay - progress.newToday(now));
    var added = 0;
    for (final c in book.cards) {
      if (added >= room) break;
      if (progress.cards.containsKey(c.id)) continue;
      tasks.add(VocabTask(c.id, VocabMode.flashcard, isNew: true));
      added++;
    }
    return tasks;
  }

  /// 決まった形式で、範囲の単語を出す（自由練習）
  static List<VocabTask> drill(
    List<VocabCard> cards,
    VocabMode mode, {
    Random? random,
    int count = 20,
  }) {
    final pool = [
      for (final c in cards)
        if (mode != VocabMode.cloze || c.hasExample) c,
    ]..shuffle(random ?? Random());
    return [for (final c in pool.take(count)) VocabTask(c.id, mode)];
  }

  /// 間違えたことのある単語だけ
  static List<VocabTask> mistakesOnly(
    VocabBook book,
    BookProgress progress, {
    int count = 30,
  }) {
    final list = [
      for (final c in book.cards)
        if ((progress.cards[c.id]?.totalMistakes ?? 0) > 0) c,
    ]..sort((a, b) => progress.cards[b.id]!.totalMistakes
        .compareTo(progress.cards[a.id]!.totalMistakes));
    return [
      for (final c in list.take(count))
        VocabTask(
          c.id,
          modeFor(progress.cards[c.id]!.topMistake?.skill ?? VocabSkill.meaning,
              progress.cards[c.id]!.skills[VocabSkill.meaning]),
        ),
    ];
  }
}

/// 4択の選択肢を作る
class VocabChoices {
  const VocabChoices._();

  /// [mode] に合わせて、正解1つとまちがい3つ（同じ品詞・似た単語を優先）
  static List<String> build(
    VocabBook book,
    VocabCard card,
    VocabMode mode, {
    Random? random,
    CardProgress? progress,
  }) {
    final rnd = random ?? Random();
    final byTerm = mode == VocabMode.choiceTerm ||
        mode == VocabMode.listening ||
        mode == VocabMode.compare;
    String label(VocabCard c) => byTerm ? c.term : c.shortMeaning;
    final answer = label(card);
    final wrong = <String>[];
    if (mode == VocabMode.compare || mode == VocabMode.listening) {
      for (final c in Confusables.of(book, card, progress: progress)) {
        if (label(c) != answer && !wrong.contains(label(c)))
          wrong.add(label(c));
      }
    }
    final others = [
      for (final c in book.cards)
        if (c.id != card.id) c,
    ]..shuffle(rnd);
    others.sort((a, b) {
      final pa = a.partOfSpeech == card.partOfSpeech ? 0 : 1;
      final pb = b.partOfSpeech == card.partOfSpeech ? 0 : 1;
      return pa - pb;
    });
    for (final c in others) {
      if (wrong.length >= 3) break;
      final l = label(c);
      if (l != answer && !wrong.contains(l)) wrong.add(l);
    }
    return [answer, ...wrong.take(3)]..shuffle(rnd);
  }
}

/// 単語帳を週ごとのコースに分ける
class VocabCourse {
  const VocabCourse._();

  static List<(String, List<VocabCard>)> weeks(VocabBook book,
      {int size = 100}) {
    final out = <(String, List<VocabCard>)>[];
    for (var i = 0; i < book.cards.length; i += size) {
      final part = book.cards.sublist(i, min(i + size, book.cards.length));
      final a = part.first.number ?? i + 1;
      final b = part.last.number ?? i + part.length;
      out.add(('Week ${out.length + 1}（$a〜$b）', part));
    }
    return out;
  }
}
