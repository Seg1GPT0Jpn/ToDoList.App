import '../models/question.dart';

/// 単語帳の1語。
class WordEntry {
  const WordEntry({
    required this.term,
    required this.meaning,
    this.number,
    this.example = '',
    this.exampleJa = '',
    this.note = '',
  });

  /// 通し番号（取り込んだ一覧にあれば）
  final int? number;
  final String term;

  /// 意味（取り込んだ一覧の説明をそのまま保持）
  final String meaning;

  /// 例文とその訳、覚えるための豆知識（なければ空）
  final String example;
  final String exampleJa;
  final String note;

  static final _pos = RegExp(r'^\s*\[([^\]]+)\]');
  static final _senseMark = RegExp('[①②③④⑤⑥⑦⑧⑨⑩]');

  /// 品詞（[名] [他] など。なければ空）
  String get partOfSpeech => _pos.firstMatch(meaning)?.group(1) ?? '';

  /// 4択に出す短い意味（最初の品詞・最初の語義だけ）
  String get shortMeaning {
    var m = meaning.replaceFirst(_pos, '').trim();
    // 2つ目の品詞や語義が始まる前で切る
    final nextPos = m.indexOf('[');
    if (nextPos > 0) m = m.substring(0, nextPos);
    final marks = _senseMark.allMatches(m).toList();
    if (marks.length >= 2) m = m.substring(0, marks[1].start);
    m = m.replaceAll(_senseMark, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return m.isEmpty ? meaning.trim() : m;
  }

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        number: (json['number'] as num?)?.toInt(),
        term: json['term'] as String,
        meaning: json['meaning'] as String,
        example: json['example'] as String? ?? '',
        exampleJa: json['exampleJa'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (number != null) 'number': number,
        'term': term,
        'meaning': meaning,
        if (example.isNotEmpty) 'example': example,
        if (exampleJa.isNotEmpty) 'exampleJa': exampleJa,
        if (note.isNotEmpty) 'note': note,
      };
}

/// 単語帳（語のリスト）。
class WordList {
  WordList({
    required this.listId,
    required this.title,
    required this.origin,
    required this.words,
  });

  final String listId;
  final String title;
  final QuestionOrigin origin;
  final List<WordEntry> words;

  factory WordList.fromJson(Map<String, dynamic> json) => WordList(
        listId: json['listId'] as String,
        title: json['title'] as String,
        origin: QuestionOrigin.parse(json['origin'] as String),
        words: (json['words'] as List)
            .map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// 貼り付けられた一覧を読み取る。
  ///
  /// 1行1語で「番号<TAB>英語<TAB>意味」または「英語<TAB>意味」の形式。
  /// 読み取れない行は [skipped] に行番号を入れて飛ばす。
  static WordList parsePasted({
    required String listId,
    required String title,
    required String text,
    List<int>? skipped,
  }) {
    final words = <WordEntry>[];
    final lines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      var cols = line.split('\t').map((c) => c.trim()).toList();
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
      final meaning = cols.sublist(1).join(' ').trim();
      if (term.isEmpty || meaning.isEmpty) {
        skipped?.add(i + 1);
        continue;
      }
      words.add(WordEntry(number: number, term: term, meaning: meaning));
    }
    return WordList(
      listId: listId,
      title: title,
      origin: QuestionOrigin.personalImport,
      words: words,
    );
  }
}
