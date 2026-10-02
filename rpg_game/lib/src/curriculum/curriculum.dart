import 'data/curriculum_all.dart';

/// 学習体系の階層。
///
/// 教科（数学）→ 科目（数学Ⅰ）→ 分野（2次関数）→ 単元（2次関数の最大・最小）
/// → 小単元（文字を含む場合分け）。問題は単元か小単元のどちらかに属する。
enum CurriculumLevel {
  subject('教科'),
  course('科目'),
  field('分野'),
  unit('単元'),
  subUnit('小単元');

  const CurriculumLevel(this.label);
  final String label;
}

/// 学習体系の1つの節（教科・科目・分野・単元・小単元）。
///
/// ID は親の ID に「.」でつないだもの（例：`math.m1.quad.maxmin.param`）。
/// データは tool/curriculum/src/*.txt に書き、build.py で Dart に変換する。
class CurriculumNode {
  const CurriculumNode({
    required this.id,
    required this.name,
    required this.level,
    this.gameName = '',
    this.description = '',
    this.curriculumReference = '',
    this.source = '',
    this.sourceUrl = '',
    this.grade = '',
    this.prerequisites = const [],
    this.keywords = const [],
    this.children = const [],
  });

  final String id;

  /// 正式な名前（学習指導要領・教科書に近い名前）
  final String name;
  final CurriculumLevel level;

  /// ゲームの中で見せる名前（なければ [name]）
  final String gameName;

  /// 何を学ぶかの短い説明
  final String description;

  /// 学習指導要領のどこに当たるか（例：数学Ⅰ 内容(3) 2次関数）
  final String curriculumReference;

  /// 出典（空なら親から受け継ぐ。[Curriculum.sourceOf] を使う）
  final String source;
  final String sourceUrl;

  /// 主に学ぶ学年（'1'・'2'・'3'・'1-2' など。空なら親から受け継ぐ）
  final String grade;

  /// 先に学んでおきたい節の ID（学習ルートの逆算に使う）
  final List<String> prerequisites;

  /// 問題を小単元に振り分けるときの手がかりの言葉
  final List<String> keywords;
  final List<CurriculumNode> children;

  String get displayName => gameName.isEmpty ? name : gameName;

  /// 親の ID（教科なら null）
  String? get parentId {
    final i = id.lastIndexOf('.');
    return i < 0 ? null : id.substring(0, i);
  }

  /// 教科の ID（例：math）
  String get subjectId => id.split('.').first;

  bool get isLeaf => children.isEmpty;
}

/// 学習体系全体をたどるための入口。
class Curriculum {
  const Curriculum._();

  /// 全教科（数学・英語・国語・理科・社会・情報・音楽）
  static List<CurriculumNode> get subjects => allCurricula;

  static final Map<String, CurriculumNode> _byId = {
    for (final s in allCurricula)
      for (final n in _walk(s)) n.id: n,
  };

  static Iterable<CurriculumNode> _walk(CurriculumNode n) sync* {
    yield n;
    for (final c in n.children) {
      yield* _walk(c);
    }
  }

  /// すべての節（深さ優先の順）
  static Iterable<CurriculumNode> get all => _byId.values;

  static CurriculumNode? tryNode(String id) => _byId[id];

  static CurriculumNode node(String id) =>
      _byId[id] ?? (throw ArgumentError('学習体系にない ID です: $id'));

  static bool contains(String id) => _byId.containsKey(id);

  static CurriculumNode? parent(String id) {
    final p = node(id).parentId;
    return p == null ? null : _byId[p];
  }

  /// 教科から自分までの道すじ（教科が先頭）
  static List<CurriculumNode> pathOf(String id) {
    final out = <CurriculumNode>[];
    CurriculumNode? n = node(id);
    while (n != null) {
      out.insert(0, n);
      n = n.parentId == null ? null : _byId[n.parentId];
    }
    return out;
  }

  /// 指定した階層の祖先（自分がその階層なら自分）。なければ null
  static CurriculumNode? ancestorAt(String id, CurriculumLevel level) {
    for (final n in pathOf(id)) {
      if (n.level == level) return n;
    }
    return null;
  }

  /// 下にある節すべて（自分をふくむ）
  static Iterable<CurriculumNode> descendants(String id) => _walk(node(id));

  /// 出典（自分になければ親をさかのぼる）
  static (String, String) sourceOf(String id) {
    for (final n in pathOf(id).reversed) {
      if (n.source.isNotEmpty) return (n.source, n.sourceUrl);
    }
    return ('', '');
  }

  /// 学年（自分になければ親をさかのぼる）
  static String gradeOf(String id) {
    for (final n in pathOf(id).reversed) {
      if (n.grade.isNotEmpty) return n.grade;
    }
    return '';
  }

  /// 前提（自分と祖先に書かれた前提をまとめたもの）
  static List<String> prerequisitesOf(String id) => [
        for (final n in pathOf(id)) ...n.prerequisites,
      ];

  /// 問題ファイルを持たない問題セット（単語・熟語のリストから作る問題）の単元。
  /// 例：words_basic_enToJa → english.eng.vocab.basic.meaning
  static String? unitForGeneratedSet(String setId) {
    for (final e in _generatedSets.entries) {
      if (setId == e.key || setId.startsWith('${e.key}_')) return e.value;
    }
    return null;
  }

  static const _generatedSets = {
    'words_basic': 'english.eng.vocab.basic.meaning',
    'words_standard': 'english.eng.vocab.standard.meaning',
    'words_advanced': 'english.eng.vocab.advanced.meaning',
    'idioms_basic': 'english.eng.vocab.idiom.idiom',
    'tsuzutan_1': 'english.eng.vocab.basic.meaning',
    'tsuzutan_2': 'english.eng.vocab.standard.meaning',
    'tsuzutan_3': 'english.eng.vocab.advanced.meaning',
  };

  /// 「数学Ⅰ ＞ 2次関数 ＞ 最大・最小」のような表示（教科は省く）
  static String breadcrumb(String id, {String separator = ' ＞ '}) =>
      pathOf(id).skip(1).map((n) => n.name).join(separator);
}
