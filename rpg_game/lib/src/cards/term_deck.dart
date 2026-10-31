import 'dart:math';

import '../models/question.dart';
import '../vocab/vocab_book.dart';

/// 暗記カード1枚：用語・意味・関連語・豆知識。
class TermCard {
  const TermCard({
    required this.term,
    required this.meaning,
    this.reading = '',
    this.related = const [],
    this.trivia = '',
    this.section = '',
  });

  factory TermCard.fromJson(Map<String, dynamic> j, String section) => TermCard(
        term: j['t'] as String,
        reading: j['r'] as String? ?? '',
        meaning: j['m'] as String,
        related: [...?(j['rel'] as List?)?.cast<String>()],
        trivia: j['tr'] as String? ?? '',
        section: section,
      );

  /// 用語の名称
  final String term;

  /// 読み（あれば）
  final String reading;

  /// 用語の意味
  final String meaning;

  /// 関連語
  final List<String> related;

  /// 豆知識
  final String trivia;

  /// 章・単元
  final String section;

  Map<String, dynamic> toJson() => {
        't': term,
        if (reading.isNotEmpty) 'r': reading,
        'm': meaning,
        if (related.isNotEmpty) 'rel': related,
        if (trivia.isNotEmpty) 'tr': trivia,
      };
}

/// 教科ごとの暗記カードの束（物理・日本史など）。
class TermDeck {
  const TermDeck({
    required this.id,
    required this.worldId,
    required this.title,
    required this.cards,
  });

  factory TermDeck.fromJson(Map<String, dynamic> j) => TermDeck(
        id: j['id'] as String,
        worldId: j['worldId'] as String,
        title: j['title'] as String,
        cards: [
          for (final s in j['sections'] as List)
            for (final c in (s as Map)['cards'] as List)
              TermCard.fromJson(c as Map<String, dynamic>, s['name'] as String),
        ],
      );

  final String id;

  /// 解放に使うワールド（science / social / japanese / information）
  final String worldId;
  final String title;
  final List<TermCard> cards;

  /// 章の名前（出てくる順）
  List<String> get sections => [
        for (final (i, c) in cards.indexed)
          if (i == 0 || cards[i - 1].section != c.section) c.section,
      ];

  List<TermCard> inSection(String name) => [
        for (final c in cards)
          if (c.section == name) c
      ];

  /// 単語帳の形にする（英語の単語帳と同じ「今日の最適学習」・熟練度・分析・苦手克服カードが使える）。
  ///
  /// カードの ID は用語そのもの（同じ用語が2枚あれば「用語#2」）。カードの順番が
  /// 変わっても、学習記録はそのまま残る
  VocabBook toBook() {
    final seen = <String, int>{};
    String idOf(String term) {
      final n = seen[term] = (seen[term] ?? 0) + 1;
      return n == 1 ? term : '$term#$n';
    }

    return VocabBook(
      id: 'cards_$id',
      title: title,
      kind: VocabBookKind.builtin,
      worldId: worldId,
      cards: [
        for (final (i, c) in cards.indexed)
          VocabCard(
            id: idOf(c.term),
            number: i + 1,
            term: c.term,
            meaning: c.meaning,
            pron: c.reading,
            note: [
              if (c.trivia.isNotEmpty) c.trivia,
              if (c.related.isNotEmpty) '関連：${c.related.join('・')}',
            ].join('\n'),
            group: c.section,
          ),
      ],
    );
  }
}

/// アプリに入っている暗記カードの一覧。
/// 理科・社会・国語・情報のワールドと一緒に使えるようになる。
class TermDeckInfo {
  const TermDeckInfo(this.id, this.worldId, this.title);
  final String id;
  final String worldId;
  final String title;

  String get assetPath => 'packages/rpg_game/assets/cards/$id.json';
}

class TermDecks {
  const TermDecks._();

  static const all = [
    TermDeckInfo('physics', 'science', '物理'),
    TermDeckInfo('chemistry', 'science', '化学'),
    TermDeckInfo('biology', 'science', '生物'),
    TermDeckInfo('earth', 'science', '地学'),
    TermDeckInfo('japanese_history', 'social', '日本史'),
    TermDeckInfo('world_history', 'social', '世界史'),
    TermDeckInfo('geography', 'social', '地理'),
    TermDeckInfo('politics', 'social', '政治・経済'),
    TermDeckInfo('kobun_words', 'japanese', '古文単語'),
    TermDeckInfo('classics', 'japanese', '古典文法・和歌・古典常識'),
    TermDeckInfo('hyoron', 'japanese', '現代文キーワード'),
    TermDeckInfo('kotowaza', 'japanese', 'ことわざ・慣用句・四字熟語'),
    TermDeckInfo('bungakushi', 'japanese', '文学史'),
    TermDeckInfo('info1', 'information', '情報Ⅰ'),
  ];

  static List<TermDeckInfo> of(String worldId) => [
        for (final d in all)
          if (d.worldId == worldId) d
      ];
}

/// 暗記カードの問題の向き
enum TermQuizMode {
  /// 意味を見て用語を選ぶ
  meaningToTerm,

  /// 用語を見て意味を選ぶ
  termToMeaning,

  /// 両方をまぜる
  mixed,
}

/// 暗記カードから4択問題を作る（定期テストの海・模擬試験の空で使う。RPG では使わない）。
class TermQuizBuilder {
  TermQuizBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// [pool] から [count] 問。まちがいの選択肢は同じ章から優先して選ぶ。
  List<QuizQuestion> build(
    TermDeck deck, {
    List<TermCard>? pool,
    int count = 20,
    TermQuizMode mode = TermQuizMode.mixed,
  }) {
    final targets = [...(pool ?? deck.cards)]..shuffle(_random);
    final out = <QuizQuestion>[];
    for (final c in targets) {
      if (out.length >= count) break;
      final toTerm = switch (mode) {
        TermQuizMode.meaningToTerm => true,
        TermQuizMode.termToMeaning => false,
        TermQuizMode.mixed => _random.nextBool(),
      };
      final q = _question(deck, c, toTerm);
      if (q != null) out.add(q);
    }
    return out;
  }

  QuizQuestion? _question(TermDeck deck, TermCard c, bool toTerm) {
    String label(TermCard e) => toTerm ? e.term : e.meaning;
    final answer = label(c);
    final others = [
      for (final e in deck.cards)
        if (!identical(e, c) &&
            label(e) != answer &&
            e.term != c.term &&
            e.meaning != c.meaning &&
            !c.related.contains(e.term))
          e,
    ]..shuffle(_random);
    // 同じ章のものを先に（まぎらわしいほうが練習になる）
    others.sort(
      (a, b) =>
          (a.section == c.section ? 0 : 1) - (b.section == c.section ? 0 : 1),
    );
    final wrong = <String>[];
    for (final e in others) {
      final l = label(e);
      if (!wrong.contains(l)) wrong.add(l);
      if (wrong.length == 3) break;
    }
    if (wrong.length < 3) return null;
    final choices = [answer, ...wrong]..shuffle(_random);
    final idx = deck.cards.indexOf(c);
    final more = [
      if (c.related.isNotEmpty) '関連語：${c.related.join('・')}',
      if (c.trivia.isNotEmpty) '豆知識：${c.trivia}',
    ].join('\n');
    return QuizQuestion(
      id: 'card_${deck.id}_${toTerm ? 't' : 'm'}_$idx',
      category: toTerm ? QuestionCategory.knowledge : QuestionCategory.meaning,
      prompt: toTerm ? '次の説明にあてはまる用語は？' : '「${c.term}」の説明として正しいものは？',
      sentence: toTerm ? c.meaning : null,
      choices: choices,
      answerIndex: choices.indexOf(answer),
      explanation:
          '${c.term}${c.reading.isEmpty ? '' : '（${c.reading}）'}：${c.meaning}'
          '${more.isEmpty ? '' : '\n$more'}',
      tags: ['card', deck.id],
    );
  }
}
