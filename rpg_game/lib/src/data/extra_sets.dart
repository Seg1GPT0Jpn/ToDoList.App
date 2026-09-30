/// 定期テストの海の「追加問題」タブで練習できる問題セット。
/// RPG のエリアには入れず、単元ごとの練習としてだけ使う。
class ExtraSet {
  const ExtraSet(this.subject, this.id, this.title);

  /// 教科（english / science / social / japanese / math / information）
  final String subject;

  /// 問題セット ID（assets/questions/<subject>/<id>.json）
  final String id;
  final String title;
}

abstract final class ExtraSets {
  static const all = [
    ExtraSet('english', 'english_stage_exam_01', '語彙・熟語・英作文・長文'),
    ExtraSet('english', 'english_applied_reading_01', 'リスニング・図表・複数の英文'),
    ExtraSet('science', 'science_physics_rlc_01', '電磁気・交流・RLC 回路'),
    ExtraSet('social', 'social_current_2426_01', '最新時事（2024〜2026年）'),
    ExtraSet('japanese', 'japanese_ronri_01', '評論の論理構造・要旨'),
    ExtraSet('japanese', 'japanese_reading_comp_01', '小説・実用文・複数文章・古文・漢文'),
    ExtraSet('math', 'math_m1_stat_01', '統計（箱ひげ図・標準偏差・相関）'),
    ExtraSet('math', 'math_m1_logic_01', '集合と命題'),
    ExtraSet('math', 'math_quadratic_app_01', '2次関数の応用'),
    ExtraSet('information', 'information_prog_algo_01', 'プログラミング・アルゴリズム'),
    ExtraSet('information', 'information_prog_algo_02', 'プログラムのトレース・データの活用'),
    ExtraSet('information', 'information_data_db_01', 'データベース・データの活用'),
    ExtraSet('english', 'english_pron_01', '発音・アクセント'),
    ExtraSet('english', 'english_conversation_01', '会話表現'),
    ExtraSet('english', 'english_order_01', '並べかえ英作文'),
    ExtraSet('english', 'english_long_01', '長文読解（共通テスト型）'),
    ExtraSet('english', 'english_listening_01', 'リスニング（音声）'),
    ExtraSet('information', 'information_dncl_01', '共通テスト用プログラム表記'),
    ExtraSet('information', 'information_design_01', '情報デザイン・メディア'),
    ExtraSet('information', 'information_network_01', 'ネットワーク・セキュリティの計算'),
    ExtraSet('information', 'information_info2_01', '情報Ⅱ（データサイエンス・情報システム）'),
    ExtraSet('japanese', 'japanese_novel_01', '小説読解（心情・表現）'),
    ExtraSet('japanese', 'japanese_practical_01', '実用文・複数資料の読解'),
    ExtraSet('japanese', 'japanese_bungakushi_01', '文学史'),
    ExtraSet('japanese', 'japanese_idiom_01', '慣用句・ことわざ・四字熟語'),
    ExtraSet('japanese', 'japanese_keigo_01', '敬語'),
    ExtraSet('japanese', 'japanese_kanji_01', '漢字の読み（ひらがなで入力）'),
    ExtraSet('math', 'math_figure_01', '図形の性質（図つき）'),
    ExtraSet('math', 'math_trig_figure_01', '三角比と図形（図つき）'),
    ExtraSet('math', 'math_vector_figure_01', 'ベクトル（図つき）'),
    ExtraSet('math', 'math_input_01', '計算（答えを入力）'),
    ExtraSet('science', 'science_physics_basic_01', '物理基礎'),
    ExtraSet('science', 'science_chem_basic_01', '化学基礎'),
    ExtraSet('science', 'science_bio_basic_01', '生物基礎'),
    ExtraSet('science', 'science_earth_basic_01', '地学基礎'),
    ExtraSet('science', 'science_graph_01', '実験・グラフの考察（図つき）'),
    ExtraSet('social', 'social_kokyo_01', '公共'),
    ExtraSet('social', 'social_rekishisogo_01', '歴史総合'),
    ExtraSet('social', 'social_chirisogo_01', '地理総合（図つき）'),
  ];

  static List<ExtraSet> of(String subject) => [
        for (final s in all)
          if (s.subject == subject) s
      ];
}
