import 'dart:math';

import '../classroom/classroom.dart';
import '../study/word_list.dart';
import '../vocab/vocab_book.dart';

/// 出題のもと
enum DuelSource {
  /// つづ単（アプリに入っている、だれでも使える単語帳）。単語もそのまま出せる
  tsuzutan,

  /// 自分の単語帳（LEAP など）。送るのは単語帳の名前と番号だけ。
  /// 相手は自分の端末の、同じ名前の単語帳で解く
  book,
}

/// 1人分の結果（点数だけ。どの問題を間違えたかは送らない）
class DuelResult {
  const DuelResult({
    required this.name,
    required this.correct,
    required this.score,
  });

  final String name;
  final int correct;
  final int score;

  Map<String, Object?> toMap() => {
        'name': name,
        'correct': correct,
        'score': score,
      };

  static DuelResult? fromMap(Object? m) {
    if (m is! Map) return null;
    final name = m['name'], correct = m['correct'], score = m['score'];
    if (name is! String || correct is! num || score is! num) return null;
    return DuelResult(
      name: name,
      correct: correct.toInt(),
      score: score.toInt(),
    );
  }
}

/// リンクで遊ぶ、単語の早押しチャレンジ。
///
/// 作った人が先に解き、リンクを受け取った友だちがあとから同じ問題で挑む
/// （同時に遊ばなくてよい）。1人1回だけ。
class WordDuel {
  const WordDuel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.source,
    required this.sourceId,
    required this.title,
    required this.numbers,
    required this.seed,
    this.results = const {},
    this.expiresAt,
  });

  /// リンクに入る ID（8文字）
  final String id;
  final String ownerId;
  final String ownerName;
  final DuelSource source;

  /// つづ単の一覧 ID、または単語帳の名前（[ClassBooks.normalize] したもの）
  final String sourceId;

  /// 見出し（「LEAP 101〜200」など）
  final String title;

  /// 出題する単語の番号（この順に出す）
  final List<int> numbers;

  /// 選択肢を並べる種（みんな同じ並びになる）
  final int seed;

  /// uid → 結果
  final Map<String, DuelResult> results;
  final DateTime? expiresAt;

  static const count = 10;
  static const maxPlayers = 30;
  static const lifetime = Duration(days: 7);

  static const _alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';

  static String newId([Random? random]) {
    final r = random ?? Random.secure();
    return [for (var i = 0; i < 8; i++) _alphabet[r.nextInt(_alphabet.length)]]
        .join();
  }

  static bool validId(String id) => RegExp(r'^[a-z0-9]{8}$').hasMatch(id);

  bool expired(DateTime now) => expiresAt != null && now.isAfter(expiresAt!);
  bool get full => results.length >= maxPlayers;
  bool played(String uid) => results.containsKey(uid);

  /// 点数の高い順（同点は正解数の多い順）
  List<(String, DuelResult)> get ranking {
    final out = [for (final e in results.entries) (e.key, e.value)];
    out.sort((a, b) {
      final s = b.$2.score.compareTo(a.$2.score);
      return s != 0 ? s : b.$2.correct.compareTo(a.$2.correct);
    });
    return out;
  }

  Map<String, Object?> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'source': source.name,
        'sourceId': sourceId,
        'title': title,
        'numbers': numbers,
        'seed': seed,
        'results': {for (final e in results.entries) e.key: e.value.toMap()},
      };

  static WordDuel? fromMap(String id, Object? m, {DateTime? expiresAt}) {
    if (m is! Map) return null;
    final source =
        DuelSource.values.where((s) => s.name == m['source']).firstOrNull;
    final numbers = m['numbers'];
    if (source == null || numbers is! List) return null;
    final results = <String, DuelResult>{};
    final raw = m['results'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final r = DuelResult.fromMap(e.value);
        if (e.key is String && r != null) results[e.key as String] = r;
      }
    }
    return WordDuel(
      id: id,
      ownerId: m['ownerId'] as String? ?? '',
      ownerName: m['ownerName'] as String? ?? '',
      source: source,
      sourceId: m['sourceId'] as String? ?? '',
      title: m['title'] as String? ?? '',
      numbers: [
        for (final n in numbers)
          if (n is num) n.toInt(),
      ],
      seed: (m['seed'] as num?)?.toInt() ?? 0,
      results: results,
      expiresAt: expiresAt,
    );
  }

  WordDuel withResult(String uid, DuelResult r) => WordDuel(
        id: id,
        ownerId: ownerId,
        ownerName: ownerName,
        source: source,
        sourceId: sourceId,
        title: title,
        numbers: numbers,
        seed: seed,
        results: {...results, uid: r},
        expiresAt: expiresAt,
      );
}

/// 1問
class DuelQuestion {
  const DuelQuestion(this.card, this.choices, this.answer);
  final VocabCard card;

  /// 意味の4択
  final List<String> choices;
  final int answer;
}

/// 問題づくりと点数
class DuelRules {
  const DuelRules._();

  /// 1問の制限時間
  static const limit = Duration(seconds: 10);

  /// 正解で100点、早いほど最大50点を足す
  static int points(bool correct, Duration took) {
    if (!correct) return 0;
    final left = (limit - took).inMilliseconds.clamp(0, limit.inMilliseconds);
    return 100 + (50 * left / limit.inMilliseconds).round();
  }

  /// つづ単の一覧を、番号つきの単語帳として使う
  static VocabBook bookOf(WordList list) => VocabBook(
        id: list.listId,
        title: list.title,
        kind: VocabBookKind.custom,
        cards: [
          for (final (i, w) in list.words.indexed)
            VocabCard(
              id: '${i + 1}',
              number: i + 1,
              term: w.term,
              meaning: w.meaning,
            ),
        ],
      );

  /// 範囲（番号 [from]〜[to]、null なら全部）から [count] 語を選ぶ
  static List<int> pick(
    VocabBook book,
    Random random, {
    int? from,
    int? to,
    int count = WordDuel.count,
  }) {
    final numbers = [
      for (final c in book.cards)
        if (c.number != null &&
            (from == null || c.number! >= from) &&
            (to == null || c.number! <= to))
          c.number!,
    ]..shuffle(random);
    return numbers.take(count).toList();
  }

  /// 番号から問題をつくる。選択肢は [seed] で決まる（同じ単語帳なら同じ並び）。
  /// 自分の単語帳にない番号はとばす
  static List<DuelQuestion> build(
    VocabBook book,
    List<int> numbers,
    int seed,
  ) {
    final byNumber = {
      for (final c in book.cards)
        if (c.number != null) c.number!: c,
    };
    final random = Random(seed);
    final out = <DuelQuestion>[];
    for (final n in numbers) {
      final card = byNumber[n];
      if (card == null) continue;
      final others = <String>{};
      final pool = [
        for (final c in book.cards)
          if (c.meaning != card.meaning) c.meaning,
      ];
      var guard = 0;
      while (others.length < 3 && pool.isNotEmpty && guard++ < 50) {
        others.add(pool[random.nextInt(pool.length)]);
      }
      final choices = [card.meaning, ...others]..shuffle(random);
      out.add(DuelQuestion(card, choices, choices.indexOf(card.meaning)));
    }
    return out;
  }
}
