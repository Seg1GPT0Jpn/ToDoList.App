import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';

// 楽典の問題の作り方。調・音名・音程・和音は、音の高さ（半音の数）から計算する。

/// 幹音（C D E F G A B）の、C からの半音の数
const _letterSemi = [0, 2, 4, 5, 7, 9, 11];
const _letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
const _jpLetters = ['ハ', 'ニ', 'ホ', 'ヘ', 'ト', 'イ', 'ロ'];
const _itLetters = ['ド', 'レ', 'ミ', 'ファ', 'ソ', 'ラ', 'シ'];

/// 音（幹音の番号 0〜6 と、変化 −1〜1）
class _Note {
  const _Note(this.letter, this.acc);
  final int letter;
  final int acc;

  int get semi => (_letterSemi[letter] + acc) % 12;

  /// ドイツ音名（C、Cis、Es、B、H…）
  String get german {
    final l = _letters[letter];
    if (acc == 0) return l == 'B' ? 'H' : l;
    if (acc == 1) return l == 'B' ? 'His' : '${l}is';
    // ♭
    return switch (l) {
      'B' => 'B',
      'E' => 'Es',
      'A' => 'As',
      _ => '${l}es',
    };
  }

  /// 英語音名（C、F♯、B♭…）
  String get english =>
      '${_letters[letter]}${acc == 1 ? '♯' : acc == -1 ? '♭' : ''}';

  /// 日本音名（ハ、嬰ヘ、変ロ…）
  String get japanese =>
      '${acc == 1 ? '嬰' : acc == -1 ? '変' : ''}${_jpLetters[letter]}';
}

/// 調：5度圏の位置 k（♯の数、♭は負）と長調/短調
class _Key {
  const _Key(this.k, this.major);
  final int k;
  final bool major;

  bool get valid => k >= -7 && k <= 7;

  /// 主音
  _Note get tonic {
    // 長調の主音は C から完全5度ずつ。短調は平行長調の主音から短3度下
    final majorLetter = ((4 * k) % 7 + 7) % 7;
    final tonicLetter = major ? majorLetter : (majorLetter + 5) % 7;
    final sig = signature;
    return _Note(tonicLetter, sig[tonicLetter] ?? 0);
  }

  /// 調号でついている音（幹音の番号 → 変化）
  Map<int, int> get signature {
    const sharps = [3, 0, 4, 1, 5, 2, 6]; // F C G D A E B
    const flats = [6, 2, 5, 1, 4, 0, 3]; // B E A D G C F
    return {
      if (k > 0)
        for (final l in sharps.take(k)) l: 1,
      if (k < 0)
        for (final l in flats.take(-k)) l: -1,
    };
  }

  /// 音階（自然短音階）
  List<_Note> get scale {
    final t = tonic.letter;
    final sig = signature;
    return [
      for (var i = 0; i < 7; i++) _Note((t + i) % 7, sig[(t + i) % 7] ?? 0),
    ];
  }

  String get german =>
      major ? '${tonic.german} dur' : '${tonic.german.toLowerCase()} moll';
  String get japanese => '${tonic.japanese}${major ? '長調' : '短調'}';

  String get signatureText => k == 0
      ? '調号なし'
      : k > 0
          ? '♯$k個'
          : '♭${-k}個';

  _Key get dominant => _Key(k + 1, major);
  _Key get subdominant => _Key(k - 1, major);
  _Key get relative => _Key(k, !major); // 平行調
  _Key get parallel => _Key(major ? k - 3 : k + 3, !major); // 同主調

  @override
  bool operator ==(Object o) => o is _Key && o.k == k && o.major == major;
  @override
  int get hashCode => Object.hash(k, major);
}

_Key _randomKey(Random r, {int range = 6}) =>
    _Key(r.range(-range, range), r.nextBool());

/// 近親調
GenQ? _relatedKey(Random r) {
  final key = _randomKey(r, range: 5);
  final ops = <(String, _Key Function(_Key))>[
    ('属調', (k) => k.dominant),
    ('下属調', (k) => k.subdominant),
    ('平行調', (k) => k.relative),
    ('同主調', (k) => k.parallel),
  ];
  final two = r.nextBool();
  final (n1, f1) = r.pick(ops);
  final (n2, f2) = r.pick(ops);
  final ans = two ? f2(f1(key)) : f1(key);
  if (!ans.valid) return null;
  final label = two ? '$n1の$n2' : n1;
  final wrong = <String>[
    for (final (_, f) in ops)
      if (f(key).valid) f(key).german,
    if (two)
      for (final (_, f) in ops)
        if (f(f1(key)).valid) f(f1(key)).german,
    _Key(ans.k, !ans.major).german,
    if (_Key(ans.k + 1, ans.major).valid) _Key(ans.k + 1, ans.major).german,
    if (_Key(ans.k - 1, ans.major).valid) _Key(ans.k - 1, ans.major).german,
  ]..shuffle(r);
  return GenQ(
    prompt: '${key.german} の$labelは？',
    answer: ans.german,
    wrong: wrong,
    explanation: '属調は完全5度上、下属調は完全5度下、平行調は同じ調号、同主調は同じ主音の調。',
    category: QuestionCategory.thinking,
  );
}

/// 調号と調
GenQ? _keySignature(Random r) {
  final key = _randomKey(r, range: 7);
  if (r.nextBool()) {
    return GenQ(
      prompt: '調号が${key.signatureText}の${key.major ? '長調' : '短調'}は？',
      answer: key.japanese,
      wrong: [
        for (final d in [1, -1, 2, -2, 3])
          if (_Key(key.k + d, key.major).valid)
            _Key(key.k + d, key.major).japanese,
        key.relative.japanese,
      ],
      explanation: '${key.japanese}の調号は${key.signatureText}。',
      category: QuestionCategory.knowledge,
    );
  }
  return GenQ(
    prompt: '${key.japanese}の調号は？',
    answer: key.signatureText,
    wrong: [
      for (final d in [1, -1, 2, -2])
        _Key(key.k + d, key.major).valid
            ? _Key(key.k + d, key.major).signatureText
            : '♯${(key.k + d).abs()}個',
      key.k > 0
          ? '♭${key.k}個'
          : key.k < 0
              ? '♯${-key.k}個'
              : '♯1個',
    ],
    explanation: '${key.japanese}（${key.german}）の調号は${key.signatureText}。',
    category: QuestionCategory.knowledge,
  );
}

/// 調号の♯・♭のつく順番
GenQ? _signatureOrder(Random r) {
  final sharp = r.nextBool();
  final i = r.range(1, 7);
  final notes = sharp
      ? [
          for (final l in [3, 0, 4, 1, 5, 2, 6]) _Note(l, 1).german
        ]
      : [
          for (final l in [6, 2, 5, 1, 4, 0, 3]) _Note(l, -1).german
        ];
  return GenQ(
    prompt: '調号の${sharp ? '♯' : '♭'}で、$i番目につく音は？',
    answer: notes[i - 1],
    wrong: [
      for (final n in [...notes]..shuffle(r)) n
    ],
    explanation: '${sharp ? '♯' : '♭'}は ${notes.join('・')} の順につく。',
    category: QuestionCategory.knowledge,
  );
}

/// 音名の言いかえ
GenQ? _noteNames(Random r) {
  final l = r.nextInt(7);
  final systems = <(String, List<String>)>[
    ('日本音名', _jpLetters),
    ('ドイツ音名', [for (var i = 0; i < 7; i++) _Note(i, 0).german]),
    ('英語音名', _letters),
    ('イタリア音名', _itLetters),
  ];
  final a = r.nextInt(4);
  var b = r.nextInt(4);
  if (a == b) b = (b + 1) % 4;
  final (na, la) = systems[a];
  final (nb, lb) = systems[b];
  return GenQ(
    prompt: '$naの「${la[l]}」を$nbにすると？',
    answer: lb[l],
    wrong: [
      for (final x in [...lb]..shuffle(r)) x
    ],
    explanation: '${la[l]}＝${lb[l]}（${_itLetters[l]}）',
    category: QuestionCategory.knowledge,
  );
}

/// 2つの幹音の音程
String? _intervalName(int degree, int semis) {
  const perfect = {1: 0, 4: 5, 5: 7, 8: 12};
  const majors = {2: 2, 3: 4, 6: 9, 7: 11};
  final name = const ['', '1', '2', '3', '4', '5', '6', '7', '8'][degree];
  if (perfect.containsKey(degree)) {
    final d = semis - perfect[degree]!;
    return switch (d) {
      0 => '完全$name度',
      1 => '増$name度',
      -1 => '減$name度',
      _ => null
    };
  }
  final d = semis - majors[degree]!;
  return switch (d) {
    0 => '長$name度',
    -1 => '短$name度',
    1 => '増$name度',
    -2 => '減$name度',
    _ => null
  };
}

String _invert(String n) {
  final degree = int.parse(RegExp(r'\d').firstMatch(n)![0]!);
  final q = n.substring(0, n.indexOf('$degree'));
  final iq =
      switch (q) { '長' => '短', '短' => '長', '増' => '減', '減' => '増', _ => q };
  return '$iq${9 - degree}度';
}

GenQ? _interval(Random r) {
  final a = r.nextInt(7);
  final steps = r.range(1, 6);
  final b = (a + steps) % 7;
  final semis = (_letterSemi[b] - _letterSemi[a] + 12) % 12;
  final name = _intervalName(steps + 1, semis);
  if (name == null) return null;
  final all = [
    for (final q in ['長', '短', '完全', '増', '減'])
      for (final d in [steps, steps + 1, steps + 2])
        if (d >= 1 && d <= 8) '$q$d度',
  ].where((s) => _validName(s)).toList()
    ..shuffle(r);
  if (r.nextInt(3) == 0) {
    final inv = _invert(name);
    return GenQ(
      prompt: '$nameを転回する（下の音を1オクターブ上げる）と何になる？',
      answer: inv,
      wrong: [name, ...all],
      explanation: '転回すると度数は 9−${steps + 1}＝${8 - steps}、長↔短、増↔減、完全はそのまま。',
      category: QuestionCategory.thinking,
    );
  }
  return GenQ(
    prompt:
        '${_jpLetters[a]}（${_letters[a]}）から上の${_jpLetters[b]}（${_letters[b]}）までの音程は？',
    answer: name,
    wrong: all,
    explanation: '幹音で ${steps + 1} 度。半音は $semis 個なので$name。',
    category: QuestionCategory.thinking,
  );
}

bool _validName(String s) {
  final d = int.parse(RegExp(r'\d').firstMatch(s)![0]!);
  final perfectDeg = {1, 4, 5, 8}.contains(d);
  if (s.startsWith('完全')) return perfectDeg;
  if (s.startsWith('長') || s.startsWith('短')) return !perfectDeg;
  return d != 1 || s.startsWith('増');
}

/// 音を、指定した半音の数だけ上の、指定した幹音の数だけ上の音として書く
_Note? _above(_Note root, int letters, int semis) {
  final l = (root.letter + letters) % 7;
  final natural = _letterSemi[l];
  final target = (root.semi + semis) % 12;
  var acc = (target - natural) % 12;
  if (acc > 6) acc -= 12;
  if (acc.abs() > 1) return null;
  return _Note(l, acc);
}

const _chords = <(String, String, List<(int, int)>)>[
  // 名前・記号・（幹音の数, 半音の数）
  ('長三和音', '', [(2, 4), (4, 7)]),
  ('短三和音', 'm', [(2, 3), (4, 7)]),
  ('属七の和音の形', '7', [(2, 4), (4, 7), (6, 10)]),
  ('長七の和音', 'M7', [(2, 4), (4, 7), (6, 11)]),
  ('短七の和音', 'm7', [(2, 3), (4, 7), (6, 10)]),
  ('sus4', 'sus4', [(3, 5), (4, 7)]),
  ('増三和音', 'aug', [(2, 4), (4, 8)]),
  ('減三和音', 'dim', [(2, 3), (4, 6)]),
];

const _roots = [
  _Note(0, 0), _Note(1, 0), _Note(2, 0), _Note(3, 0), _Note(4, 0), _Note(5, 0),
  _Note(6, 0), //
  _Note(6, -1), _Note(2, -1), _Note(5, -1), _Note(3, 1), _Note(1, -1),
];

List<_Note>? _chordNotes(_Note root, List<(int, int)> parts) {
  final out = [root];
  for (final (l, s) in parts) {
    final n = _above(root, l, s);
    if (n == null) return null;
    out.add(n);
  }
  return out;
}

GenQ? _chordTones(Random r) {
  final root = r.pick(_roots);
  final (_, sym, parts) = r.pick(_chords);
  final notes = _chordNotes(root, parts);
  if (notes == null) return null;
  String f(List<_Note> ns) => ns.map((n) => n.english).join('・');
  final wrong = <String>[
    for (final (_, s2, p2) in _chords)
      if (s2 != sym && p2.length == parts.length)
        if (_chordNotes(root, p2) case final ns?) f(ns),
  ]..shuffle(r);
  return GenQ(
    prompt: 'コードネーム「${root.english}$sym」の構成音は？（英語音名）',
    answer: f(notes),
    wrong: wrong,
    explanation:
        '根音 ${root.english} から${parts.map((p) => '半音${p.$2}個').join('・')}上の音を重ねる。',
  );
}

const _degreeNames = ['主音', '上主音', '中音', '下属音', '属音', '下中音', '導音'];
const _roman = ['Ⅰ', 'Ⅱ', 'Ⅲ', 'Ⅳ', 'Ⅴ', 'Ⅵ', 'Ⅶ'];

GenQ? _scaleDegree(Random r) {
  if (r.nextBool()) {
    final i = r.nextInt(7);
    return GenQ(
      prompt: '音階の第${_roman[i]}音を何という？',
      answer: _degreeNames[i],
      wrong: [
        for (final n in [..._degreeNames]..shuffle(r)) n
      ],
      explanation: 'Ⅰ主音・Ⅱ上主音・Ⅲ中音・Ⅳ下属音・Ⅴ属音・Ⅵ下中音・Ⅶ導音',
      category: QuestionCategory.knowledge,
    );
  }
  final key = _Key(r.range(-5, 5), true);
  final i = r.pick([3, 4, 6]);
  final sc = key.scale;
  return GenQ(
    prompt: '${key.german} の${_degreeNames[i]}は？（ドイツ音名）',
    answer: sc[i].german,
    wrong: [
      for (final n in [...sc]..shuffle(r)) n.german
    ],
    explanation: '${key.german} の音階：${sc.map((n) => n.german).join('・')}',
  );
}

GenQ? _triadOfDegree(Random r) {
  final key = _Key(r.range(-4, 4), true);
  final i = r.pick([0, 3, 4]);
  final sc = key.scale;
  final tones = [sc[i], sc[(i + 2) % 7], sc[(i + 4) % 7]];
  String f(List<_Note> ns) => ns.map((n) => n.german).join('・');
  return GenQ(
    prompt: '${key.german} の${_roman[i]}の和音の構成音は？（ドイツ音名、根音から）',
    answer: f(tones),
    wrong: [
      for (final j in [0, 1, 2, 3, 4, 5, 6])
        if (j != i) f([sc[j], sc[(j + 2) % 7], sc[(j + 4) % 7]]),
    ]..shuffle(r),
    explanation: '音階の${_roman[i]}の音から、1つおきに3つ重ねる。',
  );
}

/// 音符の長さ・拍子
GenQ? _noteLength(Random r) {
  final notes = <(String, Rat)>[
    ('全音符', Rat(4)),
    ('2分音符', Rat(2)),
    ('4分音符', Rat(1)),
    ('8分音符', Rat(1, 2)),
    ('16分音符', Rat(1, 4)),
  ];
  if (r.nextBool()) {
    final (name, len) = r.pick(notes);
    final dotted = r.nextBool() && name != '16分音符';
    final v = dotted ? len * Rat(3, 2) : len;
    return GenQ(
      prompt: '4分音符を1としたとき、${dotted ? '付点' : ''}$nameの長さは？',
      answer: '$v',
      wrong: [
        '${v * Rat(2)}',
        '${v * Rat(1, 2)}',
        '${len}',
        '${v + Rat(1)}',
        '${len * Rat(2)}'
      ],
      explanation: dotted
          ? '付点は、もとの音符の半分の長さを加える：$len＋${len * Rat(1, 2)}'
          : '$nameは4分音符の $len 個分。',
    );
  }
  final top = r.pick([2, 3, 4, 6, 9, 12]);
  final bottom = {6, 9, 12}.contains(top)
      ? 8
      : top == 3
          ? r.pick([4, 8])
          : 4;
  final (name, len) = r.pick(notes.skip(2).toList());
  // 1小節の長さ（4分音符＝1）
  final bar = Rat(top * 4, bottom);
  final count = bar / len;
  if (!count.isInt) return null;
  return GenQ(
    prompt: '$top/$bottom 拍子の1小節に入る$nameの数は？',
    answer: _count(count.num),
    wrong: [
      _count(top),
      _count(count.num * 2),
      _count(max(1, count.num ~/ 2)),
      _count(count.num + 1)
    ],
    explanation: '1小節は4分音符 $bar 個分。$nameは $len 個分。',
  );
}

/// 9までは「つ」、10からは「個」
String _count(int n) => n <= 9 ? '$nつ' : '$n個';

final Map<String, List<Gen>> musicGens = {
  'music.theory.key.relation.parallel': [_relatedKey],
  'music.theory.key.relation.dominant': [_relatedKey],
  'music.theory.key.relation': [_relatedKey],
  'music.theory.key.signature.sharp': [_keySignature, _signatureOrder],
  'music.theory.key.signature.flat': [_keySignature, _signatureOrder],
  'music.theory.key.signature.minor': [_keySignature],
  'music.theory.notation.name.natural': [_noteNames],
  'music.theory.notation.interval.natural': [_interval],
  'music.theory.terms.chord.seventh': [_chordTones],
  'music.theory.terms.chord': [_chordTones],
  'music.theory.key.scale.degree': [_scaleDegree],
  'music.theory.harmony.degree': [_triadOfDegree],
  'music.theory.harmony.degree.major': [_triadOfDegree],
  'music.theory.notation.rhythm.note': [_noteLength],
  'music.theory.notation.rhythm.meter': [_noteLength],
};
