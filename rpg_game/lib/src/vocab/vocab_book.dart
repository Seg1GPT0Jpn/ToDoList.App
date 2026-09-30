/// 単語帳の1枚（1語）。
class VocabCard {
  const VocabCard({
    required this.id,
    required this.term,
    required this.meaning,
    this.number,
    this.pron = '',
    this.example = '',
    this.exampleJa = '',
  });

  /// 単語帳の中で一意な ID（番号があれば番号、なければ単語）
  final String id;

  /// 通し番号（取り込んだ一覧にあれば）
  final int? number;
  final String term;

  /// 意味（取り込んだ一覧の説明をそのまま保持）
  final String meaning;

  /// 発音記号（あれば）
  final String pron;

  /// 例文と、その訳（あれば）
  final String example;
  final String exampleJa;

  bool get hasExample => example.isNotEmpty && clozeOf(example, term) != null;

  static final _pos = RegExp(r'^\s*\[([^\]]+)\]');
  static final _senseMark = RegExp('[①②③④⑤⑥⑦⑧⑨⑩]');

  /// 品詞（[名] [他] など。なければ空）
  String get partOfSpeech => _pos.firstMatch(meaning)?.group(1) ?? '';

  /// 4択や答え合わせに出す短い意味（最初の品詞・最初の語義だけ）
  String get shortMeaning {
    var m = meaning.replaceFirst(_pos, '').trim();
    final nextPos = m.indexOf('[');
    if (nextPos > 0) m = m.substring(0, nextPos);
    final marks = _senseMark.allMatches(m).toList();
    if (marks.length >= 2) m = m.substring(0, marks[1].start);
    m = m.replaceAll(_senseMark, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return m.isEmpty ? meaning.trim() : m;
  }

  /// スペルとして正しいと認める書き方（「afterward(s)」→ afterward / afterwards など）
  List<String> get acceptedSpellings {
    var t = term.replaceAll(RegExp(r'[～~〜]'), '').trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    final paren = RegExp(r'\(([^)]*)\)');
    if (!paren.hasMatch(t)) return [t.toLowerCase()];
    final without = t.replaceAll(paren, '').replaceAll(RegExp(r'\s+'), ' ');
    final withIt = t.replaceAllMapped(paren, (m) => m.group(1)!);
    return {without.trim().toLowerCase(), withIt.trim().toLowerCase()}.toList();
  }

  /// 入力されたスペルが合っているか（大文字小文字・前後の空白は区別しない）
  bool spellingMatches(String input) {
    final a = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return a.isNotEmpty && acceptedSpellings.contains(a);
  }

  /// スペル入力のヒント（頭文字と文字数）
  String get spellingHint {
    final s = acceptedSpellings.first;
    return '${s[0]}${List.filled(s.length - 1, '＿').join()}（${s.length}文字）';
  }

  /// 例文の中の [term]（活用形もふくむ）を空欄にしたもの。見つからなければ null
  static String? clozeOf(String example, String term) {
    final m = _clozeMatch(example, term);
    if (m == null) return null;
    return example.replaceRange(m.$1, m.$2, '＿＿＿＿');
  }

  /// 例文の中で空欄にした語（「abandoned」など、活用した形のまま）
  static String? clozeWord(String example, String term) {
    final m = _clozeMatch(example, term);
    return m == null ? null : example.substring(m.$1, m.$2);
  }

  static (int, int)? _clozeMatch(String example, String term) {
    final base = term.replaceAll(RegExp(r'[～~〜()（）]'), '').trim();
    if (base.isEmpty) return null;
    if (base.contains(' ')) {
      final i = example.toLowerCase().indexOf(base.toLowerCase());
      return i < 0 ? null : (i, i + base.length);
    }
    // 語尾が変わる（-ed / -ing / -s / y→ied など）ことを考えて、語幹で探す
    final stem = base.length > 4 ? base.substring(0, base.length - 1) : base;
    final re = RegExp(
      '\\b${RegExp.escape(stem)}[a-z]*\\b',
      caseSensitive: false,
    );
    final m = re.firstMatch(example);
    return m == null ? null : (m.start, m.end);
  }

  /// 穴埋めの答えとして正しいか（元の形でも、例文の中の形でもよい）
  bool clozeMatches(String input) {
    final a = input.trim().toLowerCase();
    if (a.isEmpty) return false;
    final w = clozeWord(example, term)?.toLowerCase();
    return a == w || spellingMatches(a);
  }

  VocabCard copyWith(
          {String? pron,
          String? example,
          String? exampleJa,
          String? meaning}) =>
      VocabCard(
        id: id,
        number: number,
        term: term,
        meaning: meaning ?? this.meaning,
        pron: pron ?? this.pron,
        example: example ?? this.example,
        exampleJa: exampleJa ?? this.exampleJa,
      );

  factory VocabCard.fromJson(Map<String, dynamic> j) => VocabCard(
        id: j['id'] as String,
        number: (j['n'] as num?)?.toInt(),
        term: j['t'] as String,
        meaning: j['m'] as String,
        pron: j['p'] as String? ?? '',
        example: j['e'] as String? ?? '',
        exampleJa: j['ej'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (number != null) 'n': number,
        't': term,
        'm': meaning,
        if (pron.isNotEmpty) 'p': pron,
        if (example.isNotEmpty) 'e': example,
        if (exampleJa.isNotEmpty) 'ej': exampleJa,
      };
}

/// 単語帳の種類
enum VocabBookKind {
  /// 市販教材を利用者が自分の端末に取り込んだもの（パスワードで保護・同期しない）
  protectedImport,

  /// 利用者が自分で作った単語帳
  custom,
}

/// 単語帳
class VocabBook {
  VocabBook({
    required this.id,
    required this.title,
    required this.kind,
    required this.cards,
  });

  final String id;
  String title;
  final VocabBookKind kind;
  List<VocabCard> cards;

  bool get isProtected => kind == VocabBookKind.protectedImport;

  VocabCard? card(String id) {
    for (final c in cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// [incoming] を加える。同じ単語があれば、空いている項目（例文・発音）だけ埋める
  ({int added, int updated}) merge(List<VocabCard> incoming) {
    var added = 0, updated = 0;
    final byTerm = {for (final c in cards) c.term.toLowerCase(): c};
    final ids = cards.map((c) => c.id).toSet();
    for (final c in incoming) {
      final old = byTerm[c.term.toLowerCase()];
      if (old != null) {
        final merged = old.copyWith(
          pron: old.pron.isEmpty ? c.pron : null,
          example: old.example.isEmpty ? c.example : null,
          exampleJa: old.exampleJa.isEmpty ? c.exampleJa : null,
        );
        if (merged.pron != old.pron ||
            merged.example != old.example ||
            merged.exampleJa != old.exampleJa) {
          cards[cards.indexOf(old)] = merged;
          byTerm[c.term.toLowerCase()] = merged;
          updated++;
        }
        continue;
      }
      var id = c.id;
      while (ids.contains(id)) {
        id = '${id}_';
      }
      final fresh = VocabCard(
        id: id,
        number: c.number,
        term: c.term,
        meaning: c.meaning,
        pron: c.pron,
        example: c.example,
        exampleJa: c.exampleJa,
      );
      cards.add(fresh);
      ids.add(id);
      byTerm[c.term.toLowerCase()] = fresh;
      added++;
    }
    return (added: added, updated: updated);
  }

  factory VocabBook.fromJson(Map<String, dynamic> j) => VocabBook(
        id: j['id'] as String,
        title: j['title'] as String,
        kind: VocabBookKind.values.byName(j['kind'] as String),
        cards: [
          for (final c in j['cards'] as List)
            VocabCard.fromJson(c as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind.name,
        'cards': [for (final c in cards) c.toJson()],
      };
}

/// 貼り付けられた一覧を読み取る。
///
/// 対応する形式:
/// - 「番号<TAB>英単語<TAB>意味」（LEAP の一覧など）
/// - 「番号」「英単語」「■品詞：意味」が1行ずつ並んだ形（STEP の一覧など）
/// - CSV・TSV（1行目が見出しなら「term, meaning, pron, example, translation」などの列名で読む）
/// - Excel やスプレッドシートからコピーした表（タブ区切り）
class VocabParser {
  const VocabParser._();

  static final _stepMeaning = RegExp(r'^[■\[]');

  static List<VocabCard> parse(String text, {List<int>? skipped}) {
    final lines = text.split(RegExp(r'\r?\n'));
    if (_looksLikeStacked(lines)) return _parseStacked(lines);
    return _parseRows(lines, skipped);
  }

  /// 「番号」「単語」「■意味」が縦に並んだ形か
  static bool _looksLikeStacked(List<String> lines) {
    var hits = 0;
    for (var i = 0; i + 2 < lines.length && hits < 3; i++) {
      if (RegExp(r'^\s*\d+\s*$').hasMatch(lines[i]) &&
          lines[i + 1].trim().isNotEmpty &&
          lines[i + 2].trim().startsWith('■')) {
        hits++;
      }
    }
    return hits >= 2;
  }

  static List<VocabCard> _parseStacked(List<String> lines) {
    final cards = <VocabCard>[];
    for (var i = 0; i + 2 < lines.length; i++) {
      final n = int.tryParse(lines[i].trim());
      if (n == null) continue;
      final term = lines[i + 1].trim();
      final meaningLine = lines[i + 2].trim();
      if (term.isEmpty || !_stepMeaning.hasMatch(meaningLine)) continue;
      cards.add(VocabCard(
        id: '$n',
        number: n,
        term: term,
        meaning: normalizeStepMeaning(meaningLine),
      ));
      i += 2;
    }
    return cards;
  }

  /// 「■動詞：上がる；起きる　■名詞：上昇」→「[動] 上がる；起きる [名] 上昇」
  static String normalizeStepMeaning(String s) {
    const abbr = {
      '動詞': '動',
      '名詞': '名',
      '形容詞': '形',
      '副詞': '副',
      '前置詞': '前',
      '接続詞': '接',
      '助動詞': '助',
    };
    return s
        .replaceAllMapped(
          RegExp(r'■\s*([^：:]+?)\s*[：:]\s*'),
          (m) => ' [${abbr[m.group(1)!.trim()] ?? m.group(1)!.trim()}] ',
        )
        .replaceAll('　', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _headerNames = {
    'term': ['term', 'word', 'english', '単語', '英単語', '英語', 'front'],
    'meaning': ['meaning', 'japanese', 'definition', '意味', '日本語', '訳語', 'back'],
    'pron': ['pron', 'pronunciation', 'ipa', '発音', '発音記号'],
    'example': ['example', 'sentence', '例文'],
    'exampleJa': ['translation', 'example_ja', '例文訳', '訳', '和訳'],
    'number': ['no', 'no.', 'number', '番号', '#'],
  };

  static List<String> _split(String line) {
    if (line.contains('\t')) {
      return line.split('\t').map((c) => c.trim()).toList();
    }
    if (!line.contains(',')) return [line.trim()];
    // CSV（ダブルクォートで囲まれたカンマに対応）
    final out = <String>[];
    final buf = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == ',' && !quoted) {
        out.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    out.add(buf.toString().trim());
    return out;
  }

  static List<VocabCard> _parseRows(List<String> lines, List<int>? skipped) {
    final cards = <VocabCard>[];
    Map<String, int>? header;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      var cols = _split(line);
      if (header == null && cards.isEmpty) {
        final h = <String, int>{};
        for (var c = 0; c < cols.length; c++) {
          final name = cols[c].toLowerCase();
          for (final e in _headerNames.entries) {
            if (e.value.contains(name)) h.putIfAbsent(e.key, () => c);
          }
        }
        if (h.containsKey('term') && h.containsKey('meaning')) {
          header = h;
          continue;
        }
        // 「No 単語 意味」のような見出しは読み飛ばす
        if (h.length >= 2) continue;
      }
      if (header != null) {
        String at(String k) {
          final c = header![k];
          return c == null || c >= cols.length ? '' : cols[c];
        }

        final term = at('term'), meaning = at('meaning');
        if (term.isEmpty || meaning.isEmpty) {
          skipped?.add(i + 1);
          continue;
        }
        final n = int.tryParse(at('number'));
        cards.add(VocabCard(
          id: n != null ? '$n' : term.toLowerCase(),
          number: n,
          term: term,
          meaning: meaning,
          pron: at('pron'),
          example: at('example'),
          exampleJa: at('exampleJa'),
        ));
        continue;
      }
      if (cols.length < 2) {
        // タブが空白に変わってしまった場合: 「番号 英語 意味」を推測する
        final m = RegExp(
                r"^(\d+)\s+([A-Za-z][A-Za-z\-.'() ~～]*?)\s+(\[.*|[^A-Za-z].*)$")
            .firstMatch(line);
        if (m == null) {
          skipped?.add(i + 1);
          continue;
        }
        cols = [m.group(1)!, m.group(2)!, m.group(3)!];
      }
      int? number;
      if (cols.length >= 3 && int.tryParse(cols[0]) != null) {
        number = int.parse(cols[0]);
        cols = cols.sublist(1);
      }
      final term = cols[0];
      final meaning = cols.length > 1 ? cols[1] : '';
      if (term.isEmpty || meaning.isEmpty) {
        skipped?.add(i + 1);
        continue;
      }
      cards.add(VocabCard(
        id: number != null ? '$number' : term.toLowerCase(),
        number: number,
        term: term,
        meaning: meaning,
        example: cols.length > 2 ? cols[2] : '',
        exampleJa: cols.length > 3 ? cols[3] : '',
      ));
    }
    return cards;
  }
}
