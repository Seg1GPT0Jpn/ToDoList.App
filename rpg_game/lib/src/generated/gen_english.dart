import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';

// 英語（文法の形）の問題の作り方。不規則動詞・比較・代名詞・名詞の複数形は表から出す。

/// 不規則動詞：原形・過去形・過去分詞・意味
const _irregular = <(String, String, String, String)>[
  ('begin', 'began', 'begun', '始める'),
  ('break', 'broke', 'broken', '壊す'),
  ('bring', 'brought', 'brought', '持ってくる'),
  ('build', 'built', 'built', '建てる'),
  ('buy', 'bought', 'bought', '買う'),
  ('catch', 'caught', 'caught', 'つかまえる'),
  ('choose', 'chose', 'chosen', '選ぶ'),
  ('come', 'came', 'come', '来る'),
  ('do', 'did', 'done', 'する'),
  ('draw', 'drew', 'drawn', '描く'),
  ('drink', 'drank', 'drunk', '飲む'),
  ('drive', 'drove', 'driven', '運転する'),
  ('eat', 'ate', 'eaten', '食べる'),
  ('fall', 'fell', 'fallen', '落ちる'),
  ('feel', 'felt', 'felt', '感じる'),
  ('find', 'found', 'found', '見つける'),
  ('fly', 'flew', 'flown', '飛ぶ'),
  ('forget', 'forgot', 'forgotten', '忘れる'),
  ('give', 'gave', 'given', '与える'),
  ('go', 'went', 'gone', '行く'),
  ('grow', 'grew', 'grown', '育つ'),
  ('have', 'had', 'had', '持っている'),
  ('hear', 'heard', 'heard', '聞こえる'),
  ('keep', 'kept', 'kept', '保つ'),
  ('know', 'knew', 'known', '知っている'),
  ('leave', 'left', 'left', '去る'),
  ('lose', 'lost', 'lost', '失う'),
  ('make', 'made', 'made', '作る'),
  ('meet', 'met', 'met', '会う'),
  ('pay', 'paid', 'paid', '払う'),
  ('put', 'put', 'put', '置く'),
  ('read', 'read', 'read', '読む'),
  ('ride', 'rode', 'ridden', '乗る'),
  ('ring', 'rang', 'rung', '鳴る'),
  ('rise', 'rose', 'risen', '上がる'),
  ('run', 'ran', 'run', '走る'),
  ('say', 'said', 'said', '言う'),
  ('see', 'saw', 'seen', '見る'),
  ('sell', 'sold', 'sold', '売る'),
  ('send', 'sent', 'sent', '送る'),
  ('sing', 'sang', 'sung', '歌う'),
  ('sit', 'sat', 'sat', '座る'),
  ('sleep', 'slept', 'slept', '眠る'),
  ('speak', 'spoke', 'spoken', '話す'),
  ('spend', 'spent', 'spent', '過ごす'),
  ('stand', 'stood', 'stood', '立つ'),
  ('steal', 'stole', 'stolen', '盗む'),
  ('swim', 'swam', 'swum', '泳ぐ'),
  ('take', 'took', 'taken', '取る'),
  ('teach', 'taught', 'taught', '教える'),
  ('tell', 'told', 'told', '伝える'),
  ('think', 'thought', 'thought', '思う'),
  ('throw', 'threw', 'thrown', '投げる'),
  ('understand', 'understood', 'understood', '理解する'),
  ('wake', 'woke', 'woken', '目を覚ます'),
  ('wear', 'wore', 'worn', '着ている'),
  ('win', 'won', 'won', '勝つ'),
  ('write', 'wrote', 'written', '書く'),
];

GenQ? _verbForm(Random r) {
  final (base, past, pp, ja) = r.pick(_irregular);
  final askPp = r.nextBool();
  final ans = askPp ? pp : past;
  final regular = base.endsWith('e') ? '${base}d' : '${base}ed';
  return GenQ(
    prompt: '$base（$ja）の${askPp ? '過去分詞' : '過去形'}は？',
    answer: ans,
    wrong: [regular, base, askPp ? past : pp, '${ans}ed', '${base}en'],
    explanation: '$base － $past － $pp',
    category: QuestionCategory.knowledge,
  );
}

/// 比較：原級・比較級・最上級
const _compare = <(String, String, String, String)>[
  ('tall', 'taller', 'tallest', '背が高い'),
  ('old', 'older', 'oldest', '年をとった'),
  ('young', 'younger', 'youngest', '若い'),
  ('long', 'longer', 'longest', '長い'),
  ('short', 'shorter', 'shortest', '短い'),
  ('small', 'smaller', 'smallest', '小さい'),
  ('fast', 'faster', 'fastest', '速い'),
  ('high', 'higher', 'highest', '高い'),
  ('strong', 'stronger', 'strongest', '強い'),
  ('cold', 'colder', 'coldest', '寒い'),
  ('new', 'newer', 'newest', '新しい'),
  ('cheap', 'cheaper', 'cheapest', '安い'),
  ('large', 'larger', 'largest', '大きい'),
  ('nice', 'nicer', 'nicest', 'すてきな'),
  ('big', 'bigger', 'biggest', '大きい'),
  ('hot', 'hotter', 'hottest', '暑い'),
  ('happy', 'happier', 'happiest', '幸せな'),
  ('easy', 'easier', 'easiest', '簡単な'),
  ('busy', 'busier', 'busiest', '忙しい'),
  ('early', 'earlier', 'earliest', '早い'),
  ('heavy', 'heavier', 'heaviest', '重い'),
  ('good', 'better', 'best', 'よい'),
  ('bad', 'worse', 'worst', '悪い'),
  ('many', 'more', 'most', '多くの'),
  ('beautiful', 'more beautiful', 'most beautiful', '美しい'),
  ('difficult', 'more difficult', 'most difficult', '難しい'),
  ('important', 'more important', 'most important', '大切な'),
  ('interesting', 'more interesting', 'most interesting', 'おもしろい'),
  ('popular', 'more popular', 'most popular', '人気のある'),
  ('famous', 'more famous', 'most famous', '有名な'),
  ('useful', 'more useful', 'most useful', '役に立つ'),
  ('expensive', 'more expensive', 'most expensive', '高価な'),
  ('careful', 'more careful', 'most careful', '注意深い'),
];

/// 人について使えるもの・物について使えるもの
const _forPeople = {
  'tall',
  'old',
  'young',
  'strong',
  'busy',
  'happy',
  'famous',
  'popular',
  'careful'
};
const _forThings = {
  'long', 'short', 'small', 'new', 'cheap', 'large', 'big', 'heavy', //
  'difficult', 'interesting', 'popular', 'useful', 'expensive', 'easy', 'old',
  'beautiful',
};

GenQ? _comparisonForm(Random r) {
  final (base, comp, sup, ja) = r.pick(_compare);
  final askSup = r.nextBool();
  final ans = askSup ? sup : comp;
  return GenQ(
    prompt: '$base（$ja）の${askSup ? '最上級' : '比較級'}は？',
    answer: ans,
    wrong: [
      askSup ? comp : sup,
      '${base}er',
      'more $base',
      askSup ? 'most $base' : '${base}est',
      '${base}r',
    ],
    explanation: '$base － $comp － $sup',
    category: QuestionCategory.knowledge,
  );
}

GenQ? _comparisonSentence(Random r) {
  final (base, comp, sup, ja) = r.pick(_compare
      .where((c) => _forPeople.contains(c.$1) || _forThings.contains(c.$1))
      .toList());
  final people =
      _forPeople.contains(base) && (!_forThings.contains(base) || r.nextBool());
  // 形容詞に合う名詞（難しいかばん、のような文にしない）
  final thing = switch (base) {
    'difficult' || 'easy' => ('This question', 'that one'),
    'interesting' || 'useful' || 'popular' => ('This book', 'that one'),
    _ => ('This bag', 'that one'),
  };
  final kind = r.nextInt(3);
  final (sentence, ans, note) = switch (kind) {
    0 => (
        people
            ? 'Emma is (   ) than her sister.'
            : '${thing.$1} is (   ) than ${thing.$2}.',
        comp,
        '後ろに than があるので比較級。',
      ),
    1 => (
        people
            ? 'Emma is the (   ) of the three.'
            : '${thing.$1} is the (   ) of the three.',
        sup,
        'the ＋ 最上級 ＋ of 〜 で「〜の中でいちばん…」。',
      ),
    _ => (
        people
            ? 'Emma is as (   ) as her sister.'
            : '${thing.$1} is as (   ) as ${thing.$2}.',
        base,
        'as ＋ 原級 ＋ as で「〜と同じくらい…」。',
      ),
  };
  return GenQ(
    prompt: '(   ) に入る最も適切なものは？（$ja）',
    sentence: sentence,
    answer: ans,
    wrong: [base, comp, sup, 'more $base', '${base}est'],
    explanation: note,
    category: QuestionCategory.usage,
  );
}

/// 人称代名詞
const _pronouns = <(String, String, String, String, String)>[
  // 主格・所有格・目的格・所有代名詞・意味
  ('I', 'my', 'me', 'mine', '私'), ('you', 'your', 'you', 'yours', 'あなた'),
  ('he', 'his', 'him', 'his', '彼'), ('she', 'her', 'her', 'hers', '彼女'),
  ('we', 'our', 'us', 'ours', '私たち'), ('they', 'their', 'them', 'theirs', '彼ら'),
];

GenQ? _pronoun(Random r) {
  final p = r.pick(_pronouns);
  final i = r.range(1, 3);
  final label = ['主格', '所有格', '目的格', '所有代名詞'][i];
  final forms = [p.$1, p.$2, p.$3, p.$4];
  final ans = forms[i];
  return GenQ(
    prompt: '${p.$1}（${p.$5}）の$labelは？',
    answer: ans,
    wrong: [
      for (final f in forms) f,
      for (final q in _pronouns)
        if (q != p) [q.$1, q.$2, q.$3, q.$4][i],
    ]..shuffle(r),
    explanation: '${p.$1} － ${p.$2} － ${p.$3} － ${p.$4}',
    category: QuestionCategory.knowledge,
  );
}

/// 名詞の複数形
const _plurals = <(String, String, String)>[
  ('child', 'children', '子ども'),
  ('man', 'men', '男性'),
  ('woman', 'women', '女性'),
  ('tooth', 'teeth', '歯'),
  ('foot', 'feet', '足'),
  ('mouse', 'mice', 'ネズミ'),
  ('box', 'boxes', '箱'),
  ('city', 'cities', '都市'),
  ('leaf', 'leaves', '葉'),
  ('knife', 'knives', 'ナイフ'),
  ('potato', 'potatoes', 'ジャガイモ'),
  ('baby', 'babies', '赤ちゃん'),
  ('bus', 'buses', 'バス'),
  ('dish', 'dishes', '皿'),
  ('watch', 'watches', '腕時計'),
  ('sheep', 'sheep', '羊'),
  ('photo', 'photos', '写真'),
  ('piano', 'pianos', 'ピアノ'),
  ('country', 'countries', '国'),
  ('wife', 'wives', '妻'),
  ('person', 'people', '人'),
];

GenQ? _plural(Random r) {
  final (one, many, ja) = r.pick(_plurals);
  return GenQ(
    prompt: '$one（$ja）の複数形は？',
    answer: many,
    wrong: ['${one}s', '${one}es', one, '${many}s', '${one}en'],
    explanation: '$one → $many',
    category: QuestionCategory.knowledge,
  );
}

/// 動名詞・不定詞を目的語にとる動詞（過去形で使う）と、自然につながる目的語の番号
const _ingVerbs = <(String, String, List<int>)>[
  ('enjoyed', 'enjoy', [0, 1, 2, 3, 5]),
  ('finished', 'finish', [1, 2, 3, 4, 5]),
  ('avoided', 'avoid', [3, 4]),
  ('gave up', 'give up', [0, 1]),
  ('considered', 'consider', [1, 0]),
  ('practiced', 'practice', [0]),
];
const _toVerbs = <(String, String, List<int>)>[
  ('wanted', 'want', [0, 1, 2, 3, 4, 5]),
  ('hoped', 'hope', [0, 1]),
  ('decided', 'decide', [0, 1, 2, 3, 4, 5]),
  ('planned', 'plan', [1, 2, 3, 4]),
  ('agreed', 'agree', [3, 4]),
  ('promised', 'promise', [1, 2, 3, 4]),
  ('refused', 'refuse', [3, 4]),
  ('managed', 'manage', [2, 3, 4, 5]),
];

/// 目的語（動詞の原形・ing 形・過去形・目的語）
const _activities = <(String, String, String, String)>[
  ('play', 'playing', 'played', 'the piano'),
  ('study', 'studying', 'studied', 'English'),
  ('write', 'writing', 'wrote', 'a letter'),
  ('cook', 'cooking', 'cooked', 'dinner'),
  ('clean', 'cleaning', 'cleaned', 'the room'),
  ('read', 'reading', 'read', 'the book'),
];

GenQ? _gerundInfinitive(Random r) {
  final ing = r.nextBool();
  final (verb, base, ok) = ing ? r.pick(_ingVerbs) : r.pick(_toVerbs);
  final (v, vIng, vPast, obj) = _activities[r.pick(ok)];
  final subject = r.pick(['She', 'He', 'They', 'I', 'Ken']);
  return GenQ(
    prompt: '(   ) に入る最も適切なものは？',
    sentence: '$subject $verb (   ) $obj.',
    answer: ing ? vIng : 'to $v',
    wrong: [
      ing ? 'to $v' : vIng,
      v,
      if (vPast != v) vPast,
      'to $vIng',
      '$vIng to'
    ],
    explanation:
        ing ? '$base は動名詞（〜ing）を目的語にとる。' : '$base は不定詞（to ＋ 動詞の原形）を目的語にとる。',
    category: QuestionCategory.usage,
  );
}

final Map<String, List<Gen>> englishGens = {
  'english.eng.grammar.tense.simple': [_verbForm],
  'english.eng.grammar.tense.perfect': [_verbForm],
  'english.eng.grammar.passive.basic': [_verbForm],
  'english.eng.grammar.comparison.basic': [
    _comparisonForm,
    _comparisonSentence
  ],
  'english.eng.grammar.comparison': [_comparisonSentence],
  'english.eng.grammar.pronoun.pronoun': [_pronoun],
  'english.eng.grammar.pronoun': [_pronoun, _plural],
  'english.eng.grammar.pronoun.noun': [_plural],
  'english.eng.grammar.gerund': [_gerundInfinitive],
  'english.eng.grammar.gerund.usage': [_gerundInfinitive],
  'english.eng.grammar.gerund.contrast': [_gerundInfinitive],
  'english.eng.grammar.infinitive.usage': [_gerundInfinitive],
};
