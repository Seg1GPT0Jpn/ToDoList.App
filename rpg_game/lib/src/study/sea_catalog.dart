import '../vocab/tsuzutan.dart';

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
    1: '高校1年（英コミⅠ・論理表現Ⅰ）',
    2: '高校2年（英コミⅡ・論理表現Ⅱ）',
    3: '高校3年（英コミⅢ・論理表現Ⅲ）',
  };

  static List<SeaUnit> unitsOf(int grade) =>
      units.where((u) => u.grade == grade).toList();

  static const units = <SeaUnit>[
    // ---- 高校1年 ----
    SeaUnit(id: 'sea_g1_01', grade: 1, number: 1, title: '文型・文構造', topics: [
      '第1〜第5文型',
      'There is / are 構文',
      'It is ～ to do',
      'It is ～ that …',
      'S + V + O + to do',
      'S + V + O + wh節',
    ]),
    SeaUnit(id: 'sea_g1_02', grade: 1, number: 2, title: '動詞・時制', topics: [
      '現在形・過去形',
      'will / be going to',
      '現在進行形・過去進行形',
      '現在完了・現在完了進行形',
    ]),
    SeaUnit(id: 'sea_g1_03', grade: 1, number: 3, title: '助動詞', topics: [
      'can / could',
      'may / might',
      'must / have to',
      'should / ought to',
      'will / would / shall',
      'need',
    ]),
    SeaUnit(id: 'sea_g1_04', grade: 1, number: 4, title: '不定詞', topics: [
      '名詞的・形容詞的・副詞的用法',
      '疑問詞 + to do',
      'too ～ to do',
      'enough to do',
      '原形不定詞',
    ]),
    SeaUnit(id: 'sea_g1_05', grade: 1, number: 5, title: '動名詞', topics: [
      '動名詞の基本用法',
      '動詞の目的語としての動名詞',
      '前置詞 + 動名詞',
      '動名詞の意味上の主語',
    ]),
    SeaUnit(id: 'sea_g1_06', grade: 1, number: 6, title: '分詞', topics: [
      '現在分詞・過去分詞',
      '分詞の形容詞的用法',
      '感情を表す分詞',
      '分詞を用いた表現',
    ]),
    SeaUnit(id: 'sea_g1_07', grade: 1, number: 7, title: '受動態', topics: [
      '現在・過去の受動態',
      '完了形の受動態',
      '助動詞 + 受動態',
      'by 以外の前置詞を使う受動態',
    ]),
    SeaUnit(id: 'sea_g1_08', grade: 1, number: 8, title: '比較', topics: [
      'as ～ as',
      '比較級 + than',
      'the + 最上級',
      'as ～ as possible',
    ]),
    SeaUnit(id: 'sea_g1_09', grade: 1, number: 9, title: '関係詞', topics: [
      '関係代名詞 who / which / that',
      '主格・目的格・所有格',
      '関係副詞の基本',
    ]),
    SeaUnit(id: 'sea_g1_10', grade: 1, number: 10, title: '仮定法', topics: [
      'if を用いた仮定',
      '仮定法過去',
      'I wish + 仮定法',
    ]),
    SeaUnit(id: 'sea_g1_11', grade: 1, number: 11, title: '接続詞・節', topics: [
      'and / but / or / so',
      'because / although',
      'when / while / before',
      'that節・if節',
    ]),
    SeaUnit(id: 'sea_g1_12', grade: 1, number: 12, title: '代名詞・その他', topics: [
      '人称代名詞・所有代名詞',
      '不定代名詞（one / other / each）',
      '指示代名詞',
      '前置詞',
    ]),
    // ---- 高校2年 ----
    SeaUnit(id: 'sea_g2_01', grade: 2, number: 1, title: '時制・完了', topics: [
      '過去完了・未来完了',
      '完了進行形',
      '時・条件の副詞節',
    ]),
    SeaUnit(id: 'sea_g2_02', grade: 2, number: 2, title: '助動詞の発展', topics: [
      'should have done',
      'must have done',
      "can't have done",
      'might have done',
      "needn't have done",
    ]),
    SeaUnit(id: 'sea_g2_03', grade: 2, number: 3, title: '不定詞の発展', topics: [
      '完了不定詞',
      '受動態の不定詞',
      '独立不定詞',
      '不定詞の意味上の主語',
    ]),
    SeaUnit(id: 'sea_g2_04', grade: 2, number: 4, title: '動名詞の発展', topics: [
      '完了動名詞',
      '受動動名詞',
      '動名詞と不定詞の使い分け',
    ]),
    SeaUnit(id: 'sea_g2_05', grade: 2, number: 5, title: '分詞構文', topics: [
      '現在分詞・過去分詞の分詞構文',
      '完了形の分詞構文',
      '否定の分詞構文',
      '慣用的な分詞構文',
    ]),
    SeaUnit(id: 'sea_g2_06', grade: 2, number: 6, title: '関係詞の発展', topics: [
      '非制限用法',
      '前置詞 + 関係代名詞',
      'what の用法',
      '複合関係詞',
    ]),
    SeaUnit(id: 'sea_g2_07', grade: 2, number: 7, title: '仮定法の発展', topics: [
      '仮定法過去完了',
      '混合仮定法',
      'wish / as if',
      'if の省略',
    ]),
    SeaUnit(id: 'sea_g2_08', grade: 2, number: 8, title: '比較の発展', topics: [
      '倍数表現',
      'the 比較級, the 比較級',
      '比較級 + than any other',
      '比較の慣用表現',
    ]),
    SeaUnit(id: 'sea_g2_09', grade: 2, number: 9, title: '否定', topics: [
      '部分否定',
      '二重否定',
      'hardly / rarely',
      'not ～ until …',
      'no sooner ～ than …',
    ]),
    SeaUnit(id: 'sea_g2_10', grade: 2, number: 10, title: '倒置・強調', topics: [
      '否定語句による倒置',
      'So / Neither',
      '強調構文 It is ～ that …',
      'do による強調',
    ]),
    SeaUnit(id: 'sea_g2_11', grade: 2, number: 11, title: '名詞・節', topics: [
      '名詞節 that / whether',
      'what節・wh節',
      '同格の that',
    ]),
    SeaUnit(id: 'sea_g2_12', grade: 2, number: 12, title: '複雑な文構造', topics: [
      '使役動詞',
      '知覚動詞',
      '無生物主語',
      'SVOC の発展',
    ]),
    // ---- 高校3年 ----
    SeaUnit(id: 'sea_g3_01', grade: 3, number: 1, title: '高度な関係詞', topics: [
      '連鎖関係詞',
      '前置詞 + 関係代名詞',
      '複合関係詞',
      '数量表現 + of which',
    ]),
    SeaUnit(id: 'sea_g3_02', grade: 3, number: 2, title: '高度な仮定法', topics: [
      '混合仮定法',
      "It's time + 仮定法",
      'but for',
      'suppose',
    ]),
    SeaUnit(id: 'sea_g3_03', grade: 3, number: 3, title: '高度な倒置', topics: [
      '否定語による倒置',
      '仮定法の倒置',
      '場所・方向の倒置',
      'so ～ that の倒置',
    ]),
    SeaUnit(id: 'sea_g3_04', grade: 3, number: 4, title: '省略', topics: [
      '主語 + be動詞の省略',
      '比較構文の省略',
      '代不定詞',
      'if 節の省略',
    ]),
    SeaUnit(id: 'sea_g3_05', grade: 3, number: 5, title: '強調・挿入・同格', topics: [
      '強調構文',
      'do による強調',
      '挿入句',
      '同格',
      '強調語句',
    ]),
    SeaUnit(id: 'sea_g3_06', grade: 3, number: 6, title: '複雑な分詞構文', topics: [
      '受動の分詞構文',
      '完了形の分詞構文',
      '独立分詞構文',
      'with + O + 分詞',
    ]),
    SeaUnit(id: 'sea_g3_07', grade: 3, number: 7, title: '複雑な不定詞・動名詞', topics: [
      '完了不定詞',
      '完了受動不定詞',
      '受動動名詞',
      '完了動名詞',
      'There is no ～ing',
    ]),
    SeaUnit(id: 'sea_g3_08', grade: 3, number: 8, title: '複雑な時制・態', topics: [
      '進行形の受動態',
      '未来完了の受動態',
      '助動詞 + 完了',
      '時制の一致',
    ]),
    SeaUnit(id: 'sea_g3_09', grade: 3, number: 9, title: '複雑な節・構文', topics: [
      '形式主語',
      'no matter + 疑問詞',
      'not A but B の強調構文',
      'the same ～ as',
    ]),
  ];

  static const baseWordBooks = <SeaWordBook>[
    SeaWordBook(
        id: 'words_basic', title: '単語・基礎', description: '高1前半レベルの基本語 40語'),
    SeaWordBook(
        id: 'words_standard',
        title: '単語・標準',
        description: '定期テスト・共通テストでよく見る語 40語'),
    SeaWordBook(
        id: 'words_advanced', title: '単語・難関', description: '難関大の長文で差がつく語 40語'),
    SeaWordBook(
        id: 'idioms_basic', title: '熟語', description: 'よく出る熟語・イディオム 40個'),
  ];

  /// 定期テストの海・模擬試験の空に並べる単語帳（自作の4冊＋つづ単）
  static List<SeaWordBook> get wordBooks =>
      [...baseWordBooks, ...Tsuzutan.seaBooks];
}
