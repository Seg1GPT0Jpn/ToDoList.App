/// 定期テストの海：文法の単元。
class SeaUnit {
  const SeaUnit({
    required this.id,
    required this.grade,
    required this.number,
    required this.title,
    required this.topics,
  });

  /// 問題セットの setId も兼ねる（assets/questions/sea/<id>.json）
  final String id;

  /// 学年（1〜3）
  final int grade;
  final int number;
  final String title;

  /// この単元で扱う文法事項
  final List<String> topics;
}

/// 定期テストの海：単語帳（アプリ同梱の自作データ）。
class SeaWordBook {
  const SeaWordBook({
    required this.id,
    required this.title,
    required this.description,
  });

  /// 単語リストの listId（assets/words/<id>.json）
  final String id;
  final String title;
  final String description;
}

class SeaCatalog {
  const SeaCatalog._();

  static const gradeNames = {
    1: '中学1年',
    2: '中学2年',
    3: '中学3年',
  };

  static List<SeaUnit> unitsOf(int grade) =>
      units.where((u) => u.grade == grade).toList();

  static const units = <SeaUnit>[
    // ---- 中学1年 ----
    SeaUnit(id: 'sea_g1_01', grade: 1, number: 1, title: 'be動詞・一般動詞', topics: [
      'am / are / is',
      '一般動詞の現在形',
      '否定文と疑問文',
    ]),
    SeaUnit(id: 'sea_g1_02', grade: 1, number: 2, title: '名詞の複数形・代名詞', topics: [
      '名詞の複数形',
      '人称代名詞（I / my / me / mine）',
      'this / that',
    ]),
    SeaUnit(id: 'sea_g1_03', grade: 1, number: 3, title: '3人称単数現在', topics: [
      '3単現の s / es',
      'does / doesn\'t',
      'have → has',
    ]),
    SeaUnit(id: 'sea_g1_04', grade: 1, number: 4, title: '疑問詞', topics: [
      'what / who / whose',
      'where / when / which',
      'how / how many / how much',
    ]),
    SeaUnit(id: 'sea_g1_05', grade: 1, number: 5, title: '現在進行形', topics: [
      'be + ～ing',
      '進行形の否定文・疑問文',
      '～ing の作り方',
    ]),
    SeaUnit(id: 'sea_g1_06', grade: 1, number: 6, title: 'can と命令文', topics: [
      'can / can\'t',
      'Can I ～? / Can you ～?',
      '命令文・Let\'s ～',
    ]),
    SeaUnit(id: 'sea_g1_07', grade: 1, number: 7, title: '過去形', topics: [
      '規則動詞の過去形',
      '不規則動詞の過去形',
      'did / didn\'t',
      'was / were',
    ]),
    SeaUnit(id: 'sea_g1_08', grade: 1, number: 8, title: '過去進行形・There is', topics: [
      'was / were + ～ing',
      'There is / are',
    ]),
    // ---- 中学2年 ----
    SeaUnit(id: 'sea_g2_01', grade: 2, number: 1, title: '未来の表現', topics: [
      'will',
      'be going to',
      '未来の否定文・疑問文',
    ]),
    SeaUnit(id: 'sea_g2_02', grade: 2, number: 2, title: '助動詞', topics: [
      'must / have to',
      'should',
      'may / Shall I ～? / Will you ～?',
    ]),
    SeaUnit(id: 'sea_g2_03', grade: 2, number: 3, title: '不定詞', topics: [
      '名詞的用法',
      '副詞的用法',
      '形容詞的用法',
    ]),
    SeaUnit(id: 'sea_g2_04', grade: 2, number: 4, title: '動名詞', topics: [
      '動名詞の主語・目的語',
      '不定詞と動名詞の使い分け',
      '前置詞 + 動名詞',
    ]),
    SeaUnit(id: 'sea_g2_05', grade: 2, number: 5, title: '接続詞', topics: [
      'when / if / because',
      'that',
      'and / but / or / so',
    ]),
    SeaUnit(id: 'sea_g2_06', grade: 2, number: 6, title: '比較', topics: [
      '比較級・最上級',
      'as ～ as',
      'more / most',
      'better / best',
    ]),
    SeaUnit(id: 'sea_g2_07', grade: 2, number: 7, title: '受け身', topics: [
      'be + 過去分詞',
      'by ～',
      '受け身の否定文・疑問文',
    ]),
    SeaUnit(id: 'sea_g2_08', grade: 2, number: 8, title: 'いろいろな文型', topics: [
      'SVC（look / become）',
      'SVOO（give 人 物）',
      'SVOC（call / make）',
    ]),
    // ---- 中学3年 ----
    SeaUnit(id: 'sea_g3_01', grade: 3, number: 1, title: '現在完了', topics: [
      '完了・結果',
      '経験',
      '継続',
      '現在完了進行形',
    ]),
    SeaUnit(id: 'sea_g3_02', grade: 3, number: 2, title: '不定詞の発展', topics: [
      'It is ～ for 人 to ...',
      'want 人 to ...',
      '疑問詞 + to ...',
      'too ～ to / enough to',
    ]),
    SeaUnit(id: 'sea_g3_03', grade: 3, number: 3, title: '分詞の後置修飾', topics: [
      '現在分詞の修飾',
      '過去分詞の修飾',
    ]),
    SeaUnit(id: 'sea_g3_04', grade: 3, number: 4, title: '関係代名詞', topics: [
      '主格 who / which / that',
      '目的格 which / that',
      '関係代名詞の省略',
    ]),
    SeaUnit(id: 'sea_g3_05', grade: 3, number: 5, title: '間接疑問', topics: [
      '疑問詞 + 主語 + 動詞',
      'I know what ～',
    ]),
    SeaUnit(id: 'sea_g3_06', grade: 3, number: 6, title: '仮定法', topics: [
      'I wish ～',
      'If I were ～',
      'If + 過去形 ～ would',
    ]),
    SeaUnit(id: 'sea_g3_07', grade: 3, number: 7, title: '使役・知覚動詞と原形不定詞', topics: [
      'let / make / help 人 ～',
      'see / hear 人 ～',
    ]),
  ];

  /// 定期テストの海・高校入試の空に並べる単語帳（自作）
  static const wordBooks = <SeaWordBook>[
    SeaWordBook(id: 'words_j1', title: '中1の単語', description: '中学1年で習う基本の単語'),
    SeaWordBook(id: 'words_j2', title: '中2の単語', description: '中学2年で習う単語'),
    SeaWordBook(id: 'words_j3', title: '中3の単語', description: '中学3年・高校入試によく出る単語'),
    SeaWordBook(id: 'idioms_j', title: '中学の熟語', description: '高校入試によく出る熟語・会話表現'),
  ];
}
